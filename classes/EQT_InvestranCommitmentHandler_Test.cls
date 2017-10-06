@isTest
private class EQT_InvestranCommitmentHandler_Test {
	
	@isTest static void fullCreationTest() {
		//set up org
		EQT_TestFactory.setUpOrg();

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
		
		//first verify there are no related records
		system.assertEquals(0, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}

	@isTest static void investorLPCodeTest() {
		//set up org
		EQT_TestFactory.setUpOrg();

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

		EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//first insert some investor LP Codes to database to verify duplications are not created
		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name first 1', EQT_Investor__c = investor1.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name first 2', EQT_Investor__c = investor2.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name first 3', EQT_Investor__c = investor3.Id));
		insert investorLPCodeToInsert;

		//check lists before insert
		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		// verify the vehicle name was changed
		EQT_Investor_LP_Code__c lpInvestor1 = [SELECT Name,EQT_Vehicle_Name__c FROM EQT_Investor_LP_Code__c WHERE Id =:investorLPCodeToInsert.get(0).Id];
		system.assertEquals(investorLPCodeToInsert.get(0).Name, lpInvestor1.Name);
		system.assertNotEquals(investorLPCodeToInsert.get(0).EQT_Vehicle_Name__c, lpInvestor1.EQT_Vehicle_Name__c);
		system.assertEquals('vehicle name1', lpInvestor1.EQT_Vehicle_Name__c);

	}

	@isTest static void fundCommitmentTest() {
		//set up org
		EQT_TestFactory.setUpOrg();

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

		EQT_TestFactory.disableAccountTrigger();
		//create sample investors
		Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor1', false);
		Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor2', false);
		Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'investor3', false);
		insert new List<Account> {investor1, investor2, investor3};

		//first insert some investor LP Codes to database to verify duplications are not created
		List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Vehicle_Name__c = 'vehicle name1', EQT_Investor__c = investor1.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Vehicle_Name__c = 'vehicle name2', EQT_Investor__c = investor2.Id));
		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Vehicle_Name__c = 'vehicle name3', EQT_Investor__c = investor3.Id));
		insert investorLPCodeToInsert;

		//create sample fund
		Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
		Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');

		//create sample fund partnership
		List<EQT_Fund_Partnership__c> fundPartnershipToInsert = new List<EQT_Fund_Partnership__c>();
		fundPartnershipToInsert.add(new EQT_Fund_Partnership__c(Partnership_Name__c = 'legal entity name1', EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity1', EQT_Fund__c = fund2.Id));
		fundPartnershipToInsert.add(new EQT_Fund_Partnership__c(Partnership_Name__c = 'legal entity name5', EQT_Investran_Partnership_Legal_EntityID__c = 'legal entity5', EQT_Fund__c = fund1.Id));
		insert fundPartnershipToInsert;

		//create fund commitment
		EQT_Fund_Commitment__c fc = new EQT_Fund_Commitment__c();
		fc.EQT_Fund__c = fund2.Id;
		fc.EQTInvestran_Partnership_Legal_Entity_ID__c = 'legal entity1';
		insert fc;

		//check lists before insert
		system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(2, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c].size());

		//insert
		insert toInsert;
		//verify
		system.assertEquals(10, [SELECT Id FROM EQT_Investor_LP_Code__c].size());
		system.assertEquals(10, [SELECT Id FROM EQT_Fund_Partnership__c].size());
		system.assertEquals(3, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	}
}