/**
 * Created by Radosław on 31.05.2017.
 */

@IsTest
private class EQT_ContactSync_REST_Test {

    @testSetup
    static void createSampleTestData() {
        User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u1.Id].size());

        User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u2.Id].size());

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

        system.runAs(u1) {
            //create contact subscriptions for User u1
            List<EQT_ContactSyncSubscription__c> subscriptions = new List<EQT_ContactSyncSubscription__c>();
            for(Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :employeeRTId LIMIT 10]) {
                subscriptions.add(createSubscriptionRecord(u1.Id, c.Id, false));
            }

            insert subscriptions;
            system.assertEquals(10, [SELECT count() FROM EQT_ContactSyncSubscription__c WHERE User__c = :u1.Id]);

            //set subscription option
            optin(u1.Id, true);
            system.assertEquals(1, [SELECT count() FROM EQT_ContactSyncUserSettings__c WHERE User__c = :u1.Id AND Opt_in_All_IAs__c = true]);
        }

        system.runAs(u2) {
            //create contact subscriptions for User u1
            List<EQT_ContactSyncSubscription__c> subscriptions = new List<EQT_ContactSyncSubscription__c>();
            for(Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :iaRTId LIMIT 10]) {
                subscriptions.add(createSubscriptionRecord(u2.Id, c.Id, false));
            }

            insert subscriptions;
            system.assertEquals(10, [SELECT count() FROM EQT_ContactSyncSubscription__c WHERE User__c = :u2.Id]);

            //set subscription option
            optin(u2.Id, false);
            system.assertEquals(1, [SELECT count() FROM EQT_ContactSyncUserSettings__c WHERE User__c = :u2.Id AND Opt_in_All_IAs__c = false]);

            //create sample sector
            List<EQT_Sector__c> sectors = EQT_TestFactory.createTestSectors(1, true);
            system.assertEquals(1, [SELECT count() FROM EQT_Sector__c]);

            List<EQT_Sector_Rating__c> sectorRatings = new List<EQT_Sector_Rating__c>();

            EQT_ContactSyncSectorSubscription__c csSectorSubs = createSectorSubscription(u2.Id, sectors[0].Id, true);
            system.assert(csSectorSubs.Id != null);

            List<Contact> iaContactList = [SELECT Id, Name FROM Contact WHERE RecordTypeId = :iaRTId];

            for(Contact c : iaContactList) {
                sectorRatings.add(EQT_TestFactory.createSampleSectorRating('sr1' + c.Name, sectors[0].Id, null, c.Id, false));
            }

            insert sectorRatings;
            system.assertEquals(iaContactList.size(), [SELECT count() FROM EQT_Sector_Rating__c]);
        }
    }

    @isTest
    public static void getContactsForUserTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.username = 'testuser1@example.eqt';

            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.ResponseObj response = EQT_ContactSync_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser1@example.eqt', response.userInfo.userName);
            system.assertEquals(2000, response.contacts.size());
            system.assert(String.isNotEmpty(response.indexToStartWith));

            //get next set of data
            params.index = response.indexToStartWith;

            req = new RestRequest();
            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            response = EQT_ContactSync_REST.getData();
            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser1@example.eqt', response.userInfo.userName);
            system.assertEquals(200, response.contacts.size());
            system.assert(String.isEmpty(response.indexToStartWith));
        }
    }

    @isTest
    public static void getContactsForUserWithDateTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.username = 'testuser1@example.eqt';
            params.lastcall_timestamp = Datetime.now().addDays(-1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.ResponseObj response = EQT_ContactSync_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser1@example.eqt', response.userInfo.userName);
            system.assertEquals(2000, response.contacts.size());
            system.assert(String.isNotEmpty(response.indexToStartWith));

            //get next set of data
            params.index = response.indexToStartWith;

            req = new RestRequest();
            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            response = EQT_ContactSync_REST.getData();
            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser1@example.eqt', response.userInfo.userName);
            system.assertEquals(200, response.contacts.size());
            system.assert(String.isEmpty(response.indexToStartWith));
        }
    }

    @isTest
    public static void getContactsForAllUsersTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];
        User secondUser = [SELECT Id, username FROM User WHERE username = :'testuser2@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/ContactSync';
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.ResponseObj response = EQT_ContactSync_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assert(response.userInfo != null);
            system.assert(response.contacts.size() > 0);
            system.assert(String.isNotEmpty(response.indexToStartWith));

            //get next set of data
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.index = response.indexToStartWith;

            req = new RestRequest();
            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            response = EQT_ContactSync_REST.getData();
            system.assert(response != null);
            system.assert(response.userInfo != null);
            system.assert(response.contacts.size() > 0);
            system.assert(String.isNotEmpty(response.indexToStartWith));
        }
    }

    @isTest
    public static void getContactsForAllUsersDateTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser1@example.eqt'];
        User secondUser = [SELECT Id, username FROM User WHERE username = :'testuser2@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.lastcall_timestamp = Datetime.now().addDays(-1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.ResponseObj response = EQT_ContactSync_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assert(response.userInfo != null);
            system.assert(response.contacts.size() > 0);
            system.assert(String.isNotEmpty(response.indexToStartWith));

            //get next set of data
            params.index = response.indexToStartWith;

            req = new RestRequest();
            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            response = EQT_ContactSync_REST.getData();
            system.assert(response != null);
            system.assert(response.userInfo != null);
            system.assert(response.contacts.size() > 0);
            system.assert(String.isNotEmpty(response.indexToStartWith));
        }
    }

    @isTest
    public static void getContactsForUserSectorTest() {
        User runningUser = [SELECT Id, username FROM User WHERE username = :'testuser2@example.eqt'];

        system.runAs(runningUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            EQT_ContactSync_Wrapper.RequestParams params = new EQT_ContactSync_Wrapper.RequestParams();
            params.username = 'testuser2@example.eqt';

            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            EQT_ContactSync_Wrapper.ResponseObj response = EQT_ContactSync_REST.getData();
            Test.stopTest();

            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser2@example.eqt', response.userInfo.userName);
            system.assertEquals(2000, response.contacts.size());
            system.assert(String.isNotEmpty(response.indexToStartWith));

            //get next set of data
            params.index = response.indexToStartWith;

            req = new RestRequest();
            req.requestURI = '/services/apexrest/ContactSync';
            req.addParameter('params', JSON.serialize(params));
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            response = EQT_ContactSync_REST.getData();
            system.assert(response != null);
            system.assertEquals(null, response.userInfo.ssoUserId);
            system.assertEquals('testuser2@example.eqt', response.userInfo.userName);
            system.assertEquals(200, response.contacts.size());
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

    private static void optin(String userid, Boolean optin) {
        EQT_ContactSyncUserSettings__c s = new EQT_ContactSyncUserSettings__c();
        s.User__c = userid;
        s.Opt_in_All_IAs__c = optin;

        insert s;
    }

    private static EQT_ContactSyncSectorSubscription__c createSectorSubscription(Id userId, Id sectorId, Boolean doDML) {
        EQT_ContactSyncSectorSubscription__c csSectorSub = new EQT_ContactSyncSectorSubscription__c();
        csSectorSub.User__c = userId;
        csSectorSub.Sector__c = sectorId;

        if(doDML) {
            insert csSectorSub;
        }

        return csSectorSub;
    }
}