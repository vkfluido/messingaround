@isTest
private class EQT_FundPartnershipHandler_Test {
	
	@isTest static void fundPartnershiptWithoutFundTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        system.runAs(u) {
			system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
			system.assertEquals(0, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			//create sample fund partnership
			List<EQT_Fund_Partnership__c> fundPartnershipToInsert = new List<EQT_Fund_Partnership__c>();
			fundPartnershipToInsert.add(new EQT_Fund_Partnership__c(Partnership_Name__c = 'legal entity name1', EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity1'));
			fundPartnershipToInsert.add(new EQT_Fund_Partnership__c(Partnership_Name__c = 'legal entity name5', EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity5'));
			insert fundPartnershipToInsert;

			system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
			system.assertEquals(2, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		}
	}

	@isTest static void fundPartnershiptInsertTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        List<EQT_Investran_Commitment__c> toInsert = new List<EQT_Investran_Commitment__c>();
		for(Integer i = 1; i <= 10; i++) {
			toInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Amount_Total_Commitment__c = i * 10,
					EQT_Commitment_Investran_ID_Invester_ID__c = 'investor' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp code' + i,
					EQT_Partnership_Legal_Entity__c = 'legal entity' + i,
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity name' + i,
					EQT_Vehicle_ID_Organization_ID__c = 'vehicle id' + i,
					EQT_Vehicle_Name_Investor__c = 'vehicle name' + i
				)
			);
		}

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//delete one fund partnerhip record to simulate insert
		delete [SELECT Id FROM EQT_Fund_Partnership__c WHERE EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity10'];
		system.assertEquals(9, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        system.runAs(u) {
			system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
			system.assertEquals(9, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			//create sample fund
			Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
			system.assertEquals(1, [SELECT Id FROM Fund__c].size());

			//insert new fund partnerhip record
			EQT_Fund_Partnership__c fp = new EQT_Fund_Partnership__c();
			fp.Partnership_Name__c = 'legal entity name10';
			fp.EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity10';
			fp.EQT_Fund__c = fund.Id;
			insert fp;

			system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
			system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund.Id].size());
		}
	}

	@isTest static void fundPartnershiptInsertDuplicateTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        List<EQT_Investran_Commitment__c> toInsert = new List<EQT_Investran_Commitment__c>();
		for(Integer i = 1; i <= 10; i++) {
			toInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Amount_Total_Commitment__c = i * 10,
					EQT_Commitment_Investran_ID_Invester_ID__c = 'investor' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp code' + i,
					EQT_Partnership_Legal_Entity__c = 'legal entity' + i,
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity name' + i,
					EQT_Vehicle_ID_Organization_ID__c = 'vehicle id' + i,
					EQT_Vehicle_Name_Investor__c = 'vehicle name' + i
				)
			);
		}

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//delete one fund partnerhip record to simulate insert
		delete [SELECT Id FROM EQT_Fund_Partnership__c WHERE EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity10'];
		system.assertEquals(9, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //create sample fund
		Fund__c fund1, fund2;
		system.runAs(u) {
			fund1 = EQT_TestFactory.createSampleFund('sample fund1');
			fund2 = EQT_TestFactory.createSampleFund('sample fund2');
			system.assertEquals(2, [SELECT Id FROM Fund__c].size());
		}

        //fund commitment
        EQT_Fund_Commitment__c fc1 = new EQT_Fund_Commitment__c();
        fc1.EQT_Amount__c = 100;
    	fc1.EQT_Fund__c = fund1.Id;
    	fc1.EQT_Investran_Invester_ID__c = 'investor10';
    	fc1.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity10';
    	fc1.EQT_LP_Code__c = 'lp code10';
    	fc1.EQT_Partnership_Name__c = 'legal entity name10';
    	fc1.EQT_Vehicle_Name__c = 'vehicle name10';
    	fc1.EQT_Vehicle_Organization_ID__c = 'vehicle id10';
    	
    	EQT_Fund_Commitment__c fc2 = new EQT_Fund_Commitment__c();
        fc2.EQT_Amount__c = 100;
    	fc2.EQT_Fund__c = fund2.Id;
    	fc2.EQT_Investran_Invester_ID__c = 'investor10';
    	fc2.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity10';
    	fc2.EQT_LP_Code__c = 'lp code10';
    	fc2.EQT_Partnership_Name__c = 'legal entity name10';
    	fc2.EQT_Vehicle_Name__c = 'vehicle name10';
    	fc2.EQT_Vehicle_Organization_ID__c = 'vehicle id10';

    	insert new List<EQT_Fund_Commitment__c> {fc1, fc2};

        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        system.runAs(u) {
			system.assertEquals(2, [SELECT Id FROM EQT_Fund_Commitment__c].size());
			system.assertEquals(9, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			

			//insert new fund partnerhip record
			EQT_Fund_Partnership__c fp = new EQT_Fund_Partnership__c();
			fp.Partnership_Name__c = 'legal entity name10';
			fp.EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity10';
			fp.EQT_Fund__c = fund1.Id;
			insert fp;

			system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
			system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund1.Id].size());
		}
	}

	@isTest static void fundPartnershiptUpdateTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        List<EQT_Investran_Commitment__c> toInsert = new List<EQT_Investran_Commitment__c>();
		for(Integer i = 1; i <= 10; i++) {
			toInsert.add(new EQT_Investran_Commitment__c
				(
					EQT_Amount_Total_Commitment__c = i * 10,
					EQT_Commitment_Investran_ID_Invester_ID__c = 'investor' + i,
					Commitment_LP_Code_Investor_Reference__c = 'lp code' + i,
					EQT_Partnership_Legal_Entity__c = 'legal entity' + i,
					EQT_Partnership_Legal_Entity_Name__c = 'legal entity name' + i,
					EQT_Vehicle_ID_Organization_ID__c = 'vehicle id' + i,
					EQT_Vehicle_Name_Investor__c = 'vehicle name' + i
				)
			);
		}

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        system.runAs(u) {
			system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
			system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			//create sample fund
			Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
			system.assertEquals(1, [SELECT Id FROM Fund__c].size());

			//get fund partnership to update
			EQT_Fund_Partnership__c fp = [SELECT Id, EQT_Fund__c FROM EQT_Fund_Partnership__c WHERE EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity10'];
			fp.EQT_Fund__c = fund.Id;
			update fp;

			system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
			system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
			system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund.Id].size());
		}
	}
}