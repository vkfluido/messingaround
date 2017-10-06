@isTest
private class EQT_BatchInvestranContactListImport_Test {
	static String processName = 'Investran_Import_Process';
	
	@testSetup
	static void testSetup(){
		// Create a new Process Log Setting (custom settings)
		EQT_ProcessLog__c process = new EQT_ProcessLog__c(Name = processName);
		process.ProcessLabel__c = 'Test Process';
		process.IsEnabled__c = true;
		process.NotificationRecipient__c = 'testIRUser@example.com';
		process.SendEmailNotification__c = true;
		insert process;

        
        User u = new User();
        u.username= 'testIRUser@eqtpartners.com.test';
        u.email ='testIRUser@example.com';
        u.localeSidKey = 'en_US';
        u.languageLocaleKey = 'en_US';
        u.profileId = EQT_UTIL_Meta.profileId('EQT Investor Relations');
        u.lastname='testIRUser';
        u.TimeZoneSidKey='GMT';
        u.EmailEncodingKey='UTF-8';
        u.Alias = 'utu';
        insert u;

	}
	
	@isTest static void test_InvestranProcess() {
		User runningUser = [SELECT Id, username FROM User WHERE username = :'testIRUser@eqtpartners.com.test'];
		Id ActiveFundrecordType = EQT_UTIL_Meta.getRecordTypeId('Fund__c.EQT_Active_Fund');
		List<Fund__c> funds = new List<Fund__c>();
		for(Integer i = 0; i < 3; i++){
			funds.add(new Fund__c(
					RecordTypeId = ActiveFundrecordType,
					Name = 'Active Fund ' + i,
					Status__c = 'Active',
					IR_Admin__c = runningUser.Id
				));
		}
		funds[0].CurrencyIsoCode = 'USD';
		insert funds;
		System.debug('[ FUNDS ]');
		for(Fund__c f:funds)
        	System.debug(f);

		Id InvestorRecordType = EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor');
		List<Account> investors = new List<Account>();
		for(Integer i = 0; i < 5; i++){
			investors.add(new Account(
					RecordTypeId = InvestorRecordType,
					Name = 'Investor ' + i,
					EQT_Investor_Type__c = 'Other',
					EQT_Country__c = 'Sweden',
					Type = 'Investor'
				));
		}
		insert investors;
		System.debug('[ INVESTORS ]');
		for(Account inv:investors)
        	System.debug(inv);

		List<EQT_Investor_LP_Code__c> lpcodes = new List<EQT_Investor_LP_Code__c>();
		for(Integer i = 0; i < 3; i++){
			lpcodes.add(new EQT_Investor_LP_Code__c(
				Name = 'LP000' + i, 
				EQT_Vehicle_Name__c = 'Investor ' + i,
				EQT_Investor__c = investors.get(i).Id)
			);
		}
		lpcodes[0].EQT_Vehicle_Name__c = 'Old VehicleName'; //Investor 0 has a different vehicle name, which we expect will be updated
		insert lpcodes;
		System.debug('[ LPCodes ]');
		for(EQT_Investor_LP_Code__c lp:lpcodes)
        	System.debug(lp);

		List<EQT_Fund_Partnership__c> partnerships = new List<EQT_Fund_Partnership__c>();
		for(Integer i = 0; i < 2; i++){
			partnerships.add(new EQT_Fund_Partnership__c(
				EQT_Fund__c = funds.get(i).Id,
				EQT_Investran_Partnership_Legal_EntityID__c = 'LE'+i,
				Partnership_Name__c = 'Fund '+i+' Partnership'));
		}
		insert partnerships;
		System.debug('[ PARTNERSHIPS ]');
		for(EQT_Fund_Partnership__c prt:partnerships)
        	System.debug(prt);
		/*
		List<EQT_Fund_Commitment__c> existingFundCommitments = new List<EQT_Fund_Commitment__c>();
		for(Integer i = 0; i < 3; i++){
			existingFundCommitments.add(new EQT_Fund_Commitment__c(
				EQT_Amount__c = 1000000,
				EQT_Fund__c = funds.get(i).Id,
				EQT_Investor__c = investors.get(i).Id,
				EQT_LP_Code__c = lpcodes.get(i).Name,
				EQT_Origin__c = 'Investran',
				EQT_Partnership_Name__c = partnerships.get(Math.mod(i,partnerships.size())).Partnership_Name__c
				));
		}
		insert existingFundCommitments;
		*/

		//create sample data to check batch

		List<EQT_Investran_Contact_List_Import__c> contactListImports = EQT_TestFactory.createContactListImportRecords(6, 4);
		insert contactListImports;
		for(EQT_Investran_Contact_List_Import__c cli : contactListImports)
			System.debug(cli);
		Test.startTest();
        	//run batch
        	Database.executeBatch(new EQT_BatchInvestranContactListImport(), 1000);
        Test.stopTest();

        List<EQT_Investran_Commitment__c> ics = [SELECT EQT_Amount_Total_Commitment__c,EQT_Commitment_Investran_ID_Invester_ID__c,Commitment_LP_Code_Investor_Reference__c,EQT_Partnership_Legal_Entity__c,EQT_Partnership_Legal_Entity_Name__c,EQT_Vehicle_ID_Organization_ID__c,EQT_Vehicle_Name_Investor__c,EQT_Commitment_LP_Code_Investor_Id__c
        										 FROM EQT_Investran_Commitment__c];
		System.assertEquals(12,ics.size()); // 12 Investran Commitments were created
		for(EQT_Investran_Commitment__c ic:ics)
        	System.debug(ic);
		List<EQT_Fund_Commitment__c> fcs = [SELECT EQT_Amount__c,EQT_Fund__c,EQT_Investor__c,EQT_LP_Code__c,EQT_Origin__c,EQT_Partnership_Name__c FROM EQT_Fund_Commitment__c];
		System.assertEquals(6,fcs.size()); // 6 Fund Commitments were created
		for(EQT_Fund_Commitment__c fc:fcs)
        	System.debug(fc);
        List<EQT_Event_Log__c> logs = [SELECT Id,TimeStamp__c,ProcessName__c,ExecutionId__c,Type__c,ApexClass__c,Method__c,EQT_Log_Detail__c FROM EQT_Event_Log__c Order BY Id];
        for(EQT_Event_Log__c log:logs)
        	System.debug(log);
	}

	@isTest static void batchTest() {
		//set up org
		EQT_TestFactory.setUpOrg();
		//disable trigger to avoid deleting imported records
		EQT_TestFactory.disableInvestranContactListTrigger();

		//create sample data to check batch
		List<EQT_Investran_Contact_List_Import__c> batchList = new List<EQT_Investran_Contact_List_Import__c>();
		for(Integer i = 1; i <= 1000; i++) {
			batchList.add(new EQT_Investran_Contact_List_Import__c
				(
					Total_Commitment__c = i * 10,
					Invester_ID__c = String.valueOf(i),
					Investor_Reference__c = 'test' + i,
					Legal_Entity_ID__c = '22',
					Legal_Entity__c = 'test',
					Organization_ID__c = 'org1',
					Investor__c = 'something',
					Imported__c = false
				)
			);
		}

		insert batchList;
		system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = false].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Commitment__c].size());

		Test.startTest();
        //run batch
        Database.executeBatch(new EQT_BatchInvestranContactListImport(), 1000);
        
        Test.stopTest();
        system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Commitment__c].size());
        //system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());
        system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = true].size());
	}

	@isTest static void batchUpsertTest() {
		//set up org
		EQT_TestFactory.setUpOrg();
		//disable trigger to avoid deleting imported records
		EQT_TestFactory.disableInvestranContactListTrigger();

		//create sample data to check batch
		List<EQT_Investran_Contact_List_Import__c> batchList = new List<EQT_Investran_Contact_List_Import__c>();
		for(Integer i = 1; i <= 1000; i++) {
			batchList.add(new EQT_Investran_Contact_List_Import__c
				(
					Total_Commitment__c = i * 10,
					Invester_ID__c = String.valueOf(i),
					Investor_Reference__c = 'test' + i,
					Legal_Entity_ID__c = 'test' + i,
					Legal_Entity__c = 'test',
					Organization_ID__c = 'org1',
					Investor__c = 'something',
					Imported__c = false
				)
			);
		}

		insert batchList;
		system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Commitment__c].size());
		//system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());

		//create some investran commitments records to check upsert
		EQT_Investran_Commitment__c ic1 = new EQT_Investran_Commitment__c(Commitment_LP_Code_Investor_Reference__c = 'test100', EQT_Partnership_Legal_Entity_Name__c = 'test100', EQT_Partnership_Legal_Entity__c = 'test100', EQT_Commitment_LP_Code_Investor_Id__c = 'test100:test100');
		EQT_Investran_Commitment__c ic2 = new EQT_Investran_Commitment__c(Commitment_LP_Code_Investor_Reference__c = 'test526', EQT_Partnership_Legal_Entity_Name__c = 'test526', EQT_Partnership_Legal_Entity__c = 'test256', EQT_Commitment_LP_Code_Investor_Id__c = 'test526:test526');
		insert new List<EQT_Investran_Commitment__c> {ic1, ic2};
		system.assertEquals(2, [SELECT Id FROM EQT_Investran_Commitment__c].size());

		Test.startTest();
        //run batch
        Database.executeBatch(new EQT_BatchInvestranContactListImport(), 1000);
        
        Test.stopTest();
        system.assertEquals(2, [SELECT Id FROM EQT_Investran_Commitment__c].size());
        system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = false].size());
        system.assertEquals(0, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = true].size());
  		//List<EQT_Event_Log__c> logList = [SELECT Id, EQT_Log_Detail__c FROM EQT_Event_Log__c];
		//system.assertEquals(1, logList.size());
		//system.assert(logList[0].EQT_Log_Detail__c.contains('Target tables are not empty. Please check the EQT_BatchInvestranRemoveCommitments job has completed and review any errors reported'));
	}

	@isTest static void failTest() {
		//set up org
		EQT_TestFactory.setUpOrg();
		//disable trigger to avoid deleting imported records
		EQT_TestFactory.disableInvestranContactListTrigger();

		//create sample data to check batch
		List<EQT_Investran_Contact_List_Import__c> batchList = new List<EQT_Investran_Contact_List_Import__c>();
		for(Integer i = 1; i <= 1000; i++) {
			batchList.add(new EQT_Investran_Contact_List_Import__c
				(
					Total_Commitment__c = i * 10,
					Invester_ID__c = String.valueOf(i),
					Investor_Reference__c = 'test' + i,
					Legal_Entity_ID__c = '22',
					Legal_Entity__c = 'test',
					Organization_ID__c = 'org1',
					Investor__c = 'something',
					Imported__c = false
				)
			);
		}

		insert batchList;
		system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Commitment__c].size());

		Test.startTest();
        //run batch
        EQT_BatchInvestranContactListImport batchTest = new EQT_BatchInvestranContactListImport();
        batchTest.setTotalFailed(4);
        Database.executeBatch(batchTest, 1000);
        
        Test.stopTest();
        //verify log was created
        //system.assertEquals(1, [SELECT Id FROM EQT_Event_Log__c].size());
        //EQT_Event_Log__c log = [SELECT Id, EQT_Log_Detail__c FROM EQT_Event_Log__c LIMIT 1];
        //system.assert(log.EQT_Log_Detail__c.contains('EQT_BatchInvestranContactListImport log:'));
	}
}