@IsTest
private class EQT_AgreementHandler_Test {

    @isTest static void noChangesTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = null].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            EQT_TestFactory.createSampleAgreement(c.Id, 'Permanent IE', 'Active', true);

            //verify agreement was created and contact contracting status and engagement level does not changed
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c != :EQT_UTIL_Settings.getIABoardIEEngagementLevelName()].size());
        }
    }

    @isTest static void iaContractingStatusChangeTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = null].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            String agreementType = 'Permanent IE';
            Id agreementCompanyRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_IA_Contract__c.' + EQT_UTIL_Settings.getAgreementCompanyRecordTypeName());
            EQT_IA_Contract__c agreement = EQT_TestFactory.createSampleAgreement(c.Id, agreementType, 'Active', false);
            agreement.RecordTypeId = agreementCompanyRecordTypeId;
            insert agreement;

            //verify nothing changes on contact
            agreement = [SELECT Id, EQT_Status__c, EQT_Type__c, EQT_Start_Date__c, EQT_End_Date__c FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id];
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_IA_Agreement_Counterpart__c = :a.Id].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = :agreementType].size());

            //change agreement status to expired now
            agreement.EQT_Status__c = EQT_UTIL_Settings.getAgreementExpiredStatusName();
            update agreement;

            //verify agreement was created and contact contracting status and engagement level does not changed
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementExpiredStatusName() AND EQT_End_Date__c != TODAY].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c = :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c != :EQT_UTIL_Settings.getIABoardIEEngagementLevelName()].size());

            //set agreement status back to active
            agreement.EQT_Status__c = EQT_UTIL_Settings.getAgreementActiveStatusName();
            update agreement;

            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName() AND EQT_End_Date__c != null].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND Engagement_Level__c = :agreementType].size());
        }
    }

    @isTest static void iaContractingStatusEngagementLvlChangeTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = null].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            //create assignment
            Id boardMngAssignmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
            String assignmentRole = EQT_UTIL_Settings.getAssignmentRolesToSetIAEngagementLevelToBoardIE();
            Set<String> assignmentRoles = new Set<String>();

            if(assignmentRole.contains(';')) {
                for(String role : assignmentRole.split(';')) {
                    assignmentRoles.add(role.trim());
                }
            }
            else {
                assignmentRoles.add(assignmentRole);
            }

            EQT_Assignment__c assignment = EQT_TestFactory.createSampleAssignment(a.Id, c.Id, boardMngAssignmentRecordTypeId, assignmentRole.split(';')[0], false);
            assignment.Start_Date__c = Date.today();
            insert assignment;
            system.assertEquals(1, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id AND EQT_Is_Active__c = true AND RecordTypeId = :boardMngAssignmentRecordTypeId AND EQT_Role__c IN :assignmentRoles].size());

            EQT_IA_Contract__c agreement = EQT_TestFactory.createSampleAgreement(c.Id, 'Permanent IE', 'Active', true);

            //verify nothing changes on contact
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c != :EQT_UTIL_Settings.getIABoardIEEngagementLevelName()].size());

            //change agreement status to expired now
            agreement.EQT_Status__c = EQT_UTIL_Settings.getAgreementExpiredStatusName();
            update agreement;

            //verify agreement was created and contact contracting status and engagement level does not changed
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id  AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementExpiredStatusName()].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c = :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = :EQT_UTIL_Settings.getIABoardIEEngagementLevelName()].size());
        }
    }

    @isTest static void endDateChangeTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id AND EQT_IA_Status__c != :EQT_UTIL_Settings.getIAContractingExpiredStatus() AND Engagement_Level__c = null].size());

            //verify there are no assignments and agreements
            system.assertEquals(0, [SELECT Id FROM EQT_Assignment__c WHERE Contact__c = :c.Id].size());
            system.assertEquals(0, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id].size());

            String agreementType = 'Permanent IE';
            Date startDate = Date.today().addMonths(-2);
            Date endDate = Date.today().addMonths(-1);

            EQT_IA_Contract__c agreement = EQT_TestFactory.createSampleAgreement(c.Id, agreementType, 'Active', false);
            agreement.EQT_Start_Date__c = startDate;
            insert agreement;

            //verify nothing changes on contact
            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_Start_Date__c = :startDate].size());

            //change date to past and verify status was changed to expired
            agreement.EQT_End_Date__c = endDate;
            update agreement;

            system.assertEquals(1, [SELECT Id FROM EQT_IA_Contract__c WHERE EQT_Industrial_Advisor__c = :c.Id AND EQT_End_Date__c = :endDate AND EQT_Status__c = :EQT_UTIL_Settings.getAgreementExpiredStatusName()].size());
        }
    }
}