/**
    About
    -----
    Description: Test class for EQT_SchedulableAutoGenerateTask
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
private class EQT_SchedulableAutoGenerateTask_Test {
    @isTest static void scheduleTest() {
        Test.startTest();

        String jobName = 'Batch Auto Generate Tasks';
        String schedulePeriod = '0 0 0 1 1 ? 2020'; //schedule 1.01.2020 at midnight
        String jobId = System.schedule(jobName, schedulePeriod, new EQT_SchedulableAutoGenerateTask());

        List<CronJobDetail> lstJobs = [select Id from CronJobDetail where Name = :jobName];
        System.assertEquals(false, lstJobs.isEmpty());

        CronTrigger ct = [select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];

        System.assertEquals(schedulePeriod, ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);

        System.assertEquals('2020-01-01 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
    }
}