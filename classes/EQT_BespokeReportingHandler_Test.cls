@isTest
private class EQT_BespokeReportingHandler_Test {

    @testSetup static void setup() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
       
        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');
            
            Account aResult = [select Id, OwnerId, EQT_EPM_Responsible__c from Account where Id=:a.Id];
            //system.assertEquals(responsibleUser1.Id, aResult.OwnerId);  

            Bespoke_Reporting__c br = new Bespoke_Reporting__c(
            	Account__c = a.Id,
            	Last_Case_Created__c = null,
            	Days_before_Deadline__c = 0, 
            	Name = 'Subject',
            	Description__c = 'Description', 
            	Recurrence__c = '12', 
            	Start_Date__c = date.today().addMonths(-12)
            );
            insert br;
        }
    }

    @isTest static void createCase() {

        Test.startTest();
            EQT_ScheduleBespokeReporting sj = new EQT_ScheduleBespokeReporting();
            Id batchprocessid = Database.executeBatch(sj, 20);
        Test.stopTest();

        Bespoke_Reporting__c br = [SELECT Id, Name FROM Bespoke_Reporting__c WHERE Name = 'Subject' LIMIT 1];
        Account acn = [SELECT Id, OwnerId FROM Account WHERE Name = 'Sample account' LIMIT 1];
        Id queueId = [SELECT Id, QueueId, Queue.Name FROM QueueSobject where Queue.Name = 'RFI Inbox' LIMIT 1].QueueId;

        // New case
        Case cse = [SELECT Id, OwnerId, Subject, AccountId FROM Case LIMIT 1];

        // Check some of the parameters
        system.assertEquals(queueId, cse.OwnerId);  
        system.assertEquals(acn.Id, cse.AccountId);  
        system.assertEquals(br.Name, cse.Subject);  
        
    }

    @isTest static void deleteBespokeReporting() {
        Bespoke_Reporting__c br = [SELECT Id FROM Bespoke_Reporting__c LIMIT 1];
        delete br;
    }

    @isTest static void runScheduledJob() {
		EQT_ScheduleBespokeReporting m = new EQT_ScheduleBespokeReporting();
        String CRON_EXP = '0 0 0 15 3 ? 2030';


        Test.startTest();
            String jobId = System.schedule('EQT_ScheduleBespokeReporting', CRON_EXP, m);

            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                FROM CronTrigger WHERE id = :jobId];

            // Verify the expressions are the same
            System.assertEquals(CRON_EXP, ct.CronExpression);

            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);

            // Verify the next time the job will run
            System.assertEquals('2030-03-15 00:00:00', String.valueOf(ct.NextFireTime));

            // Start the batch that should have been trigged
            EQT_ScheduleBespokeReporting sj = new EQT_ScheduleBespokeReporting();
            Id batchprocessid = Database.executeBatch(sj, 20);
        Test.stopTest();
    }
}