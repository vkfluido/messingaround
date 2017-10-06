@IsTest
private class EQT_AgreementAutoExpire_BATCH_Test {
    @isTest static void noChangesTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            EQT_TestFactory.createSampleAgreement(c.Id, 'Permanent IE', EQT_UTIL_Settings.getAgreementActiveStatusName(), true);

            //verify agreement was created
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName()].size());

            //run batch
            Test.startTest();

            EQT_AgreementAutoExpire_BATCH b = new EQT_AgreementAutoExpire_BATCH();
            Database.executeBatch(b);

            Test.stopTest();

            //verify there are no logs
            system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());

            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName()].size());
        }
    }

    @isTest static void successUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            EQT_IA_Contract__c agreement = EQT_TestFactory.createSampleAgreement(c.Id, 'Permanent IE', EQT_UTIL_Settings.getAgreementActiveStatusName(), false);
            agreement.EQT_Start_Date__c = Date.today().addMonths(-2);
            agreement.EQT_End_Date__c = Date.today().addDays(-1);
            insert agreement;

            //verify agreement was created
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName()].size());

            //run batch
            Test.startTest();

            EQT_AgreementAutoExpire_BATCH b = new EQT_AgreementAutoExpire_BATCH();
            Database.executeBatch(b);

            Test.stopTest();

            //verify there are no logs
            system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());

            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementExpiredStatusName()].size());
        }
    }

    @isTest static void failLogTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            EQT_TestFactory.createSampleAgreement(c.Id, 'Permanent IE', EQT_UTIL_Settings.getAgreementActiveStatusName(), true);

            //verify agreement was created
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName()].size());

            //verify there are no logs
            system.assertEquals(0, [SELECT Id FROM EQT_Event_Log__c].size());

            //run batch
            Test.startTest();
            //run batch
            EQT_AgreementAutoExpire_BATCH b = new EQT_AgreementAutoExpire_BATCH();
            b.setTotalFailed(1); //set failed variable to 1
            Database.executeBatch(b);

            Test.stopTest();

            system.assertEquals(1, [SELECT Id FROM EQT_Event_Log__c].size());
        }
    }
}