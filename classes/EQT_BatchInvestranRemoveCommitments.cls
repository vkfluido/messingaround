/**
    About
    -----
    Description: Batch to clean down investran data before each import

    Created for: EQT
    Created date: September 2016
    
    Details / Methods
    -----------------
    

    Update History
    --------------
    Created September 2016 - R.B.
    August 2017 felix.guerrero@fluidogroup.com - Added process logging

    Issues / TODOs
    --------------
*/
public with sharing class EQT_BatchInvestranRemoveCommitments implements Database.Batchable<SObject>, Database.Stateful {
	
	private Boolean proceed = false;
	private List<sObject> itemsToDelete = new List<sObject>();

	private static String PROCESS = 'Investran_Import_Process';
	public String EX_ID;
	private Boolean loggingActive = false;

	public EQT_BatchInvestranRemoveCommitments() {
		EX_ID = EQT_UtilApexLog.startProcessLog(PROCESS);
		loggingActive = (EX_ID != null);
		System.debug(LoggingLevel.INFO,PROCESS + ' logging ' + (loggingActive?'Active':'Inactive'));
		System.debug(EQT_ProcessLog__c.getInstance(PROCESS));
	}

	public Iterable<sObject> start(Database.BatchableContext BC) {
		List<EQT_UtilApexLog.Log> logsToSave = new List<EQT_UtilApexLog.Log>();
		//check if data from tables should be deleted
		List<EQT_Investran_Contact_List_Import__c> latestRecord = [SELECT Id, CreatedDate FROM EQT_Investran_Contact_List_Import__c ORDER BY CreatedDate DESC LIMIT 1];
		if(!latestRecord.isEmpty()) {
			Datetime latestDate = latestRecord[0].CreatedDate;
			logsToSave.add(new EQT_UtilApexLog.Info(
							   PROCESS, EX_ID, 'EQT_BatchInvestranRemoveCommitments', 'start()','Processing Investran import records from ' + latestDate.format() ));

			List<sObject> investranCommitmentList = [SELECT Id FROM EQT_Investran_Commitment__c];
			List<sObject> fundCommitmentList = [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Origin__c != 'Manual entry'];
			
			itemsToDelete.addAll(investranCommitmentList);
			itemsToDelete.addAll(fundCommitmentList);

			logsToSave.add(new EQT_UtilApexLog.Info(
							   PROCESS, EX_ID, 'EQT_BatchInvestranRemoveCommitments', 'start()',
							   'Removing  ' + investranCommitmentList.size() + ' EQT_Investran_Commitment records and '+fundCommitmentList.size()+ ' EQT_Fund_Commitment records.'));
			proceed = true;
		}else{
			logsToSave.add(new EQT_UtilApexLog.Error(
							   PROCESS, EX_ID, 'EQT_BatchInvestranRemoveCommitments', 'start()','No Investran Import records found, process cannot continue. '));
		}
		if(loggingActive)
			EQT_UtilApexLog.saveLog(logsToSave);
		return itemsToDelete;
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		//if there are records to delete
		if(!scope.isEmpty()) {
			delete scope;
		}
	}

	public void finish(Database.BatchableContext BC) {
		//if data should not be deleted (investran contact list import table is empty) - add log
		if(!proceed) {
			String errorMsg = 'Batch job ended unexpectedly. Zero rows in "EQT Investran Contact List Import" object to import. Possible cause: Investran Data was not loaded into salesforce.\nDid not remove existing commitment data.';
			if(loggingActive)
				EQT_UtilApexLog.endProcessLog(PROCESS, false);
			EQT_UtilApexLog.saveLog(new EQT_UtilApexLog.Info(
			 'Batch to clean down investran data before each import','','EQT_BatchInvestranRemoveCommitments','finish()',
			 errorMsg));
			EQT_UtilApexLog.sendProcessLogNotification(PROCESS, errorMsg);
		}
		else {
			if(!Test.isRunningTest()) {
				Database.executeBatch(new EQT_BatchInvestranContactListImport());
			}
		}
	}
}