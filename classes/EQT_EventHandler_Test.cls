@isTest
private class EQT_EventHandler_Test {
	
	@isTest static void setOwnerByEPMTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
                system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

                User responsibleUser1 = EQT_TestFactory.createUser('responsibleUser1@example.eqt', 'EQT Investor Relations');
                responsibleUser1.EQT_EPM_User_ID__c = '11111';

                User responsibleUser2 = EQT_TestFactory.createUser('responsibleUser2@example.eqt', 'EQT Investor Relations');
                responsibleUser2.EQT_EPM_User_ID__c = '22222';

                User irDefaultUser = EQT_TestFactory.createUser('irDefaultUser@example.eqt', 'EQT Investor Relations');
                irDefaultUser.IR_default_user__c = true;

                update new List<User> {responsibleUser1, responsibleUser2, irDefaultUser};

                System.debug(LoggingLevel.INFO, '@@ responsibleUser1 '+responsibleUser1);
                System.debug(LoggingLevel.INFO, '@@ responsibleUser2 '+responsibleUser2);
                System.debug(LoggingLevel.INFO, '@@ irDefaultUser '+irDefaultUser);

                Opportunity opp;
                Fund__c fund;
                Event e;

                system.runAs(u) {
                	fund = EQT_TestFactory.createSampleFund('sample fund');
                	system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

                	String defaultStage = 'Showing interest';

                	opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, defaultStage, true);
                	system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

                	//create sample event for opportunity
                	e = new Event();
                	e.EQT_EPM_Activity_Owner_UserId__c = '11111';
                	e.WhatId = opp.Id;
                	e.DurationInMinutes = 15;
                	e.ActivityDateTime = Datetime.now();
                	insert e;

                	system.assertEquals(responsibleUser1.Id, [SELECT OwnerId FROM Event WHERE Id = :e.Id].OwnerId);
                }

                system.runAs(u) {
                	e.EQT_EPM_Activity_Owner_UserId__c = '22222';
                	update e;

                	system.assertEquals(responsibleUser2.Id, [SELECT OwnerId FROM Event WHERE Id = :e.Id].OwnerId);
                }

                system.runAs(u) {
                	e.EQT_EPM_Activity_Owner_UserId__c = '12344789';
                	update e;

                    e = [SELECT Id, OwnerId FROM Event WHERE Id = :e.Id];
                	system.assertEquals(true, [SELECT IR_default_user__c FROM User WHERE Id = :e.OwnerId].IR_default_user__c);
                }
	}
	

    @isTest static void setRecordIDByNamefromEPM() {
            User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
            system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
            system.runAs(u) {
                    Event e;
                    Fund__c fund;
                    Opportunity opp;

                    fund = EQT_TestFactory.createSampleFund('sample fund');
                    system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

                    String defaultStage = 'Showing interest';

                    opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, defaultStage, true);
                    system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

                    //create sample event for opportunity
                    e = new Event();
                    e.EQT_EPM_Activity_Owner_UserId__c = '11111';
                    e.WhatId = opp.Id;
                    e.DurationInMinutes = 15;
                    e.ActivityDateTime = Datetime.now();
                    e.EQT_EPM_Record_Type_Name__c = 'EQT_Meeting_Fundraising';
                    insert e;

                    system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Event.EQT_Meeting_Fundraising'), [SELECT Id, RecordTypeId FROM Event WHERE Id = :e.Id].RecordTypeId);

                    //Update sample with other record type name and check the record type is set
                    e.EQT_EPM_Record_Type_Name__c = 'General_Meeting';
                    update e;
                    system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Event.General_Meeting'), [SELECT Id, RecordTypeId FROM Event WHERE Id = :e.Id].RecordTypeId);
            }
    }

    @isTest static void setWhoWhatIdTest() {
    	User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable contact trigger
        EQT_TestFactory.disableContactTrigger();

        system.runAs(u) {
        	Event e;
            Fund__c fund;
            Opportunity opp;
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account', false);
            a.EQT_EPM_CounterpartID__c = '123';
            insert a;
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id AND EQT_EPM_CounterpartID__c = '123'].size());
            
            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id, false);
            c.EQT_EPM_PersonID__c = '567';
            insert c;
           	system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_EPM_PersonID__c = '567'].size());
            
            String defaultStage = 'Showing interest';

            fund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());            

            opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, defaultStage, true);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

           	//create sample event
            e = new Event();
            e.DurationInMinutes = 15;
            e.ActivityDateTime = Datetime.now();
            e.EQT_EPM_PersonID__c = '567';
            e.EQT_EPM_CounterpartID__c = '123';
            insert e;

            Event result = [SELECT Id, WhatId, WhoId, RecordTypeId FROM Event WHERE Id = :e.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Event.EQT_Meeting_Fundraising'), result.RecordTypeId);
            system.assertEquals(a.Id, result.WhatId);
            system.assertEquals(c.Id, result.WhoId);
        }
    }

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
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFund('sample fund2', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            EQT_TestFactory.disableEventTrigger();
            //create events
            Event e1 = EQT_TestFactory.createSampleEvent(opp.Id, sampleFund.Id, Datetime.now().addDays(-1), false);
            Event e2 = EQT_TestFactory.createSampleEvent(opp.Id, sampleFund2.Id, Datetime.now().addDays(-2), false);
            insert new List<Event> {e1, e2};
            system.assertEquals(2, [SELECT Id FROM Event WHERE WhatId = :opp.Id].size());
            //verify that EQT_First_Interaction_Date__c is not set
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            EQT_TestFactory.enableEventTrigger();
            Event e3 = EQT_TestFactory.createSampleEvent(opp.Id, sampleFund2.Id, Datetime.now().addDays(-3), true);
            //verify that EQT_First_Interaction_Date__c is set
            system.assertEquals(Datetime.now().addDays(-3).date(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
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

        Event e;
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

            //create sample event
            e = new Event();
            e.DurationInMinutes = 15;
            e.ActivityDateTime = Datetime.now();
            e.EQT_EPM_PersonID__c = '567';
            e.Subject = 'test';
            e.WhatId = opp.id;
            insert e;

            Event result = [SELECT Id, WhatId, EQT_Opportunity_Owner__c FROM Event WHERE Id = :e.Id];
            system.assertEquals(userList.get(0).Name, result.EQT_Opportunity_Owner__c);
            system.debug('result: ' + result);

        }

        system.debug('funds user2: ' + [SELECT ID, name from fund__c]);
        opp2 = EQT_TestFactory.createSampleOpportunity('test opportunity 2', fund.Id, 'Showing interest', true);
        system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp2.Id].size());

        e.WhatId = opp2.Id;
        update e;

        Event result = [SELECT Id, WhatId, EQT_Opportunity_Owner__c FROM Event WHERE Id = :e.Id];
        system.assertEquals(UserInfo.getName(), result.EQT_Opportunity_Owner__c);

    }
}