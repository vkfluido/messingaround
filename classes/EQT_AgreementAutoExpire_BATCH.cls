/**
    About
    -----
    Description: Batch to check if agreement end data passed and change it status to Expired
    Created for: EQT
    Create date: April 2017

    Details / Methods
    -----------------
    - setTotalFailed - Used for testing purposes only

    Update History
    --------------
    Created April 2017 - R.B.

    Issues / TODOs
    --------------
*/
global class EQT_AgreementAutoExpire_BATCH implements Database.Batchable<sObject>, Database.Stateful {

    private Integer totalCount = 0;		//total processed record
    private Integer totalFailed = 0;	//total failed record
    private List<String> errorLog = new List<String>(); //upsert fail log

    global EQT_AgreementAutoExpire_BATCH() {}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, EQT_Status__c FROM EQT_IA_Contract__c
                                        WHERE EQT_End_Date__c < TODAY
                                        AND (EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName()
                                            OR EQT_Status__c = :EQT_UTIL_Settings.getAgreementInProgressStatusName())]);
    }

    global void execute(Database.BatchableContext BC, List<EQT_IA_Contract__c> scope) {
        for(EQT_IA_Contract__c agreement : scope) {
            agreement.EQT_Status__c = EQT_UTIL_Settings.getAgreementExpiredStatusName();
        }

        List<Database.SaveResult> results = Database.update(scope, false);

        for(Database.SaveResult ur : results) {
            if(!ur.isSuccess()) {
                totalFailed++;
                for(Database.Error e : ur.getErrors()) {
                    errorLog.add(e.getMessage());
                }
            }

            totalCount++;
        }
    }

    global void finish(Database.BatchableContext BC) {
        if(totalFailed > 0) {
            //get string message from error log
            String errorLogMessage = '';
            for(String error : errorLog) {
                errorLogMessage += error + '\n';
            }

            if(errorLogMessage.length() > 32768) {
                errorLogMessage = errorLogMessage.substring(0, 32500);
            }

            String message = String.format('There was {0} failed updates of total {1} records processed. Detail error log: {2}',
                    new List<String>{String.valueOf(totalFailed), String.valueOf(totalCount), errorLogMessage});
            //write log
            EQT_UtilApexLog.generateLog('EQT_AgreementAutoExpire_BATCH log: ', message);
        }
    }

    @testVisible
    private void setTotalFailed(Integer failedNumber) {
        if(Test.isRunningTest()) {
            this.totalFailed = failedNumber;
        }
    }
}