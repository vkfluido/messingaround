/**
    About
    -----
    Description: Test class for EQT_BatchAutoGenerateTask
    Created for: EQT
    Create date: January 2017

    Details / Method
    -----------------

    Update History
    --------------
    Created January 2017 - F.A.

    Issues / TODOs
    --------------
**/
@isTest
private class EQT_BatchAutoGenerateTask_Test {

    @isTest static void successfullTest() {
        //create test user
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');

        Fund__c f = EQT_TestFactory.createSampleFund('sample fund');
        system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :f.Id].size());

        String defaultStage = 'Showing interest';

        Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opportunity', f.Id, defaultStage, true);
        system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

        //Datetime eventDate = System.now().addDays(-7);
        Datetime eventDate = DateTime.newInstance(System.today().addDays(-7), Time.newInstance(5, 0, 0, 0));

        system.debug('eventDate: ' + eventDate );
        Event event = EQT_TestFactory.createSampleEvent(opp.Id, f.Id, eventDate, false);
        event.Type = 'Meeting';
        insert event;

        Test.startTest();
            EQT_BatchAutoGenerateTask jobBatch = new EQT_BatchAutoGenerateTask();
            Database.executeBatch(jobBatch );
        Test.stopTest();

        List<Task> tasks = [SELECT Id,OwnerId, ActivityDate , WhatId , Type FROM Task];
        system.debug('tasks: ' + tasks);
        system.assertEquals(1, tasks.size());
    }
}