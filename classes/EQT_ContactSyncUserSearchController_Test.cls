@isTest
public class EQT_ContactSyncUserSearchController_Test {

    @isTest
    public static void testSearchUsers_NoUsers1() {
        Test.startTest();
        List<User> users = EQT_ContactSyncUserSearchController.searchUsers('foo');
        System.assert(users.size() == 0);
        Test.stopTest();
    }
    
    @isTest
    public static void testSearchUsers_NoActiveUsers() {
        // create 10 users not active
        createUsers(10, false);
        
        Test.startTest();
        List<User> users = EQT_ContactSyncUserSearchController.searchUsers('asdfghjkl');
        System.assert(users.size() == 0);
        Test.stopTest();
    }
    
    @isTest
    public static void testSearchUsers_1ActiveUser() {
        // create 10 users not active
        createUsers(10, false);
        insert createUser('asdfghjkl', 'UserXYZ', true);
        
        Test.startTest();
        List<User> users1 = EQT_ContactSyncUserSearchController.searchUsers('asdfghjkl');
        List<User> users2 = EQT_ContactSyncUserSearchController.searchUsers('UserXYZ');
        System.assert(users1.size() == 1);
        System.assert(users2.size() == 1);
        
        // validate that the search for first name or last name return the same user
        System.assertEquals(users1[0].Id, users2[0].Id);
        Test.stopTest();
    }
    
    @isTest
    public static void testSearchUsers_30ActiveUser_ReturnOnlyFirst20() {
        // create 30 active users 
        createUsers(30, true);
        
        Test.startTest();
        List<User> users = EQT_ContactSyncUserSearchController.searchUsers('asdfghjkl');
        System.assert(users.size() == 20);
        Test.stopTest();
    }
    
    private static void createUsers(integer count, boolean active) {
        List<User> users = new List<User>();
        for (integer i=0; i<count; i++) {
            User u = createUser('Asdfghjkl', 'User' + i, active);
            users.add(u);
        }
        insert users;
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
        return u;
    }
    
}