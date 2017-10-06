public without sharing  class EQT_DataTransformation_SVC {
	/*
		Prevent integration from overwriting more recent records held in Salesforce using a standard field "EQT_EPM_LastModifiedDate__c"
		Map matching old to new records is processed. The map is returned to the calling function with the "winner" mapped to the old record
	*/
	public static void acceptOverwriteFromEPM(sObject newObj, Datetime epmLastModDate, Datetime objLastModDate)
	{
		if (!EQT_UTIL_Settings.getDateComparisonDisabled()) 
		{
			String integrationUsername = EQT_UTIL_Settings.getEPMIntegrationUsername();
			String currentUsername = UserInfo.getUserName();
			if (integrationUsername == currentUsername)
			{
				if (epmLastModDate==null) {
					newObj.addError('EQT_EPM_LastModifiedDate__c date field must be supplied to avoid accidental overwrite');
				}
				if (epmLastModDate <= objLastModDate)
				{
					newObj.addError('Record is more recent in Salesforce');
				}
			}
		}
	}

	/*
		Set owner on objects based on EPM Person ID
	*/
	public static void setOwnerByEPMPersonId(Map<sObject,String> sobjsToAssign) 
	{
        System.Debug(LoggingLevel.INFO,'@@ Starting setOwnerByEPMPersonId sobjsToAssign: '+sobjsToAssign);
		// Map provided: Objects to update, Person ID that should match
		// Get the user map based on the person id's provided
		Set<String> epmPersonIDs = new Set<String>();
		for (String epmPersonID : sobjsToAssign.values())
		{
			epmPersonIDs.add(epmPersonID);
		}
		Map<String, User> userMap = lookupUsers_ByEPMPersonId(epmPersonIDs);
        List<User> irDefaultUser = [SELECT Id, Name FROM User WHERE IR_default_user__c = true LIMIT 1];
        System.Debug(LoggingLevel.INFO,'@@ setOwnerByEPMPersonId userMap: '+userMap);
		
		// Set OwnerId
		for (sObject o : sobjsToAssign.keySet())
		{
			String epmPersonID = sobjsToAssign.get(o);
        	System.Debug(LoggingLevel.INFO,'@@ setOwnerByEPMPersonId Object o: '+o);
			
			if (userMap!=null && userMap.containsKey(epmPersonID)) {
        		System.Debug(LoggingLevel.INFO,'@@ setOwnerByEPMPersonId Match to user: '+userMap.get(epmPersonID));
				o.put('OwnerID', userMap.get(epmPersonID).Id);
			}
			else if(!irDefaultUser.isEmpty()) {
				o.put('OwnerID', irDefaultUser[0].Id);
			}

		} 
        System.Debug(LoggingLevel.INFO,'@@ Exiting setOwnerByEPMPersonId sobjsToAssign: '+sobjsToAssign);
    }

    /*
		Set owner on objects based on EQT_EPM_Activity_Owner_UserId 
	*/
    public static void setOwnerByEPMActivityOwnerUserId(Map<sObject, String> sobjsToAssign) {
    	Set<String> activityOwnerIds = new Set<String>();

    	for(String actOwnerId : sobjsToAssign.values()) {
    		activityOwnerIds.add(actOwnerId);
    	}

    	Map<String, User> userMap = new Map<String, User>();
    	List<User> irDefaultUser = [SELECT Id, Name FROM User WHERE IsActive = true AND IR_default_user__c = true LIMIT 1];
    	
    	for(User u : [SELECT Id, EQT_EPM_User_ID__c
    					FROM User
    					WHERE EQT_EPM_User_ID__c IN :activityOwnerIds
    					AND IsActive = true]) {

    		userMap.put(u.EQT_EPM_User_ID__c, u);
    	}

    	//set owner
    	for(sObject o : sobjsToAssign.keySet()) {
    		String actOwnerId = sobjsToAssign.get(o);

    		if(userMap != null && userMap.containsKey(actOwnerId)) {
    			o.put('OwnerId', userMap.get(actOwnerId).Id);
    		}
    		else if(!irDefaultUser.isEmpty()) {
    			o.put('OwnerID', irDefaultUser[0].Id);
    		}
    		else {
    			o.put('OwnerID', UserInfo.getUserId());
    		}
    	}
    }

	/* 
		Find users according to their contact record (EPM Person Id)
	*/
	public static Map<String, User> lookupUsers_ByEPMPersonId(Set<String> EPMPersonIds) 
	{
        System.Debug(LoggingLevel.INFO,'@@ Starting lookupUsers_ByEPMPersonId EPMPersonIds: '+EPMPersonIds);
        System.Debug(LoggingLevel.INFO,'@@ lookupUsers_ByEPMPersonId Contacts: '+[select id,EQT_EPM_PersonID__c, EQT_EPM_User_ID__c from Contact where EQT_EPM_PersonID__c != null]);
        System.Debug(LoggingLevel.INFO,'@@ lookupUsers_ByEPMPersonId Users: '+[select id, EQT_EPM_User_ID__c from User where EQT_EPM_User_ID__c != null]);

		Map<String,Contact> contactsByEPMUserId = new Map<String,Contact>();
		for (Contact c : [select id,EQT_EPM_PersonID__c, EQT_EPM_User_ID__c from Contact where EQT_EPM_PersonID__c in :EPMPersonIds])
		{
			contactsByEPMUserId.put(c.EQT_EPM_User_ID__c,c);
		}
		System.Debug(LoggingLevel.INFO,'@@ lookupUsers_ByEPMPersonId contactsByEPMUserId: '+contactsByEPMUserId);

		Map<String,User> usersByEPMUPersonId = new Map<String,User>();
		for (User u : [select id, EQT_EPM_User_ID__c from User where EQT_EPM_User_ID__c in :contactsByEPMUserId.keySet()])
		{
			System.Debug(LoggingLevel.INFO,'@@ lookupUsers_ByEPMPersonId User with matching EPM User ID: '+u);
			if ((contactsByEPMUserId.get(u.EQT_EPM_User_ID__c)).EQT_EPM_PersonID__c!=null)
			{
				usersByEPMUPersonId.put((contactsByEPMUserId.get(u.EQT_EPM_User_ID__c)).EQT_EPM_PersonID__c,u);
			}
		}
        System.Debug(LoggingLevel.INFO,'@@ Exiting lookupUsers_ByEPMPersonId usersByEPMUPersonId: '+usersByEPMUPersonId);
		return usersByEPMUPersonId;
	}

	/*
		Find user according to the EPM User Id
		Called when inserting Account, Contact and Fund records as the responsileID is the owner of the record (EQT_EPM_User_ID__c on the updated record)
		So this can be used to map the EPM User ID to a User record and set the owner
	* /
	public static Map<String, User> lookupUsers_ByEPMUserId(Set<String> EPMUserIds) 
	{
		Map<String,User> usersByEPMUserId = new Map<String,User>();
		for (User u : [select id, EQT_EPM_User_ID__c from User where EQT_EPM_User_ID__c in :EPMUserIds])
		{
			usersByEPMUserId.put(u.EQT_EPM_User_ID__c,u);
		}
		return usersByEPMUserId;
	}

	/*
		Called when users are inserted into Salesforce or have the EPMUser ID updated on their record
	* /
	public static User[] connectUsersToContact_ByEPMUserId(User[] users) {
		Map<String,User> usersByEPMUserId = new Map<String,User>();
		for (User u : users ){
			usersByEPMUserId.put(u.EQT_EPM_User_ID__c,u);
		}
		for (Contact c : [select id, EQT_EPM_User_ID__c from Contact where EQT_Is_Employee__c = TRUE])
		{
			if (usersByEPMUserId.containsKey(c.EQT_EPM_User_ID__c)) {
				User u  = usersByEPMUserId.get(c.EQT_EPM_User_ID__c);
				u.ContactId = c.Id;
			}
		}
		return usersByEPMUserId.values();
	}
	*/
}