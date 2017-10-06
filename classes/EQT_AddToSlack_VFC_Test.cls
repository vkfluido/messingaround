@isTest
private class EQT_AddToSlack_VFC_Test {
	
	@isTest static void emptyClientIdTest() {
		User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        PageReference pageRef = Page.EQT_AddToSlack;
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_AddToSlack_VFC controller = new EQT_AddToSlack_VFC();
        	system.assertEquals(false, controller.irisClientIdExists);
        	system.assert(String.isEmpty(controller.irisClientId));

        	String responseBody = '{"ok": true, "team":{"id": "123","name": "test team"}}';

	        Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

	        Test.startTest();

	        controller.addToSlack();

	        List<Apexpages.Message> msgs = ApexPages.getMessages();
	        system.assertEquals(1, msgs.size());
			boolean expectedMessage = false;
			for(Apexpages.Message msg : msgs) {
			    if(msg.getDetail().contains(Label.EQT_ErrorMessage_SlackClientIdIsMissing)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);

			Test.stopTest();
        }
	}

	@isTest static void addToSlackTest() {
		User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        PageReference pageRef = Page.EQT_AddToSlack;
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_AddToSlack_VFC controller = new EQT_AddToSlack_VFC();
        	system.assertEquals(false, controller.irisClientIdExists);
        	system.assert(String.isEmpty(controller.irisClientId));

        	controller.irisClientId = '123456789';

        	String responseBody = '{"ok": true, "team":{"id": "123","name": "test team"}}';

	        Test.setMock(HttpCalloutMock.class, new EQT_MockSlackCallout(responseBody, 200));

	        Test.startTest();

	        PageReference pr = controller.addToSlack();

	        List<Apexpages.Message> msgs = ApexPages.getMessages();
	        system.assertEquals(0, msgs.size());

	        system.assert(pr.getUrl().contains('scope=bot'));
			system.assert(pr.getUrl().contains('client_id=' + controller.irisClientId));
			system.assert(pr.getUrl().contains('team=123'));

			Test.stopTest();
        }
	}

	@isTest static void cancelTest() {
        User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        PageReference pageRef = Page.EQT_AddToSlack;
        Test.setCurrentPage(pageRef);

		system.runAs(u) {
			EQT_AddToSlack_VFC controller = new EQT_AddToSlack_VFC();
        	system.assertEquals(false, controller.irisClientIdExists);
        	system.assert(String.isEmpty(controller.irisClientId));

			PageReference cancelAction = controller.cancel();
			system.assert(cancelAction != null);
		}
	}

	@isTest static void authenticationSuccessTest() {
		User u = EQT_TestFactory.createUser('testuseradmin@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        PageReference pageRef = Page.EQT_AddToSlack;
        pageRef.getParameters().put('success', '1');
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_AddToSlack_VFC controller = new EQT_AddToSlack_VFC();
        	system.assertEquals(false, controller.irisClientIdExists);
        	system.assert(String.isEmpty(controller.irisClientId));

	        List<Apexpages.Message> msgs = ApexPages.getMessages();
	        system.assertEquals(1, msgs.size());
			boolean expectedMessage = false;
			for(Apexpages.Message msg : msgs) {
			    if(msg.getDetail().contains(Label.EQT_InfoMessage_SlackAppAuthenticationSuccess)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
        }
	}
}