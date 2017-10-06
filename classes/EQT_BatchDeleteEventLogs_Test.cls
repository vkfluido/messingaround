@isTest
private class EQT_BatchDeleteEventLogs_Test {
    @isTest static void successfullDeleteEventLogTest() {
        //create test user
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
            //create some logs
            EQT_TestFactory.createSampleLogs();
            system.assertEquals(1, [SELECT Id FROM EQT_Event_Log__c].size());
            
            Test.startTest();
            //run batch
            EQT_BatchDeleteEventLogs deleteBatch = new EQT_BatchDeleteEventLogs();
            Database.executeBatch(deleteBatch);
            
            Test.stopTest();
            system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());
        }
    }
    
    @isTest static void failDeleteEventLogTest() {
        //create test user
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //turn on logging feature
        EQT_TestFactory.enableLoggingFeature();
        
        system.runAs(u) {
            //create some logs
            EQT_TestFactory.createSampleLogs();
            system.assertEquals(1, [SELECT Id FROM EQT_Event_Log__c].size());
            
            Test.startTest();
            //run batch
            EQT_BatchDeleteEventLogs deleteBatch = new EQT_BatchDeleteEventLogs();
            deleteBatch.setTotalFailed(1); //set failed variable to 1
            Database.executeBatch(deleteBatch);
            
            Test.stopTest();
            system.assertEquals(1, [SELECT Id FROM EQT_Event_Log__c].size());
        }
    }
}