@isTest
private class EQT_BatchRefreshDataRoomUsage_Test {
	
	@isTest static void failTokenRefreshTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
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

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        }
	}

	@isTest static void tokenRefreshTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
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

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        }
	}

	@isTest static void getWorkspaceTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
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

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(4, [SELECT Id FROM EQT_Event_Log__c].size());
        }
	}

	@isTest static void getWorkspaceUsersTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	system.assertEquals(1, [SELECT Id FROM EQT_Dataroom_Activity__c WHERE Opportunity__c = :opp.Id AND Contact__c = :con.Id AND Dataroom_Access_Given__c = true AND Intralinks_Workspace_User_ID__c = '1111'].size());
        }
	}

	@isTest static void getWorkspaceUsersUpdateTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
            //create sample dataroom record
            EQT_Dataroom_Activity__c dra = new EQT_Dataroom_Activity__c();
			dra.Opportunity__c = opp.Id;
			dra.Contact__c = con.Id;
			insert dra;
			system.assertEquals(1, [SELECT Id FROM EQT_Dataroom_Activity__c WHERE Opportunity__c = :opp.Id AND Contact__c = :con.Id AND Dataroom_Access_Given__c = false AND Intralinks_Workspace_User_ID__c = null].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	system.assertEquals(1, [SELECT Id FROM EQT_Dataroom_Activity__c WHERE Opportunity__c = :opp.Id AND Contact__c = :con.Id AND Dataroom_Access_Given__c = true AND Intralinks_Workspace_User_ID__c = '1111'].size());
        }
	}

	@isTest static void enterWorkspaceTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	b.testEnterWorkspaceStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	system.assertEquals(1, [SELECT Id FROM EQT_Dataroom_Activity__c WHERE Opportunity__c = :opp.Id AND Contact__c = :con.Id AND Dataroom_Access_Given__c = true AND Intralinks_Workspace_User_ID__c = '1111'].size());
        }
	}

	@isTest static void acceptSplashTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	b.testEnterWorkspaceStatus = true;
        	b.testAcceptSplashStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(3, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	system.assertEquals(1, [SELECT Id FROM EQT_Dataroom_Activity__c WHERE Opportunity__c = :opp.Id AND Contact__c = :con.Id AND Dataroom_Access_Given__c = true AND Intralinks_Workspace_User_ID__c = '1111'].size());
        }
	}

	@isTest static void coverageReportTest() {
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
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	b.testEnterWorkspaceStatus = true;
        	b.testAcceptSplashStatus = true;
        	b.testCoverageReportStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should not be created
        	system.assertEquals(2, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	List<EQT_Dataroom_Activity__c> dra = [SELECT Id, Date_added__c, First_Access__c, Last_Access__c
        											FROM EQT_Dataroom_Activity__c
        											WHERE Opportunity__c = :opp.Id
        											AND Contact__c = :con.Id
        											AND Dataroom_Access_Given__c = true
        											AND Intralinks_Workspace_User_ID__c = '1111'];
        	system.assertEquals(1, dra.size());
        	Datetime dt = Datetime.newInstance(2016, 1, 19);
        	system.assertEquals(dt.date(), dra[0].Date_added__c);
        	system.assertEquals(dt.date(), dra[0].First_Access__c.date());
        	system.assertEquals(dt.date(), dra[0].Last_Access__c.date());
        }
	}

	@isTest static void logTest() {
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
        appSettings.put('Log_Intralinks_Callout__c', true);
        update appSettings;

        system.runAs(u) {
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund', false);
            sampleFund.Status__c = 'Planning';
            sampleFund.Update_Dataroom_analytics__c = true;
        	sampleFund.Dataroom_Update_Request__c = null;
        	sampleFund.Dataroom_Workspace_Name__c = 'test workspace name';
            insert sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = true AND Status__c = 'Planning'].size());
            //create sample account
            acc = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :acc.Id].size());
            //create contact
            con = EQT_TestFactory.createSampleContact('contact', 'test', acc.Id, false);
            con.Email = 'r.biniek@polsource.com';
            insert con;
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :con.Id].size());
            //verify relation between account and contact
            system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id].size());
            //create sample opportunity related to fund
            opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('test opp', acc.Id, 'No Interest', sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND AccountId = :acc.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        system.runAs(u) {
        	Test.startTest();
        	EQT_BatchRefreshDataRoomUsage b = new EQT_BatchRefreshDataRoomUsage();
			//simulate success for refresh tokens
        	b.testTokenRefreshStatus = true;
        	b.testGetWorkspaceIdStatus = true;
        	b.testGetWorkspaceUsersStatus = true;
        	b.testEnterWorkspaceStatus = true;
        	b.testAcceptSplashStatus = true;
        	b.testCoverageReportStatus = true;
        	Database.executeBatch(b, 100);
        	Test.stopTest();
        	//after batch finished fund record field Update_Dataroom_analytics__c should be set to false
        	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND Update_Dataroom_analytics__c = false AND Status__c = 'Planning' AND Intralinks_Workspace_ID__c = '123456'].size());
        	//log should be created
        	system.assertEquals(9, [SELECT Id FROM EQT_Event_Log__c].size());
        	//verify dataroom record with workspace user id was created
        	List<EQT_Dataroom_Activity__c> dra = [SELECT Id, Date_added__c, First_Access__c, Last_Access__c
        											FROM EQT_Dataroom_Activity__c
        											WHERE Opportunity__c = :opp.Id
        											AND Contact__c = :con.Id
        											AND Dataroom_Access_Given__c = true
        											AND Intralinks_Workspace_User_ID__c = '1111'];
        	system.assertEquals(1, dra.size());
        	Datetime dt = Datetime.newInstance(2016, 1, 19);
        	system.assertEquals(dt.date(), dra[0].Date_added__c);
        	system.assertEquals(dt.date(), dra[0].First_Access__c.date());
        	system.assertEquals(dt.date(), dra[0].Last_Access__c.date());
        }
	}	
}