@isTest
private class EQT_UtilApexLog_Test
{
	static String processName = 'TestProcess';

	@testSetup
	static void testSetup(){
		
		// Create a new Process Log Setting (custom settings)
		EQT_ProcessLog__c process = new EQT_ProcessLog__c(Name = processName);
		process.ProcessLabel__c = 'Test Process';
		process.IsEnabled__c = true;
		process.NotificationRecipient__c = 'test@example.com';
		process.SendEmailNotification__c = true;
		insert process;
	}
	
	@isTest
	static void test_processLogging()
	{

		//Initialize log
		String executionId = EQT_UtilApexLog.startProcessLog(processName);

		// Log parameters: String process, String exId, String cls, String routine, String msg
		// Log Info
		EQT_UtilApexLog.Info infoLog0 = new EQT_UtilApexLog.Info(
										processName, executionId, 'Info Class', 'Test Method 0','Test Info Message');
		EQT_UtilApexLog.saveLog(infoLog0);

		EQT_UtilApexLog.Info infoLog1 = new EQT_UtilApexLog.Info(
										processName, executionId, 'Info Class', 'Test Method 1','Test Info Message 1');
		// Log Warning
		EQT_UtilApexLog.Warning warnLog = new EQT_UtilApexLog.Warning(
										processName, executionId, 'Warning Class', 'Test Method','Test Warning Message');
		// Log Error
		EQT_UtilApexLog.Error errorLog = new EQT_UtilApexLog.Error(
										processName, executionId, 'Error Class', 'Test Method','Test Error Message');
		
		List<EQT_UtilApexLog.Log> logsToSave = new List<EQT_UtilApexLog.Log>();
		logsToSave.add(infoLog1);
		logsToSave.add(warnLog);
		logsToSave.add(errorLog);
		EQT_UtilApexLog.saveLog(logsToSave);

		EQT_UtilApexLog.endProcessLog(processName,true);
		
		List<EQT_Event_Log__c> eventLogs = [SELECT ProcessName__c,ExecutionId__c,Type__c,ApexClass__c,Method__c,EQT_Log_Detail__c,TimeStamp__c FROM EQT_Event_Log__c];
		for(EQT_Event_Log__c ev : eventLogs)
			System.debug(ev);

		EQT_ProcessLog__c process = EQT_ProcessLog__c.getInstance(processName);
		System.debug(process);

	}
}