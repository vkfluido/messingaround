/**
    About
    -----
    Description: Trigger Handler for the Case SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: August 2016
    
    Details / Methods
    -----------------
    Use case 1. Set Contact on Case based on user email
    Use case 2. Closed date calculation based on given input in slack during new case creation
    Use case 3. Set Fund on Case object if related Opportunity is set and attached to Fund record

    Update History
    --------------
    Created August 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_CaseHandler implements EQT_ITrigger {

	private Id rfiRT = EQT_UTIL_Meta.getRecordTypeId('Case.RFI');
	private Set<String> emails = new Set<String>();
	private Map<String, Id> emailContactMap = new Map<String, Id>();
    private Set<Id> opportunityIds = new Set<Id>();
    private Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

	public void bulkBefore() {
		if(Trigger.isInsert) {
			for(SObject c : Trigger.new) {
    			Case theCase = (Case) c;

    			if(theCase.Origin == 'Slack' && theCase.RecordTypeId == rfiRT) {
    				if(theCase.SuppliedEmail != null) {
    					emails.add(theCase.SuppliedEmail);
    				}
                    if(theCase.Opportunity__c != null) {
                        opportunityIds.add(theCase.Opportunity__c);
                    }
    			}
    		}

    		if(!emails.isEmpty()) {
    			for(Contact c : [SELECT Id, Email FROM Contact WHERE Email IN :emails]) {
    				emailContactMap.put(c.Email, c.Id);
    			}
    		}

            if(!opportunityIds.isEmpty()) {
                opportunityMap = new Map<Id, Opportunity>([SELECT Id, EQT_Fund__c FROM Opportunity WHERE Id IN :opportunityIds]);
            }
		}
	}
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {
    	Case theCase = (Case) so;
    	//Use Case 1 - set contact on case record
    	if(String.isNotEmpty(theCase.SuppliedEmail) && emailContactMap.containsKey(theCase.SuppliedEmail)) {
    		theCase.ContactId = emailContactMap.get(theCase.SuppliedEmail);
    	}

    	//Use Case 2 - converting text data provided by user in slack to date and proper case field
    	if(String.isNotEmpty(theCase.Slack_date__c)) {
    		try {
                //add this date to description field
                theCase.Description += '\n' + 'Deadline: ' + theCase.Slack_date__c;

				Date d = Date.valueOf(theCase.Slack_date__c);
				theCase.Deadline__c = d;
    		}
    		catch(Exception e) {
                theCase.Deadline__c = null;
    		}
    	}

        //Use Case 3 - set fund on case if possible
        if(theCase.Opportunity__c != null
            && opportunityMap.containsKey(theCase.Opportunity__c)
            && opportunityMap.get(theCase.Opportunity__c).EQT_Fund__c != null) {

            theCase.Fund__c = opportunityMap.get(theCase.Opportunity__c).EQT_Fund__c;
        }
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
    public void andFinally() {}
}