/**
    About
    -----
    Description: Batch to delete event logs

    Created for: EQT
    Created date: May 2016
    
    Details / Methods
    -----------------
    

    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public class EQT_BatchDeleteEventLogs implements Database.Batchable<SObject>, Database.Stateful {
    
    private Integer totalCount = 0;     //total processed record delete
    private Integer totalFailed = 0;    //total failed record delete
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM EQT_Event_Log__c]);
    }
    
    public void execute(Database.BatchableContext BC, List<EQT_Event_Log__c> scope) {
        List<Database.DeleteResult> results = Database.delete(scope, false);

        for(Database.DeleteResult dr : results) {
            if(!dr.isSuccess()) {
                totalFailed++;
            }
            totalCount++;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if(totalFailed > 0) {
            if(EQT_UTIL_Settings.getLoggingEnabled()) {
                String message = String.format('There was {0} failed deletes of total {1} records processed',
                                            new List<String>{String.valueOf(totalFailed), String.valueOf(totalCount)});
                                            
                EQT_UtilApexLog.generateLog('Error deleting logs', message);
            }
        }
    }
    
    @testVisible
    private void setTotalFailed(Integer failedNumber) {
        if(Test.isRunningTest()) {
            this.totalFailed = failedNumber;
        }
    }
}