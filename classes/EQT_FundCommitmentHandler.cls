/**
    About
    -----
    Description: Trigger Handler for the Fund Commitment SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Connect investor to commitment

    Update History
    --------------
    Created June 2016 - R.B.
    November 9, 2016   Added code to assign correct CurrencyIsoCode (same as Fund) to new fund commitments - felix.guerrero@fluidogroup.com
    December 5, 2016   Changed the 'calculate sums' routine to avoid using an aggregated result which would return the wrong amount
                       for commitments in USD (not equal to Org's default currency) - felix.guerrero@fluidogroup.com

    Issues / TODOs
    --------------
*/
public with sharing class EQT_FundCommitmentHandler implements EQT_ITrigger {

    //set of lp codes to process
    private Set<String> lpCodes = new Set<String>();
    //set of connected funds
    private Set<String> fundIds = new Set<String>();
    //Map of currencies of connected funds
    private Map<Id,String> fundCurrencyMap = new Map<Id,String>();
    //set of connected investors
    private Set<String> investorIds = new Set<String>();
    //investor map, lpCode -> EQT_Investor_LP_Code__c
    private Map<String, EQT_Investor_LP_Code__c> investorLPCodeMap = new Map<String, EQT_Investor_LP_Code__c>();
    //list of commitments to be updated
    private List<EQT_Commitment__c> commitmentsToUpdate = new List<EQT_Commitment__c>();
    //set(EQT_Fund__c + ':' + EQT_Investor__c) of already existing commitments
    private Set<String> existingCommitments = new Set<String>();
    //list of commitments to create
    private Map<String, EQT_Commitment__c> commitmentsToInsert = new Map<String, EQT_Commitment__c>();

    public EQT_FundCommitmentHandler() {}

    public void bulkBefore() {
        if(Trigger.isInsert) {
            Set<Id> fundSet = new Set<Id>(); // Ids of funds to query
            for(SObject so : Trigger.new) {
                if(so.get('EQT_LP_Code__c') != null) {
                    lpCodes.add((String)so.get('EQT_LP_Code__c'));
                }
                if(so.get('EQT_Fund__c') != null)
                    fundSet.add((Id)so.get('EQT_Fund__c'));
            }

            if(!lpCodes.isEmpty()) {
                for(EQT_Investor_LP_Code__c ilcp : [SELECT Id, Name, EQT_Investor__c
                                                    FROM EQT_Investor_LP_Code__c
                                                    WHERE Name IN :lpCodes]) {

                    investorLPCodeMap.put(ilcp.Name, ilcp);
                }
            }
            if(!fundSet.isEmpty()) // Gather the Currency of each related Fund in a map
                for(Fund__c f : [SELECT Id, CurrencyIsoCode FROM Fund__c WHERE Id IN :fundSet])
                        fundCurrencyMap.put(f.Id, f.CurrencyIsoCode);
        }
    }
    
    public void bulkAfter() {
        if(Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> investorSet = new Set<Id>();
            Set<Id> fundSet = new Set<Id>();

            for(SObject so : Trigger.new) {
                if(so.get('EQT_Investor__c') != null
                    && so.get('EQT_Fund__c') != null) {

                    //store investor and fund ids
                    investorSet.add((Id)so.get('EQT_Investor__c'));
                    fundSet.add((Id)so.get('EQT_Fund__c'));
                }
            }

            if(!investorSet.isEmpty() && !fundSet.isEmpty()) {
                for(EQT_Commitment__c c : [SELECT Id, EQT_Fund__c, EQT_Investor__c FROM EQT_Commitment__c
                                            WHERE EQT_Fund__c IN :fundSet
                                            AND EQT_Investor__c IN :investorSet]) {
                    existingCommitments.add(c.EQT_Fund__c + ':' + c.EQT_Investor__c);
                }
            }
        }
    }
        
    public void beforeInsert(SObject so) {
        EQT_Fund_Commitment__c fc = (EQT_Fund_Commitment__c)so;

        if(fc.EQT_Investor__c == null && fc.EQT_LP_Code__c != null
            && investorLPCodeMap.containsKey(fc.EQT_LP_Code__c)
            && investorLPCodeMap.get(fc.EQT_LP_Code__c).EQT_Investor__c != null) {

            fc.EQT_Investor__c = investorLPCodeMap.get(fc.EQT_LP_Code__c).EQT_Investor__c;
        }
        // Set the currency equals to that of the parent fund
        if(fc.EQT_Fund__c != null && fundCurrencyMap.containsKey(fc.EQT_Fund__c))
            fc.CurrencyIsoCode = fundCurrencyMap.get(fc.EQT_Fund__c);
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        EQT_Fund_Commitment__c fc = (EQT_Fund_Commitment__c)so;

        //add fund and investor to sets for later process
        if(fc.EQT_Fund__c != null && fc.EQT_Investor__c != null
            && fc.EQT_Amount__c != null && fc.EQT_Amount__c != 0) {
            fundIds.add(fc.EQT_Fund__c);
            investorIds.add(fc.EQT_Investor__c);
        }

        //if mapping is set check for Commitment record for such pair
        if(fc.EQT_Fund__c != null && fc.EQT_Investor__c != null) {
            String key = fc.EQT_Fund__c + ':' + fc.EQT_Investor__c;

            //if mapping is done but no commitment record is existsing for such pair - create it
            if(!existingCommitments.contains(key)) {
                commitmentsToInsert.put(key, new EQT_Commitment__c(
                    EQT_Fund__c = fc.EQT_Fund__c,
                    EQT_Investor__c = fc.EQT_Investor__c));

                fundIds.add(fc.EQT_Fund__c);
                investorIds.add(fc.EQT_Investor__c);
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        EQT_Fund_Commitment__c fcNew = (EQT_Fund_Commitment__c)so;
        EQT_Fund_Commitment__c fcOld = (EQT_Fund_Commitment__c)oldSo;

        if(fcNew.EQT_Fund__c != null && fcnew.EQT_Investor__c != null
            && fcNew.EQT_Amount__c != fcOld.EQT_Amount__c
            ) {
            fundIds.add(fcNew.EQT_Fund__c);
            investorIds.add(fcNew.EQT_Investor__c);
        }

        //if mapping is set check for Commitment record for such pair
        if(fcNew.EQT_Fund__c != null && fcnew.EQT_Investor__c != null) {
            String key = fcNew.EQT_Fund__c + ':' + fcNew.EQT_Investor__c;

            //if mapping is done but no commitment record is existsing for such pair - create it
            if(!existingCommitments.contains(key)) {
                commitmentsToInsert.put(key, new EQT_Commitment__c(
                    EQT_Fund__c = fcNew.EQT_Fund__c,
                    EQT_Investor__c = fcNew.EQT_Investor__c));

                fundIds.add(fcNew.EQT_Fund__c);
                investorIds.add(fcNew.EQT_Investor__c);
            }
        }
    }
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        //first insert new commitments
        if(!commitmentsToInsert.isEmpty()) {
            insert commitmentsToInsert.values();
        }
        List<EQT_Fund_Commitment__c> fundCommitmentsToUpdate = new List<EQT_Fund_Commitment__c>();
        //calculate sums
        if(!fundIds.isEmpty() && !investorIds.isEmpty()) {
            //build map of commitments for later process
            Map<String, EQT_Commitment__c> commitmentMap = new Map<String, EQT_Commitment__c>();
            for(EQT_Commitment__c c : [SELECT Id, EQT_Amount__c, EQT_Fund__c, EQT_Investor__c
                                       FROM EQT_Commitment__c
                                       WHERE EQT_Fund__c IN :fundIds
                                       AND EQT_Investor__c IN :investorIds]) {
                                           commitmentMap.put(c.EQT_Fund__c + ':' + c.EQT_Investor__c, c);
                                       }
            if(!commitmentMap.isEmpty()) {
                //calculate sums
                Map<String, Decimal> commitmentSumMap = new Map<String, Decimal>();
                for(EQT_Fund_Commitment__c fc : [
                    SELECT EQT_Fund__c, EQT_Investor__r.Name, EQT_Investor__c, EQT_Amount__c,EQT_Commitment__c
                    FROM EQT_Fund_Commitment__c
                    WHERE EQT_Fund__c IN :fundIds
                    AND EQT_Investor__c IN :investorIds
                    ORDER BY EQT_Fund__c, EQT_Investor__c]){
                        
                        String fundId = fc.EQT_Fund__c;
                        String investorId = fc.EQT_Investor__c;
                        Decimal amount = fc.EQT_Amount__c;
                        String mapKey = fundId + ':' + investorId;
                        if(amount > 0){
                            if(!commitmentSumMap.containsKey(mapKey))
                                commitmentSumMap.put(mapKey,amount);
                            else{
                                Decimal tempamount = commitmentSumMap.get(mapKey);
                                tempamount += amount;
                                commitmentSumMap.put(mapKey,tempamount);
                            }
                        }
                        System.debug(commitmentMap.get(mapKey));
                        if(commitmentMap.containsKey(mapKey)){
                            Id commitmentId = commitmentMap.get(mapKey).Id;
                            if(fc.EQT_Commitment__c != commitmentId){
                                fc.EQT_Commitment__c = commitmentId;
                                fundCommitmentsToUpdate.add(fc);
                            }
                        }
                    }
                    for(String mapKey : commitmentMap.keySet()){
                        if(commitmentSumMap.containsKey(mapKey)){
                            EQT_Commitment__c c = commitmentMap.get(mapKey);
                            if(c.EQT_Amount__c != commitmentSumMap.get(mapKey)){
                                c.EQT_Amount__c = commitmentSumMap.get(mapKey);
                                commitmentsToUpdate.add(c);
                            }
                        }
                    }
             }
            if(!commitmentsToUpdate.isEmpty()) {
                update commitmentsToUpdate;
            }
            if(!fundCommitmentsToUpdate.isEmpty()) {
                System.debug('Updating Fund Commitments. List size:'+fundCommitmentsToUpdate.size());
                update fundCommitmentsToUpdate;
            }
        }
    }
}