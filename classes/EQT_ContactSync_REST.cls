/**
    About
    -----
    Description: REST Service class to call contact sync
    Created for: EQT
    Create date: May 2017

    Details / Methods
    -----------------


    Update History
    --------------
    Created May 2017 - R.B.
    Restructured September 2017 - Felix Guerrero

    Issues / TODOs
    --------------
*/
@RestResource(urlMapping='/ContactSync/*')
global with sharing class EQT_ContactSync_REST {

    public static Id employeeRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee');
    public static Id iaRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());
    static final Integer pageSize = 2000;//000;
    private static Map<String,Contact> contactListResults;

    @HttpGet
    global static EQT_ContactSync_Wrapper.ResponseObj getData() {
        EQT_ContactSync_Wrapper.ResponseObj response = new EQT_ContactSync_Wrapper.ResponseObj();
        contactListResults = new Map<String,Contact>();
        /*  contacts
            userInfo
                String ssoUserId 
                String userName 
                Boolean isActive 
                String lastModifiedDate
            indexToStartWith */
        EQT_ContactSync_Wrapper.RequestParams parameters;

        String requestParam = RestContext.request.params.get('params');
        system.debug(LoggingLevel.INFO, 'requestParam=' + requestParam);

        Datetime timeStamp; // If null, it means all contacts should be retrieved
        Id userId; // What user should be queried
        User givenUser;
        User nextUser;
        String contactIndex = ''; // At what Autonumber to start the contact list, format: EQT-C-XXXXX
        String userIndex = ''; // At what Id to start the contact list

        if (String.isNotEmpty(requestParam)) {
            parameters = (EQT_ContactSync_Wrapper.RequestParams) JSON.deserialize(requestParam, EQT_ContactSync_Wrapper.RequestParams.class);
            // lastcall_timestamp (Datetime) include only contacts updated since this date, if null: retrieve all subscribed contacts
            // username (String) get contacts for specific user, if null: index defines which user to query
            // index (String array separated by ;) [SalesforceId of User to query for];[Last Contact Autonumber from previous call], if null: start from the user with lowest Id
            System.debug(LoggingLevel.INFO, 'object params=' + parameters);
            if(parameters != null){
                if(String.isNotBlank(parameters.lastcall_timestamp))
                    timeStamp = (DateTime)JSON.deserialize('"'+parameters.lastcall_timestamp+'"', DateTime.class);
                
                if(String.isNotBlank(parameters.username)){
                    // INDIVIDUAL USER
                    List<User> usersByUsername = [SELECT Id, EQT_SSO_User_Id__c, Username, isActive, CreatedDate, LastModifiedDate, (SELECT LastModifiedDate FROM CustomSyncUserConfigurations__r WHERE Opt_in_All_IAs__c = TRUE ORDER BY LastModifiedDate DESC), (SELECT Sector__c, LastModifiedDate FROM ContactSyncSectorSubscriptions__r) FROM User WHERE Username =: parameters.username LIMIT 1];
                    if(usersByUsername.size() == 1){
                        givenUser = usersByUsername[0];
                        userId = givenUser.Id;
                    }
                    else
                        System.debug('!ERROR: no user matched username: '+parameters.username);
                    if(String.isNotBlank(parameters.index) && parameters.index.startsWith('EQT-C'))
                        contactIndex = parameters.index;
                }else{
                    // ITERATING ALL USERS 
                    if(String.isNotBlank(parameters.index)){
                        // HAS INDEX
                        if(parameters.index.contains(';')){
                            String[] indexes = parameters.index.split(';');
                            userId = Id.valueOf(indexes[0]);
                            userIndex = indexes[0];
                            contactIndex = indexes[1];
                        }else{
                            if(parameters.index.startsWith('EQT-C'))
                                contactIndex = parameters.index;
                            else{
                                userId = Id.valueOf(parameters.index);
                                userIndex = parameters.index;
                            }
                        }
                    }
                }
            }
        }
        // If userId was resolved, use it to get User Info
        // otherwise, start from the lowest User Id and set it as User Info
        // indexToStartWith will become the immediate User Id unless there is no higher Id
        if(givenUser==null){
            String userQuery = 'SELECT Id, EQT_SSO_User_Id__c, Username, isActive, CreatedDate, LastModifiedDate, (SELECT LastModifiedDate FROM CustomSyncUserConfigurations__r WHERE Opt_in_All_IAs__c = TRUE ORDER BY LastModifiedDate DESC), (SELECT Sector__c, LastModifiedDate FROM ContactSyncSectorSubscriptions__r) FROM User ';
            userQuery += (userId != null?'WHERE Id >= :userId ':'');
            userQuery += 'ORDER By Id LIMIT 2';
            System.debug('userQuery: '+ userQuery);
        
            List<User> usersByIndex = Database.query(userQuery);
            givenUser = usersByIndex[0];
            userIndex = String.valueOf(givenUser.Id);
            nextUser = (usersByIndex.size()==2?usersByIndex[1]:null);
        }

        response.userInfo = new EQT_ContactSync_Wrapper.UserInfo(givenUser);

        System.debug('timeStamp: '+ timeStamp);
        System.debug('givenUser: '+ givenUser);
        System.debug('CustomSyncUserConfigurations__r: '+givenUser.CustomSyncUserConfigurations__r);
        System.debug('ContactSyncSectorSubscriptions__r: '+givenUser.ContactSyncSectorSubscriptions__r);
        System.debug('contactIndex: '+ contactIndex);
        System.debug('userIndex: '+ userIndex);
        System.debug('response.userInfo: '+ response.userInfo);
/**
    RETRIEVE Employee Subscriptions
 **/
 System.debug('## Retrieving Employee Subscriptions');
        Boolean allEmployeeContacts = (timeStamp == null || givenUser.CreatedDate > timeStamp); // If new user, get all
        for(Contact c : getEmployeeContacts(timeStamp,contactIndex, allEmployeeContacts)){
            contactListResults.put(c.EQT_AutoNumber__c,c);
            System.debug(c.Id+', '+c.EQT_AutoNumber__c+', '+c.FirstName+', '+c.LastName);
        }
/**
    RETRIEVE IA Subscriptions
 **/
  System.debug('## Retrieving IA Subscriptions');
    if(!givenUser.CustomSyncUserConfigurations__r.isEmpty()){
        EQT_ContactSyncUserSettings__c iaSub = givenUser.CustomSyncUserConfigurations__r[0];
        Boolean allIAContacts = (timeStamp == null || iaSub.LastModifiedDate > timeStamp); // If new IA Subscription, get all
        for(Contact c : getIAContacts(timeStamp,contactIndex,allIAContacts)){
            contactListResults.put(c.EQT_AutoNumber__c,c);
            System.debug(c.Id+', '+c.EQT_AutoNumber__c+', '+c.FirstName+', '+c.LastName);
        }
    }else
        System.debug('> The user has not subscribed to All IAs');
/**
    RETRIEVE Sector Subscriptions
 **/
    if(!givenUser.ContactSyncSectorSubscriptions__r.isEmpty()){
        System.debug('## Retrieving Sector Subscriptions');
        Boolean allSectorContacts = (timeStamp == null);
        for(EQT_ContactSyncSectorSubscription__c sectorSub : givenUser.ContactSyncSectorSubscriptions__r)
            allSectorContacts |=  (sectorSub.LastModifiedDate > timeStamp); // If new Sector Subscription, get all. ToDo: get all contacts for recently added sectors only, not all sectors
        for(Contact c : getSectorContacts(userId,timeStamp,contactIndex, allSectorContacts)){
            contactListResults.put(c.EQT_AutoNumber__c,c);
            System.debug(c.Id+', '+c.EQT_AutoNumber__c+', '+c.FirstName+', '+c.LastName);
        }
    }else
        System.debug('> The user has not subscribed to any Sectors');
/**
    RETRIEVE Individual Subscriptions
 **/
        System.debug('## Retrieving Individual Subscriptions');
        Boolean allSubscribedContacts = (timeStamp == null) ;
        for(Contact c : getSubscribedContacts(userId,timeStamp,contactIndex,allSubscribedContacts)){
            contactListResults.put(c.EQT_AutoNumber__c,c);
            System.debug(c.Id+', '+c.EQT_AutoNumber__c+', '+c.FirstName+', '+c.LastName);
        }

    if(!contactListResults.isEmpty()){
        List<String> keys = new List<String>();
        keys.addAll(contactListResults.keySet());
        keys.sort();
        Integer resultSize;
        if(contactListResults.size() > pageSize){
            if(String.isNotBlank(userIndex)) // Keep he same index if there are more results
                response.indexToStartWith = userIndex;
            resultSize = pageSize;
            if(String.isBlank(response.indexToStartWith))
                response.indexToStartWith = '';
            else
                response.indexToStartWith += ';';
            response.indexToStartWith += keys.get(pageSize-1);
        }else{
            if(String.isNotBlank(userIndex)) // Move to next index if done
                response.indexToStartWith = String.valueOf(nextUser.Id);
            resultSize = keys.size();
        }
        List<Contact> sortedContacts = new List<Contact>();
        for(Integer i = 0; i < resultSize; i++){
            sortedContacts.add(contactListResults.get(keys.get(i)));
        }
        response.contacts = sortedContacts;
    }
        

        /*
        //get all users with all contacts
        if (parameters == null) {
            response = getAllContactUsers(null, pageSize, null);
        }
        //prev call was without params but there are more contacts for user to get
        else if(parameters != null && String.isEmpty(parameters.username)
                && String.isEmpty(parameters.lastcall_timestamp) && String.isNotEmpty(parameters.index)) {

            response = getAllContactUsers(null, pageSize, parameters.index);
        }
        //last modification date was set
        else if (parameters     != null && String.isNotEmpty(parameters.lastcall_timestamp)) {
            if (String.isNotEmpty(parameters.username)) {
                response = getContactsForUser(parameters.username, parameters.lastcall_timestamp, pageSize, parameters.index);
            } else {
                response = getAllContactUsers(parameters.lastcall_timestamp, pageSize, parameters.index);
            }   
        } else if (parameters != null && String.isNotEmpty(parameters.username)) {
            response = getContactsForUser(parameters.username, null, pageSize, parameters.index);
        }
        */
        return response;
    }
    /*
    private static EQT_ContactSync_Wrapper.ResponseObj getContactsForUser(String userName, String csLastModifiedDate, Integer pageSize, String index) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> subscribedContactIds = new Set<Id>();
        Boolean allIAs = false;
        EQT_ContactSync_Wrapper.ResponseObj response = new EQT_ContactSync_Wrapper.ResponseObj();

        User givenUser;
        try {
            givenUser = [SELECT Id, EQT_SSO_User_Id__c, Username, IsActive, LastModifiedDate FROM User WHERE Username = :userName];
        } catch (Exception e) {
            system.debug(LoggingLevel.INFO, 'User not found for username="' + userName + '"');
            return response;
        }

        String subscriptionQuery = 'SELECT Id, Contact__c FROM EQT_ContactSyncSubscription__c WHERE User__c = \'' + givenUser.Id + '\'';

        if(String.isNotEmpty(csLastModifiedDate)) {
            subscriptionQuery += ' AND LastModifiedDate > ' + csLastModifiedDate;
        }

        system.debug(LoggingLevel.INFO, 'Subscription query=' + subscriptionQuery);

        for (EQT_ContactSyncSubscription__c cs : Database.query(subscriptionQuery)) {
            contactIds.add(cs.Contact__c);
            subscribedContactIds.add(cs.Contact__c);
        }

        //get all contact of type employees
        contactIds.addAll(getEmployeeContactIds(employeeRTId));

        //get sync user settings
        allIAs = getSyncUserSetting(givenUser);

        if (allIAs) {
            contactIds.addAll(getIAContactIds(iaRTId));
        } else {
            contactIds.addAll(getSectorContactIds(givenUser.Id));
        }

        String contactQuery = 'SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,' +
                'Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,' +
                'OtherAddress, EQT_Alternative_Address__c ' +
                'FROM Contact';

        String recordCountQuery = 'SELECT count() FROM Contact';

        if (String.isEmpty(index)) {
            if(String.isNotEmpty(csLastModifiedDate)) {
                contactQuery += ' WHERE (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                recordCountQuery += ' WHERE (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';

                if(!subscribedContactIds.isEmpty()) {
                    contactQuery += ' OR Id IN :subscribedContactIds';
                    recordCountQuery += ' OR Id IN :subscribedContactIds';
                }
            }
            else {
                contactQuery += ' WHERE Id IN :contactIds';
                recordCountQuery += ' WHERE Id IN :contactIds';
            }

            contactQuery += ' ORDER BY EQT_AutoNumber__c LIMIT :pageSize';

            system.debug(LoggingLevel.INFO, 'Contact query=' + contactQuery);
            system.debug(LoggingLevel.INFO, 'Record count query=' + recordCountQuery);

            Integer recordsCount = Database.countQuery(recordCountQuery);

            response.contacts = Database.query(contactQuery);

            if (!response.contacts.isEmpty() && recordsCount > pageSize) {
                response.indexToStartWith = response.contacts[response.contacts.size() - 1].EQT_AutoNumber__c;
            }
        } else {
            contactQuery += ' WHERE EQT_AutoNumber__c > :index';
            recordCountQuery += ' WHERE EQT_AutoNumber__c > :index';

            if(String.isNotEmpty(csLastModifiedDate)) {
                if(!subscribedContactIds.isEmpty()) {
                    contactQuery += ' AND ((Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                    contactQuery += ' OR Id IN :subscribedContactIds)';

                    recordCountQuery += ' AND ((Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                    recordCountQuery += ' OR Id IN :subscribedContactIds)';
                }
                else {
                    contactQuery += ' AND (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                    recordCountQuery += ' AND (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                }
            }
            else {
                contactQuery += ' AND Id IN :contactIds';
                recordCountQuery += ' AND Id IN :contactIds';
            }

            contactQuery += ' ORDER BY EQT_AutoNumber__c LIMIT :pageSize';

            system.debug(LoggingLevel.INFO, 'Contact query=' + contactQuery);
            system.debug(LoggingLevel.INFO, 'Record count query=' + recordCountQuery);

            Integer recordsCount = Database.countQuery(recordCountQuery);

            response.contacts = Database.query(contactQuery);

            if (!response.contacts.isEmpty() && recordsCount > pageSize) {
                response.indexToStartWith = response.contacts[response.contacts.size() - 1].EQT_AutoNumber__c;
            }
        }

        response.userInfo = new EQT_ContactSync_Wrapper.UserInfo(givenUser);

        return response;
    }

    private static EQT_ContactSync_Wrapper.ResponseObj getAllContactUsers(String csLastModifiedDate, Integer pageSize, String index) {
        EQT_ContactSync_Wrapper.ResponseObj response = new EQT_ContactSync_Wrapper.ResponseObj();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> subscribedContactIds = new Set<Id>();
        Map<String, Set<String>> userContactMap = new Map<String, Set<String>>();
        Map<String, Boolean> userSyncIAMap = new Map<String, Boolean>();
        String contactAutoNumber;
        Boolean allIAs = false;
        List<EQT_ContactSyncSubscription__c> subscriptions;
        List<User> users;
        User givenUser;
        String userId;

        if(String.isEmpty(index)) {
            //get first 2 users order by user Id
            users = [SELECT Id, EQT_SSO_User_Id__c, Username, IsActive, LastModifiedDate FROM User ORDER BY Id LIMIT 2];
            if(!users.isEmpty()) {
                givenUser = users[0];
            }
            else {
                return response;
            }
        }
        else {
            //as index can be userId or userId;last contact autonumber field, check which of those we deal with
            List<String> indexParams = index.split(';');

            if(indexParams.size() == 1) {
                userId = indexParams[0];
            }
            else {
                userId = indexParams[0];
                contactAutoNumber = indexParams[1];
            }
        }

        //get given user details
        if(givenUser == null) {
            givenUser = [SELECT Id, EQT_SSO_User_Id__c, Username, IsActive, LastModifiedDate FROM User WHERE Id = :userId];
        }

        //get Contact subscription set
        String subscriptionQuery = 'SELECT Id, Contact__c, User__c FROM EQT_ContactSyncSubscription__c WHERE User__c = \'' + givenUser.Id + '\'';

        if(String.isNotEmpty(csLastModifiedDate)) {
            subscriptionQuery += ' AND LastModifiedDate > ' + csLastModifiedDate;
        }

        system.debug(LoggingLevel.INFO, 'Subscription query=' + subscriptionQuery);

        for (EQT_ContactSyncSubscription__c cs : Database.query(subscriptionQuery)) {
            contactIds.add(cs.Contact__c);
            subscribedContactIds.add(cs.Contact__c);
        }

        //get sync user settings
        allIAs = getSyncUserSetting(givenUser);

        //get all contact of type employees
        contactIds.addAll(getEmployeeContactIds(employeeRTId));

        if (allIAs) {
            contactIds.addAll(getIAContactIds(iaRTId));
        } else {
            contactIds.addAll(getSectorContactIds(givenUser.Id));
        }

        system.debug(LoggingLevel.INFO, 'contactIds size=' + contactIds.size());

        String contactQuery = 'SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,' +
                ' Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,' +
                ' OtherAddress, EQT_Alternative_Address__c' +
                ' FROM Contact';

        //build response result
        if (String.isEmpty(index)) { //first call
            //build contact map

            if(String.isNotEmpty(csLastModifiedDate)) {
                contactQuery += ' WHERE (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';

                if(!subscribedContactIds.isEmpty()) {
                    contactQuery += ' OR Id IN :subscribedContactIds';
                }
            }
            else {
                contactQuery += ' WHERE Id IN :contactIds';
            }

            contactQuery += ' ORDER BY EQT_AutoNumber__c';

            system.debug(LoggingLevel.INFO, 'Contact query=' + contactQuery);

            Integer counter = 1;
            String contactLastIndex;

            response = new EQT_ContactSync_Wrapper.ResponseObj();
            response.userInfo = new EQT_ContactSync_Wrapper.UserInfo(givenUser);
            response.contacts = new List<Contact>();

            for(Contact c : Database.query(contactQuery)) {
                if(counter > pageSize) {
                    break;
                }
                else {
                    response.contacts.add(c);
                    contactLastIndex = c.EQT_AutoNumber__c;
                }
                counter++;
            }


            //if there are more contact records for given user, set proper index for next process
            if (counter > pageSize) {
                response.indexToStartWith = givenUser.Id + ';' + contactLastIndex;
            }
            else {
                //set next user
                if(users.size() == 2) {
                    response.indexToStartWith = users[1].Id;
                }
            }
        }
        //second call with index param
        else {
            //build contact map
            contactQuery += ' WHERE EQT_AutoNumber__c > :contactAutoNumber';

            if(String.isNotEmpty(csLastModifiedDate)) {
                if(!subscribedContactIds.isEmpty()) {
                    contactQuery += ' AND ((Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                    contactQuery += ' OR Id IN :subscribedContactIds)';
                }
                else {
                    contactQuery += ' AND (Id IN :contactIds AND EQT_Contact_Sync_Last_Modified_Date__c >' + csLastModifiedDate + ')';
                }
            }
            else {
                contactQuery += ' AND Id IN :contactIds';
            }

            contactQuery += ' ORDER BY EQT_AutoNumber__c';

            system.debug(LoggingLevel.INFO, 'Contact query=' + contactQuery);

            Integer counter = 1;
            String contactLastIndex;

            response = new EQT_ContactSync_Wrapper.ResponseObj();
            response.userInfo = new EQT_ContactSync_Wrapper.UserInfo(givenUser);
            response.contacts = new List<Contact>();

            for(Contact c : Database.query(contactQuery)) {
                if(counter > pageSize) {
                    break;
                }
                else {
                    response.contacts.add(c);
                    contactLastIndex = c.EQT_AutoNumber__c;
                }
                counter++;
            }

            //if there are more records for given user, set proper start index
            if (counter > pageSize) {
                response.indexToStartWith = givenUser.Id + ';' + contactLastIndex;
            } else {
                //get next user from User table
                List<User> userList = [SELECT Id FROM User WHERE Id > :givenUser.Id ORDER BY Id LIMIT 1];

                if(!userList.isEmpty()) {
                    response.indexToStartWith = userList[0].Id;
                }
            }
        }

        return response;
    }
*/
    private static List<Contact> getEmployeeContacts(DateTime timeStamp, String index, Boolean allContacts) {
        Set<String> indexFilter = contactListResults.keySet();
        String contactQuery = 'SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,' +
                              ' Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,' +
                              ' OtherAddress, EQT_Alternative_Address__c' +
                              ' FROM Contact WHERE RecordTypeId = :employeeRTId AND EQT_Ex_Employee__c = FALSE ';
        contactQuery += (String.isBlank(index)?'':'AND EQT_AutoNumber__c > :index ');
        contactQuery += ' AND EQT_AutoNumber__c NOT IN : indexFilter ';
        contactQuery += (allContacts?'':' AND EQT_Contact_Sync_Last_Modified_Date__c > :timeStamp ');
        contactQuery += 'ORDER BY EQT_AutoNumber__c LIMIT :pageSize';
        //System.debug(contactQuery);
        return Database.query(contactQuery);
    }

    private static List<Contact> getIAContacts(DateTime timeStamp, String index, Boolean allContacts) {
        Set<String> indexFilter = contactListResults.keySet();
        String contactQuery = 'SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,' +
                              ' Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,' +
                              ' OtherAddress, EQT_Alternative_Address__c' +
                              ' FROM Contact WHERE RecordTypeId = :iaRTId ';
        contactQuery += (String.isBlank(index)?'':'AND EQT_AutoNumber__c > :index ');
        contactQuery += ' AND EQT_AutoNumber__c NOT IN :indexFilter ';
        contactQuery += (allContacts?'':'AND EQT_Contact_Sync_Last_Modified_Date__c > :timeStamp ');
        contactQuery += 'ORDER BY EQT_AutoNumber__c LIMIT :pageSize';

        return Database.query(contactQuery);
    }

    private static List<Contact> getSectorContacts(Id userId, DateTime timeStamp, String index, Boolean allContacts) {
        Set<String> indexFilter = contactListResults.keySet();
        String contactQuery = 'SELECT Contact__c FROM EQT_Sector_Rating__c' +
                              ' WHERE Sector__c IN (SELECT Sector__c FROM EQT_ContactSyncSectorSubscription__c WHERE User__c = :userId)';
        contactQuery += (String.isBlank(index)?'':' AND Contact__r.EQT_AutoNumber__c > :index ');
        contactQuery += ' AND Contact__r.EQT_AutoNumber__c NOT IN :indexFilter ';
        contactQuery += (allContacts?'':' AND Contact__r.EQT_Contact_Sync_Last_Modified_Date__c > :timeStamp ');
        contactQuery += 'GROUP BY Contact__c';
        //System.debug(contactQuery);
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactList = new List<Contact>();
        for(AggregateResult ar : Database.query(contactQuery)){
            contactIds.add((Id)ar.get('Contact__c'));
        }

        return [SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,
                Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,
                OtherAddress, EQT_Alternative_Address__c
                FROM Contact WHERE Id IN :contactIds];
    }

    private static List<Contact> getSubscribedContacts(Id userId, DateTime timeStamp, String index, Boolean allContacts) {
        Set<String> indexFilter = contactListResults.keySet();
        String contactQuery = 'SELECT Id, EQT_AutoNumber__c, FirstName, MiddleName, LastName, Account.Name, Title,' +
                              ' Phone, MobilePhone, OtherPhone, Email, EQT_Email_2__c, EQT_Email_3__c, MailingAddress,' +
                              ' OtherAddress, EQT_Alternative_Address__c' +
                              ' FROM Contact WHERE Id IN (SELECT Contact__c FROM EQT_ContactSyncSubscription__c WHERE User__c = :userId ';
        contactQuery += (allContacts?'':' AND (Contact__r.EQT_Contact_Sync_Last_Modified_Date__c > :timeStamp OR LastModifiedDate > :timeStamp) ');
        contactQuery += ' ) ';
        contactQuery += (String.isBlank(index)?'':'AND EQT_AutoNumber__c > :index ');
        contactQuery += ' AND EQT_AutoNumber__c NOT IN : indexFilter ';
        contactQuery += 'ORDER BY EQT_AutoNumber__c LIMIT :pageSize';
        //System.debug(contactQuery);
        return Database.query(contactQuery);
    }
/*
    private static Set<Id> getEmployeeContactIds(String recordTypeId) {
        Set<Id> contactIds = new Set<Id>();

        for (Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :recordTypeId AND EQT_Ex_Employee__c = false]) {
            contactIds.add(c.Id);
        }

        return contactIds;
    }

    private static Set<Id> getIAContactIds(String recordTypeId) {
        Set<Id> contactIds = new Set<Id>();

        for (Contact c : [SELECT Id FROM Contact WHERE RecordTypeId = :recordTypeId]) {
            contactIds.add(c.Id);
        }

        return contactIds;
    }

    private static Set<Id> getSectorContactIds(Id userId) {
        Set<String> sectorIds = new Set<String>();
        Set<Id> contactIds = new Set<Id>();

        for(EQT_ContactSyncSectorSubscription__c sectorSync : [SELECT Sector__c FROM EQT_ContactSyncSectorSubscription__c
                                                                WHERE User__c = :userId]) {
            sectorIds.add(sectorSync.Sector__c);
        }

        if(!sectorIds.isEmpty()) {
            for (EQT_Sector_Rating__c sr : [SELECT Id, Contact__c FROM EQT_Sector_Rating__c WHERE Sector__c IN :sectorIds]) {
                contactIds.add(sr.Contact__c);
            }
        }

        return contactIds;
    }

    private static Boolean getSyncUserSetting(User givenUser) {
        Boolean allIAs = false;

        try {
            allIAs = [SELECT Opt_in_All_IAs__c FROM EQT_ContactSyncUserSettings__c WHERE User__c = :givenUser.Id].Opt_in_All_IAs__c;
        } catch (Exception e) {
            system.debug(LoggingLevel.INFO, 'No contact sync settings for username="' + givenUser.Username + '"');
        }

        return allIAs;
    }*/
}