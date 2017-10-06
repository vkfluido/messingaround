@IsTest
private class EQT_OpportunityTeamMemberHandler_Test {
    @isTest static void dealTypeTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Business Line Credit Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Opportunity_Deal_Record_Type_Name__c', 'EQT_Deal');
        appSettings.put('Opportunity_Team_Member_Deal_Team_Role__c', 'Deal Team');
        update appSettings;

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            system.assert(a.Id != null);

            String oppStageName = 'Lead';
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('sample opp', null, oppStageName, false);
            opp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityDealRecordTypeName());
            opp.AccountId = a.Id;
            insert opp;
            system.assert(opp.Id != null);

            //add team member
            String role = EQT_UTIL_Settings.getOpportunityTeamMemberDealTeamRoleName();
            OpportunityTeamMember otm = EQT_TestFactory.createSampleOppTeamMember(opp.Id, u.Id, role, 'Read', true);
            otm = [SELECT Id, TeamMemberRole, OpportunityAccessLevel FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id];
            system.assertEquals(role, otm.TeamMemberRole);
            system.assertEquals('Edit', otm.OpportunityAccessLevel);
        }
    }

    @isTest static void fundraisingTypeTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Business Line Credit Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Opportunity_Deal_Record_Type_Name__c', 'EQT_Deal');
        appSettings.put('Opportunity_Team_Member_Deal_Team_Role__c', 'Deal Team');
        update appSettings;

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            system.assert(a.Id != null);

            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assert(sampleFund.Id != null);

            //create sample Fundraising Request Opportunity
            String oppStageName = 'Showing interest';
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', a.Id, oppStageName, sampleFund.Id);
            system.assert(opp.Id != null);

            //add team member
            String role = EQT_UTIL_Settings.getOpportunityTeamMemberDealTeamRoleName();
            OpportunityTeamMember otm = EQT_TestFactory.createSampleOppTeamMember(opp.Id, u.Id);
            otm = [SELECT Id, OpportunityAccessLevel FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id];
            system.assertEquals('Read', otm.OpportunityAccessLevel);
        }
    }
}