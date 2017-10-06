@isTest
private class EQT_IntralinksLogin_VFC_Test {
	
	@isTest static void noAuthorizationCodeTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create Intralinks configuration
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Endpoint_URL__c', 'https://api.intralinks.com');
        appSettings.put('Intralinks_Client_Id__c', '123');
        appSettings.put('Intralinks_Client_Secret__c', '123');
        appSettings.put('Intralinks_Access_Token__c', 'abc');
        appSettings.put('Intralinks_Refresh_Token__c', 'def');
        appSettings.put('Intralinks_Admin_email__c', 'some@emailexampletest.p');
        appSettings.put('Log_Intralinks_Callout__c', false);
        update appSettings;

        PageReference pageRef = Page.EQT_IntralinksLogin;
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_IntralinksLogin_VFC controller = new EQT_IntralinksLogin_VFC();
        	system.assertEquals('abc', controller.accessToken);
        	system.assertEquals('def', controller.refreshToken);
        	system.assertEquals('https://api.intralinks.com', controller.endpointURL);
        	system.assertEquals('123', controller.clientId);
        	controller.cancel();
        }
	}

	@isTest static void authorizationCodeErrorTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create Intralinks configuration
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Endpoint_URL__c', 'https://api.intralinks.com');
        appSettings.put('Intralinks_Client_Id__c', '123');
        appSettings.put('Intralinks_Client_Secret__c', '123');
        appSettings.put('Intralinks_Access_Token__c', 'abc');
        appSettings.put('Intralinks_Refresh_Token__c', 'def');
        appSettings.put('Intralinks_Admin_email__c', 'some@emailexampletest.p');
        appSettings.put('Log_Intralinks_Callout__c', false);
        update appSettings;

        PageReference pageRef = Page.EQT_IntralinksLogin;
        pageRef.getParameters().put('code', '1111');
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_IntralinksLogin_VFC controller = new EQT_IntralinksLogin_VFC();
        	system.assertEquals('abc', controller.accessToken);
        	system.assertEquals('def', controller.refreshToken);
        	system.assertEquals('https://api.intralinks.com', controller.endpointURL);
        	system.assertEquals('123', controller.clientId);
        	controller.getAndStoreTokens();

        	List<Apexpages.Message> msgs = ApexPages.getMessages();
			boolean expectedMessage = false;
			for(Apexpages.Message msg:msgs) {
			    if(msg.getDetail().contains('test error message')) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
        }
	}

	@isTest static void authorizationCodeTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create Intralinks configuration
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Endpoint_URL__c', 'https://api.intralinks.com');
        appSettings.put('Intralinks_Client_Id__c', '123');
        appSettings.put('Intralinks_Client_Secret__c', '123');
        appSettings.put('Intralinks_Access_Token__c', 'abc');
        appSettings.put('Intralinks_Refresh_Token__c', 'def');
        appSettings.put('Intralinks_Admin_email__c', 'some@emailexampletest.p');
        appSettings.put('Log_Intralinks_Callout__c', false);
        update appSettings;

        PageReference pageRef = Page.EQT_IntralinksLogin;
        pageRef.getParameters().put('code', '1111');
        Test.setCurrentPage(pageRef);

        system.runAs(u) {
        	EQT_IntralinksLogin_VFC controller = new EQT_IntralinksLogin_VFC();
        	system.assertEquals('abc', controller.accessToken);
        	system.assertEquals('def', controller.refreshToken);
        	system.assertEquals('https://api.intralinks.com', controller.endpointURL);
        	system.assertEquals('123', controller.clientId);
        	//simulate success get tokens method
        	controller.testAuthenticationStatus = true;
        	controller.getAndStoreTokens();

        	List<Apexpages.Message> msgs = ApexPages.getMessages();
			boolean expectedMessage = false;
			for(Apexpages.Message msg:msgs) {
			    if(msg.getDetail().contains(Label.EQT_InfoMessage_TokensGeneratedSuccessfully)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);

			system.assertEquals('123', controller.accessToken);
			system.assertEquals('321', controller.refreshToken);
			system.assertEquals(controller.accessToken, EQT_UTIL_Settings.getIntralinksAccessToken());
			system.assertEquals(controller.refreshToken, EQT_UTIL_Settings.getIntralinksRefreshToken());
        }
	}
}