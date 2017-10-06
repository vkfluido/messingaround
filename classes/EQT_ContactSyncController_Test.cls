@isTest
public class EQT_ContactSyncController_Test {
    
    @isTest
    public static void testGetInitializationInfo_ManageOnbehalf_NotSubscribed_NotOptin() {
        // get user and create setup context in a block to void MIXED_DML_OPERATION error
        User u = [select id from User where Id=: UserInfo.getUserId() limit 1];
        Contact c = null;
        System.runAs(u) {
	        createCustomSetting('foo_set');
    	    assignCurrentUserPermissionSet('foo_set');
        	c = createContact();
        }
        
        // run test
        Test.startTest();
        String str = EQT_ContactSyncController.getInitializationInfo(c.Id);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('subscriptionStatus') == false);
        System.assert(obj.get('manageOnBehalf') == true);
        System.assert(obj.get('optinAllIAs') == false);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInitializationInfo_NotManageOnbehalf_Subscribed_NotOptin() {
        // create contact
        Contact c = createContact();
        createSubscriptionRecord(UserInfo.getUserId(), c.Id);
        
        Test.startTest();
        String str = EQT_ContactSyncController.getInitializationInfo(c.Id);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('subscriptionStatus') == true);
        System.assert(obj.get('manageOnBehalf') == true);
        System.assert(obj.get('optinAllIAs') == false);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInitializationInfo_ManageOnbehalf_NotSubscribed_NotOptinObjectThere() {
        // create contact
        Contact c = createContact();
        optin(userInfo.getUserId(), false);
        
        Test.startTest();
        String str = EQT_ContactSyncController.getInitializationInfo(c.Id);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('subscriptionStatus') == false);
        System.assert(obj.get('manageOnBehalf') == true);
        System.assert(obj.get('optinAllIAs') == false);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInitializationInfo_ManageOnbehalf_NotSubscribed_OptinObjectThere() {
        // create contact
        Contact c = createContact();
        optin(UserInfo.getUserId(), true);
        
        Test.startTest();
        String str = EQT_ContactSyncController.getInitializationInfo(c.Id);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('subscriptionStatus') == false);
        System.assert(obj.get('manageOnBehalf') == true);
        System.assert(obj.get('optinAllIAs') == true);
        Test.stopTest();
    }
    
    @isTest
    public static void testOptinAllIAs_CurrentUserOptin() {
        optin(UserInfo.getUserId(), true);
        
        Test.startTest();
        EQT_ContactSyncController.optinAllIAs(false, null);
        String str = EQT_ContactSyncController.getInitializationInfo(null);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('optinAllIAs') == false);
        Test.stopTest();
    }
    
    @isTest
    public static void testOptinAllIAs_CurrentUserOptout() {
        optin(UserInfo.getUserId(), false);
        
        Test.startTest();
        EQT_ContactSyncController.optinAllIAs(true, null);
        String str = EQT_ContactSyncController.getInitializationInfo(null);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('optinAllIAs') == true);
        Test.stopTest();
    }
    
    @isTest
    public static void testOptinAllIAs_CurrentUserOptIn_NoSetting() {        
        Test.startTest();
        EQT_ContactSyncController.optinAllIAs(true, null);
        String str = EQT_ContactSyncController.getInitializationInfo(null);
        Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(str);
        System.assert(obj.get('optinAllIAs') == true);
        Test.stopTest();
    }
    
    @isTest
    public static void testOptinAllIAs_UsersOptout() {
        // create perm set and assign so user may manage onbehalf
        User u = [select id from User where Id=: UserInfo.getUserId() limit 1];
        System.runAs(u) {
	        createCustomSetting('foo_set');
    	    assignCurrentUserPermissionSet('foo_set');
        }
        
        // craete user and opt both user and current user into all IAs
        User user1 = createUser('Test', 'User123', true);
        optin(user1.Id, true);
        optin(UserInfo.getUserId(), true);
        
        // create list of users id
        List<String> users = new List<String>();
        users.add(user1.Id);
        users.add(UserInfo.getUserId());
        
        Test.startTest();
        EQT_ContactSyncController.optinAllIAs(false, users);
        
        List<EQT_ContactSyncUserSettings__c> bools = [select opt_in_all_ias__c from EQT_ContactSyncUserSettings__c];
        System.assert(bools.size() == 2);
        for (EQT_ContactSyncUserSettings__c b : bools) System.assert(b.opt_in_all_ias__c == false);
        Test.stopTest();
    }
    
    @isTest
    public static void testOptinAllIAs_UsersOptin() {
        // create perm set and assign so user may manage onbehalf
        User u = [select id from User where Id=: UserInfo.getUserId() limit 1];
        System.runAs(u) {
	        createCustomSetting('foo_set');
    	    assignCurrentUserPermissionSet('foo_set');
        }
        
        // create a user and opt that user into all IA's but do 
        // not opt current user in so we find some records only)
        User user1 = createUser('Test', 'User123', true);
        optin(user1.Id, true);
        
        // create list of users id
        List<String> users = new List<String>();
        users.add(user1.Id);
        users.add(UserInfo.getUserId());
        
        Test.startTest();
        EQT_ContactSyncController.optinAllIAs(true, users);
        
        List<EQT_ContactSyncUserSettings__c> bools = [select opt_in_all_ias__c from EQT_ContactSyncUserSettings__c];
        System.assert(bools.size() == 2);
        for (EQT_ContactSyncUserSettings__c b : bools) System.assert(b.opt_in_all_ias__c == true);
        Test.stopTest();
    }
    
    @isTest
    public static void testSetSubscriptionStatus_CurrentUser_NoContactId() {
        try {
	        EQT_ContactSyncController.setSubscriptionStatus(null, true, null);
            System.assert(false);
            
        } catch (AuraHandledException e) {
            // yeah - should throw if no id
        }
    }
    
    @isTest
    public static void testSetSubscriptionStatus_CurrentUser_Subscribe() {
        Contact c = createContact();
        
        Test.startTest();
        
        String str = EQT_ContactSyncController.setSubscriptionStatus(c.Id, true, null);
        Map<String,Object> obj = (Map<String,Object>)JSON.deserializeUntyped(str);
        List<Object> inserted = (List<Object>)obj.get('inserted');
        System.assert(inserted.size() == 1);
        System.assert(inserted[0].equals(UserInfo.getUserId()));
        
        Test.stopTest();
    }
    
    @isTest
    public static void testSetSubscriptionStatus_CurrentUser_Unsubscribe_PrevSubscribed() {
        Contact c = createContact();
        subscribeUserIdToContactId(UserInfo.getUserId(), c.Id);
        
        Test.startTest();
        String str = EQT_ContactSyncController.setSubscriptionStatus(c.Id, false, null);
        Map<String,Object> obj = (Map<String,Object>)JSON.deserializeUntyped(str);
        List<Object> deleted = (List<Object>)obj.get('deleted');
        System.assert(deleted.size() == 1);
        System.assert(deleted[0].equals(UserInfo.getUserId()));
        
        Test.stopTest();
    }
    
    @isTest
    public static void testSetSubscriptionStatus_MultipleUsersAllowed_Unsubscribe() {
        // allow current user to do onbehalf of (in separate context to avoid mixed dml)
        User runas = [select id from user where id=:UserInfo.getUserId()];
        System.runAs(runas) {
            createCustomSetting('the_permset');
            assignCurrentUserPermissionSet('the_permset');
        }
        
        // create contact and dummy user and subscribe current user and dummy user to contact
        Contact c = createContact();
        User user = createUser('Test', 'User', True);
        subscribeUserIdToContactId(UserInfo.getUserId(), c.Id);
        subscribeUserIdToContactId(user.Id, c.Id);

        List<String> users = new List<String>(); 
        users.add(UserInfo.getUserId()); 
        users.add(user.id);
        
        Test.startTest();
        String str = EQT_ContactSyncController.setSubscriptionStatus(c.Id, false, users);
        Map<String,Object> obj = (Map<String,Object>)JSON.deserializeUntyped(str);
        List<Object> deleted = (List<Object>)obj.get('deleted');
        System.assert(deleted.size() == 2);
        //System.assert(deleted[0].equals(UserInfo.getUserId())); // order is not exect, wrong assert
        //System.assert(deleted[1].equals(user.Id)); // order is not exect, wrong assert
        Test.stopTest();
    }
        
    @isTest
    public static void testSetSubscriptionStatus_MultipleUsersAllowed_Subscribe() {
        // allow current user to do onbehalf of (in separate context to avoid mixed dml)
        User runas = [select id from user where id=:UserInfo.getUserId()];
        System.runAs(runas) {
            createCustomSetting('the_permset');
            assignCurrentUserPermissionSet('the_permset');
        }
        
        // create contact and dummy user and subscribe dummy user to contact (not current user)
        Contact c = createContact();
        User user = createUser('Test', 'User', True);
        subscribeUserIdToContactId(user.Id, c.Id);
        List<String> users = new List<String>(); users.add(UserInfo.getUserId()); users.add(user.id);
        
        Test.startTest();
        String str = EQT_ContactSyncController.setSubscriptionStatus(c.Id, true, users);
        Map<String,Object> obj = (Map<String,Object>)JSON.deserializeUntyped(str);
        List<Object> inserted = (List<Object>)obj.get('inserted');
        System.assert(inserted.size() == 1);
        System.assert(inserted[0].equals(UserInfo.getUserId()));
        Test.stopTest();
    }
    
    @isTest
    public static void testSetSubscriptionSector_CurrentUser_Subscribe() {
        // create sector
        EQT_Sector__c sector = createSector('Sector 1');

        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs(sector.Id, null, true);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(1, results.size());
        System.assertEquals(sector.Id, results[0].Sector__c); 
        System.assertEquals(UserInfo.getUserId(), results[0].User__c); 

        Test.stopTest();        
    }

    @isTest
    public static void testSetSubscriptionSector_CurrentUser_UnSubscribe() {
        // create sector
        EQT_Sector__c sector = createSector('Sector 1');
        createSectorSubscription(UserInfo.getUserId(), sector.Id);

        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs('', null, true);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(0, results.size());
        Test.stopTest();        
    }

    @isTest
    public static void testSetSubscriptionSector_CurrentUser_SubscribeToDifferent() {
        // create sector
        EQT_Sector__c sector = createSector('Sector 1');
        createSectorSubscription(UserInfo.getUserId(), sector.Id);

        EQT_Sector__c sector2 = createSector('Sector 2');

        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs(sector2.Id, null, true);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(1, results.size());
        System.assertEquals(sector2.Id, results[0].Sector__c); 
        System.assertEquals(UserInfo.getUserId(), results[0].User__c); 
        
        Test.stopTest();        
    }

    @isTest
    public static void testSetSubscriptionSector_Multiple_Subscribe() {
        // allow current user to do onbehalf of (in separate context to avoid mixed dml)
        User runas = [select id from user where id=:UserInfo.getUserId()];
        System.runAs(runas) {
            createCustomSetting('the_permset');
            assignCurrentUserPermissionSet('the_permset');
        }
        
        // create sector and dummy user and subscribe dummy user to contact (not current user)
        EQT_Sector__c sector = createSector('Sector 1');

        User user = createUser('Test', 'User', True);
        List<String> users = new List<String>(); 
        users.add(UserInfo.getUserId()); 
        users.add(user.id);
        
        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs(sector.Id, users, true);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(2, results.size());

        Test.stopTest();
    }
    
     @isTest
    public static void testSetSubscriptionSector_Multiple_UnSubscribe() {
        // allow current user to do onbehalf of (in separate context to avoid mixed dml)
        User runas = [select id from user where id=:UserInfo.getUserId()];
        System.runAs(runas) {
            createCustomSetting('the_permset');
            assignCurrentUserPermissionSet('the_permset');
        }
        
        // create sector and dummy user and subscribe dummy user to contact (not current user)
        EQT_Sector__c sector = createSector('Sector 1');

        User user = createUser('Test', 'User', True);
        List<String> users = new List<String>(); 
        users.add(UserInfo.getUserId()); 
        users.add(user.id);
        
        createSectorSubscription(UserInfo.getUserId(), sector.Id);
        createSectorSubscription(user.id, sector.Id);

        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs(sector.Id, users, false);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(0, results.size());
        Test.stopTest();        
    }   

    @isTest
    public static void testSetSubscriptionSector_Multiple_SubscribeToExisting() {
        // allow current user to do onbehalf of (in separate context to avoid mixed dml)
        User runas = [select id from user where id=:UserInfo.getUserId()];
        System.runAs(runas) {
            createCustomSetting('the_permset');
            assignCurrentUserPermissionSet('the_permset');
        }
        
        // create sector and dummy user and subscribe dummy user to contact (not current user)
        EQT_Sector__c sector = createSector('Sector 1');

        User user = createUser('Test', 'User', True);
        List<String> users = new List<String>(); 
        users.add(UserInfo.getUserId()); 
        users.add(user.id);
        
        createSectorSubscription(UserInfo.getUserId(), sector.Id);

        Test.startTest();
        EQT_ContactSyncController.optinBySectorIAs(sector.Id, users, true);
        
        List<EQT_ContactSyncSectorSubscription__c> results = [select Sector__c, User__c from EQT_ContactSyncSectorSubscription__c];
        System.assertEquals(2, results.size());

        Test.stopTest();
    }



    // utility method to assign the current user a permission set with 
    // the supplied name
    private static void assignCurrentUserPermissionSet(String permsetName) {
        // create permission set
        PermissionSet zet = new PermissionSet();
        zet.Name = permsetName;
        zet.Label = permsetName;
        insert zet;
        
        // get current user and assign set to user
        PermissionSetAssignment assignment = new PermissionSetAssignment();
        assignment.AssigneeId = UserInfo.getUserId();
        assignment.PermissionSetId = zet.Id;
        insert assignment;
    }
    
    // create a custom settings object and set the permission set name supplied
    // into the custom settings
    private static void createCustomSetting(String permsetName) {
        EQT_ContactSyncOrgSettings__c settings = new EQT_ContactSyncOrgSettings__c();
        settings.Permission_Set_Name__c = permsetName;
        insert settings;
    }
    
    // create a contact object, insert and return
    private static Contact createContact() {
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact0';
        insert c;
        return c;
    }
    
    private static void createSubscriptionRecord(String userId, String recordId) {
        EQT_ContactSyncSubscription__c sub = new EQT_ContactSyncSubscription__c();
        sub.Contact__c = recordId;
        sub.User__c = userId;
        insert sub;
    }
    
    private static void optin(String userid, boolean optin) {
        EQT_ContactSyncUserSettings__c s = new EQT_ContactSyncUserSettings__c();
        s.User__c = userid;
        s.Opt_in_All_IAs__c = optin;
        insert s;
    }
    
    private static User createUser(String fn, String ln, boolean active) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        
        User u = new User();
        u.FirstName = fn;
        u.LastName = ln;
        u.IsActive = active;
        u.Email = fn.toLowerCase() + '_' + ln.toLowerCase() + '@example.com';
        u.Username = UserInfo.getUserId() + '_' + u.Email;
        u.Alias = ln.toLowerCase();
        u.EmailEncodingKey = 'UTF-8';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
		u.ProfileId = p.Id;
        insert u;
        return u;
    }
    
    private static void subscribeUserIdToContactId(String userid, String contactid) {
        EQT_ContactSyncSubscription__c sub = new EQT_ContactSyncSubscription__c();
        sub.User__c = userid;
        sub.Contact__c = contactId;
        insert sub;
    }

    private static EQT_Sector__c createSector(String sectorName){
        EQT_Sector__c sector = new EQT_Sector__c();
        sector.Name = sectorName;
        insert sector;

        return sector;
    }

    private static void createSectorSubscription(Id userId, Id sectorId){
        EQT_ContactSyncSectorSubscription__c sub = new EQT_ContactSyncSectorSubscription__c();
        sub.Sector__c = sectorId;
        sub.User__c = userId;
        insert sub;
    }
}