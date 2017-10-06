@isTest
private class EQT_AddInvestorToCampaign_VFCx_Test {
	
	@isTest static void noSelectionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        String campaignRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.' + EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());

        Account a;
        Campaign c;

        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //create sample campaign
            c = EQT_TestFactory.createSampleCampaign('testCampaign', campaignRecordTypeId, true);
            system.assertEquals(1, [SELECT Id FROM Campaign WHERE Id = :c.Id].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorToCampaign;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToCampaign_VFCx extension = new EQT_AddInvestorToCampaign_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(1, extension.getCampaigns().size());
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
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        String campaignRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.' + EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());

        Account a;
        Campaign c;

        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //create sample campaign
            c = EQT_TestFactory.createSampleCampaign('testCampaign', campaignRecordTypeId, true);
            system.assertEquals(1, [SELECT Id FROM Campaign WHERE Id = :c.Id].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorToCampaign;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToCampaign_VFCx extension = new EQT_AddInvestorToCampaign_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(1, extension.getCampaigns().size());
        	//verify there are not account campaign members
        	system.assertEquals(0, [SELECT Id FROM EQT_Campaign_Account_Member__c WHERE EQT_Account__c = :a.Id AND EQT_Campaign__c = :c.Id].size());
        	//select campaign
        	extension.campaignList[0].selected = true;
        	//try to save
        	extension.addInvestor();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(0, messages.size());
			//verify memeber was added to account campaign members
        	system.assertEquals(1, [SELECT Id FROM EQT_Campaign_Account_Member__c WHERE EQT_Account__c = :a.Id AND EQT_Campaign__c = :c.Id].size());			
        }
        Test.stopTest();
	}

	@isTest static void paginationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        String campaignRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.' + EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());

        Account a;
        Campaign c;

        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //create sample campaigns
            List<Campaign> campaignList = new List<Campaign>();
            for(Integer i=1; i<=15; i++) {
            	campaignList.add(EQT_TestFactory.createSampleCampaign('testCampaign' + i, campaignRecordTypeId, false));
            }
            insert campaignList;
            system.assertEquals(15, [SELECT Id FROM Campaign WHERE RecordTypeId = :campaignRecordTypeId].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorToCampaign;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToCampaign_VFCx extension = new EQT_AddInvestorToCampaign_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(10, extension.getCampaigns().size());
        	//verify there are some results
			system.assertEquals(10, extension.campaignList.size());
			//verify total size
			system.assertEquals(15, extension.totalSize);
			//verify next page exists
			system.assertEquals(true, extension.hasNext);
			//goto next page
			extension.next();
			//verify results size
			system.assertEquals(5, extension.getCampaigns().size());
			system.assertEquals(5, extension.campaignList.size());
			//verify no next page
			system.assertEquals(false, extension.hasNext);
			//verify previous page exists
			system.assertEquals(true, extension.hasPrevious);
			//go back to previous page
			extension.previous();
			//verify results size
			system.assertEquals(10, extension.getCampaigns().size());
			system.assertEquals(10, extension.campaignList.size());
			//go to last page
			extension.last();
			//verify results size
			system.assertEquals(5, extension.getCampaigns().size());
			system.assertEquals(5, extension.campaignList.size());
			//go back to first page
			extension.first();
			//verify results size
			system.assertEquals(10, extension.getCampaigns().size());
			system.assertEquals(10, extension.campaignList.size());
        }
        Test.stopTest();
	}

	@isTest static void duplicationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        String campaignRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.' + EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());

        Account a;
        Campaign c;

        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //create sample campaign
            c = EQT_TestFactory.createSampleCampaign('testCampaign', campaignRecordTypeId, true);
            system.assertEquals(1, [SELECT Id FROM Campaign WHERE Id = :c.Id].size());
            //create account campaign members
            EQT_Campaign_Account_Member__c campaignMember = new EQT_Campaign_Account_Member__c();
            campaignMember.EQT_Account__c = a.Id;
            campaignMember.EQT_Campaign__c = c.Id;
            insert campaignMember;
            system.assertEquals(1, [SELECT Id FROM EQT_Campaign_Account_Member__c WHERE EQT_Account__c = :a.Id AND EQT_Campaign__c = :c.Id].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorToCampaign;
        pageRef.getParameters().put('id', a.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorToCampaign_VFCx extension = new EQT_AddInvestorToCampaign_VFCx(new ApexPages.StandardController(a));
        	system.assertEquals(1, extension.getCampaigns().size());
        	//select campaign
        	extension.campaignList[0].selected = true;
        	//try to save
        	extension.addInvestor();
        	List<Apexpages.Message> messages = ApexPages.getMessages();
			system.assertEquals(1, messages.size());
			
			boolean expectedMessage = false;
			for(Apexpages.Message msg : ApexPages.getMessages()){
			    if (msg.getDetail().contains(Label.EQT_ErrorMessage_InvestorAlreadyAddedToCampaign)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);
        }
        Test.stopTest();
	}	
}