@isTest
private class EQT_TaskHandler_Test {
	
	@isTest static void firstInteractionDateTaskTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample task for this opportunity
            Task t = EQT_TestFactory.createSampleTask(opp.Id, Date.today(), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void firstInteractionDateEventTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample event for this opportunity
            Event e = EQT_TestFactory.createSampleEvent(opp.Id, sampleFund.Id, Datetime.now(), true);
            system.assertEquals(1, [SELECT Id FROM Event WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void firstInteractionDateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample task for this opportunity
            Task t = EQT_TestFactory.createSampleTask(opp.Id, Date.today().addDays(-2), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today().addDays(-2), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create event and verify that EQT_First_Interaction_Date__c is not changed
            Event e = EQT_TestFactory.createSampleEvent(opp.Id, sampleFund.Id, Datetime.now(), true);
            system.assertEquals(1, [SELECT Id FROM Event WHERE WhatId = :opp.Id].size());
            system.assertEquals(Date.today().addDays(-2), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void firstInteractionDateFewTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund1', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            EQT_TestFactory.disableTaskTrigger();
            //create tasks
            Task t1 = EQT_TestFactory.createSampleTask(opp.Id, Date.today().addDays(-1), false);
            Task t2 = EQT_TestFactory.createSampleTask(opp.Id, Date.today().addDays(-2), false);
            insert new List<Task> {t1, t2};
            system.assertEquals(2, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify that EQT_First_Interaction_Date__c is not set
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            EQT_TestFactory.enableTaskTrigger();
            Task t3 = EQT_TestFactory.createSampleTask(opp.Id, Date.today().addDays(-3), true);
            //verify that EQT_First_Interaction_Date__c is set
            system.assertEquals(t3.ActivityDate, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void updateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample task for this opportunity
            Task t = EQT_TestFactory.createSampleTask(opp.Id, Date.today(), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            t.ActivityDate = Date.today().addDays(1);
            update t;
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void deleteTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample task for this opportunity
            Task t = EQT_TestFactory.createSampleTask(opp.Id, Date.today(), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //delete task
            delete t;
            system.assertEquals(0, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest
    static void opportunityOwnerName() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        List<User> userList = [SELECT Id, Name FROM User WHERE UserName = 'testuser@example.eqt'];
        system.assertEquals(1, userList.size());
        //disable account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable contact trigger
        EQT_TestFactory.disableContactTrigger();

        Task t;
        Fund__c fund;
        Opportunity opp;
        Opportunity opp2;

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account', false);
            a.EQT_EPM_CounterpartID__c = '123';
            insert a;
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id AND EQT_EPM_CounterpartID__c = '123'].size());

            fund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

            opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, 'Showing interest', true);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

            t = EQT_TestFactory.createSampleTask(opp.Id, Date.today(), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());

            Task result = [SELECT Id, WhatId, EQT_Opportunity_Owner__c FROM Task WHERE Id = :t.Id];
            system.assertEquals(userList.get(0).Name, result.EQT_Opportunity_Owner__c);
            system.debug('result: ' + result);
        }

        opp2 = EQT_TestFactory.createSampleOpportunity('test opportunity 2', fund.Id, 'Showing interest', true);
        system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp2.Id].size());

        t.WhatId = opp2.Id;
        update t;

        Task result = [SELECT Id, WhatId, EQT_Opportunity_Owner__c FROM Task WHERE Id = :t.Id];
        system.assertEquals(UserInfo.getName(), result.EQT_Opportunity_Owner__c);
        system.debug('result: ' + result);

    }
}