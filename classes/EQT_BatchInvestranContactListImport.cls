/**
    About
    -----
    Description: Batch to group by LP Code investran contact list and upsert it to Investran Commitment table

    Created for: EQT
    Created date: June 2016
    
    Details / Methods
    -----------------
    

    Update History
    --------------
    Created June 2016 - R.B.
	Sept 2017 felix.guerrero@fluidogroup.com - Implemented process logging 

    Issues / TODOs
    --------------
*/
public without sharing class EQT_BatchInvestranContactListImport implements Database.Batchable<SObject>, Database.Stateful {
	
	private Integer totalCount = 0;		//total processed record
	private Integer totalFailed = 0;	//total failed record
	private Set<Id> successIds = new Set<Id>();
	private List<String> errorLog = new List<String>(); //upsert fail log
	private Integer fundCommitmentSize = 0;
	private Integer investranCommitmentSize = 0;
	private static String PROCESS = 'Investran_Import_Process';
	private static String EX_ID = EQT_UtilApexLog.getProcessExecutionId(PROCESS);
	public Boolean loggingActive = (EX_ID != null);
	private List<EQT_UtilApexLog.Log> logsToSave = new List<EQT_UtilApexLog.Log>();
	private static Map<String, Double> currencyRates = new Map<String, Double>();
	
	//handle batch exceptions
	public class BatchInvestranContactListImportException extends Exception {}

	public EQT_BatchInvestranContactListImport() {}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		
		if(EX_ID == null){
			EX_ID = EQT_UtilApexLog.startProcessLog(PROCESS);
			loggingActive = (EX_ID != null);
			logsToSave.add(new EQT_UtilApexLog.Info(
							   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'Batch job start','Processing Investran Contact List Import records.' ));
		}
		System.debug('@EQT_BatchInvestranContactListImport ExecutionId:'+EX_ID + ' >loggingActive:'+loggingActive);
		//check if "source" tables are empty
		fundCommitmentSize = [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Origin__c != 'Manual entry'].size();
		investranCommitmentSize = [SELECT Id FROM EQT_Investran_Commitment__c].size();
		System.debug('fundCommitmentSize:'+fundCommitmentSize+', investranCommitmentSize:'+investranCommitmentSize);
		Database.QueryLocator q;

		if(fundCommitmentSize == 0 && investranCommitmentSize == 0) {
			q = Database.getQueryLocator
			(
				[
					Select Id, Total_Commitment__c, Invester_ID__c, Investor_Reference__c, Legal_Entity_ID__c,
							Legal_Entity__c, Organization_ID__c, Investor__c
					FROM EQT_Investran_Contact_List_Import__c
					WHERE Imported__c = false
				]
			);
		}else{
			EQT_UtilApexLog.saveLog(new EQT_UtilApexLog.Error(
							   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'execute()',
							   'Could not proceed because of existing Investran Fund Commitment records.'));
			if(loggingActive)
				EQT_UtilApexLog.endProcessLog(PROCESS, false);
			System.abortJob(BC.getJobId());
		}
		
		return q;
	}

	public void execute(Database.BatchableContext BC, List<EQT_Investran_Contact_List_Import__c> scope) {
		System.debug('Processing batch of ' + scope.size() + ' Contact_List_Import records');
		/*logsToSave.add(new EQT_UtilApexLog.Info(
							   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'execute()',
							   'Processing batch of ' + scope.size() + ' Contact_List_Import records'));*/
		

			Set<Id> idsToProcess = new Set<Id>();
			Map<String, EQT_Investran_Commitment__c> toUpsert = new Map<String, EQT_Investran_Commitment__c>();

			Map<String,EQT_Investran_Contact_List_Import__c> importList = new Map<String,EQT_Investran_Contact_List_Import__c>();
			for(EQT_Investran_Contact_List_Import__c item : scope) {
				importList.put(item.Investor_Reference__c + ':' + item.Legal_Entity_ID__c, item); // group by LP code and legal entity id
				idsToProcess.add(item.Id);
			}

			for(EQT_Investran_Contact_List_Import__c result : importList.values()) {

				if(result.get('Investor_Reference__c') != null && result.get('Legal_Entity_ID__c') != null) {
					String key = (String)result.get('Investor_Reference__c') + ':' + (String)result.get('Legal_Entity_ID__c');
					toUpsert.put(key, new EQT_Investran_Commitment__c
						(
							EQT_Amount_Total_Commitment__c = (Decimal)result.get('Total_Commitment__c'),
							EQT_Commitment_Investran_ID_Invester_ID__c = (String)result.get('Invester_ID__c'),
							Commitment_LP_Code_Investor_Reference__c = (String)result.get('Investor_Reference__c'),
							EQT_Partnership_Legal_Entity__c = (String)result.get('Legal_Entity_ID__c'),
							EQT_Partnership_Legal_Entity_Name__c = (String)result.get('Legal_Entity__c'),
							EQT_Vehicle_ID_Organization_ID__c = (String)result.get('Organization_ID__c'),
							EQT_Vehicle_Name_Investor__c = String.valueOf(result.get('Investor__c')).length() > 150 ? String.valueOf(result.get('Investor__c')).substring(0,150) : String.valueOf(result.get('Investor__c')),
							EQT_Commitment_LP_Code_Investor_Id__c = key
						)
					);
				}
			}

			Schema.SObjectField f = EQT_Investran_Commitment__c.Fields.EQT_Commitment_LP_Code_Investor_Id__c;
			Database.UpsertResult[] result = Database.upsert(toUpsert.values(), f, false);
			Integer successCount = 0;
			for(Database.UpsertResult ur : result) {
				if(ur.isSuccess()) {
					successCount++;
					successIds.add(ur.getId());
				}
				else {
					totalFailed++;
					for(Database.Error e : ur.getErrors()) {
						errorLog.add(e.getMessage());
					}
				}

				totalCount++;
			}
			/*logsToSave.add(new EQT_UtilApexLog.Info(
							   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'execute()',
							   successCount + ' of '+ toUpsert.size() + ' Investran Commitment records upserted successfully, ' + (toUpsert.size()-successCount) + ' failed.')
			);*/

			List<EQT_Investran_Contact_List_Import__c> toUpdate = new List<EQT_Investran_Contact_List_Import__c>();

			for(EQT_Investran_Contact_List_Import__c imp : [SELECT Id, Imported__c FROM EQT_Investran_Contact_List_Import__c
	                                                           WHERE Id IN :idsToProcess]) {

				imp.Imported__c = true;
				toUpdate.add(imp);
			}

			if(!toUpdate.isEmpty()) {
				try{
					update toUpdate;
				}catch(DmlException e){
					logsToSave.add(new EQT_UtilApexLog.Error(
							   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'Delete Contact_List_Import records',
							   'DML update action failed.\n'+e.getMessage())
					);
				}
			}

		if(loggingActive)
			EQT_UtilApexLog.saveLog(logsToSave);
	}

	public void finish(Database.BatchableContext BC) {
		Boolean success = false;
		loggingActive = (EQT_UtilApexLog.getProcessExecutionId(PROCESS) != null);
		if(totalFailed > 0) {
			//get string message from error log
			String errorLogMessage = '';
			for(String error : errorLog) {
				errorLogMessage += error + '\n';
			}

			if(errorLogMessage.length() > 32768) {
				errorLogMessage = errorLogMessage.substring(0, 32768);
			}

			String message = String.format('There were {0} failed upserts of total {1} records processed. Detail error log: {2}',
											new List<String>{String.valueOf(totalFailed), String.valueOf(totalCount), errorLogMessage});
			//write log
			if(loggingActive)
				EQT_UtilApexLog.saveLog(new EQT_UtilApexLog.Error(
						   PROCESS, EX_ID, 'EQT_BatchInvestranContactListImport', 'finish()', message));
			else
				EQT_UtilApexLog.generateLog('EQT_BatchInvestranContactListImport log: ', message);
		}else{
			success = true;
		}
		System.debug('totalFailed:'+totalFailed+', success:'+success + ', loggingActive:' +loggingActive);
		
		if(loggingActive){
			EQT_UtilApexLog.endProcessLog(PROCESS,success);

			String defaultCurrency;
			for (CurrencyType cRates : [SELECT ISOCode, ConversionRate, IsCorporate FROM CurrencyType WHERE IsActive=TRUE]) {
	                  CurrencyRates.put(cRates.IsoCode, cRates.ConversionRate);
	                  if(cRates.IsCorporate)
	                  	defaultCurrency = cRates.IsoCode;
	            }
			// Send Process Notification
			String summary = '\nProcess Results - Total Fund Commitments by Fund:\n'+
							 'Fund name : # records : Total Amount\n';
			AggregateResult[] fundCommitmentSummary = [SELECT EQT_Fund__r.Name, Count(Id), Sum(EQT_Amount__c), CurrencyIsoCode from EQT_Fund_Commitment__c
														WHERE EQT_Origin__c = 'Investran'
														GROUP BY EQT_Fund__r.Name, CurrencyIsoCode
														ORDER BY EQT_Fund__r.Name];
			for (AggregateResult ar : fundCommitmentSummary)  {
				String fund = (String)ar.get('Name');
				Integer records = (Integer)ar.get('expr0');
				String fundCurrency = (String)ar.get('CurrencyIsoCode');
				Decimal amount = (Decimal)ar.get('expr1');
				amount = (amount==null?0:amount);
				if(!fundCurrency.equals(defaultCurrency))
					amount = (Decimal)convertCurrency(amount,defaultCurrency,fundCurrency).round();
				summary += fund + ' : ';
				summary += String.valueOf(records) + ' records : ';
				summary += amount.format() + ' ' +fundCurrency+' \n';
			}									
			EQT_UtilApexLog.sendProcessLogNotification(PROCESS, summary);
		}
	}

	private Double convertCurrency(Decimal amount, String fromCurrency, String toCurrency ) {
            Double fromCurrencyRate = currencyRates.get(fromCurrency);
            Double toCurrencyRate = currencyRates.get(toCurrency);

            Double fromAmount = amount/fromCurrencyRate;
            Double toAmount = fromAmount * toCurrencyRate;

            return toAmount;
    }
	//used to simulate fail
	public void setTotalFailed(Integer failedNumber) {
		if(Test.isRunningTest()) {
			this.totalFailed = failedNumber;
		}
	}
}