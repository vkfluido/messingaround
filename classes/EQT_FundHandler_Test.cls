@isTest
private class EQT_FundHandler_Test {

    @isTest static void fundSetOwnerByPersonIdFromEPM() {
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

        Contact c;
        Contact c2;
        Fund__c fund;

        //set default account
        Account undefinedCompany = EQT_TestFactory.createSampleAccount('Account.EQT_Placeholder', 'Undefined Company');
        system.assert(undefinedCompany.Id != null);
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('EQT_Default_Account_ID__c', undefinedCompany.Id);
        update appSettings;

        system.runAs(u) {
            c = new Contact();
            c.LastName = 'Generic Contact, will get default RT';
            c.EQT_EPM_PersonID__c = '1234';
            c.EQT_EPM_User_ID__c = responsibleUser1.EQT_EPM_User_ID__c;
            c.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
            insert c;
            System.debug(LoggingLevel.INFO, '@@ c'+c);

            c2 = new Contact();
            c2.LastName = 'Generic Contact2, will get default RT';
            c2.EQT_EPM_PersonID__c = '4321';
            c2.EQT_EPM_User_ID__c = responsibleUser2.EQT_EPM_User_ID__c;
            c2.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
            insert c2;
            System.debug(LoggingLevel.INFO, '@@ c2 '+c2);

            // Set some User ID on the users to connect with
            // See if the Owner field is set
    		fund = EQT_TestFactory.createSamplePlanningFundraisingFund('New Fund', FALSE);
    	    fund.EQT_EPM_Responsible__c = c.EQT_EPM_PersonID__c; 
            insert fund;
        }

        fund = [select id,OwnerId,EQT_EPM_Responsible__c from Fund__c where id=:fund.id];
        system.assertEquals(responsibleUser1.Id, fund.OwnerId);

        system.runAs(responsibleUser1) {
            fund.EQT_EPM_Responsible__c = c2.EQT_EPM_PersonID__c;
            update fund;
        }

        fund = [select id,OwnerId,EQT_EPM_Responsible__c from Fund__c where id=:fund.id];
        system.assertEquals(responsibleUser2.Id, fund.OwnerId);

        system.runAs(responsibleUser2) {
            fund.EQT_EPM_Responsible__c = '789';
            update fund;
        }

        fund = [select id,OwnerId,EQT_EPM_Responsible__c from Fund__c where id=:fund.id];
        system.assertEquals(true, [SELECT IR_default_user__c FROM User WHERE Id = :fund.OwnerId].IR_default_user__c);
    }


    @isTest static void fundSetRecordIDByNamefromEPM() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        system.runAs(u) {
            //Create sample fund and check the record type is set
            Fund__c fund = EQT_TestFactory.createSamplePlanningFundraisingFund('New Fund', FALSE);
            fund.EQT_EPM_Record_Type_Name__c = 'EQT_Planning_Fundraising';
            insert fund;
            
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Fund__c.EQT_Planning_Fundraising'), [SELECT Id, RecordTypeId FROM Fund__c WHERE Id = :fund.Id].RecordTypeId);
            
            //Update sample with other record type name and check the record type is set
            fund.EQT_EPM_Record_Type_Name__c = 'EQT_Active_Fund';
            update fund;
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Fund__c.EQT_Active_Fund'), [SELECT Id, RecordTypeId FROM Fund__c WHERE Id = :fund.Id].RecordTypeId);
        }
    }

    @isTest static void fundDeleteTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        system.runAs(u) {
            //Create sample fund and check the record type is set
            Fund__c fund = EQT_TestFactory.createSamplePlanningFundraisingFund('New Fund', FALSE);
            fund.EQT_EPM_Record_Type_Name__c = 'EQT_Planning_Fundraising';
            insert fund;

            system.assertEquals(1, [SELECT Id FROM Fund__c].size());

            //delete
            delete fund;
            system.assertEquals(0, [SELECT Id FROM Fund__c].size());
        }
    }
}