@isTest
private class EQT_FundCommitmentHandler_Test {
	
	@isTest static void insertTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        system.runAs(u) {
        	//create sample account
        	Account investor = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor', true);
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investor.Id].size());
        	
        	//create sample investor lp code
        	EQT_Investor_LP_Code__c ilpc = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Investor__c = investor.Id);
        	insert ilpc;
        	system.assertEquals(1, [SELECT Id FROM EQT_Investor_LP_Code__c WHERE Id = :ilpc.Id].size());

        	//create sample fund
        	Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

        	//fund commitment
	        EQT_Fund_Commitment__c fc = new EQT_Fund_Commitment__c();
	        fc.EQT_Amount__c = 100;
	    	fc.EQT_Fund__c = fund.Id;
	    	fc.EQT_Investran_Invester_ID__c = 'investor10';
	    	fc.EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity1';
	    	fc.EQT_LP_Code__c = 'lp code1';
	    	fc.EQT_Partnership_Name__c = 'legal entity name10';
	    	fc.EQT_Vehicle_Name__c = 'vehicle name10';
	    	fc.EQT_Vehicle_Organization_ID__c = 'vehicle id10';

	    	insert new List<EQT_Fund_Commitment__c> {fc};

	    	system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE Id = :fc.Id AND EQT_Investor__c = :investor.Id].size());
        }
	}

	@isTest static void updateTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        system.runAs(u) {
        	//create sample account
        	Account investor = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor', true);
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investor.Id].size());
        	
        	//create sample investor lp code
        	EQT_Investor_LP_Code__c ilpc = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Investor__c = investor.Id);
        	insert ilpc;
        	system.assertEquals(1, [SELECT Id FROM EQT_Investor_LP_Code__c WHERE Id = :ilpc.Id].size());

        	//create sample fund
        	Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

        	//create sample commitment
        	EQT_Commitment__c c = EQT_TestFactory.createSampleCommitment(fund.Id, investor.Id);
        	system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c.Id].size());
        	//verify amount
        	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c.Id].EQT_Amount__c);

        	//fund commitment
	        EQT_Fund_Commitment__c fc = new EQT_Fund_Commitment__c();
	        fc.EQT_Amount__c = 100;
	    	fc.EQT_Fund__c = fund.Id;
	    	fc.EQT_Investran_Invester_ID__c = 'investor10';
	    	fc.EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity1';
	    	fc.EQT_LP_Code__c = 'lp code1';
	    	fc.EQT_Partnership_Name__c = 'legal entity name10';
	    	fc.EQT_Vehicle_Name__c = 'vehicle name10';
	    	fc.EQT_Vehicle_Organization_ID__c = 'vehicle id10';

	    	insert new List<EQT_Fund_Commitment__c> {fc};

	    	system.assertEquals(1, [SELECT Id FROM EQT_Fund_Commitment__c WHERE Id = :fc.Id AND EQT_Investor__c = :investor.Id].size());
	    	//verify roll up
	    	system.assertEquals(100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c.Id].EQT_Amount__c);

	    	fc.EQT_Amount__c = 500;
	    	update fc;

	    	system.assertEquals(500, [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE Id = :fc.Id AND EQT_Investor__c = :investor.Id].EQT_Amount__c);
	    	//verify roll up
	    	system.assertEquals(500, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c.Id].EQT_Amount__c);
        }
	}

	@isTest static void updateMassDataTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

        system.runAs(u) {
        	//create sample account
        	Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor1', false);
        	Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor2', false);
        	Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor3', false);
        	insert new List<Account> {investor1, investor2, investor3};

        	system.assertEquals(3, [SELECT Id FROM Account].size());
        	
        	//create sample investor lp code
        	EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Investor__c = investor1.Id);
        	EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Investor__c = investor2.Id);
        	EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Investor__c = investor3.Id);
        	insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};
        	system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());

        	//create sample fund
        	Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund1.Id].size());
        	Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund2.Id].size());
        	Fund__c fund3 = EQT_TestFactory.createSampleFund('sample fund3');
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund3.Id].size());

        	//create sample commitment
        	EQT_Commitment__c c1 = EQT_TestFactory.createSampleCommitment(fund1.Id, investor1.Id);
        	system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c1.Id].size());

        	EQT_Commitment__c c2 = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);
        	system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c2.Id].size());

        	EQT_Commitment__c c3 = EQT_TestFactory.createSampleCommitment(fund3.Id, investor3.Id);
        	system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c3.Id].size());
        	//verify amount
        	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c1.Id].EQT_Amount__c);
        	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c2.Id].EQT_Amount__c);
        	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c3.Id].EQT_Amount__c);

        	//disable trigger
        	EQT_TestFactory.disableFundCommitmentTrigger();

        	List<EQT_Fund_Commitment__c> toInsert = new List<EQT_Fund_Commitment__c>();

        	for(Integer i=1; i<= 700; i++) {
        		EQT_Fund_Commitment__c fcInvestor1 = new EQT_Fund_Commitment__c
        		(
        			EQT_Amount__c = 100,
        			EQT_Fund__c = fund1.Id,
        			EQT_Investor__c = investor1.Id,
        			EQT_Investran_Invester_ID__c = 'investor1',
        			EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity1',
        			EQT_LP_Code__c = 'lp code1',
		    		EQT_Partnership_Name__c = 'legal entity name1',
		    		EQT_Vehicle_Name__c = 'vehicle name1' + i,
		    		EQT_Vehicle_Organization_ID__c = 'vehicle id1' + i
        		);
        		toInsert.add(fcInvestor1);

        		EQT_Fund_Commitment__c fcInvestor2 = new EQT_Fund_Commitment__c
        		(
        			EQT_Amount__c = 200,
        			EQT_Fund__c = fund2.Id,
        			EQT_Investor__c = investor2.Id,
        			EQT_Investran_Invester_ID__c = 'investor2',
        			EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity2',
        			EQT_LP_Code__c = 'lp code2',
		    		EQT_Partnership_Name__c = 'legal entity name2',
		    		EQT_Vehicle_Name__c = 'vehicle name2' + i,
		    		EQT_Vehicle_Organization_ID__c = 'vehicle id2' + i
        		);
        		toInsert.add(fcInvestor2);

        		EQT_Fund_Commitment__c fcInvestor3 = new EQT_Fund_Commitment__c
        		(
        			EQT_Amount__c = 300,
        			EQT_Fund__c = fund3.Id,
        			EQT_Investor__c = investor3.Id,
        			EQT_Investran_Invester_ID__c = 'investor3',
        			EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity3',
        			EQT_LP_Code__c = 'lp code3',
		    		EQT_Partnership_Name__c = 'legal entity name3',
		    		EQT_Vehicle_Name__c = 'vehicle name3' + i,
		    		EQT_Vehicle_Organization_ID__c = 'vehicle id3' + i
        		);
        		toInsert.add(fcInvestor3);
        	}

        	insert toInsert;
	    	system.assertEquals(2100, [SELECT Id FROM EQT_Fund_Commitment__c].size());
	    	system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund1.Id].size());
	    	system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund2.Id].size());
	    	system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund3.Id].size());
	    	//verify roll up
	    	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c1.Id].EQT_Amount__c);
	    	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c2.Id].EQT_Amount__c);
	    	system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c3.Id].EQT_Amount__c);


	    	//now update 3 func commitments
	    	EQT_Fund_Commitment__c fc1 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund1.Id LIMIT 1];
	    	fc1.EQT_Amount__c = 200;
	    	EQT_Fund_Commitment__c fc2 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund2.Id LIMIT 1];
	    	fc2.EQT_Amount__c = 300;
	    	EQT_Fund_Commitment__c fc3 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund3.Id LIMIT 1];
	    	fc3.EQT_Amount__c = 400;

	    	//enable trigger
	    	EQT_TestFactory.enableFundCommitmentTrigger();
	    	update new List<EQT_Fund_Commitment__c> {fc1, fc2, fc3};

	    	//verify rollups
	    	Test.startTest();

	    	system.assertEquals(70100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c1.Id].EQT_Amount__c);
	    	system.assertEquals(140100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c2.Id].EQT_Amount__c);
	    	system.assertEquals(210100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c3.Id].EQT_Amount__c);

	    	Test.stopTest();
        }
	}

        @isTest static void updateMassDataNoCommitmentTest() {
                User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
                       system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

                //get permission set id
                Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;

                system.runAs(u) {
                        //create sample account
                        Account investor1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor1', false);
                        Account investor2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor2', false);
                        Account investor3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor3', false);
                        insert new List<Account> {investor1, investor2, investor3};

                        system.assertEquals(3, [SELECT Id FROM Account].size());
                        
                        //create sample investor lp code
                        EQT_Investor_LP_Code__c ilpc1 = new EQT_Investor_LP_Code__c(Name = 'lp code1', EQT_Investor__c = investor1.Id);
                        EQT_Investor_LP_Code__c ilpc2 = new EQT_Investor_LP_Code__c(Name = 'lp code2', EQT_Investor__c = investor2.Id);
                        EQT_Investor_LP_Code__c ilpc3 = new EQT_Investor_LP_Code__c(Name = 'lp code3', EQT_Investor__c = investor3.Id);
                        insert new List<EQT_Investor_LP_Code__c> {ilpc1, ilpc2, ilpc3};
                        system.assertEquals(3, [SELECT Id FROM EQT_Investor_LP_Code__c].size());

                        //create sample fund
                        Fund__c fund1 = EQT_TestFactory.createSampleFund('sample fund1');
                        system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund1.Id].size());
                        Fund__c fund2 = EQT_TestFactory.createSampleFund('sample fund2');
                        system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund2.Id].size());
                        Fund__c fund3 = EQT_TestFactory.createSampleFund('sample fund3');
                        system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund3.Id].size());

                        //verify there are no commitments records
                        system.assertEquals(0, [SELECT Id FROM EQT_Commitment__c].size());

                        /*
                        //create sample commitment
                        EQT_Commitment__c c1 = EQT_TestFactory.createSampleCommitment(fund1.Id, investor1.Id);
                        system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c1.Id].size());

                        EQT_Commitment__c c2 = EQT_TestFactory.createSampleCommitment(fund2.Id, investor2.Id);
                        system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c2.Id].size());

                        EQT_Commitment__c c3 = EQT_TestFactory.createSampleCommitment(fund3.Id, investor3.Id);
                        system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c WHERE Id = :c3.Id].size());
                        //verify amount
                        system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c1.Id].EQT_Amount__c);
                        system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c2.Id].EQT_Amount__c);
                        system.assertEquals(null, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE Id = :c3.Id].EQT_Amount__c);
                        */

                        //disable trigger
                        EQT_TestFactory.disableFundCommitmentTrigger();

                        List<EQT_Fund_Commitment__c> toInsert = new List<EQT_Fund_Commitment__c>();

                        for(Integer i=1; i<= 700; i++) {
                                EQT_Fund_Commitment__c fcInvestor1 = new EQT_Fund_Commitment__c
                                (
                                        EQT_Amount__c = 100,
                                        EQT_Fund__c = fund1.Id,
                                        EQT_Investor__c = investor1.Id,
                                        EQT_Investran_Invester_ID__c = 'investor1',
                                        EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity1',
                                        EQT_LP_Code__c = 'lp code1',
                                        EQT_Partnership_Name__c = 'legal entity name1',
                                        EQT_Vehicle_Name__c = 'vehicle name1' + i,
                                        EQT_Vehicle_Organization_ID__c = 'vehicle id1' + i
                                );
                                toInsert.add(fcInvestor1);

                                EQT_Fund_Commitment__c fcInvestor2 = new EQT_Fund_Commitment__c
                                (
                                        EQT_Amount__c = 200,
                                        EQT_Fund__c = fund2.Id,
                                        EQT_Investor__c = investor2.Id,
                                        EQT_Investran_Invester_ID__c = 'investor2',
                                        EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity2',
                                        EQT_LP_Code__c = 'lp code2',
                                        EQT_Partnership_Name__c = 'legal entity name2',
                                        EQT_Vehicle_Name__c = 'vehicle name2' + i,
                                        EQT_Vehicle_Organization_ID__c = 'vehicle id2' + i
                                );
                                toInsert.add(fcInvestor2);

                                EQT_Fund_Commitment__c fcInvestor3 = new EQT_Fund_Commitment__c
                                (
                                        EQT_Amount__c = 300,
                                        EQT_Fund__c = fund3.Id,
                                        EQT_Investor__c = investor3.Id,
                                        EQT_Investran_Invester_ID__c = 'investor3',
                                        EQTInvestran_Partnership_Legal_Entity_ID__c = 'entity3',
                                        EQT_LP_Code__c = 'lp code3',
                                        EQT_Partnership_Name__c = 'legal entity name3',
                                        EQT_Vehicle_Name__c = 'vehicle name3' + i,
                                        EQT_Vehicle_Organization_ID__c = 'vehicle id3' + i
                                );
                                toInsert.add(fcInvestor3);
                        }

                        insert toInsert;
                        system.assertEquals(2100, [SELECT Id FROM EQT_Fund_Commitment__c].size());
                        system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund1.Id].size());
                        system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund2.Id].size());
                        system.assertEquals(700, [SELECT Id FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund3.Id].size());

                        //now update 3 func commitments
                        EQT_Fund_Commitment__c fc1 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund1.Id LIMIT 1];
                        fc1.EQT_Amount__c = 200;
                        EQT_Fund_Commitment__c fc2 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund2.Id LIMIT 1];
                        fc2.EQT_Amount__c = 300;
                        EQT_Fund_Commitment__c fc3 = [SELECT EQT_Amount__c FROM EQT_Fund_Commitment__c WHERE EQT_Fund__c = :fund3.Id LIMIT 1];
                        fc3.EQT_Amount__c = 400;

                        //enable trigger
                        EQT_TestFactory.enableFundCommitmentTrigger();
                        update new List<EQT_Fund_Commitment__c> {fc1, fc2, fc3};

                        //verify rollups
                        Test.startTest();

                        system.assertEquals(70100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund1.Id AND EQT_Investor__c = :investor1.Id].EQT_Amount__c);
                        system.assertEquals(140100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund2.Id AND EQT_Investor__c = :investor2.Id].EQT_Amount__c);
                        system.assertEquals(210100, [SELECT EQT_Amount__c FROM EQT_Commitment__c WHERE EQT_Fund__c = :fund3.Id AND EQT_Investor__c = :investor3.Id].EQT_Amount__c);

                        //verify commitments creteion
                        system.assertEquals(3, [SELECT Id FROM EQT_Commitment__c].size());

                        Test.stopTest();
                }
        }
}