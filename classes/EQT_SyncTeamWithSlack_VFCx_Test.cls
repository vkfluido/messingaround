@isTest
private class EQT_SyncTeamWithSlack_VFCx_Test {
	
	@isTest static void channelNotExistTest() {
		User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
		User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
		User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser1@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u1) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            EQT_TestFactory.createFundTeamForSlackSync(sampleFund.Id, new Set<String> {u1.Id, u2.Id, u3.Id});
        }

        PageReference pageRef = Page.EQT_SyncTeamWithSlack;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        system.runAs(u1) {
        	EQT_SyncTeamWithSlack_VFCx extension = new EQT_SyncTeamWithSlack_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.currentFund.Slack_SalesforceIsMemberMaster__c);
        	system.assertEquals(false, extension.showContinueButton);
        	system.assertEquals(true, extension.showSyncButton);

        	extension.syncTeamWithSlack();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail().contains(Label.EQT_ErrorMessage_ChannelNotExists)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
			system.assertEquals(false, extension.showContinueButton);
        }
	}
	
	@isTest static void channelExistTest() {
		User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
		User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
		User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser1@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u1) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            EQT_TestFactory.createFundTeamForSlackSync(sampleFund.Id, new Set<String> {u1.Id, u2.Id, u3.Id});
        }

        PageReference pageRef = Page.EQT_SyncTeamWithSlack;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        system.runAs(u1) {
        	EQT_SyncTeamWithSlack_VFCx extension = new EQT_SyncTeamWithSlack_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.currentFund.Slack_SalesforceIsMemberMaster__c);
        	system.assertEquals(false, extension.showContinueButton);
        	system.assertEquals(true, extension.showSyncButton);
        	extension.channelId = '123';

        	extension.syncTeamWithSlack();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			String message = String.format(Label.EQT_InfoMessage_SyncTeamWithSlack, new List<String> {Label.EQT_Button_Continue});
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail() == message) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
			system.assertEquals(true, extension.showContinueButton);
        }
	}

	@isTest static void channelExceptionTest() {
		User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
		User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
		User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser1@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u1) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            EQT_TestFactory.createFundTeamForSlackSync(sampleFund.Id, new Set<String> {u1.Id, u2.Id, u3.Id});
        }

        PageReference pageRef = Page.EQT_SyncTeamWithSlack;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        system.runAs(u1) {
        	EQT_SyncTeamWithSlack_VFCx extension = new EQT_SyncTeamWithSlack_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.currentFund.Slack_SalesforceIsMemberMaster__c);
        	system.assertEquals(false, extension.showContinueButton);
        	system.assertEquals(true, extension.showSyncButton);
        	extension.channelId = 'throw sync';
        	String exceptionMessage = 'testing exception';

        	try {
        		extension.syncTeamWithSlack();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(exceptionMessage));
        	}
        	
        }
	}

	@isTest static void syncTest() {
		User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
		User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
		User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser1@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u1) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            EQT_TestFactory.createFundTeamForSlackSync(sampleFund.Id, new Set<String> {u1.Id, u2.Id, u3.Id});
        }

        PageReference pageRef = Page.EQT_SyncTeamWithSlack;
        pageRef.getParameters().put('id', sampleFund.Id);
        pageRef.getParameters().put('shoulddelete', 'true');
        Test.setCurrentPage(pageRef);

        system.runAs(u1) {
        	EQT_SyncTeamWithSlack_VFCx extension = new EQT_SyncTeamWithSlack_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.currentFund.Slack_SalesforceIsMemberMaster__c);
        	system.assertEquals(false, extension.showContinueButton);
        	system.assertEquals(true, extension.showSyncButton);
        	extension.channelId = '123';

        	extension.syncTeamWithSlack();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			String message = String.format(Label.EQT_InfoMessage_SyncTeamWithSlack, new List<String> {Label.EQT_Button_Continue});
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail() == message) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
			system.assertEquals(true, extension.showContinueButton);

			//sync
			extension.addUsersToChannel();

			system.assertEquals(1, [SELECT Id FROM Fund__c
									WHERE Slack_connected__c = true
									AND Slack_Sync_Errors__c = null
									AND Slack_Channel_Id__c = :extension.channelId].size());
        }
	}

	@isTest static void syncExceptionTest() {
		User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
		User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
		User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser1@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u1) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            EQT_TestFactory.createFundTeamForSlackSync(sampleFund.Id, new Set<String> {u1.Id, u2.Id, u3.Id});
        }

        PageReference pageRef = Page.EQT_SyncTeamWithSlack;
        pageRef.getParameters().put('id', sampleFund.Id);
        pageRef.getParameters().put('shoulddelete', 'true');
        Test.setCurrentPage(pageRef);

        system.runAs(u1) {
        	EQT_SyncTeamWithSlack_VFCx extension = new EQT_SyncTeamWithSlack_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.currentFund.Slack_SalesforceIsMemberMaster__c);
        	system.assertEquals(false, extension.showContinueButton);
        	system.assertEquals(true, extension.showSyncButton);
        	extension.channelId = 'throw';

        	extension.syncTeamWithSlack();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			String message = String.format(Label.EQT_InfoMessage_SyncTeamWithSlack, new List<String> {Label.EQT_Button_Continue});
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail() == message) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
			system.assertEquals(true, extension.showContinueButton);
			String exceptionMessage = 'testing exception';

			try {
				//sync
				extension.addUsersToChannel();
			}
			catch(Exception e) {
				system.assert(e.getMessage() == exceptionMessage);
			}

			system.assertEquals(1, [SELECT Id FROM Fund__c
									WHERE Slack_connected__c = false
									AND Slack_Sync_Errors__c = :exceptionMessage
									AND Slack_Channel_Id__c = :extension.channelId].size());
        }
	}
	
}