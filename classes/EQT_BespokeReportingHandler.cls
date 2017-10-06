/**
    About
    -----
    Description: To help the BespokeReporting batch job the trigger sets the next Next Deadline
				 when record is inserted or updated
    Created for: EQT
    Create date: November 2016
    
    Details / Methods
    -----------------
    Use case 1. Set Next Deadline on insert and update

    Update History
    --------------
    Created November 2016 - Fredrik Burlin

    Issues / TODOs
    --------------
*/
public with sharing class EQT_BespokeReportingHandler implements EQT_ITrigger {

	public void bulkBefore() {
		if(Trigger.isInsert || Trigger.isUpdate) {
			for(SObject br : Trigger.new) {
    			Bespoke_Reporting__c  theBespokeReport = (Bespoke_Reporting__c) br;
				theBespokeReport.Next_Deadline__c = EQT_BespokeReportingHelper.nextDeadline(theBespokeReport);
    		}
		}
	}
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {}
    
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