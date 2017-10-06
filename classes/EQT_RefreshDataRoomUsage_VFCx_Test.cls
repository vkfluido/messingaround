@isTest
private class EQT_RefreshDataRoomUsage_VFCx_Test {
	
	@isTest static void loadBatchNoConfigTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        Fund__c sampleFund;

        system.runAs(u) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund', false);
            sampleFund.Status__c = 'Planning';
            sampleFund.Update_Dataroom_analytics__c = false;
        	sampleFund.Dataroom_Update_Request__c = null;
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning'].size());
        }

        PageReference pageRef = Page.EQT_RefreshDataRoomUsage;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_RefreshDataRoomUsage_VFCx ext = new EQT_RefreshDataRoomUsage_VFCx(new ApexPages.StandardController(sampleFund));
        	//verify no batch is runnnig
        	//check if batch is not running or is about to run
        	system.assertEquals(0, [SELECT Id FROM AsyncApexJob
									WHERE JobType = 'BatchApex'
									AND ApexClass.Name = 'EQT_BatchRefreshDataRoomUsage'
									AND Status IN ('Queued', 'Preparing', 'Processing')].size());
        	//verify there are no logs
        	system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());
        	String fundStatuses = EQT_UTIL_Settings.getFundStatusesForDataroomRefresh();
			List<String> statusList = fundStatuses.split(';');
			system.debug('Radek statusList=' + statusList);
			List<Fund__c> t = [SELECT Id FROM Fund__c WHERE Update_Dataroom_analytics__c = true];
        	//try to run batch
        	Test.startTest();
        	ext.scheduleBatchToRefreshDataRoom();
        	Test.stopTest();

        	List<EQT_Event_Log__c> logs = [SELECT Id, EQT_Log_Detail__c FROM EQT_Event_Log__c];
        	system.assertEquals(3, logs.size());
        	system.assert(logs[0].EQT_Log_Detail__c.contains(Label.EQT_InfoMessage_NoIntralinksConfiguration));
        }
	}

	@isTest static void loadBatchTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        Fund__c sampleFund;
        Account acc;
        Contact con;
        Opportunity opp;
        //create Intralinks configuration
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Endpoint_URL__c', 'https://api.intralinks.com');
        appSettings.put('Intralinks_Client_Id__c', '123');
        appSettings.put('Intralinks_Client_Secret__c', '123');
        appSettings.put('Intralinks_Access_Token__c', 'abc');
        appSettings.put('Intralinks_Refresh_Token__c', 'def');
        appSettings.put('Intralinks_Admin_email__c', 'some@emailexampletest.p');
        update appSettings;

        system.runAs(u) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund', false);
            sampleFund.Status__c = 'Planning';
            sampleFund.Update_Dataroom_analytics__c = false;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, true);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        PageReference pageRef = Page.EQT_RefreshDataRoomUsage;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_RefreshDataRoomUsage_VFCx ext = new EQT_RefreshDataRoomUsage_VFCx(new ApexPages.StandardController(sampleFund));
        	//verify no batch is runnnig
        	//check if batch is not running or is about to run
        	system.assertEquals(0, [SELECT Id FROM AsyncApexJob
									WHERE JobType = 'BatchApex'
									AND ApexClass.Name = 'EQT_BatchRefreshDataRoomUsage'
									AND Status IN ('Queued', 'Preparing', 'Processing')].size());
        	//verify there are no logs
        	system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());
        	String fundStatuses = EQT_UTIL_Settings.getFundStatusesForDataroomRefresh();
			List<String> statusList = fundStatuses.split(';');
			system.debug('Radek statusList=' + statusList);
			List<Fund__c> t = [SELECT Id FROM Fund__c WHERE Update_Dataroom_analytics__c = true];
        	//try to run batch
        	Test.startTest();
        	ext.scheduleBatchToRefreshDataRoom();
        	Test.stopTest();

        	//List<EQT_Event_Log__c> logs = [SELECT Id, EQT_Log_Detail__c FROM EQT_Event_Log__c];
        	//system.assertEquals(1, logs.size());
        	//system.assert(logs[0].EQT_Log_Detail__c.contains(Label.EQT_InfoMessage_NoIntralinksConfiguration));
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning'].size());
        }
	}
}