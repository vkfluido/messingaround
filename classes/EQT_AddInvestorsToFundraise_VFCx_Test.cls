@isTest
private class EQT_AddInvestorsToFundraise_VFCx_Test {
	
	@isTest static void noSelectionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Fund__c sampleFund;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.hasNext);
			system.assertEquals(false, extension.hasPrevious);
			//perform search
			extension.search();
			//verify there are some results
			system.assertEquals(1, extension.searchResults.size());
        	//try to save
        	extension.add();
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
        Account a1;
        Fund__c sampleFund;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create another sample account
            a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account1');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.hasNext);
			system.assertEquals(false, extension.hasPrevious);
			//verify there are no opportunities
			system.assertEquals(0, [SELECT Id FROM Opportunity].size());
			//perform search
			extension.search();
			//verify there are some results
			system.assertEquals(2, extension.searchResults.size());
			//verify there are no selections
			Boolean anySelected = false;
			for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
				if(aw.selected) {
					anySelected = true;
					break;
				}
			}
			system.assertEquals(false, anySelected);
        	//select all
        	extension.allSelected = true;
        	extension.checkAll();
        	//verify all selected
        	Boolean notSelected = false;
        	for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
				if(!aw.selected) {
					notSelected = true;
					break;
				}
			}
			system.assertEquals(false, notSelected);
			//deselect second account
			extension.searchResults[1].selected = false;
        	//try to save
        	extension.add();
			system.assertEquals(1, ApexPages.getMessages().size()); //1 success
			//verify newly created opportunity
        	system.assertEquals(1, [SELECT Id FROM Opportunity WHERE EQT_Fund__c = :sampleFund.Id AND AccountId = :a.Id].size());
        }
        Test.stopTest();
	}

	@isTest static void paginationTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Fund__c sampleFund;
        
        system.runAs(u) {
        	//create set of accounts
        	EQT_TestFactory.createSetOfSampleAccounts('Account.EQT_Investor', 65);
        	system.assertEquals(65, [SELECT Id FROM Account].size());
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	
			system.assertEquals(false, extension.hasPrevious);
			//perform search
			extension.search();
			//verify there are some results
			system.assertEquals(50, extension.searchResults.size());
			//verify total size
			system.assertEquals(65, extension.totalSize);
			//verify next page exists
			system.assertEquals(true, extension.hasNext);
			//goto next page
			extension.next();
			//verify results size
			system.assertEquals(15, extension.searchResults.size());
			//verify no next page
			system.assertEquals(false, extension.hasNext);
			//verify previous page exists
			system.assertEquals(true, extension.hasPrevious);
			//go back to previous page
			extension.previous();
			//verify results size
			system.assertEquals(50, extension.searchResults.size());
			//go to last page
			extension.last();
			//verify results size
			system.assertEquals(15, extension.searchResults.size());
			//select all
			extension.allSelected = true;
			extension.checkAll();
			Integer countSelected = 0;
			for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
				if(aw.selected) {
					countSelected++;
				}
			}
			//verify all records are selected
			system.assertEquals(15, countSelected);
			//go back to first page
			extension.first();
			//verify results size
			system.assertEquals(50, extension.searchResults.size());
			//verify no records are selected
			countSelected = 0;
			for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
				if(aw.selected) {
					countSelected++;
				}
			}
			//verify all records are deselected
			system.assertEquals(0, countSelected);
		}
	}

	@isTest static void searchTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Fund__c sampleFund;
        
        system.runAs(u) {
            //create set of accounts
        	EQT_TestFactory.createSetOfSampleAccounts('Account.EQT_Investor', 10);
        	system.assertEquals(10, [SELECT Id FROM Account].size());
        	//create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            sampleFund.EQT_Fund_Strategy__c = 'Credit';
            update sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND EQT_Fund_Strategy__c = 'Credit'].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.hasNext);
			system.assertEquals(false, extension.hasPrevious);
			//perform search
			extension.search();
			//verify there are some results
			system.assertEquals(10, extension.searchResults.size());
			//add more search cryteria
			extension.accountToSearch.Name = 'sample name1';
			extension.accountToSearch.Type = 'Investor';

			for(Schema.FieldSetMember f : extension.investorPreferencesFields) {
				if(f.getType() == Schema.DisplayType.PICKLIST || f.getType() == Schema.DisplayType.STRING) {
					extension.investorPreferenceToSearch.put(f.getFieldPath(), 'test');
				}
				else if(f.getType() == Schema.DisplayType.BOOLEAN) {
					extension.investorPreferenceToSearch.put(f.getFieldPath(), true);
				}
			}

            extension.oppToSearchCommitment.EQT_Fund__c = sampleFund.Id;

			extension.fundToSearchStrategySubstrategy.EQT_Fund_Strategy__c = 'Credit';
			//search
			extension.search();
			system.assertEquals(2, extension.searchResults.size());
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
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
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

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assertEquals(false, extension.hasNext);
			system.assertEquals(false, extension.hasPrevious);
			//perform search
			extension.search();
			//verify there are some results
			system.assertEquals(1, extension.searchResults.size());
			//select account
			extension.searchResults[0].selected = true;
        	//try to save
        	extension.add();

			boolean expectedMessage = false;
			for(Apexpages.Message msg : ApexPages.getMessages()){
			    if (msg.getDetail().contains(Label.EQT_ErrorMessage_OppExistsForAccountAndFund)) {
			    	expectedMessage = true;
			    }
			}
			system.assert(expectedMessage);

        }
        Test.stopTest();
	}

	@isTest static void remoteActionTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Fund__c sampleFund;
        
        system.runAs(u) {
			//create sample fund
        	sampleFund = EQT_TestFactory.createSamplePlanningFundraisingFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
        	EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
        	system.assert(EQT_AddInvestorsToFundraise_VFCx.getOwner('test').size() > 0);
        	system.assertEquals(1, EQT_AddInvestorsToFundraise_VFCx.getFunds('sample fund').size());
        }
        Test.stopTest();
    }

    @isTest static void creationCoInvestmentTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        String oppStageName = 'Showing interest';
        Account a;
        Account a1;
        Fund__c sampleFund;
        
        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create another sample account
            a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account1');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample fund
            sampleFund = EQT_TestFactory.createSampleCoInvestmentFund('sample fund', true);
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
        }

        PageReference pageRef = Page.EQT_AddInvestorsToFundraise;
        pageRef.getParameters().put('id', sampleFund.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        system.runAs(u) {
            EQT_AddInvestorsToFundraise_VFCx extension = new EQT_AddInvestorsToFundraise_VFCx(new ApexPages.StandardController(sampleFund));
            system.assertEquals(false, extension.hasNext);
            system.assertEquals(false, extension.hasPrevious);
            //verify there are no opportunities
            system.assertEquals(0, [SELECT Id FROM Opportunity].size());
            //perform search
            extension.search();
            //verify there are some results
            system.assertEquals(2, extension.searchResults.size());
            //verify there are no selections
            Boolean anySelected = false;
            for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
                if(aw.selected) {
                    anySelected = true;
                    break;
                }
            }
            system.assertEquals(false, anySelected);
            //select all
            extension.allSelected = true;
            extension.checkAll();
            //verify all selected
            Boolean notSelected = false;
            for(EQT_AddInvestorsToFundraise_VFCx.AccountWrapper aw : extension.searchResults) {
                if(!aw.selected) {
                    notSelected = true;
                    break;
                }
            }
            system.assertEquals(false, notSelected);
            //deselect second account
            extension.searchResults[1].selected = false;
            //try to save
            extension.add();
            system.assertEquals(1, ApexPages.getMessages().size()); // 1 success
            //verify newly created opportunity
            String oppCoInvestmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName());
            List<Opportunity> opp = [SELECT Id FROM Opportunity
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND AccountId = :a.Id
                                    AND RecordTypeId = :oppCoInvestmentRecordTypeId
                                    AND StageName = :EQT_UTIL_Settings.getOpportunityCoInvestmentDefaultStage()
                                    AND Type = :EQT_UTIL_Settings.getOpportynityCoInvestmentDefaultType()
                                    AND EQT_Likelyhood_for_close__c = :EQT_UTIL_Settings.getOpportunityCoInvestmentLikelyHoodForClose()];

            system.assertEquals(1, opp.size());
        }
        Test.stopTest();
    }
}