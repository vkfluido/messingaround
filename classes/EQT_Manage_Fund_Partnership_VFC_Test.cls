@isTest
private class EQT_Manage_Fund_Partnership_VFC_Test {
	
	@isTest static void noPaginationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create sample fund partnership records
        EQT_TestFactory.createSampleFundPartnerships(20);
        system.assertEquals(20, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        PageReference pageRef = Page.EQT_Manage_Fund_Partnerships;
        Test.setCurrentPage(pageRef);

		system.runAs(u) {
			EQT_Manage_Fund_Partnership_VFC controller = new EQT_Manage_Fund_Partnership_VFC();
			system.assertEquals(20, controller.fundPartnershipList.size());
			system.assertEquals(false, controller.hasNext);
			system.assertEquals(false, controller.hasPrevious);
			system.assertEquals(20, controller.totalSize);

			//check filter
			controller.showNotMapped = false;
			controller.filter();
			system.assertEquals(0, controller.fundPartnershipList.size());

			PageReference cancelAction = controller.cancel();
			system.assert(cancelAction != null);
		}
	}

	@isTest static void paginationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create sample fund partnership records
        EQT_TestFactory.createSampleFundPartnerships(75);
        system.assertEquals(75, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        PageReference pageRef = Page.EQT_Manage_Fund_Partnerships;
        Test.setCurrentPage(pageRef);

		system.runAs(u) {
			EQT_Manage_Fund_Partnership_VFC controller = new EQT_Manage_Fund_Partnership_VFC();
			system.assertEquals(50, controller.fundPartnershipList.size());
			system.assertEquals(true, controller.hasNext);
			system.assertEquals(false, controller.hasPrevious);
			system.assertEquals(75, controller.totalSize);
			//goto next page
			controller.next();
			//verify page size
			system.assertEquals(25, controller.fundPartnershipList.size());
			//verify there is no next page
			system.assertEquals(false, controller.hasNext);
			//verify previous page
			system.assertEquals(true, controller.hasPrevious);
			//goto previous page
			controller.previous();
			//verify page size
			system.assertEquals(50, controller.fundPartnershipList.size());
			//verify next page exists
			system.assertEquals(true, controller.hasNext);
			//verify previous page
			system.assertEquals(false, controller.hasPrevious);
			//goto last page
			controller.last();
			//verify page size
			system.assertEquals(25, controller.fundPartnershipList.size());
			//verify there is no next page
			system.assertEquals(false, controller.hasNext);
			//verify previous page
			system.assertEquals(true, controller.hasPrevious);
			//goto first page
			controller.first();
			//verify page size
			system.assertEquals(50, controller.fundPartnershipList.size());
			//verify next page exists
			system.assertEquals(true, controller.hasNext);
			//verify previous page
			system.assertEquals(false, controller.hasPrevious);
		}
	}

	@isTest static void noChangesTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create sample fund partnership records
        EQT_TestFactory.createSampleFundPartnerships(20);
        system.assertEquals(20, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        PageReference pageRef = Page.EQT_Manage_Fund_Partnerships;
        Test.setCurrentPage(pageRef);

		system.runAs(u) {
			EQT_Manage_Fund_Partnership_VFC controller = new EQT_Manage_Fund_Partnership_VFC();
			system.assertEquals(20, controller.fundPartnershipList.size());
			system.assertEquals(false, controller.hasNext);
			system.assertEquals(false, controller.hasPrevious);
			system.assertEquals(20, controller.totalSize);

			//try to save without changes
			controller.save();
			
			List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail().contains(Label.EQT_InfoMessage_NoChangesDetected)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);

			PageReference cancelAction = controller.cancel();
			system.assert(cancelAction != null);
		}
	}

	@isTest static void saveTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        //create sample fund partnership records
        EQT_TestFactory.createSampleFundPartnerships(20);
        system.assertEquals(20, [SELECT Id FROM EQT_Fund_Partnership__c].size());

        //get permission set id
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Investran_Import'].Id;
        //assign test user permission set to access object
        Test.startTest();
        EQT_TestFactory.assignUserToPermissionSet(u.Id, permissionSetId);
        Test.stopTest();

        PageReference pageRef = Page.EQT_Manage_Fund_Partnerships;
        Test.setCurrentPage(pageRef);

		system.runAs(u) {
			//create investor account
			Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test investor', true);
			system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
			//create sample fund
			Fund__c fund = EQT_TestFactory.createSampleFund('test fund');
			system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

			EQT_Manage_Fund_Partnership_VFC controller = new EQT_Manage_Fund_Partnership_VFC();
			system.assertEquals(20, controller.fundPartnershipList.size());
			system.assertEquals(false, controller.hasNext);
			system.assertEquals(false, controller.hasPrevious);
			system.assertEquals(20, controller.totalSize);

			controller.fundPartnershipList[0].fundPartnershipRecord.EQT_Fund__c = fund.Id;
			controller.save();
			
			List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			for(Apexpages.Message msg : messages){
			    if (msg.getDetail().contains(Label.EQT_InfoMessage_MappingSuccessfullySaved)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);

			system.assertEquals(1, [SELECT Id FROM EQT_Fund_Partnership__c WHERE EQT_Fund__c = :fund.Id].size());
		}
	}
}