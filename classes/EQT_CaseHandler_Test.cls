@isTest
private class EQT_CaseHandler_Test {
	
	@isTest static void createTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
                system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

                system.runAs(u) {
                	//check subscription list
                	system.assertEquals(0, [SELECT Id FROM EntitySubscription LIMIT 100].size());
                	Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
                	system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());

                	Contact c = EQT_TestFactory.createSampleContact('contact', 'test', a.Id, false);
                	c.Email = 'test@test.test';
                	insert c;
                	system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND Email = 'test@test.test'].size());
                        String deadlineDate = '2018-10-01';

                	Case slackTestCase = EQT_TestFactory.createSampleSlackCase('test subject', 'test desc', deadlineDate, null, 'test@test.test');
                	system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :slackTestCase.Id].size());
                	system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :slackTestCase.Id AND ContactId = :c.Id].size());
                        Date d = Date.valueOf(deadlineDate);
                        system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :slackTestCase.Id AND ContactId = :c.Id AND Deadline__c = :d].size());
                }
	}

        @isTest static void opportunityFundSetTest() {
                User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
                system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

                system.runAs(u) {
                        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
                        system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());

                        Contact c = EQT_TestFactory.createSampleContact('contact', 'test', a.Id, false);
                        c.Email = 'test@test.test';
                        insert c;
                        system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND Email = 'test@test.test'].size());

                        Fund__c fund = EQT_TestFactory.createSampleFund('test fund');
                        system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

                        String oppStageName = 'Showing interest';

                        Opportunity opp = EQT_TestFactory.createSampleFundraiseOpportunity('sample opp', fund.Id, oppStageName);
                        system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

                        Case slackTestCase = EQT_TestFactory.createSampleSlackCase('test subject', 'test desc', 'asd', opp.Id, 'test@test.test');
                        system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :slackTestCase.Id AND ContactId = :c.Id AND Opportunity__c = :opp.Id AND Fund__c = :fund.Id].size());
                }
        }	
}