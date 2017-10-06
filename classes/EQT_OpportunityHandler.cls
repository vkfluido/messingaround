/**
    About
    -----
    Description: Trigger Handler for the Opportunity SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use Case 1. Set record type ID based on record type name provided by external system (EPM)
    Use Case 2. Set EQT_E_T_TT__c field on opportunity based on related Commitments
    Use Case 3. Set rollup summary fields on Fund
    Use Case 4. Creating gatekeeper association records if they don't exists
    Use Case 5. Autopopulate Account county value (translation workbench)
    Use Case 6. Populate EQT_Invested_Previous_Fund__c with the investors commitment in Previous fund
    Use Case 7. Set first interaction date

    Update History
    --------------
    Created May 2016 - R.B.
    Updated July 2016 - R.B. Added use case 4
    Updated February 2017 - R.B. Logic for E/T/TT should fire only for Fundraising Request Opportunity Record type
    Updated May - F.A. Autopopulating CurrencyIsoCode from related fund for IR opportunities on Create - Trello 194-eqt-mid-market-asia-iii-opportunities-showing-bite-size-in-eur-instead-of-usd
    
    Issues / TODOs
    --------------
*/
public with sharing class EQT_OpportunityHandler implements EQT_ITrigger {
    
    /* TA384 Commented out according to demo on 11.05.2016
    
    //Map<OpportunityChildId, OpportunityParent>
    private Map<Id, Opportunity> childParentMap = new Map<Id, Opportunity>();
    private Map<Id, Id> childParentIdMap = new Map<Id, Id>();
    
    private List<OpportunityTeamMember> oppMembersToAdd = new List<OpportunityTeamMember>();
    private Set<Id> opportunityIdsToDeleteTeamMembers = new Set<Id>();
    */

    //private Set<String> closedWonStages = new Set<String>();
    //private Set<String> notClosedStages = new Set<String>();
    private Set<Id> fundToProcessIds = new Set<Id>();
    //private List<String> opportunity1stCloseValues = new List<String>();
    private Set<String> investorIds = new Set<String>();
    private Map<String, List<EQT_Commitment__c>> investorCommitmentMap = new Map<String, List<EQT_Commitment__c>>();
    private String fundraisingRecordTypeId;
    private Set<Id> gatekeeperIds = new Set<Id>();
    private Set<Id> oppAccountIds = new Set<Id>();
    private Map<String, EQT_Investor_Gatekeeper_Associations__c> gatekeeperAssociationMap = new Map<String, EQT_Investor_Gatekeeper_Associations__c>();
    private Map<String, EQT_Investor_Gatekeeper_Associations__c> associationsToInsert = new Map<String, EQT_Investor_Gatekeeper_Associations__c>();
    private Set<Id> accountIds = new Set<Id>();
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    //Use Case 6
    private Set<Id> fundIds = new Set<Id>(); //funds to get previous funds
    private Map<Id, Id> fundPrevFundMap = new Map<Id, Id>(); //funds with prev funds map (fundId -> prevFundId)
    //Use Case 7
    private Set<Id> updatedOpportunityIds = new Set<Id>();
    private Map<Id, Opportunity> opportunityActivityMap = new Map<Id, Opportunity>();
    private Map<String, Decimal> currencyConversionRateMap = new Map<String, Decimal>();
    // Investor Not Interested Preferences Map
    private Map<Id, Set<String>> investorsNotInterestedPreferencesMap = new Map<Id, Set<String>>();
    private Map<Id, String> fundId2StrategyMap = new Map<Id, String>();
    private Set<Id> changedOwnerOpportunityIds = new Set<Id>();
    private Map<Id, String> irFundIdToCurrencyMap = new Map<Id, String>(); // Trello 194-eqt-mid-market-asia-iii-opportunities-showing-bite-size-in-eur-instead-of-usd
    
    // Constructor
    public EQT_OpportunityHandler() {}

    public void bulkBefore() {
        // TA449
        if(Trigger.isInsert) {
            String oppChildRecordTypeName = 'Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName();
            String oppCoInvestmentRecordTypeName = 'Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName();

            for(sObject opp : Trigger.new) {
                Opportunity theOpp = (Opportunity) opp;
                /*
                // Use case 1. Set record type ID based on record type name provided by external system (EPM)
                // - Checks for EPM Record Type Name set by external system & set record type ID on record
                if (theOpp.EQT_EPM_Record_Type_Name__c!=null) {
                    try {
                        // -Set record type ID
                        theOpp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.'+theOpp.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
                    } catch (Exception e) {
                        // -Do nothing if no match found
                    }
                }
                */

                system.debug('theOpp.currencyIsoCode: ' + theOpp.currencyIsoCode);

                //Use Case 2.
                //if record type is set to "Fundraising Request"
                if((Id)opp.get('RecordTypeId') == EQT_UTIL_Meta.getRecordTypeId(oppChildRecordTypeName)) {
                    investorIds.add((String)opp.get('AccountId'));

                    if(opp.get('EQT_Fund__c') != null) {
                        fundIds.add((Id)opp.get('EQT_Fund__c'));
                    }
                }

                //Use Case 5 - get account id for later process
                if(theOpp.AccountId != null) {
                    accountIds.add(theOpp.AccountId);
                }

                if(theOpp.EQT_Fund__c != null) {
                    fundId2StrategyMap.put(theOpp.EQT_Fund__c, null);
                }
                
                // Trello 194-eqt-mid-market-asia-iii-opportunities-showing-bite-size-in-eur-instead-of-usd
                if(
                    (
                        theOpp.RecordTypeId == EQT_UTIL_Meta.getRecordTypeId(oppChildRecordTypeName) ||
                        theOpp.RecordTypeId == EQT_UTIL_Meta.getRecordTypeId(oppCoInvestmentRecordTypeName)
                    ) &&
                    theOpp.EQT_Fund__c != null
                ){
                    irFundIdToCurrencyMap.put(theOpp.EQT_Fund__c, null);
                }
                
            }

            //Use Case 2. build commitment map for investors for later process
            if(!investorIds.isEmpty()) {
                //build Account -> Commitment map
                for(EQT_Commitment__c comm : [SELECT Id, EQT_Investor__c, EQT_Fund_Strategy__c, EQT_Fund__c,
                                                EQT_Fund__r.EQT_Previous_Fund__c, EQT_Amount__c, CurrencyIsoCode
                                                FROM EQT_Commitment__c
                                                WHERE EQT_Investor__c IN :investorIds]) {
                    if(investorCommitmentMap.containsKey(comm.EQT_Investor__c)) {
                        investorCommitmentMap.get(comm.EQT_Investor__c).add(comm);
                    }
                    else {
                        List<EQT_Commitment__c> commList = new List<EQT_Commitment__c>();
                        commList.add(comm);
                        investorCommitmentMap.put(comm.EQT_Investor__c, commList);
                    }
                }
            }

            //Use Case 6 - build fund previous fund map
            if(!fundIds.isEmpty()) {
                for(Fund__c f : [SELECT Id, EQT_Previous_Fund__c FROM Fund__c
                                    WHERE Id IN :fundIds]) {
                    if(f.EQT_Previous_Fund__c != null) {
                        fundPrevFundMap.put(f.Id, f.EQT_Previous_Fund__c);
                    }
                }
            }

            // Build Investor Not Interested prefferences map
            if(!accountIds.isEmpty()){
                List<EQT_Investor_Preference_PE__c> investorsNotInterestedPreferencesList = [
                    SELECT Id, EQT_Account__c, EQT_Strategy__c
                    FROM EQT_Investor_Preference_PE__c
                    WHERE
                        EQT_Account__c IN :accountIds AND
                        EQT_Interested_Not_Interested__c = 'Not Interested'
                ];

                if(!investorsNotInterestedPreferencesList.isEmpty()){
                    for(EQT_Investor_Preference_PE__c investorPreferencesItem : investorsNotInterestedPreferencesList){
                        if(!investorsNotInterestedPreferencesMap.containsKey(investorPreferencesItem.EQT_Account__c)){
                            investorsNotInterestedPreferencesMap.put(investorPreferencesItem.EQT_Account__c, new Set<String>() );
                        }
                        investorsNotInterestedPreferencesMap.get(investorPreferencesItem.EQT_Account__c).add(investorPreferencesItem.EQT_Strategy__c);
                    }
                }
            }

            if(!fundId2StrategyMap.isEmpty()){
                List<Fund__c> fundsList = [
                    SELECT Id, EQT_Fund_Strategy__c
                    FROM Fund__c
                    WHERE Id IN :fundId2StrategyMap.keySet()
                ];
                for(Fund__c fundItem : fundsList){
                    fundId2StrategyMap.put(fundItem.Id, fundItem.EQT_Fund_Strategy__c);
                }
            }
            
            // Trello 194-eqt-mid-market-asia-iii-opportunities-showing-bite-size-in-eur-instead-of-usd
            if(!irFundIdToCurrencyMap.isEmpty()){
                List<Fund__c> fundsList = [SELECT Id, CurrencyIsoCode FROM Fund__c WHERE Id IN :irFundIdToCurrencyMap.keySet()];
                
                for(Fund__c f : fundsList){
                    irFundIdToCurrencyMap.put(f.Id, f.CurrencyIsoCode);
                }
            }
        }
        else if(Trigger.isUpdate) {
            //Use Case 5 - get account id for later process
            for(sObject opp : Trigger.new) {
                Opportunity theOpp = (Opportunity) opp;
                Opportunity theOpp_old = (Opportunity) Trigger.oldMap.get(opp.Id);

                if(theOpp.AccountId != null) {
                    accountIds.add(theOpp.AccountId);
                }

                //Use Case 7
                if(theOpp.EQT_First_Interaction_Date__c == null) {
                    updatedOpportunityIds.add(theOpp.Id);
                }
            }
        }

        if(!accountIds.isEmpty()) {
            accountMap = new Map<Id, Account>
            (
                [
                    SELECT Id, EQT_Country__c
                    FROM Account
                    WHERE Id IN :accountIds
                ]
            );
        }

        //Use case 7 build activity map for opportunities without EQT_First_Interaction_Date__c
        if(!updatedOpportunityIds.isEmpty()) {
            opportunityActivityMap = new Map<Id, Opportunity>
            (
                [
                    SELECT Id, Name,
                        (SELECT Id, StartDateTime FROM Events ORDER BY StartDateTime LIMIT 1),
                        (SELECT Id, ActivityDate FROM Tasks ORDER BY ActivityDate LIMIT 1)
                    FROM Opportunity
                    WHERE Id IN :updatedOpportunityIds
                ]
            );
        }

        //build currency coversion rate map
        currencyConversionRateMap = new Map<String, Decimal>();
        for(CurrencyType ct : [SELECT Id, IsoCode, ConversionRate
                                FROM CurrencyType
                                WHERE IsActive = true]) {

            currencyConversionRateMap.put(ct.IsoCode, ct.ConversionRate);
        }
        /*
        if (Trigger.isUpdate) {
            for(sObject opp : Trigger.new) {
                Opportunity theOpp = (Opportunity) opp;
                Opportunity theOpp_old = (Opportunity) Trigger.oldMap.get(opp.Id);
                
                // Use case 1. Set record type ID based on record type name provided by external system (EPM)
                // - Checks for EPM Record Type Name set by external system & set record type ID on record
                if (theOpp.EQT_EPM_Record_Type_Name__c!=null && (theOpp.EQT_EPM_Record_Type_Name__c != theOpp_old.EQT_EPM_Record_Type_Name__c)) {
                    try {
                        // -Set record type ID
                        theOpp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.'+theOpp.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
                    } catch (Exception e) {
                        // -Do nothing if no match found
                    }
                }
            }
        }
        */
    }
    
    public void bulkAfter() {
        /* TA384 Commented out according to demo on 11.05.2016
        String oppChildRecordTypeName = 'Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName();

        if(Trigger.isInsert || Trigger.isUpdate) {
            for(sObject opp : Trigger.new) {
                //if record type is set to "Fundraising Request" and we have parent opportunity set
                if((Id)opp.get('RecordTypeId') == EQT_UTIL_Meta.getRecordTypeId(oppChildRecordTypeName) && opp.get('EQT_Fundraise__c') != null) {
                    childParentIdMap.put((Id)opp.get('Id'), (Id) opp.get('EQT_Fundraise__c'));
                }
            }
        }
        
        if(!childParentIdMap.isEmpty()) {
            childParentMap = EQT_Opportunity_SVC.buildChildParentMap(childParentIdMap);
        }

        for(OpportunityStage os : [SELECT Id, MasterLabel, IsClosed, IsWon FROM OpportunityStage]) {
            if(os.IsClosed && os.IsWon) {
                closedWonStages.add(os.MasterLabel);
            }
            else if(!os.IsClosed) {
                notClosedStages.add(os.MasterLabel);
            }
        }
        */

        //Use case 3. Get Opportunity stages for later rollup calculation
        //get stages for later roll-up
        /*
        for(OpportunityStage os : [SELECT Id, MasterLabel, IsClosed, IsWon FROM OpportunityStage]) {
            if(os.IsClosed && os.IsWon) {
                closedWonStages.add(os.MasterLabel);
            }
            else if(!os.IsClosed) {
                notClosedStages.add(os.MasterLabel);
            }
        }
        */

        //Use case 3. Get Opportunity stages from custom setting for later process
        /*
        String customSettingValue = EQT_UTIL_Settings.getOpportunityCloseValue();

        if(customSettingValue != null) {
            //if more then 1 values is set in custom setting
            if(customSettingValue.contains(';')) {
                opportunity1stCloseValues.addAll(customSettingValue.split(';'));
            }
            else {
                opportunity1stCloseValues.add(customSettingValue);
            }
        }
        */

        //Use case 3. Get related funds records for which rollup calculation will be made
        //Use case 4. Get gatekeepers ids and opporutnity account ids
        fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        if(Trigger.isInsert) {
            for(sObject opportunity : Trigger.new) {
                if(opportunity.get('EQT_Fund__c') != null && opportunity.get('EQT_Bite_Size__c') != null && opportunity.get('EQT_Bite_Size__c') != 0) {
                    fundToProcessIds.add((String)opportunity.get('EQT_Fund__c'));
                }

                if(opportunity.get('RecordTypeId') == fundraisingRecordTypeId
                    && opportunity.get('EQT_Gatekeeper__c') != null
                    && opportunity.get('AccountId') != null) {

                    gatekeeperIds.add(Id.valueOf((String)opportunity.get('EQT_Gatekeeper__c')));
                    oppAccountIds.add(Id.valueOf((String)opportunity.get('AccountId')));
                }
                //rollup for co-investment part
                if(opportunity.get('EQT_Fund__c') != null
                    && opportunity.get('EQT_Bite_Size__c') != null
                    && opportunity.get('EQT_Bite_Size__c') != 0
                    && opportunity.get('Probability') != 0) {

                    fundToProcessIds.add((String)opportunity.get('EQT_Fund__c'));
                } 
            }
        }
        else if(Trigger.isUpdate) {
            for(sObject opportunity : Trigger.new) {
                Opportunity newOpp = (Opportunity)opportunity;
                Opportunity oldOpp = (Opportunity)Trigger.oldMap.get(newOpp.Id);
                if(oldOpp.EQT_Fund__c != newOpp.EQT_Fund__c || oldOpp.EQT_Bite_Size__c != newOpp.EQT_Bite_Size__c) {
                    fundToProcessIds.add(newOpp.EQT_Fund__c);
                }

                if(newOpp.RecordTypeId == fundraisingRecordTypeId
                    && newOpp.AccountId != null
                    && newOpp.EQT_Gatekeeper__c != oldOpp.EQT_Gatekeeper__c
                    && newOpp.EQT_Gatekeeper__c != null) {

                    gatekeeperIds.add(newOpp.EQT_Gatekeeper__c);
                    oppAccountIds.add(newOpp.AccountId);
                }

                //rollup for co-investment
                if(newOpp.Probability != 0 && (oldOpp.EQT_Fund__c != newOpp.EQT_Fund__c || oldOpp.EQT_Bite_Size__c != newOpp.EQT_Bite_Size__c)) {
                    
                    fundToProcessIds.add(newOpp.EQT_Fund__c);
                }

                // for trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
                if(newOpp.OwnerId != oldOpp.OwnerId){
                    changedOwnerOpportunityIds.add(newOpp.Id);
                }
            }
        }
        else if(Trigger.isDelete) {
            for(sObject opportunity : Trigger.old) {
                if(opportunity.get('EQT_Fund__c') != null && opportunity.get('Amount') != 0) {
                    fundToProcessIds.add((String)opportunity.get('EQT_Fund__c'));
                }
            }
        }

        //build existing gatekeeper associations map for later process
        if(!gatekeeperIds.isEmpty() && !oppAccountIds.isEmpty()) {
            for(EQT_Investor_Gatekeeper_Associations__c item : [SELECT Id, EQT_Gatekeeper__c, EQT_Investor__c
                                                                FROM EQT_Investor_Gatekeeper_Associations__c
                                                                WHERE EQT_Gatekeeper__c IN :gatekeeperIds
                                                                AND EQT_Investor__c IN :oppAccountIds]) {

                String key = item.EQT_Gatekeeper__c + ':' + item.EQT_Investor__c;
                gatekeeperAssociationMap.put(key, item);
            }
        }

        //build currency coversion rate map
        currencyConversionRateMap = new Map<String, Decimal>();
        for(CurrencyType ct : [SELECT Id, IsoCode, ConversionRate
                                FROM CurrencyType
                                WHERE IsActive = true]) {

            currencyConversionRateMap.put(ct.IsoCode, ct.ConversionRate);
        }
    }
        
    public void beforeInsert(SObject so) {
        Opportunity opp = (Opportunity)so;

        //Use Case 2. Set appropriete value on opportunity based on investor commitments
        //TA 449 there are commitments for given investor
        if(opp.RecordTypeId == EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName())) {
            if(investorCommitmentMap.containsKey(opp.AccountId)) {
                for(EQT_Commitment__c c : investorCommitmentMap.get(opp.AccountId)) {
                    if(c.EQT_Fund_Strategy__c != opp.EQT_Fund_Strategy__c) {
                        opp.EQT_E_T_TT__c = 'T';
                    }
                    if(c.EQT_Fund__r.EQT_Previous_Fund__c != null) {
                        opp.EQT_E_T_TT__c = 'E';
                        /*
                            there is possibility that both conditions match and in this situation
                            E takes precendese, so if E is set then no need to continue loop
                        */
                        break;
                    }
                }
            }
            //no commitment - new investor
            else {
                opp.EQT_E_T_TT__c = 'TT';
            }
        }

        //Use case 6 populate a field EQT_Invested_Previous_Fund__c (currency field) with the investors commitment in Previous fund
        if(investorCommitmentMap.containsKey(opp.AccountId)) {
            for(EQT_Commitment__c c : investorCommitmentMap.get(opp.AccountId)) {
                //if there is a previous fund for fund on opportunity AND this previous fund is equal to commitment fund
                if(fundPrevFundMap.containsKey(opp.EQT_Fund__c) && c.EQT_Fund__c == fundPrevFundMap.get(opp.EQT_Fund__c)) {
                    Decimal amount = 0;
                    if(c.EQT_Amount__c != null && c.EQT_Amount__c != 0) {
                        if(c.CurrencyIsoCode != opp.CurrencyIsoCode) {
                            Decimal commitmentConversionRate = currencyConversionRateMap.get(c.CurrencyIsoCode);
                            Decimal opportunityConversionRate = currencyConversionRateMap.get(opp.CurrencyIsoCode);
                            if(opportunityConversionRate == 1) {
                                amount = c.EQT_Amount__c / commitmentConversionRate;
                            }
                            else {
                                amount = c.EQT_Amount__c * opportunityConversionRate;
                            }
                        }
                        else {
                            amount = c.EQT_Amount__c;
                        }
                    }
                    opp.EQT_Invested_Previous_Fund__c  = amount;
                }
            }
        }

        // Use case 1. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(opp.EQT_EPM_Record_Type_Name__c != null) {
            try {
                // -Set record type ID
                opp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.'+opp.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }

        //Set Opportunity Decline if investor preferences are not interested in fund strategy
        if(
            opp.EQT_Fund__c != null &&
            opp.AccountId != null &&
            fundId2StrategyMap.containsKey(opp.EQT_Fund__c) &&
            String.isNotBlank(fundId2StrategyMap.get(opp.EQT_Fund__c)) &&
            investorsNotInterestedPreferencesMap.containsKey(opp.AccountId) &&
            investorsNotInterestedPreferencesMap.get(opp.AccountId) != null
        ){
            // if Set/List of investor preferences not interested strategies contains related fund strategy
            // then opportunity goes automatically into the Decline stage
            if(
                investorsNotInterestedPreferencesMap.get(opp.AccountId).contains(fundId2StrategyMap.get(opp.EQT_Fund__c))
            ){
                opp.StageName = EQT_UTIL_Settings.getStageNameForNotInterestedOpportunity();
                opp.EQT_Decline_Reason__c = EQT_UTIL_Settings.getDeclineReasonForNotInterestedOpportunity();
                opp.EQT_Decline_Reason_text__c = EQT_UTIL_Settings.getDeclineReasonTextForNotInterestedOpportunity();
            }
        }
        
        // Trello 194-eqt-mid-market-asia-iii-opportunities-showing-bite-size-in-eur-instead-of-usd
        if(
            (
                opp.RecordTypeId == EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName()) ||
                opp.RecordTypeId == EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName())
            ) &&
            opp.EQT_Fund__c != null &&
            irFundIdToCurrencyMap.containsKey(opp.EQT_Fund__c) &&
            irFundIdToCurrencyMap.get(opp.EQT_Fund__c) != null
        ){
            opp.CurrencyIsoCode = irFundIdToCurrencyMap.get(opp.EQT_Fund__c);
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Opportunity theOpp = (Opportunity) so;
        Opportunity theOpp_old = (Opportunity) oldSo;
        
        // Use case 1. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theOpp.EQT_EPM_Record_Type_Name__c!=null && (theOpp.EQT_EPM_Record_Type_Name__c != theOpp_old.EQT_EPM_Record_Type_Name__c)) {
            try {
                // -Set record type ID
                theOpp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.'+theOpp.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }

        //Use Case 7 Set EQT_First_Interaction_Date__c
        if(theOpp.EQT_First_Interaction_Date__c == null && opportunityActivityMap.containsKey(theOpp.Id)) {
            Opportunity oppWithActivities = opportunityActivityMap.get(theOpp.Id);

            if(!oppWithActivities.Events.isEmpty()) {
                theOpp.EQT_First_Interaction_Date__c = oppWithActivities.Events[0].StartDateTime.date();
            }

            if(!oppWithActivities.Tasks.isEmpty()) {
                if(theOpp.EQT_First_Interaction_Date__c == null
                    || theOpp.EQT_First_Interaction_Date__c > oppWithActivities.Tasks[0].ActivityDate) {
                    
                    theOpp.EQT_First_Interaction_Date__c = oppWithActivities.Tasks[0].ActivityDate;
                }
            }
        }
    }
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {

        /* TA384 Commented out according to demo on 11.05.2016
        //if parent object was added - copy opp team from parent to child
        Opportunity opp = (Opportunity) so;
        
        //if parent is set and exists in child parent map and have some team members
        if(opp.EQT_Fundraise__c != null && childParentMap.get(opp.Id) != null && !childParentMap.get(opp.Id).OpportunityTeamMembers.isEmpty()) {
            oppMembersToAdd.addAll(EQT_Opportunity_SVC.copyOpportunityTeamMembers(childParentMap.get(opp.Id).OpportunityTeamMembers, opp.Id));
        }
        */

        //Use case 4. Check if gatekeeper association record exists for given opportunity Gatekeeper and Account if not add it for later creation
        Opportunity opp = (Opportunity) so;

        if(opp.RecordTypeId == fundraisingRecordTypeId
            && opp.EQT_Gatekeeper__c != null
            && opp.AccountId != null
            && !gatekeeperAssociationMap.containsKey(opp.EQT_Gatekeeper__c + ':' + opp.AccountId)) {

            //create new gatekeeper association record
            EQT_Investor_Gatekeeper_Associations__c toAdd = new EQT_Investor_Gatekeeper_Associations__c();
            toAdd.EQT_Gatekeeper__c = opp.EQT_Gatekeeper__c;
            toAdd.EQT_Investor__c = opp.AccountId;

            associationsToInsert.put(opp.EQT_Gatekeeper__c + ':' + opp.AccountId, toAdd);
        } 
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {

        /* TA384 Commented out according to demo on 11.05.2016
        Opportunity newOpp = (Opportunity) so;
        Opportunity oldOpp = (Opportunity) oldSo;
        //if previously there was no parent obj and not it is - copy opp team from parent to child
        if(oldOpp.EQT_Fundraise__c == null && newOpp.EQT_Fundraise__c != null) {
            //if parent exists in child map and have some team members
            if(childParentMap.get(newOpp.Id) != null && !childParentMap.get(newOpp.Id).OpportunityTeamMembers.isEmpty()) {
                oppMembersToAdd.addAll(EQT_Opportunity_SVC.copyOpportunityTeamMembers(childParentMap.get(newOpp.Id).OpportunityTeamMembers, newOpp.Id));
            }
        }
        //if previously there was parent object but it was changed to some other one - delete opp team from child and copy opp team from new parent
        else if(oldOpp.EQT_Fundraise__c != null && newOpp.EQT_Fundraise__c != null && oldOpp.EQT_Fundraise__c != newOpp.EQT_Fundraise__c) {
            opportunityIdsToDeleteTeamMembers.add(oldOpp.Id);
            
            //if parent exists in child map and have some team members
            if(childParentMap.get(newOpp.Id) != null && !childParentMap.get(newOpp.Id).OpportunityTeamMembers.isEmpty()) {
                oppMembersToAdd.addAll(EQT_Opportunity_SVC.copyOpportunityTeamMembers(childParentMap.get(newOpp.Id).OpportunityTeamMembers, newOpp.Id));
            }
        }
        
        /* as EQT_Fundraise__c is a mandatory field below scenario is not possible
        //if previously there was parent object but now it is removed delete child team members
        else if(oldOpp.EQT_Fundraise__c != null && newOpp.EQT_Fundraise__c == null) {
            opportunityIdsToDeleteTeamMembers.add(oldOpp.Id);
        }
        */
        
        //Use case 4. Check if gatekeeper association record exists for given opportunity Gatekeeper and Account if not add it for later creation
        Opportunity newOpp = (Opportunity) so;
        Opportunity oldOpp = (Opportunity) oldSo;

        if(newOpp.RecordTypeId == fundraisingRecordTypeId
            && newOpp.AccountId != null
            && oldOpp.EQT_Gatekeeper__c != newOpp.EQT_Gatekeeper__c
            && newOpp.EQT_Gatekeeper__c != null
            && !gatekeeperAssociationMap.containsKey(newOpp.EQT_Gatekeeper__c + ':' + newOpp.AccountId)) {

            //create new gatekeeper association record
            EQT_Investor_Gatekeeper_Associations__c toAdd = new EQT_Investor_Gatekeeper_Associations__c();
            toAdd.EQT_Gatekeeper__c = newOpp.EQT_Gatekeeper__c;
            toAdd.EQT_Investor__c = newOpp.AccountId;

            associationsToInsert.put(newOpp.EQT_Gatekeeper__c + ':' + newOpp.AccountId, toAdd);
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
        /* TA384 Commented out according to demo on 11.05.2016
        if(!opportunityIdsToDeleteTeamMembers.isEmpty()) {
            delete [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN :opportunityIdsToDeleteTeamMembers];
        }
        
        if(!oppMembersToAdd.isEmpty()) {
            insert oppMembersToAdd;
        }
        */

        //Use case 4. Create gatekeeper association if needed
        if(!associationsToInsert.isEmpty()) {
            insert associationsToInsert.values();
        }
        
        //Use case 3. Calculate rollup fields on related fund records
        system.debug('fundToProcessIds: ' + fundToProcessIds);
        if(!fundToProcessIds.isEmpty()) {
            Map<Id, Fund__c> fundMapToProcess = new Map<Id, Fund__c>
            (
                [
                    SELECT Id, EQT_Committed_volumes__c, EQT_Pipeline_Volume_Weighted__c,
                    EQT_Pipeline_Volume__c, CurrencyIsoCode
                    FROM Fund__c
                    WHERE Id IN :fundToProcessIds
                ]
            );

            //get stages for each calculation
            String csPipelineVolumeWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation();
            List<String> stagesForPipelineWeighted = new List<String>();
            if(csPipelineVolumeWeighted.contains(';')) {
                stagesForPipelineWeighted.addAll(csPipelineVolumeWeighted.split(';'));
            }
            else {
                stagesForPipelineWeighted.add(csPipelineVolumeWeighted);
            }

            String csPipelineVolumeUnWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation();
            List<String> stagesForPipelineUnweighted = new List<String>();
            if(csPipelineVolumeUnWeighted.contains(';')) {
                stagesForPipelineUnweighted.addAll(csPipelineVolumeUnWeighted.split(';'));
            }
            else {
                stagesForPipelineUnweighted.add(csPipelineVolumeUnWeighted);
            }

            String csCommittedCapital = EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation();
            List<String> stagesForCommittedCapital = new List<String>();
            if(csCommittedCapital.contains(';')) {
                stagesForCommittedCapital.addAll(csCommittedCapital.split(';'));
            }
            else {
                stagesForCommittedCapital.add(csCommittedCapital);
            }

            Map<Id, Decimal> resultCommitedVolumeMap = new Map<Id, Decimal>();

            //aggregate EQT_Committed_volumes__c
            for(AggregateResult result : [SELECT EQT_Fund__c, SUM(EQT_Bite_Size__c) oppAmount
                                            FROM Opportunity
                                            WHERE EQT_Fund__c IN :fundToProcessIds
                                            AND StageName IN :stagesForCommittedCapital
                                            GROUP By EQT_Fund__c]) {

                resultCommitedVolumeMap.put((Id)result.get('EQT_Fund__c'), (Decimal)result.get('oppAmount'));
            }

            Map<Id, Decimal> resultPipelineVolumeWeightedMap = new Map<Id, Decimal>();
            //aggregate EQT_Pipeline_Volume_Weighted__c
            for(AggregateResult result : [SELECT EQT_Fund__c, SUM(EQT_BS_Avg_Wght__c) oppAmount
                                            FROM Opportunity
                                            WHERE EQT_Fund__c IN :fundToProcessIds
                                            AND StageName NOT IN :stagesForPipelineWeighted
                                            GROUP By EQT_Fund__c]) {

                resultPipelineVolumeWeightedMap.put((Id)result.get('EQT_Fund__c'), (Decimal)result.get('oppAmount'));
            }

            Map<Id, Decimal> resultPipelineVolumeUnWeightedMap = new Map<Id, Decimal>();
            //aggregate EQT_Pipeline_Volume__c
            for(AggregateResult result : [SELECT EQT_Fund__c, SUM(EQT_Bite_Size__c) oppAmount
                                            FROM Opportunity
                                            WHERE EQT_Fund__c IN :fundToProcessIds
                                            AND StageName NOT IN :stagesForPipelineUnweighted
                                            GROUP By EQT_Fund__c]) {

                resultPipelineVolumeUnWeightedMap.put((Id)result.get('EQT_Fund__c'), (Decimal)result.get('oppAmount'));
            }

            Map<Id, Decimal> resultPreSignMap = new Map<Id, Decimal>();
            //Pre-sign calculation - aggregate EQT_Pre_sign_syndication__c
            for(AggregateResult result : [SELECT EQT_Fund__c, SUM(EQT_Bite_Size__c) oppAmount
                                            FROM Opportunity
                                            WHERE EQT_Fund__c IN :fundToProcessIds
                                            AND Probability != 0
                                            AND Type = :EQT_UTIL_Settings.getOpportunityCoInvestmentPreSignType()
                                            GROUP By EQT_Fund__c]) {

                resultPreSignMap.put((Id)result.get('EQT_Fund__c'), (Decimal)result.get('oppAmount'));
            }

            Map<Id, Decimal> resultPostSignMap = new Map<Id, Decimal>();
            //Post-sign calculation - aggregate EQT_Post_sign_syndication__c
            for(AggregateResult result : [SELECT EQT_Fund__c, SUM(EQT_Bite_Size__c) oppAmount
                                            FROM Opportunity
                                            WHERE EQT_Fund__c IN :fundToProcessIds
                                            AND Probability != 0
                                            AND Type = :EQT_UTIL_Settings.getOpportunityCoInvestmentPostSignType()
                                            GROUP By EQT_Fund__c]) {

                resultPostSignMap.put((Id)result.get('EQT_Fund__c'), (Decimal)result.get('oppAmount'));
            }

            system.debug('fundMapToProcess: ' + fundMapToProcess);
            for(Id key : fundMapToProcess.keySet()) {
                Fund__c f = fundMapToProcess.get(key);

                Decimal commitedVolume = 0;
                if(resultCommitedVolumeMap.containsKey(key) && resultCommitedVolumeMap.get(key) != null) {
                    commitedVolume = resultCommitedVolumeMap.get(key);
                }
                Decimal pipelineWeightedVolume = 0;
                if(resultPipelineVolumeWeightedMap.containsKey(key) && resultPipelineVolumeWeightedMap.get(key) != null) {
                    pipelineWeightedVolume = resultPipelineVolumeWeightedMap.get(key);
                }
                Decimal pipelineUnWeightedVolume = 0;
                if(resultPipelineVolumeUnWeightedMap.containsKey(key) && resultPipelineVolumeUnWeightedMap.get(key) != null) {
                    pipelineUnWeightedVolume = resultPipelineVolumeUnWeightedMap.get(key);
                }
                Decimal preSignVolume = 0;
                if(resultPreSignMap.containsKey(key) && resultPreSignMap.get(key) != null) {
                    preSignVolume = resultPreSignMap.get(key);
                }
                Decimal postSignVolume = 0;
                if(resultPostSignMap.containsKey(key) && resultPostSignMap.get(key) != null) {
                    postSignVolume = resultPostSignMap.get(key);
                }

                Decimal conversionRate = currencyConversionRateMap.get(f.CurrencyIsoCode);
                
                system.debug('conversionRate: ' + conversionRate);
                system.debug('commitedVolume: ' + commitedVolume);

                if(commitedVolume != 0) {
                    commitedVolume = commitedVolume * conversionRate;
                }
                if(pipelineWeightedVolume != 0) {
                    pipelineWeightedVolume = pipelineWeightedVolume * conversionRate;                    
                }
                if(pipelineUnWeightedVolume != 0) {
                    pipelineUnWeightedVolume = pipelineUnWeightedVolume * conversionRate;
                }
                if(preSignVolume != 0) {
                    preSignVolume = preSignVolume * conversionRate;
                }
                if(postSignVolume != 0) {
                    postSignVolume = postSignVolume * conversionRate;
                }

                f.EQT_Committed_volumes__c = commitedVolume;
                f.EQT_Pipeline_Volume_Weighted__c = pipelineWeightedVolume;
                f.EQT_Pipeline_Volume__c = pipelineUnWeightedVolume;
                f.EQT_Pre_sign_syndication__c = preSignVolume;
                f.EQT_Post_sign_syndication__c  = postSignVolume;                
            }

            update fundMapToProcess.values();
        }

        // for trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(!changedOwnerOpportunityIds.isEmpty()){
            // select owner names for relevant opportunities
            List<Opportunity> oppResult = [
                SELECT Id, Owner.Name
                FROM Opportunity
                WHERE Id IN :changedOwnerOpportunityIds
            ];

            Map<Id, String> opportunityId2OwnerName = new Map<Id, String>();
            for(Opportunity oppItem : oppResult){
                opportunityId2OwnerName.put(oppItem.Id, oppItem.Owner.Name);
            }

            // find Events for updated opportunities
            List<Event> eventsList = [SELECT Id,EQT_Opportunity_Owner__c,WhatId FROM Event WHERE WhatId IN :changedOwnerOpportunityIds];
            if(!eventsList.isEmpty()){
                for(Event eventItem : eventsList){
                    eventItem.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(eventItem.WhatId);
                }
                update eventsList;
            }

            // find Tasks for updated opportunities
            List<Task> tasksList = [SELECT Id,EQT_Opportunity_Owner__c,WhatId FROM Task WHERE WhatId IN :changedOwnerOpportunityIds];
            if(!tasksList.isEmpty()) {
                for (Task taskItem : tasksList) {
                    taskItem.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(taskItem.WhatId);
                }
                update tasksList;
            }
        }

    }
}