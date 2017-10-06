@isTest
private class EQT_SlackCallout_Test {
	
	@isTest static void noConfigurationTest() {
        String channelName = 'test channel';
    	String responseBody = '{"ok": true, "groups": [{"id": "123", "name": "test channel"}]}';

    	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));
    	try {
    		EQT_SlackCallout.checkIfChannelExists(channelName);
    	}
    	catch(Exception e) {
    		system.assert(e.getMessage().contains('Configuration was not found.'));
    	}
	}
	
	@isTest static void groupExistsTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String channelName = 'test channel';
        	String responseBody = '{"ok": true, "groups": [{"id": "123", "name": "test channel"}]}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();
        	
        	String groupId = EQT_SlackCallout.checkIfChannelExists(channelName);
        	system.assertEquals('123', groupId);

        	Test.stopTest();
        }
	}

	@isTest static void groupNotExistTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String channelName = 'test channel 123';
        	String responseBody = '{"ok": true, "groups": [{"id": "123", "name": "test channel"}]}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();
        	
        	String groupId = EQT_SlackCallout.checkIfChannelExists(channelName);
        	system.assertEquals('', groupId);

        	Test.stopTest();
        }
	}

	@isTest static void getIntegrationUserTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true, "url": "url", "team": "team", "user": "stefan", "team_id": "xxx", "user_id": "123"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();
        	
        	String integrationUserId = EQT_SlackCallout.getIntegrationUserId();
        	system.assertEquals('123', integrationUserId);

        	Test.stopTest();
        }
	}

	@isTest static void getIntegrationUserExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": false, "error": "something wrong happend"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();
        	
        	try {
        		String integrationUserId = EQT_SlackCallout.getIntegrationUserId();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to get available users could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getIntegrationUserFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": "' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();
        	
        	try {
        		String integrationUserId = EQT_SlackCallout.getIntegrationUserId();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void inviteUserToGroupTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true, "already_in_group": false, "group": {"id": "xxx", "name": "my-test-channel"}}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	EQT_SlackCallout.inviteUserToGroup('123', 'xxx');

        	Test.stopTest();
        }
	}

	@isTest static void inviteUserToGroupExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": false, "error": "something wrong happend"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();

        	try {
        		EQT_SlackCallout.inviteUserToGroup('123', 'xxx');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to invite user to channel could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void inviteUserToGroupFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	try {
        		EQT_SlackCallout.inviteUserToGroup('123', 'xxx');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void kickUserFromGroupTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	EQT_SlackCallout.kickUserFromGroup('123', 'xxx');

        	Test.stopTest();
        }
	}

	@isTest static void kickUserFromGroupExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": false, "error": "something wrong happend"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();

        	try {
        		EQT_SlackCallout.kickUserFromGroup('123', 'xxx');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to delete user from channel could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void kickUserFromGroupFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	try {
        		EQT_SlackCallout.kickUserFromGroup('123', 'xxx');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getChannelMembersTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true, "group": {"id": "123", "name": "my-test-channel", "members": ["user1","user2"]}}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	Set<String> userList = EQT_SlackCallout.getChannelMembers('123');

        	system.assertEquals(2, userList.size());

        	Test.stopTest();
        }
	}

	@isTest static void getChannelMembersExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();

        	try {
        		Set<String> userList = EQT_SlackCallout.getChannelMembers('123');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to get channel members could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getChannelMembersFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	try {
        		Set<String> userList = EQT_SlackCallout.getChannelMembers('123');
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}        	

        	Test.stopTest();
        }
	}

	@isTest static void getAvailableUserFromSlackTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true, "members": [' +
        							'{"id": "1", "name": "test1", "deleted": false, "profile": {"email": "test1@test.com"},"is_bot": false},' +
        							'{"id": "2", "name": "test2", "deleted": false, "profile": {"email": "test2@test.com"},"is_bot": false},' +
        							'{"id": "3", "name": "test3", "deleted": true, "profile": {"email": "test3@test.com"},"is_bot": false},' +
        							'{"id": "4", "name": "test4", "deleted": false, "profile": {"email": "test4@test.com"},"is_bot": true}]}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	Map<String, String> userList = EQT_SlackCallout.getAvailableUserFromSlack();
        	//should be 2 - as we exclude deleted users and bots
        	system.assertEquals(2, userList.size());

        	Test.stopTest();
        }
	}

	@isTest static void getAvailableUserFromSlackExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();

        	try {
        		Map<String, String> userList = EQT_SlackCallout.getAvailableUserFromSlack();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to get available users could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getAvailableUserFromSlackFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	try {
        		Map<String, String> userList = EQT_SlackCallout.getAvailableUserFromSlack();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getPrivateGroupListTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String responseBody = '{"ok": true, "groups": [{"id": "1", "name": "my-test-channel-1"},{"id": "2","name": "my-test-channel-2"}]}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	Map<String, String> groupList = EQT_SlackCallout.getPrivateGroupList();
        	
        	system.assertEquals(2, groupList.size());

        	Test.stopTest();
        }
	}

	@isTest static void getPrivateGroupListExceptionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 401));

        	Test.startTest();

        	try {
        		Map<String, String> groupList = EQT_SlackCallout.getPrivateGroupList();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains('EQT_SlackCallout: Request to get private group list could not be sent from Salesforce'));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getPrivateGroupListFailTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	String errorMessage = 'something wrong happend';
        	String responseBody = '{"ok": false, "error": " ' + errorMessage + '"}';

        	Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

        	Test.startTest();

        	try {
        		Map<String, String> groupList = EQT_SlackCallout.getPrivateGroupList();
        	}
        	catch(Exception e) {
        		system.assert(e.getMessage().contains(errorMessage));
        	}

        	Test.stopTest();
        }
	}

	@isTest static void getSlackUserIdTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
        	Map<String, String> slackUserMap = new Map<String, String>();
        	slackUserMap.put('id1', 'test1@test.com');
        	slackUserMap.put('id2', 'test2@test.com');
        	slackUserMap.put('id3', 'test3@test.com');
        	slackUserMap.put('id4', 'test4@test.com');

        	String slacUserId = EQT_SlackCallout.getSlackUserId('test3@test.com', slackUserMap);

        	system.assertEquals('id3', slacUserId);
        }
	}

    @isTest static void inviteUserToChannelTest() {
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
            system.assertEquals(3, [SELECT Id FROM EQT_Team_Member_Association__c WHERE EQT_Fund__c = :sampleFund.Id].size());
            //invite
            EQT_SlackCallout.inviteUserToChannel(sampleFund.Id, '1', false);
        }
    }

    /*
    @isTest static void postMessageToSlackTest() {
        User u = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        system.runAs(u) {
            Case c = EQT_TestFactory.createSampleSlackCase('subject', 'description', '2020-01-01', null, null);
            system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :c.Id].size());

            String responseBody = '{"ok": true}';

            Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

            Test.startTest();

            EQT_SlackCallout.postMessageToSlack('test@test.test', 'test message');

            Test.stopTest();
        }
    }
    */

    @isTest static void getSlackTeamIdTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        
        system.runAs(u) {
            String responseBody = '{"ok": true, "team":{"id": "123","name": "test team"}}';

            Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

            Test.startTest();
            
            EQT_SlackTeamID_WS.SlackTeamResult result = EQT_SlackCallout.getSlackTeamId();
            system.assertEquals('123', result.teamId);
            system.assert(String.isEmpty(result.message));

            Test.stopTest();
        }
    }

    @isTest static void getSlackTeamIdErrorTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        
        system.runAs(u) {
            String responseBody = '{"ok": false, "error": "something wrong happend"}';

            Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

            Test.startTest();
            
            EQT_SlackTeamID_WS.SlackTeamResult result = EQT_SlackCallout.getSlackTeamId();
            system.assertEquals('something wrong happend', result.message);
            system.assert(String.isEmpty(result.teamId));

            Test.stopTest();
        }
    }
}