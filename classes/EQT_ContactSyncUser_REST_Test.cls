/**
 * Created by Radosław on 12.06.2017.
 */

@IsTest
private class EQT_ContactSyncUser_REST_Test {
    @testSetup
    static void createSampleTestData() {
        User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u1.Id].size());

        User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u2.Id].size());

        User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u3.Id].size());

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
        system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());

        Id employeeRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee');
        Id iaRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());

        List<Contact> contacts = new List<Contact>();
        contacts.addAll(EQT_TestFactory.createTestContacts(1100, 'EQT_Employee', new List<Account> {a}, false));
        contacts.addAll(EQT_TestFactory.createTestContacts(1100, 'EQT_Industrial_Advisor', new List<Account> {a}, false));

        insert contacts;
        system.assertEquals(1100, [SELECT count() FROM Contact WHERE RecordTypeId = :employeeRTId]);
        system.assertEquals(1100, [SELECT count() FROM Contact WHERE RecordTypeId = :iaRTId]);

        EQT_ContactSyncUserSettings__c s = new EQT_ContactSyncUserSettings__c();
        s.User__c = u3.Id;
        s.Opt_in_All_IAs__c = true;
        insert s;

        system.runAs(u1) {
            //create contact subscriptions for User u1
            List<EQT_ContactSyncSubscription__c> subscriptions = new List<EQT_ContactSyncSubscription__c>();
            for(Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :employeeRTId LIMIT 10]) {
                subscriptions.add(createSubscriptionRecord(u1.Id, c.Id, false));
            }

            insert subscriptions;
            system.assertEquals(10, [SELECT count() FROM EQT_ContactSyncSubscription__c WHERE User__c = :u1.Id]);
        }

        system.runAs(u2) {
            //create contact subscriptions for User u1
            List<EQT_ContactSyncSubscription__c> subscriptions = new List<EQT_ContactSyncSubscription__c>();
            for(Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :iaRTId LIMIT 10]) {
                subscriptions.add(createSubscriptionRecord(u2.Id, c.Id, false));
            }

            insert subscriptions;
            system.assertEquals(10, [SELECT count() FROM EQT_ContactSyncSubscription__c WHERE User__c = :u2.Id]);
        }
    }

    @isTest
    public static void getUsersTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.lastcall_timestamp = Datetime.now().addDays(-1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

            req.requestURI = '/services/apexrest/ContactSyncUser';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.UserResponseObj response = EQT_ContactSyncUser_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assertEquals(false, response.users.isEmpty());
            system.assert(String.isEmpty(response.indexToStartWith));
        }
    }
    
    @isTest
    public static void getAllUsersTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.index = runningUser.Id;
            req.requestURI = '/services/apexrest/ContactSyncUser';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.UserResponseObj response = EQT_ContactSyncUser_REST.getData();
            Test.stopTest();
            System.debug(response);
            system.assert(response != null);
            system.assertEquals(false, response.users.isEmpty());
            system.assert(String.isEmpty(response.indexToStartWith));
        }
    }

    private static EQT_ContactSyncSubscription__c createSubscriptionRecord(String userId, String recordId, Boolean doDML) {
        EQT_ContactSyncSubscription__c sub = new EQT_ContactSyncSubscription__c();
        sub.Contact__c = recordId;
        sub.User__c = userId;

        if(doDML) {
            insert sub;
        }

        return sub;
    }
}