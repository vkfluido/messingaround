/**
    About
    -----
    Description: Schedule class to schedule batch to refresh dataroom usage
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    - 
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_ScheduleDateRoomRefresh implements Schedulable {
	
	public EQT_ScheduleDateRoomRefresh() {}

	public void execute(SchedulableContext ctx) {
		//get custom setting valur to check if should run
        if(EQT_UTIL_Settings.getIntralinksWeeklyRefresh()) {
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
        }
	}
}