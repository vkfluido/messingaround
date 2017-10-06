@isTest
private class EQT_Investor_LPCode_Handler_Test {
	
	@isTest static void insertNewRecordsTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(0, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id));
		insert investorLPCodeToInsert;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(0, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}

	@isTest static void insertNewRecordsCommitmentTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');

		//create sample Commitment record
		EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);

		//create fund commitment
		EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
		fc1.EQT_Fund__c = fund1.Id;
		fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		fc1.EQT_Amount__c = 100;
		fc1.EQT_LP_Code__c = 'lp code1';

		EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
		fc2.EQT_Fund__c = fund2.Id;
		fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity2';
		fc2.EQT_Amount__c = 100;
		fc2.EQT_LP_Code__c = 'lp code2';
		
		insert new List<EQT_Fund_Commitment__c> {fc1, fc2};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id));
		insert investorLPCodeToInsert;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(2, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}

	@isTest static void updateDeleteTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');

		//create sample Commitment record
		//EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);

		//create fund commitment
		EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
		fc1.EQT_Fund__c = fund1.Id;
		fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		fc1.EQT_Amount__c = 100;
		fc1.EQT_LP_Code__c = 'lp code1';

		EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
		fc2.EQT_Fund__c = fund2.Id;
		fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity2';
		fc2.EQT_Amount__c = 200;
		fc2.EQT_LP_Code__c = 'lp code2';
		
		insert new List<EQT_Fund_Commitment__c> {fc1, fc2};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id);
		EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id);
		EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id);
		insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(2, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor1.Id AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());

		//now update Investor LP code to simulate "delete"
		ilpc1.EQT_Investor__c = null;
		update ilpc1;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = null AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());
	}

	@isTest static void updateInvestorTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');

		//create sample Commitment record
		//EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);

		//create fund commitment
		EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
		fc1.EQT_Fund__c = fund1.Id;
		fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		fc1.EQT_Amount__c = 100;
		fc1.EQT_LP_Code__c = 'lp code1';

		EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
		fc2.EQT_Fund__c = fund2.Id;
		fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity2';
		fc2.EQT_Amount__c = 200;
		fc2.EQT_LP_Code__c = 'lp code2';
		
		insert new List<EQT_Fund_Commitment__c> {fc1, fc2};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = null);
		EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id);
		EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id);
		insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = null AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());

		//now update Investor LP code to simulate delete
		ilpc1.EQT_Investor__c = investor1.Id;
		update ilpc1;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(2, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor1.Id AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());
	}

	@isTest static void updateChangeToNewInvestorTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
		Fund__c fund3 = EQT_TestFactory.createSampleFund('sample fund3');

		//create sample Commitment record
		//EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);

		//create fund commitment
		EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
		fc1.EQT_Fund__c = fund1.Id;
		fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		fc1.EQT_Amount__c = 100;
		fc1.EQT_LP_Code__c = 'lp code1';

		EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
		fc2.EQT_Fund__c = fund2.Id;
		fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity2';
		fc2.EQT_Amount__c = 200;
		fc2.EQT_LP_Code__c = 'lp code2';

		EQT_Fund_Commitment__c fc3 = new EQT_Fund_Commitment__c();
		fc3.EQT_Fund__c = fund3.Id;
		fc3.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity3';
		fc3.EQT_Amount__c = 500;
		fc3.EQT_LP_Code__c = 'lp code3';
		
		insert new List<EQT_Fund_Commitment__c> {fc1, fc2, fc3};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id);
		EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id);
		EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id);
		insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(3, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//now update Investor LP code to simulate delete
		ilpc1.EQT_Investor__c = investor3.Id;
		update ilpc1;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(3, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor3.Id].EQT_Amount__c);
		//system.assertEquals(500, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund3.Id AND EQT_Investor__c = :investor3.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}

	@isTest static void updateChangeToNewInvestorCommitmentUpdateTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
		Fund__c fund3 = EQT_TestFactory.createSampleFund('sample fund3');

		//create sample Commitment record
		//EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund3.Id, investor3.Id);

		//create fund commitment
		EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
		fc1.EQT_Fund__c = fund1.Id;
		fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		fc1.EQT_Amount__c = 100;
		fc1.EQT_LP_Code__c = 'lp code1';

		EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
		fc2.EQT_Fund__c = fund2.Id;
		fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity2';
		fc2.EQT_Amount__c = 200;
		fc2.EQT_LP_Code__c = 'lp code2';

		EQT_Fund_Commitment__c fc3 = new EQT_Fund_Commitment__c();
		fc3.EQT_Fund__c = fund3.Id;
		fc3.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity3';
		fc3.EQT_Amount__c = 500;
		fc3.EQT_LP_Code__c = 'lp code3';
		
		insert new List<EQT_Fund_Commitment__c> {fc1, fc2, fc3};

		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c].size());
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id);
		EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id);
		EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id);
		insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(3, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor1.Id AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor3.Id AND EQT_LP_Code__c = 'lp code3'].size());

		//now update Investor LP code to simulate delete
		ilpc1.EQT_Investor__c = investor3.Id;
		update ilpc1;

		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		//system.assertEquals(3, [SELECT Id FROM EQT_Commitment__c].size());
		//system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor3.Id].EQT_Amount__c);
		//system.assertEquals(500, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund3.Id AND EQT_Investor__c = :investor3.Id].EQT_Amount__c);
		//system.assertEquals(200, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor3.Id AND EQT_LP_Code__c = 'lp code1'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor2.Id AND EQT_LP_Code__c = 'lp code2'].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Investor__c = :investor3.Id AND EQT_LP_Code__c = 'lp code3'].size());
	}
}