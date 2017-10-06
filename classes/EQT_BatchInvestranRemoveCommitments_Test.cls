@isTest
private class EQT_BatchInvestranRemoveCommitments_Test {	
	@isTest static void deleteTest() {
		//create some sample data
		List<EQT_Investran_Contact_List_Import__c> importedDataToInsert = new List<EQT_Investran_Contact_List_Import__c>();
		List<EQT_Investran_Commitment__c> investranCommitmentToInsert = new List<EQT_Investran_Commitment__c>();
		List<EQT_Fund_Commitment__c> fundCommitmentToInsert = new List<EQT_Fund_Commitment__c>();

		for(Integer i = 1; i <= 20; i++) {
			importedDataToInsert.add(new EQT_Investran_Contact_List_Import__c(Name = 'import ' + i));
			investranCommitmentToInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Vehicle_Name_Investor__c = 'investran ' + i,
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity ' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp ' + i
				));
		}
		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund1.Id].size());
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund2.Id].size());

		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 100, EQT_Fund__c = fund1.Id, EQT_Origin__c = 'Investran'));
		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 200, EQT_Fund__c = fund2.Id, EQT_Origin__c = 'Manual entry'));

		insert importedDataToInsert;
		insert investranCommitmentToInsert;
		insert fundCommitmentToInsert;

		system.assertEquals(20, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(20, [SELECT Id FROM EQT_Investran_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		Test.startTest();
		EQT_BatchInvestranRemoveCommitments b = new EQT_BatchInvestranRemoveCommitments();
        Database.executeBatch(b, 100);
        Test.stopTest();

        system.assertEquals(20, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}
	
	@isTest static void noLoggingTest() {
		//create some sample data
		List<EQT_Investran_Commitment__c> investranCommitmentToInsert = new List<EQT_Investran_Commitment__c>();
		List<EQT_Fund_Commitment__c> fundCommitmentToInsert = new List<EQT_Fund_Commitment__c>();

		for(Integer i = 1; i <= 20; i++) {
			investranCommitmentToInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Vehicle_Name_Investor__c = 'investran ' + i,
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity ' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp ' + i
				));
		}
		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund1.Id].size());
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund2.Id].size());

		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 100, EQT_Fund__c = fund1.Id, EQT_Origin__c = 'Investran'));
		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 200, EQT_Fund__c = fund2.Id, EQT_Origin__c = 'Manual entry'));

		insert investranCommitmentToInsert;
		insert fundCommitmentToInsert;

		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(20, [SELECT Id FROM EQT_Investran_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		for(EQT_Event_Log__c log : [SELECT Id,ProcessName__c,ExecutionId__c,Type__c,ApexClass__c,Method__c,EQT_Log_Detail__c,TimeStamp__c FROM EQT_Event_Log__c])
			system.debug(log);

		Test.startTest();
			EQT_BatchInvestranRemoveCommitments b = new EQT_BatchInvestranRemoveCommitments();
	        Database.executeBatch(b, 100);
        Test.stopTest();

        system.assertEquals(0, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(20, [SELECT Id FROM EQT_Investran_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		List<EQT_Event_Log__c> logList = [SELECT Id, ProcessName__c,ExecutionId__c,Type__c,ApexClass__c,Method__c,EQT_Log_Detail__c,TimeStamp__c FROM EQT_Event_Log__c
		WHERE ApexClass__c='EQT_BatchInvestranRemoveCommitments'];

		system.assertEquals(1, logList.size());
		system.assertEquals(logList[0].ProcessName__c, 'Batch to clean down investran data before each import');
	}

	@isTest static void loggingTest() {
		// Setup Process Logging
		EQT_ProcessLog__c process = new EQT_ProcessLog__c(Name = 'Investran_Import_Process');
		process.ProcessLabel__c = 'Test Process';
		process.IsEnabled__c = true;
		process.NotificationRecipient__c = 'testIRUser@example.com';
		process.SendEmailNotification__c = false;
		insert process;

		//create some sample data
		List<EQT_Investran_Commitment__c> investranCommitmentToInsert = new List<EQT_Investran_Commitment__c>();
		List<EQT_Fund_Commitment__c> fundCommitmentToInsert = new List<EQT_Fund_Commitment__c>();
		List<EQT_Investran_Contact_List_Import__c> contactListImports = EQT_TestFactory.createContactListImportRecords(6, 4);
		insert contactListImports;

		for(Integer i = 1; i <= 20; i++) {
			investranCommitmentToInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Vehicle_Name_Investor__c = 'investran ' + i,
					EQT_Partnership_Legal_Entity__c = String.valueOf(i),
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity ' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp ' + i
				));
		}
		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund1.Id].size());
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
		system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund2.Id].size());

		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 100, EQT_Fund__c = fund1.Id, EQT_Origin__c = 'Investran'));
		fundCommitmentToInsert.add(new EQT_Fund_Commitment__c(EQT_Amount__c = 200, EQT_Fund__c = fund2.Id, EQT_Origin__c = 'Manual entry'));

		insert investranCommitmentToInsert;
		insert fundCommitmentToInsert;

		Test.startTest();
		EQT_BatchInvestranRemoveCommitments b = new EQT_BatchInvestranRemoveCommitments();
        Database.executeBatch(b, 100);
        Test.stopTest();

		List<EQT_Event_Log__c> logList = [SELECT Id, ProcessName__c,ExecutionId__c,Type__c,ApexClass__c,Method__c,EQT_Log_Detail__c,TimeStamp__c FROM EQT_Event_Log__c];
		System.debug(logList);

	}
}