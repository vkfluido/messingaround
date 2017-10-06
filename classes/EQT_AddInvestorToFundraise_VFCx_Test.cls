@isTest
private class EQT_AddInvestorToFundraise_VFCx_Test {
	
	@isTest static void noSelectionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample contact
            Contact c = EQT_TestFactory.createSampleContact('firstName', 'lastName', a.Id);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE AccountId = :a.Id AND LastName = :'lastName'].size());
            //verify relation roles
            List<AccountContactRelation> role = [SELECT Id, IsDirect
            									FROM AccountContactRelation
            									WHERE ContactId = :c.Id
            									AND AccountId = :a.Id
            									AND isActive = true];
            system.assertEquals(1, role.size());
        }


        PageReference pageRef = Page.EQT_AddInvestorToFundraise;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToFundraise_VFCx extension = new EQT_AddInvestorToFundraise_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(1, extension.fundList.size());
        	system.assertEquals(1, extension.keyContactList.size());
        	//try to save
        	extension.addInvestor();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail().contains(Label.EQT_ErrorMessage_NoRecordSelected)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
        }
        Test.stopTest();
	}

	@isTest static void creationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Fund__c sampleFund;
        Contact c;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample contact
            c = EQT_TestFactory.createSampleContact('firstName', 'lastName', a.Id);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE AccountId = :a.Id AND LastName = :'lastName'].size());
            //verify relation roles
            List<AccountContactRelation> role = [SELECT Id, IsDirect
            									FROM AccountContactRelation
            									WHERE ContactId = :c.Id
            									AND AccountId = :a.Id
            									AND isActive = true];
            system.assertEquals(1, role.size());
        }


        PageReference pageRef = Page.EQT_AddInvestorToFundraise;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToFundraise_VFCx extension = new EQT_AddInvestorToFundraise_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(1, extension.fundList.size());
        	system.assertEquals(1, extension.keyContactList.size());
        	//select fund
        	extension.fundList[0].selected = true;
        	//add investor
        	extension.addInvestor();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(0, messages.size());
        	//verify newly created opportunity
        	system.assertEquals(1, [SELECT Id FROM Opportunity WHERE EQT_Fund__c = :sampleFund.Id].size());
        	List<Opportunity> newOpp = [SELECT Id FROM Opportunity
        								WHERE AccountId = :a.Id
										AND StageName = :EQT_UTIL_Settings.getOpportunityFundraisingRequestDefaultStage()
										AND CloseDate = :sampleFund.EQT_Final_Close_Date__c
										AND OwnerId = :a.OwnerId
										AND EQT_Fund__c = :sampleFund.Id
										AND RecordTypeId = :EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName())];

			system.assertEquals(1, newOpp.size());
			//verify Opportunity contact role creation
			system.assertEquals(1, [SELECT Id FROM OpportunityContactRole WHERE ContactId = :extension.keyContactList[0].contactId AND OpportunityId = :newOpp[0].Id].size());
        }
        Test.stopTest();
	}

    @isTest static void creationDuplicateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Fund__c sampleFund;
        Contact c;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample contact
            c = EQT_TestFactory.createSampleContact('firstName', 'lastName', a.Id);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE AccountId = :a.Id AND LastName = :'lastName'].size());
            //verify relation roles
            List<AccountContactRelation> role = [SELECT Id, IsDirect
                                                FROM AccountContactRelation
                                                WHERE ContactId = :c.Id
                                                AND AccountId = :a.Id
                                                AND isActive = true];
            system.assertEquals(1, role.size());
            //create opp for this investor and fund
            String fundrasingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

            Opportunity opp = new Opportunity(
                Name = 'sample name',
                AccountId = a.Id,
                StageName = EQT_UTIL_Settings.getOpportunityFundraisingRequestDefaultStage(),
                CloseDate = Date.today(),
                EQT_Fund__c = sampleFund.Id,
                RecordTypeId = fundrasingRecordTypeId
            );

            insert opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }


        PageReference pageRef = Page.EQT_AddInvestorToFundraise;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
            EQT_AddInvestorToFundraise_VFCx extension = new EQT_AddInvestorToFundraise_VFCx(new ApexPages.StandardController(a));
            system.assertEquals(1, extension.fundList.size());
            system.assertEquals(1, extension.keyContactList.size());
            //select fund
            extension.fundList[0].selected = true;
            //add investor
            extension.addInvestor();
            List<Apexpages.Message> messages = ApexPages.getMessages();
            boolean expectedMessage = false;
            for(Apexpages.Message msg : messages){
                if (msg.getDetail().contains(Label.EQT_ErrorMessage_OppExistsForAccountAndFund)) {
                    expectedMessage = true;
                }
            }
            system.assert(expectedMessage);
            
        }
        Test.stopTest();
    }

    @isTest static void creationCoInvestmentTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Fund__c sampleFund;
        Contact c;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSampleCoInvestmentFund('sample fund', true);
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create sample contact
            c = EQT_TestFactory.createSampleContact('firstName', 'lastName', a.Id);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE AccountId = :a.Id AND LastName = :'lastName'].size());
            //verify relation roles
            List<AccountContactRelation> role = [SELECT Id, IsDirect
                                                FROM AccountContactRelation
                                                WHERE ContactId = :c.Id
                                                AND AccountId = :a.Id
                                                AND isActive = true];
            system.assertEquals(1, role.size());
        }


        PageReference pageRef = Page.EQT_AddInvestorToFundraise;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
            EQT_AddInvestorToFundraise_VFCx extension = new EQT_AddInvestorToFundraise_VFCx(new ApexPages.StandardController(a));
            system.assertEquals(1, extension.fundList.size());
            system.assertEquals(1, extension.keyContactList.size());
            //select fund
            extension.fundList[0].selected = true;
            //add investor
            extension.addInvestor();
            List<Apexpages.Message> messages = ApexPages.getMessages();
            system.assertEquals(0, messages.size());
            //verify newly created opportunity
            String oppCoInvestmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName());
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE EQT_Fund__c = :sampleFund.Id].size());
            List<Opportunity> newOpp = [SELECT Id FROM Opportunity
                                        WHERE EQT_Fund__c = :sampleFund.Id
                                        AND AccountId = :a.Id
                                        AND RecordTypeId = :oppCoInvestmentRecordTypeId
                                        AND StageName = :EQT_UTIL_Settings.getOpportunityCoInvestmentDefaultStage()
                                        AND Type = :EQT_UTIL_Settings.getOpportynityCoInvestmentDefaultType()
                                        AND EQT_Likelyhood_for_close__c = :EQT_UTIL_Settings.getOpportunityCoInvestmentLikelyHoodForClose()];

            system.assertEquals(1, newOpp.size());
            //verify Opportunity contact role creation
            system.assertEquals(1, [SELECT Id FROM OpportunityContactRole WHERE ContactId = :extension.keyContactList[0].contactId AND OpportunityId = :newOpp[0].Id].size());
        }
        Test.stopTest();
    }
}