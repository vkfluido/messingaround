/**
    About
    -----
    Description: Trigger Handler for the EQT_Proxy_AccountContactRelation__c SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Import data from EPM and insert or update existing account contact relationship

    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public without sharing class EQT_Proxy_AccountContactRelationHandler implements EQT_ITrigger {  

	//list of standard account contact relation to be added/updated
	private List<AccountContactRelation> accountContactRelationToUpsert = new List<AccountContactRelation>();
	//set of account ids to be processed
	private Set<Id> accountIds = new Set<Id>();
	//set of contact ids to be processed
	private Set<Id> contactIds = new Set<Id>();
	//build account contact map
	private Map<Id, Id> contactAccountMap = new Map<Id, Id>();
	//contact map to determine if contact is a private one
	private Map<Id, Contact> contactMap = new Map<Id, Contact>();
	//relation map that exists in salesforce for given account and contact ids, accountIdContactId -> AccountContactRelation record
	private Map<String, AccountContactRelation> relationMap = new Map<String, AccountContactRelation>();
	//private contacts to update
	private List<Contact> contactsToUpdate = new List<Contact>();
	//list to remove
	private List<String> proxyRecordsToRemove = new List<String>();

	public void bulkBefore() {
		if(Trigger.isInsert) {
			for(SObject record : Trigger.new) {
				if(record.get('Account__c') != null && record.get('Contact__c') != null) {
					accountIds.add((Id)record.get('Account__c'));
					contactIds.add((Id)record.get('Contact__c'));

					contactAccountMap.put((Id)record.get('Contact__c'), (Id)record.get('Account__c'));
				}
			}

			//build contact map to get private contact
			contactMap = new Map<Id, Contact>
			(
				[
					SELECT Id, AccountId
					FROM Contact
					WHERE Id IN :contactIds
				]
			);

			//go through contacts and get those which AccountId = null and update it according to proxy record
			for(Contact c : contactMap.values()) {
				if(c.AccountId == null && contactAccountMap.containsKey(c.Id)) {
					c.AccountId = contactAccountMap.get(c.Id);
					contactsToUpdate.add(c);
				}
			}

			//update private contacts
			if(!contactsToUpdate.isEmpty()) {
				update contactsToUpdate;
			}

			//build map for later process
			if(!accountIds.isEmpty() && !contactIds.isEmpty()) {
				for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId, isActive, StartDate, EndDate,
													Roles, EQT_EPM_CounterpartPersonID__c, EQT_Key_Contact__c
												  FROM AccountContactRelation
												  WHERE AccountId IN :accountIds
												  AND ContactId IN :contactIds]) {
					String key = acr.AccountId + ':' + acr.ContactId;
					relationMap.put(key, acr);
				}
			}
		}		
	}
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {
    	EQT_Proxy_AccountContactRelation__c proxyRecord = (EQT_Proxy_AccountContactRelation__c)so;

    	String mapKey = proxyRecord.Account__c + ':' + proxyRecord.Contact__c;
    	//if given proxy record exist in current relation map - update it
    	if(relationMap.containsKey(mapKey)) {
    		AccountContactRelation acrRec = relationMap.get(mapKey);
    		acrRec.isActive = proxyRecord.IsActive__c;
    		acrRec.StartDate = proxyRecord.StartDate__c;
    		acrRec.EndDate = proxyRecord.EndDate__c;
    		acrRec.Roles = proxyRecord.Roles__c;
    		acrRec.EQT_EPM_CounterpartPersonID__c = proxyRecord.EQT_EPM_CounterpartPersonID__c;
    		acrRec.EQT_Key_Contact__c = proxyRecord.EQT_Key_Contact__c;

    		//add for later update
    		accountContactRelationToUpsert.add(acrRec);
    	}
    	else { //if given proxy record does not exist in current relation map - create new account contact relation record
	    	AccountContactRelation acrRec = new AccountContactRelation();
    		acrRec.AccountId = proxyRecord.Account__c;
    		acrRec.ContactId = proxyRecord.Contact__c;
    		acrRec.isActive = proxyRecord.IsActive__c;
    		acrRec.StartDate = proxyRecord.StartDate__c;
    		acrRec.EndDate = proxyRecord.EndDate__c;
    		acrRec.Roles = proxyRecord.Roles__c;
    		acrRec.EQT_EPM_CounterpartPersonID__c = proxyRecord.EQT_EPM_CounterpartPersonID__c;
    		acrRec.EQT_Key_Contact__c = proxyRecord.EQT_Key_Contact__c;

    		//add for later insert
    		accountContactRelationToUpsert.add(acrRec);
    	}
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
    	EQT_Proxy_AccountContactRelation__c proxyRecord = (EQT_Proxy_AccountContactRelation__c)so;
    	//add processed record to delete list
    	proxyRecordsToRemove.add(proxyRecord.Id);
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
    	//upsert list of relations
    	if(!accountContactRelationToUpsert.isEmpty()) {
    		try {
    			Schema.SObjectField f = AccountContactRelation.Fields.Id;
    			Database.UpsertResult[] upsertResult = Database.upsert(accountContactRelationToUpsert, f, false);
    		}
    		catch(Exception e) {}
    	}

    	//delete all data from proxy table after all trigger is done
    	if(!proxyRecordsToRemove.isEmpty()) {
    		EQT_Proxy_AccountContactRelation_SVC.emptyProxyTable(proxyRecordsToRemove);
    	}
    }


}