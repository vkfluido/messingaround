/**
    About
    -----
    Description: Trigger Handler for the Commitment__c SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Based on related Fund Strategy value select appropriate checkbox on related investor field.

    Update History
    --------------
    Created May 2016 - R.B.
    Updated September 2016 - R.B. - commented out trigger body according to TA768 remove fields on Account
    November 9, 2016   Added code to assign correct CurrencyIsoCode (same as Fund) to new Commitments - felix.guerrero@fluidogroup.com

    Issues / TODOs
    --------------
*/
 public with sharing class EQT_CommitmentHandler implements EQT_ITrigger {

    private Set<Id> investorIds = new Set<Id>();
    //Investor -> map of commitments
    private Map<String, Map<Id,EQT_Commitment__c>> investorCommitmentMap = new Map<String, Map<Id,EQT_Commitment__c>>();
    //Investor map to process and update
    private Map<Id, Account> investorMap = new Map<Id, Account>();
    //Map of currencies of connected funds
    private Map<Id,String> fundCurrencyMap = new Map<Id,String>();

    public EQT_CommitmentHandler() {}

	public void bulkBefore() {
        if(Trigger.isInsert) {
            Set<Id> fundSet = new Set<Id>(); // Ids of funds to query
            for(SObject so : Trigger.new)
                if(so.get('EQT_Fund__c') != null)
                        fundSet.add((Id)so.get('EQT_Fund__c'));
            if(!fundSet.isEmpty()) // Gather the Currency of each related Fund in a map
                for(Fund__c f : [SELECT Id, CurrencyIsoCode FROM Fund__c WHERE Id IN :fundSet])
                        fundCurrencyMap.put(f.Id, f.CurrencyIsoCode);
        }
    }
    
    public void bulkAfter() {
        /* TA768 remove fields on Account
        //Use case 1. Get related investor ids for later process
        if(Trigger.isInsert) {
            for(Sobject commitment : Trigger.new) {
                if(commitment.get('EQT_Investor__c') != null) {
                    investorIds.add((Id)commitment.get('EQT_Investor__c'));
                }
            }
        }
        else if(Trigger.isUpdate) {
            for(Sobject commitment : Trigger.new) {
                SObject oldCommitment = Trigger.oldMap.get((Id) commitment.get('Id'));
                if(commitment.get('EQT_Investor__c') != null
                    && commitment.get('EQT_Investor__c') != oldCommitment.get('EQT_Investor__c')) {

                    investorIds.add((Id)commitment.get('EQT_Investor__c'));
                    investorIds.add((Id)oldCommitment.get('EQT_Investor__c'));
                }
            }
        }
        else if(Trigger.isDelete) {
            for(Sobject commitment : Trigger.old) {
                if(commitment.get('EQT_Investor__c') != null) {
                    investorIds.add((Id)commitment.get('EQT_Investor__c'));
                }
            }
        }

        //Use case 1. Build investors map for later process
        if(!investorIds.isEmpty()) {
            investorMap = new Map<Id, Account>
            (
                [
                    SELECT Id, EQT_Equity__c, EQT_Mid_Market__c,
                    EQT_Credit__c, EQT_Infrastructure__c
                    FROM Account
                    WHERE Id IN :investorIds
                ]
            );

            //Use case 1. Build commitment map for each investor to be sure that proper checkbox is selected
            for(EQT_Commitment__c commitment : [SELECT Id, EQT_Investor__c, EQT_Fund_Strategy__c
                                                FROM EQT_Commitment__c
                                                WHERE EQT_Investor__c IN :investorIds]) {
                if(investorCommitmentMap.containsKey(commitment.EQT_Investor__c)) {
                    investorCommitmentMap.get(commitment.EQT_Investor__c).put(commitment.Id, commitment);
                }
                else {
                    Map<Id,EQT_Commitment__c> commitmentMap = new Map<Id,EQT_Commitment__c>();
                    commitmentMap.put(commitment.Id, commitment);
                    investorCommitmentMap.put(commitment.EQT_Investor__c, commitmentMap);
                }
            }
        }
        */
    }
        
    public void beforeInsert(SObject so) {
        EQT_Commitment__c c = (EQT_Commitment__c)so;
        // Set the currency equals to that of the parent fund
        if(c.EQT_Fund__c != null && fundCurrencyMap.containsKey(c.EQT_Fund__c))
            c.CurrencyIsoCode = fundCurrencyMap.get(c.EQT_Fund__c);
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {}
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        /*
            3  -> Equity
            6  -> Credit
            7  -> Infrastructure
            10 -> Mid Market
            11 -> Senior Debt
        */

        /* TA768 remove fields on Account
        //Use case 1. Mark proper checkbox for each investor based on this commitments
        if(!investorMap.isEmpty()) {
            for(Id accountId : investorMap.keySet()) {
                Account investor = investorMap.get(accountId);
                //set all values to defaults
                investor.EQT_Equity__c = false;
                investor.EQT_Credit__c = false;
                investor.EQT_Infrastructure__c = false;
                investor.EQT_Mid_Market__c = false;

                if(investorCommitmentMap.containsKey(accountId)) {
                    for(EQT_Commitment__c commitment : investorCommitmentMap.get(accountId).values()) {
                        if(commitment.EQT_Fund_Strategy__c == '3') {
                            investor.EQT_Equity__c = true;
                        }
                        else if(commitment.EQT_Fund_Strategy__c == '6'
                                || commitment.EQT_Fund_Strategy__c == '11') {
                            investor.EQT_Credit__c = true;
                        }
                        else if(commitment.EQT_Fund_Strategy__c == '7') {
                            investor.EQT_Infrastructure__c = true;
                        }
                        else if(commitment.EQT_Fund_Strategy__c == '10') {
                            investor.EQT_Mid_Market__c = true;
                        }
                    }
                }
                
            }

            update investorMap.values();
        }
        */
    }
}