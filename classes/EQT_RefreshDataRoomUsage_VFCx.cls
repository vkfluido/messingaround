/**
    About
    -----
    Description: Schedule batch to refresh dataroom usage and for current Fund record set Update_Dataroom_analytics__c = true
    				and Dataroom_Update_Request__c = Datetime.now
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    - Page actions
    	scheduleBatchToRefreshDataRoom 	// set Update_Dataroom_analytics__c = true and Dataroom_Update_Request__c = Datetime.now
    									// schedule a batch to refresh dataroom data
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_RefreshDataRoomUsage_VFCx {
	private Fund__c currentRecord;
	private String DEBUGPREFIX = '*** EQT_RefreshDataRoomUsage_VFCx ***';

	public EQT_RefreshDataRoomUsage_VFCx(ApexPages.StandardController stdController) {
		currentRecord = [SELECT Id, Update_Dataroom_analytics__c, Dataroom_Update_Request__c
						FROM Fund__c
						WHERE Id = :stdController.getId()];
	}

	public PageReference scheduleBatchToRefreshDataRoom() {
		PageReference pr = new PageReference('/' + currentRecord.Id);
		pr.setRedirect(true);
		//mark "Update Dataroom Anlaytics" and update "Dataroom Update Request" to now
		Datetime now = Datetime.now();
		currentRecord.Update_Dataroom_analytics__c = true;
		currentRecord.Dataroom_Update_Request__c = now;
		update currentRecord;

		//check if batch is not running or is about to run
		List<AsyncApexJob> runningRefreshDataRoomBatches = [SELECT Id FROM AsyncApexJob
															WHERE JobType = 'BatchApex'
															AND ApexClass.Name = 'EQT_BatchRefreshDataRoomUsage'
															AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
		//if batch is not running and is not about to run - schedule it
		if(runningRefreshDataRoomBatches.isEmpty()) {
			Integer batchSize = EQT_UTIL_Settings.getIntralinksBatchSize();
			Database.executeBatch(new EQT_BatchRefreshDataRoomUsage(), batchSize);
		}

		return pr;
	}
}