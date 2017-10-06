/**
 * Created by brian.williams on 30/01/17.
 */

@isTest
private class EQT_AssignmentHandler_Test {

    @isTest static void assignmentBoardManagementTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);

            system.assertEquals(1, [SELECT Id FROM Account WHERE Id= :a.Id].size());

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assert(String.isEmpty([SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c));

            Id boardManagementRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
            EQT_TestFactory.createSampleAssignment(a.Id, c.Id, boardManagementRTId, null, true);

            //verify engagement level was set
            system.assertEquals(EQT_UTIL_Settings.getIABoardIEEngagementLevelName(), [SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c);
        }
    }

    @isTest static void assignmentDealTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);

            system.assertEquals(1, [SELECT Id FROM Account WHERE Id= :a.Id].size());

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assert(String.isEmpty([SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c));

            Id dealRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentDealRecordTypeName());
            EQT_TestFactory.createSampleAssignment(a.Id, c.Id, dealRTId, null, true);

            //verify engagement level was set
            system.assertEquals(EQT_UTIL_Settings.getIADealEngagementLevelName(), [SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c);
        }
    }

    @isTest static void assignmentUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1', true);

            system.assertEquals(1, [SELECT Id FROM Account WHERE Id= :a.Id].size());

            Contact c = EQT_TestFactory.createSampleContact('test', 'contact', a.Id);

            system.assert(String.isEmpty([SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c));

            Id dealRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentDealRecordTypeName());
            EQT_TestFactory.createSampleAssignment(a.Id, c.Id, dealRTId, null, true);

            //get contact and remove engagement level
            c  = [SELECT Id, Engagement_Level__c FROM Contact WHERE Id = :c.Id];
            c.Engagement_Level__c = null;
            update c;

            EQT_Assignment__c assignment = [SELECT Id, RecordTypeId FROM EQT_Assignment__c WHERE Contact__c = :c.Id AND Company__c = :a.Id];
            assignment.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
            update assignment;

            //verify engagement level was set
            system.assertEquals(EQT_UTIL_Settings.getIABoardIEEngagementLevelName(), [SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c);

            //get contact and remove engagement level
            c  = [SELECT Id, Engagement_Level__c FROM Contact WHERE Id = :c.Id];
            c.Engagement_Level__c = null;
            update c;

            assignment = [SELECT Id, RecordTypeId FROM EQT_Assignment__c WHERE Contact__c = :c.Id AND Company__c = :a.Id];
            assignment.RecordTypeId = dealRTId;
            update assignment;

            //verify engagement level was set
            system.assertEquals(EQT_UTIL_Settings.getIADealEngagementLevelName(), [SELECT Engagement_Level__c FROM Contact WHERE Id = :c.Id].Engagement_Level__c);
        }
    }
}