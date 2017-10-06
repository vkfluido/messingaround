/**
 *  Trigger handler for users
 *  This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place
 *
 *  Supports the following methods:
 *  - Provision User with a contact: Creates a new Contact with Employee record type based on User Info. Run after User Insert.
 *  - Skip if the contact already exists or profile is 'System Administrator','Integration User' and employee number is empty (contractors, consultants, etc.).
 *	- Adds new Employee users to the EQT_ContactSyncUserSettings__c table so that they can get all employee contacts synced as default.
 *
 *  @author Felix Guerrero
 *  @author Vadim Koroliov
 *  @version 1.1
 *
 * */
global class EQT_UserHandler implements EQT_ITrigger{
	public static final String EMPLOYEE_RT_ID;
	private List<Id> usersIdsToInsertContact = new List<Id>();
	private Set<String> existingContactKeys = new Set<String>();
	private static EQT_Admin_Settings__c settings = EQT_Admin_Settings__c.getOrgDefaults();
	public static Set<Id> adminProfileIds = new Set<Id>();
	static {
		if(EMPLOYEE_RT_ID == null){
			EMPLOYEE_RT_ID = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee');
		}
	}
	/* CONSTRUCTOR */
	public EQT_UserHandler(){}

	/* BULK TRIGGER METHODS */
	public void bulkBefore(){}
    
    public void bulkAfter() {
    	
    	if(Trigger.isInsert){

			/* Contact provisioning */
			if(adminProfileIds.size() == 0){
				List<Profile> pfs = [SELECT Id FROM Profile WHERE Name IN ('System Administrator','Integration User')];
				for(Profile p : pfs)
					adminProfileIds.add(p.Id);
			}

			Set<String> namesSet = new Set<String>();
			Set<String> lastNamesSet = new Set<String>();
			Set<String> emailsSet = new Set<String>();
			
			// Get all names and emails
			for(SObject so : Trigger.new) {
                User u = (User)so;
                //Check first if the new user has a full Salesforce License
				if(u.UserType == 'Standard'){
	                if(adminProfileIds.contains(u.ProfileId) && String.isBlank(u.EmployeeNumber)){
	                	// Check if User has System Administrator profile
						// The contact is created only if the 'employee number' field is populated	
	                }else{
	                	usersIdsToInsertContact.add(u.Id);

	                	namesSet.add(u.FirstName);
			    		lastNamesSet.add(u.LastName);
			    		emailsSet.add(u.Email);
	                }
	            }
            }

            // Assemble a set of existing contacts by a "key" = Email+LastName+FirstName;
			existingContactKeys.addAll(employeeContactMatches(namesSet, lastNamesSet, emailsSet));
    	}
    }

    /* PER RECORD TRIGGER METHODS */
    public void beforeInsert(SObject so){}
    public void beforeUpdate(SObject old_so, SObject new_so){}
    public void beforeDelete(SObject so){}

	public void afterInsert(SObject so) {}
	public void afterUpdate(SObject old_so, SObject new_so){}
    public void afterDelete(SObject so){}
	
	/* DML Operations */
	public void andFinally(){
		
		createContactsFromUsers(usersIdsToInsertContact,existingContactKeys,EMPLOYEE_RT_ID);
		      
	}

	/**
	 * Provision User with a contact: Creates a new Contact with Employee record type based on User Info
	 * Runs after User Insert
	 *
	 * @param userIds the ids of the user objects
	 * 
	 * */
	@future
	private static void createContactsFromUsers(List<Id> userIds, Set<String> existingContactKeys, String recordTypeId){

		List<user> users = [SELECT FirstName,LastName,Title,Department,Phone,MobilePhone,Email,EQT_Office__c,EQT_Business_Line__c,Street,PostalCode,City,Country,State
							FROM User WHERE Id IN :userIds];
		List<Contact> contactsToInsert = new List<Contact>();
		for(User u : users){

			String matchKey = (u.Email+u.LastName+u.FirstName).toLowerCase();
			// Check if the contact does not exist yet
			if(!existingContactKeys.contains(matchKey)){

				Contact c = EQT_UserHandler.createContactFromUser(u,recordTypeId);		
				// Contact record can be created successfully
				if(c!=null)
					contactsToInsert.add(c);
				else
					System.debug('ERROR: Contact could not be created for user Id '+u.Id+
								 '.\nVerify that a Contact Record Type "EQT_Employee" exists and a "Default Employee Account" in custom settings is valid.');
			}
		}

		addUsersToContactSubscriptionList(userIds);

		/** Insert provisioned user contact's **/
		if(contactsToInsert.size() > 0){
			Integer errors = 0;
			Database.SaveResult[] srList = Database.insert(contactsToInsert, false);
			// Iterate through each returned result
			for (Database.SaveResult sr : srList) {
			    if (!sr.isSuccess()) {
			    	errors++;
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('Fields that affected this error: ' + err.getFields());
			        }
			    }
			}
			System.debug(contactsToInsert.size() + ' Employee Contacts were created successfully and '+ errors + ' failed.');
		}

	}


	private Set<String> employeeContactMatches(Set<String> namesSet, Set<String> lastNamesSet, Set<String> emailsSet){
		//System.debug('employeeContactMatches');
		//Get all contacts that might match the user(s) in name and email and return them as pseudo-unique key strings
		Set<String> matchKeySet = new Set<String>();
		for(Contact c : [SELECT Id,FirstName,LastName,Email FROM Contact 
						  WHERE FirstName in :namesSet
						    AND LastName in :lastNamesSet
						    AND RecordTypeId = :EMPLOYEE_RT_ID
						    AND Email in :emailsSet]){
			String key = c.Email+c.LastName+c.FirstName;
			matchKeySet.add(key.toLowerCase());
			//System.debug(key+':'+c);
		}
		return matchKeySet;
	}

	/**
	 *
	 *
	 * */
	private static Contact createContactFromUser(User u, String recordTypeId){
		Contact newContact;
		try{
			newContact = new Contact(
					FirstName = u.FirstName,
					LastName = u.LastName,
					RecordTypeId = recordTypeId,
					AccountId = settings.Default_EQT_Partners_Employee_Account__c,
					Title = u.Title,
					Department = u.Department,
					Phone = u.Phone,
					MobilePhone = u.MobilePhone,
					Email = u.Email,
					EQT_Office__c = u.EQT_Office__c,
					EQT_Business_Line__c = u.EQT_Business_Line__c,
					MailingStreet = u.Street,
					MailingPostalCode = u.PostalCode,
					MailingCity = u.City,
					MailingCountry = u.Country,
					MailingState = u.State
				);
		}catch(Exception e){
			System.debug(e.getMessage());
		}
		return newContact;
	}

	private static void addUsersToContactSubscriptionList(List<Id> userIds){
		List<EQT_ContactSyncUserSettings__c> newCSUS = new List<EQT_ContactSyncUserSettings__c>();
		for(Id userId : userIds){
			newCSUS.add(new EQT_ContactSyncUserSettings__c(User__c = userId, Opt_in_All_IAs__c = false));
		}
		try{
			insert newCSUS;
		}catch(DmlException e){
			System.debug(e.getMessage());
		}
	}

}