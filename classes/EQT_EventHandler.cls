/**
    About
    -----
    Description: Trigger Handler for the Event SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Set the owner based on the EQT_EPM_Activity_Owner_UserId on incoming record when set and a matching user is found
    Use case 2. Use EQT_EPM_Record_Type_Name on incoming record to set the RecordtypeID
    Use case 3. Set WhatId/WhoId based  on Counterpart Id and/or PersonID
    Use case 4. Set EQT_First_Interaction_Date__c on Opportunity if this field is empty and event is related to Opportunity 

    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_EventHandler implements EQT_ITrigger {
	
	// Event map to set owner based on EQT_EPM_Activity_Owner_UserId  (Record -> ActivityOwnerUserId)
    private Map<sObject, String> eventsToSetOwnerbyActivityOwnerID = new Map<sObject,String>();
    //map of account based on Counterpart Id
    private Map<String, Account> accountMap = new Map<String, Account>();
    //map of contacts based on PersonID
    private Map<String, Contact> contactMap = new Map<String, Contact>();
    //set of account counterpart ide
    private Set<String> counterpartIDs = new Set<String>();
    //set of contact peron ids
    private Set<String> personIds = new Set<String>();
    //use case 4
    private Set<Id> opportunityIds = new Set<Id>();
    private Map<Id, Opportunity> opportunityEvents = new Map<Id, Opportunity>();
    private List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    private Map<Id, String> opportunityId2OwnerName = new Map<Id, String>();


	public EQT_EventHandler() {}

	public void bulkBefore() {
		//Use case 3 check if counterpart id and person Id are set
		//if so create account and contact map based on those to update event
		if(Trigger.isInsert || Trigger.isUpdate) {
			for(sObject so : Trigger.new) {
				if(so.get('EQT_EPM_CounterpartID__c') != null) {
					counterpartIDs.add((String)so.get('EQT_EPM_CounterpartID__c'));
				}

				if(so.get('EQT_EPM_PersonID__c') != null) {
					personIds.add((String)so.get('EQT_EPM_PersonID__c'));
				}
			}

			//create map of accounts based on counterpartids
			if(!counterpartIDs.isEmpty()) {
				for(Account a : [SELECT Id, EQT_EPM_CounterpartID__c FROM Account
									WHERE EQT_EPM_CounterpartID__c IN :counterpartIDs]) {
					accountMap.put(a.EQT_EPM_CounterpartID__c, a);
				}
			}

			//create map of contacts based on personids
			if(!personIds.isEmpty()) {
				for(Contact c : [SELECT Id, EQT_EPM_PersonID__c FROM Contact
									WHERE EQT_EPM_PersonID__c IN :personIds]) {
					contactMap.put(c.EQT_EPM_PersonID__c, c);
				}
			}
		}

        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(Trigger.isInsert || Trigger.isUpdate){
            for(sObject so : Trigger.new) {
                Event eventItem = (Event)so;

                if(Trigger.isInsert && eventItem.WhatId!=null && String.valueOf(eventItem.WhatId).startsWith('006')){
                    opportunityId2OwnerName.put(eventItem.WhatId, null);
                } else if(Trigger.isUpdate){
                    Event eventItemOld = (Event)Trigger.oldMap.get(eventItem.Id);
                    if(
                        eventItem.WhatId != eventItemOld.WhatId &&
                        String.valueOf(eventItem.WhatId).startsWith('006')
                    ){
                        opportunityId2OwnerName.put(eventItem.WhatId, null);
                    }
                }
            }

            if(!opportunityId2OwnerName.isEmpty()){
                List<Opportunity> oppResult = [
                    SELECT Id, Owner.Name
                    FROM Opportunity
                    WHERE Id IN :opportunityId2OwnerName.keySet()
                ];

                for(Opportunity oppItem : oppResult){
                    opportunityId2OwnerName.put(oppItem.Id, oppItem.Owner.Name);
                }
            }
        }
	}

    public void bulkAfter() {
        if(Trigger.isInsert) {
            for(sObject so : Trigger.new) {
                Event e = (Event)so;

                //if event is related to Opportunity
                if(e.WhatId != null && e.WhatId.getSobjectType() == Schema.Opportunity.SObjectType) {
                    opportunityIds.add(e.WhatId);
                }
            }
        }

        if(!opportunityIds.isEmpty()) {
            opportunityEvents = new Map<Id, Opportunity>
            (
                [
                    SELECT Id, EQT_First_Interaction_Date__c,
                        (SELECT Id, StartDateTime FROM Events ORDER BY StartDateTime LIMIT 1)
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
                ]
            );
        }
    }
        
    public void beforeInsert(SObject so) {
        Event e = (Event) so;

        // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Activity_Owner_UserId  
        // using their own external ID. Default otherwise is current user.
        if(e.OwnerId == null) {
            e.OwnerId = UserInfo.getUserId();
        }

        if(e.EQT_EPM_Activity_Owner_UserId__c != null) {
            eventsToSetOwnerbyActivityOwnerID.put(so, e.EQT_EPM_Activity_Owner_UserId__c);
        }

        // Use case 2. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(e.EQT_EPM_Record_Type_Name__c!=null) {
            try {
                // -Set record type ID
                e.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Event.'+e.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception exc) {
                // -Do nothing if no match found
            }
        }

        //use case 3 set whoId and what Id based on counterpart id and person id
        if(e.EQT_EPM_CounterpartID__c != null && accountMap.containsKey(e.EQT_EPM_CounterpartID__c)) {
        	e.WhatId = accountMap.get(e.EQT_EPM_CounterpartID__c).Id;
        }

        if(e.EQT_EPM_PersonID__c != null && contactMap.containsKey(e.EQT_EPM_PersonID__c)) {
        	e.WhoId = contactMap.get(e.EQT_EPM_PersonID__c).Id;
        }

        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(e.WhatId!=null && String.valueOf(e.WhatId).startsWith('006')){
            if(opportunityId2OwnerName.get(e.WhatId)!=null) {
                e.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(e.WhatId);
            }
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Event eNew = (Event) so;
        Event eOld = (Event) oldSo;

        // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Activity_Owner_UserId 
        // using their own external ID. Default otherwise is current user.

        if(eNew.EQT_EPM_Activity_Owner_UserId__c != null && (eNew.EQT_EPM_Activity_Owner_UserId__c != eOld.EQT_EPM_Activity_Owner_UserId__c)) {
            eventsToSetOwnerbyActivityOwnerID.put(so, eNew.EQT_EPM_Activity_Owner_UserId__c);
        }

        // Use case 2. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(eNew.EQT_EPM_Record_Type_Name__c != null && (eNew.EQT_EPM_Record_Type_Name__c != eOld.EQT_EPM_Record_Type_Name__c)) {
            try {
                // -Set record type ID
                eNew.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Event.'+eNew.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception exc) {
                // -Do nothing if no match found
            }
        }

        //use case 3 set whoId and what Id based on counterpart id and person id
        if(eNew.EQT_EPM_CounterpartID__c != null && eNew.EQT_EPM_CounterpartID__c != eOld.EQT_EPM_CounterpartID__c && accountMap.containsKey(eNew.EQT_EPM_CounterpartID__c)) {
        	eNew.WhatId = accountMap.get(eNew.EQT_EPM_CounterpartID__c).Id;
        }

        if(eNew.EQT_EPM_PersonID__c != null && eNew.EQT_EPM_PersonID__c != eOld.EQT_EPM_PersonID__c && contactMap.containsKey(eNew.EQT_EPM_PersonID__c)) {
        	eNew.WhoId = contactMap.get(eNew.EQT_EPM_PersonID__c).Id;
        }

        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(eNew.WhatId!=eOld.WhatId){
            // if WhatId has changed
            if(eNew.WhatId==null){
                eNew.EQT_Opportunity_Owner__c = null;
            } else {
                if(String.valueOf(eNew.WhatId).startsWith('006')){
                    eNew.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(eNew.WhatId);
                } else {
                    eNew.EQT_Opportunity_Owner__c = null;
                }
            }
        }
    }
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        Event e = (Event)so;

        //if event is related to opportunity and given opportunity have no interaction date
        if(e.WhatId != null && e.WhatId.getSobjectType() == Schema.Opportunity.SObjectType
            && opportunityEvents.containsKey(e.WhatId)
            && opportunityEvents.get(e.WhatId).EQT_First_Interaction_Date__c == null) {

            Opportunity opp = opportunityEvents.get(e.WhatId);
            opp.EQT_First_Interaction_Date__c = e.StartDateTime.date();

            if(!opp.Events.isEmpty() && opp.EQT_First_Interaction_Date__c > opp.Events[0].StartDateTime.date())  {
                opp.EQT_First_Interaction_Date__c = opp.Events[0].StartDateTime.date();
            }

            opportunitiesToUpdate.add(opp);
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        if(!eventsToSetOwnerbyActivityOwnerID.isEmpty()) {
            EQT_DataTransformation_SVC.setOwnerByEPMActivityOwnerUserId(eventsToSetOwnerbyActivityOwnerID);
        }

        //use case 3 - update opportunities to set EQT_First_Interaction_Date__c
        if(!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}