@IsTest
private class EQT_PostAccountToSlack_VFC_Test {

    @isTest
    static void testNoRecords() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        Test.startTest();
        system.runAs(u) {
            List<Account> accountList = new List<Account>();

            ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(accountList );

            EQT_PostAccountToSlack_VFC controller = new EQT_PostAccountToSlack_VFC(setCtr);

            System.assertEquals(true, controller.showToastMessage);
            System.assertEquals('error', controller.toastMessageSeverity);
            System.assert( controller.toastMessage.length() > 0);
        }
        Test.stopTest();
    
    }

    @isTest
    static void testNoRecordsPost() {
        EQT_TestFactory.setUpOrg();

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        Test.startTest();
        system.runAs(u) {
            List<Account> accountList = new List<Account>();

            ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(accountList );

            EQT_PostAccountToSlack_VFC controller = new EQT_PostAccountToSlack_VFC(setCtr);
            
            PageReference prResult = controller.postToSlack();

            System.assertEquals(null, prResult);
            System.assertEquals(true, controller.showToastMessage);
            System.assertEquals('error', controller.toastMessageSeverity);
            System.assert( controller.toastMessage.length() > 0);
        }
        Test.stopTest();
    
    }

    @isTest
    static void testInvalidChannel() {

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        Account a;

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());

        }

        Test.startTest();
        system.runAs(u) {
            List<Account> accountList = [SELECT Id, Name FROM Account];

            EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
            appSettings.put('Slack_Account_Channel__c', null);
            update appSettings;

            ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(accountList );
            setCtr.setSelected(new Account[]{a});

            EQT_PostAccountToSlack_VFC controller = new EQT_PostAccountToSlack_VFC(setCtr);
            PageReference prResult = controller.postToSlack();

            System.assertEquals(null, prResult);
            System.assertEquals(true, controller.showToastMessage);
            System.assertEquals('error', controller.toastMessageSeverity);
            System.assert( controller.toastMessage.length() > 0);
        }
        Test.stopTest();
    }

    @isTest
    static void testValid() {

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        Account a;

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());

        }

        Test.startTest();
        system.runAs(u) {
            List<Account> accountList = [SELECT Id, Name FROM Account];

            ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(accountList );
            setCtr.setSelected(new Account[]{a});

            EQT_PostAccountToSlack_VFC controller = new EQT_PostAccountToSlack_VFC(setCtr);
            controller.messageForSlack = 'test message';
            PageReference prResult = controller.postToSlack();

            System.assertEquals(null, prResult);
            System.assertEquals(true, controller.showToastMessage);
            System.assertEquals('success', controller.toastMessageSeverity);

            System.assert( controller.toastMessage.length() > 0);
        }
        Test.stopTest();
    }    

    @isTest
    static void testCancel() {

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        Account a;

        system.runAs(u) {
            //create sample account
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());

        }

        Test.startTest();
        system.runAs(u) {
            List<Account> accountList = [SELECT Id, Name FROM Account];

            ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(accountList );
            setCtr.setSelected(new Account[]{a});

            EQT_PostAccountToSlack_VFC controller = new EQT_PostAccountToSlack_VFC(setCtr);
            controller.messageForSlack = 'test message';
            PageReference prResult = controller.cancel();

            System.assertNotEquals(null, prResult);
        }
        Test.stopTest();
    }    
}