/**
 * Description: Batch to invoke triggers/flows on objects post-deploy.
 */
global class EQT_BatchPostDeployTouchRecords implements Database.Batchable<sObject>{

    global String query;
   
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        System.debug(LoggingLevel.INFO, '## Executing post deploy batch job ##');
        System.debug(LoggingLevel.INFO, '## - ' + scope.size() + ' records received ##');
        // Just update the records without changing data
        try {
        	update scope;            
            System.debug(LoggingLevel.INFO, '## - ' + scope.size() + ' records updated ##');
        }
        catch (DMLException e) {
            System.debug(LoggingLevel.ERROR, '>>' + e.getMessage());
            throw e;
        }

    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, '## Post deploy batch job finished ##');
    } 
}