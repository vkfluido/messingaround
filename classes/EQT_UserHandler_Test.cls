@isTest
private class EQT_UserHandler_Test
{
@testSetup static void setup() {

		// setUpOrg
		EQT_TestFactory.setUpOrg();
        // Create EQT default account
        Account eqt = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'EQT Partners Test', true);
		
		EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Default_EQT_Partners_Employee_Account__c', eqt.Id);
        upsert appSettings;

    }

	@isTest
	static void testProvisionUsers()
	{

		Account eqt = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'EQT_Other' AND Name = 'EQT Partners Test'];
		String EMPLOYEE_RT_ID = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee');

		List<User> users = new List<User>();
		
		// Create 6 New Users: 
		// 2 with IR profile 
		//     --> 1 should create a contact
		//     --> 1 the contact already exists
		String IR = EQT_UTIL_Meta.profileId('EQT Investor Relations');
		// 2 with BL Profile -> should create contact
		String BLP = EQT_UTIL_Meta.profileId('EQT Business Line Profile');
		// 2 with Admin Profile 
		//     but 1 without Employee Number -> should NOT create contact
		String ADM = EQT_UTIL_Meta.profileId('System Administrator');
		
		Contact existingContact = new Contact();
		
		for(Integer i = 0; i < 6; i++){

			String random = String.valueOf(Math.abs(Crypto.getRandomInteger()));
			String profileId = (i<2?IR:(i>=2 && i<4?BLP:ADM));
			System.debug((i<2?'IR':(i>=2 && i<4?'BLP':'ADM')));
			
			User u = new User();
	        u.username= 'testuser'+i+'@'+random+'.example.com';
	        u.Email =random+'@example.com';
	        u.localeSidKey = 'en_US';
	        u.languageLocaleKey = 'en_US';
	        u.profileId = profileId;
	        u.FirstName = 'Test';
	        u.LastName = random;
	        u.TimeZoneSidKey='GMT';
	        u.EmailEncodingKey='UTF-8';
	        u.Alias = 'test'+random.left(4);
	        
	        u.EmployeeNumber = (i==5?null:random); // Null if "i" is 5 (last loop)
			u.Department = (i<2?'Investor Relations':(i>=2 && i<4?'Business Line':'IT'));
			u.EQT_Office__c = 'Stockholm';

	        users.add(u);

	        if(i==0){
	        	existingContact.FirstName = u.FirstName;
	        	existingContact.LastName = u.LastName;
	        	existingContact.Email = u.Email;
	        	existingContact.RecordTypeId = EMPLOYEE_RT_ID;
	        	existingContact.AccountId = eqt.Id;
	        }

	        //System.debug(u);
		}
		insert existingContact;

		Test.startTest();
			// Test User Trigger on Insert
			insert users;
		Test.stopTest();

		List<Contact> contacts = [SELECT Id, FirstName, LastName, Department, Email, EQT_Office__c,
										 RecordTypeId, AccountId 
									FROM Contact Order by Id];
		// Only 4 were created as the last one is not eqt employee
		// Plus 1 already existing
		system.assertEquals(5,contacts.size());
		// These 5 users also have an entry in the Contact Sync Subscription Settings List
		List<EQT_ContactSyncUserSettings__c> usList = [SELECT User__c, LastModifiedDate FROM EQT_ContactSyncUserSettings__c];
		System.assertEquals(5,usList.size());
		/*for(EQT_ContactSyncUserSettings__c us : usList)
			System.debug(us);*/

		for(Integer i = 0; i < 5; i++){
			//System.debug(contacts[i]);

			// These should be equal for all employee contacts
			system.assertEquals(EMPLOYEE_RT_ID, contacts[i].RecordTypeId);
			system.assertEquals(users[i].FirstName, contacts[i].FirstName);
			system.assertEquals(users[i].LastName, contacts[i].LastName);
			system.assertEquals(users[i].Email, contacts[i].Email);
			
			// These are only equal for employee contacts inserted by the trigger, the first contact already existed
			if(i == 0){
				system.assertEquals(eqt.Id, contacts[i].AccountId);
				system.assert(String.isBlank(contacts[i].Department));
				system.assert(String.isBlank(contacts[i].EQT_Office__c));
			}else{
				system.assertEquals(eqt.Id, contacts[i].AccountId);
				system.assertEquals(users[i].Department, contacts[i].Department);
				system.assertEquals(users[i].EQT_Office__c, contacts[i].EQT_Office__c);
				}
		}



	}


}