@isTest
private class EQT_SchedulableInvestranContactImport_T {
	@isTest static void scheduleTest() {
		Test.startTest();

		String jobName = 'Batch Import data from Investran';
		String schedulePeriod = '0 0 0 1 1 ? 2020'; //schedule 1.01.2020 at midnight
		String jobId = System.schedule(jobName, schedulePeriod, new EQT_SchedulableInvestranContactImport());

		List<CronJobDetail> lstJobs = [select Id from CronJobDetail where Name = :jobName];
        System.assertEquals(false, lstJobs.isEmpty());

        CronTrigger ct = [select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(schedulePeriod, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next job run date
        System.assertEquals('2020-01-01 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
	}	
}