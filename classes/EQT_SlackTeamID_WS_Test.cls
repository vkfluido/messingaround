@isTest
private class EQT_SlackTeamID_WS_Test {
	
	@isTest static void getSlackTeamIdTest() {
		User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        system.runAs(u) {
			String responseBody = '{"ok": true, "team":{"id": "123","name": "test team"}}';

	        Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

	        Test.startTest();

			EQT_SlackTeamID_WS.SlackTeamResult result = EQT_SlackTeamID_WS.getSlackTeamId();
			system.assertEquals('123', result.teamId);
	        system.assert(String.isEmpty(result.message));

	        Test.stopTest();
	    }
	}

	@isTest static void getSlackTeamIdExceptionTest() {
		User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        system.runAs(u) {
			String responseBody = '{"ok": true, "team":{"id": "123","name": "test team"}}';

	        Test.startTest();

			EQT_SlackTeamID_WS.SlackTeamResult result = EQT_SlackTeamID_WS.getSlackTeamId();
			system.assert(String.isEmpty(result.teamId));
	        system.assert(String.isNotEmpty(result.message));

	        Test.stopTest();
	    }
	}
}