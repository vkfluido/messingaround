/**
    About
    -----
    Description: REST Service class to call contact sync for users
    Created for: EQT
    Create date: June 2017

    Details / Methods
    -----------------


    Update History
    --------------
    Created June 2017 - R.B.
    Updated July 2017 - fguerrero@fluiogroup.com: EQT_ContactSyncUserSettings__c is now assumed to include all users who need to be included in sync, employee contacts synced by default

    Issues / TODOs
    --------------
*/
@RestResource(urlMapping='/ContactSyncUser/*')
global with sharing class EQT_ContactSyncUser_REST {

    private static Id empRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee'); //01258000000A0OXAA0
    public static Id iaRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName()); //01258000000VN03AAG

    @HttpGet
    global static EQT_ContactSync_Wrapper.UserResponseObj getData() {
        Integer pageSize = 2000;

        EQT_ContactSync_Wrapper.UserResponseObj response = new EQT_ContactSync_Wrapper.UserResponseObj();
        EQT_ContactSync_Wrapper.RequestParams parameters = new EQT_ContactSync_Wrapper.RequestParams();

        String requestParam = RestContext.request.params.get('params');
        system.debug(LoggingLevel.INFO, 'requestParam=' + requestParam);
        
        if (String.isNotEmpty(requestParam)) {
            parameters = (EQT_ContactSync_Wrapper.RequestParams) JSON.deserialize(requestParam, EQT_ContactSync_Wrapper.RequestParams.class);
        }
        
        system.debug(LoggingLevel.INFO, 'object params=' + parameters);

        response = getUsers(parameters.lastcall_timestamp, parameters.index, pageSize);

        return response;
    }

    private static EQT_ContactSync_Wrapper.UserResponseObj getUsers(String csLastModifiedDate, String index, Integer pageSize) {

        EQT_ContactSync_Wrapper.UserResponseObj results = new EQT_ContactSync_Wrapper.UserResponseObj();
        results.users = new List<EQT_ContactSync_Wrapper.UserInfo>();

        // IF a) the request does not include the Last Modified Date
        // OR b) there are Employee Contacts that have changed since the Time Stamp
        // Then retrieve all users
        Datetime lastModifiedDate;
        Boolean doGetAllUsers = String.isBlank(csLastModifiedDate); // check if a) is true
        Map<Id,Boolean> contactRTUpdates = new Map<Id,Boolean>{
                                                    empRTId => false,
                                                    iaRTId => false
                                            };
        if(!doGetAllUsers){
            lastModifiedDate = (DateTime)JSON.deserialize('"'+csLastModifiedDate+'"', DateTime.class);
            System.debug('TimeStamp: ' + lastModifiedDate);
            System.debug(contactRTUpdates.keySet());
            // check if b) is true // also get if there are updated IAs
            AggregateResult[] contactRTCount = [SELECT RecordTypeId, Count(Id) FROM Contact 
                                                 WHERE RecordTypeId IN :contactRTUpdates.keySet()
                                                   AND EQT_Contact_Sync_Last_Modified_Date__c > :lastModifiedDate
                                                 GROUP BY RecordTypeId];
            for( AggregateResult rtCount : contactRTCount ){
                contactRTUpdates.put((Id)rtCount.get('RecordTypeId'),(Integer)rtCount.get('expr0') > 0);
            }
            if(contactRTUpdates.containsKey(empRTId))
                doGetAllUsers = contactRTUpdates.get(empRTId);
        }
        Integer counter = 1;
        String indexId = (index==null?'000000000000000':index);

        if(doGetAllUsers){
            // when a) and b) are true, all users are returned
            for(User u : [SELECT Id, EQT_SSO_User_Id__c, Username, isActive, LastModifiedDate FROM User WHERE Id > :indexId Order By Id]) {
                results.users.add(new EQT_ContactSync_Wrapper.UserInfo(u));
                if(counter == pageSize) {
                    results.indexToStartWith = u.Id;
                    break;
                }
                counter++;
            }
        }else{
            // Retrieve only those users whose subscriptions have changed
            Map<Id, Datetime> userMap = new Map<Id, Datetime>();
            // If there are changes on IA Contacts, retrieve all users that have Opted In
            if(contactRTUpdates.containsKey(iaRTId) && contactRTUpdates.get(iaRTId))
                for(EQT_ContactSyncUserSettings__c cs : [  SELECT User__c, LastModifiedDate FROM EQT_ContactSyncUserSettings__c
                                            WHERE Opt_in_All_IAs__c = true AND User__c > :indexId
                                            ORDER BY User__c ]) {
                    Id userId = cs.User__c;
                    Datetime lastModified = cs.LastModifiedDate;
                    if(!userMap.containsKey(userId) || (userMap.get(userId) < lastModified))
                        userMap.put(userId,lastModified);
                }
            else // If no changes, verify new subscriptions to All IA's
                for(EQT_ContactSyncUserSettings__c cs : [  SELECT User__c, LastModifiedDate FROM EQT_ContactSyncUserSettings__c
                                            WHERE Opt_in_All_IAs__c = true AND User__c > :indexId AND LastModifiedDate > :lastModifiedDate
                                            ORDER BY User__c ]){
                    Id userId = cs.User__c;
                    Datetime lastModified = cs.LastModifiedDate;
                    if(!userMap.containsKey(userId) || (userMap.get(userId) < lastModified))
                        userMap.put(userId,lastModified);
                }
            

            // Retrieve what sectors have Contacts that have been updated since TimeStamp
            Set<Id> updatedSectors = new Set<Id>();
            for(AggregateResult ar : [ SELECT Sector__c, Sector__r.Name, Count(Contact__c) 
                                        FROM EQT_Sector_Rating__c
                                        WHERE Sector__c IN (SELECT Sector__c FROM EQT_ContactSyncSectorSubscription__c)
                                        AND Contact__r.EQT_Contact_Sync_Last_Modified_Date__c > :lastModifiedDate
                                        GROUP BY Sector__c, Sector__r.Name ]){
                Id sectorId = (Id)ar.get('Sector__c');
                if((Integer)ar.get('expr0') > 0)
                    updatedSectors.add(sectorId);
            }
            // Get users subscribed to those sectors OR that were updated since TimeStamp
            for(EQT_ContactSyncSectorSubscription__c sub : [ 
                                        SELECT User__c, LastModifiedDate FROM EQT_ContactSyncSectorSubscription__c
                                        WHERE (Sector__c IN :updatedSectors 
                                                OR (Sector__c <> NULL AND LastModifiedDate > :lastModifiedDate))
                                                AND User__c > :indexId AND User__c NOT IN :userMap.keyset()
                                        ORDER BY User__c ]){
                Id userId = sub.User__c;
                Datetime lastModified = sub.LastModifiedDate;
                if(!userMap.containsKey(userId) || (userMap.get(userId) < lastModified))
                    userMap.put(userId,lastModified);
            }

            // Retrieve Individual Subscriptions for users with recently updated subscriptions or subscribed to recently updated contacts
            for(AggregateResult ar : [SELECT User__c, MIN(LastModifiedDate) from EQT_ContactSyncSubscription__c
                                        WHERE (Contact__r.EQT_Contact_Sync_Last_Modified_Date__c > :lastModifiedDate
                                                OR (Contact__c <> NULL AND LastModifiedDate > :lastModifiedDate))
                                                AND User__c > :indexId AND User__c NOT IN :userMap.keyset()
                                        GROUP BY User__c ORDER BY User__c ]){
                Id userId = (Id)ar.get('User__c');
                Datetime lastModified = (Datetime)ar.get('expr0');
                if(!userMap.containsKey(userId) || (userMap.get(userId) < lastModified))
                    userMap.put(userId,lastModified);
            }

            for(User u : [SELECT Id, EQT_SSO_User_Id__c, Username, isActive FROM User WHERE Id IN :userMap.keySet() Order By Id]) {
                results.users.add(new EQT_ContactSync_Wrapper.UserInfo(
                    u.EQT_SSO_User_Id__c,
                    u.Username,
                    u.isActive,
                    userMap.get(u.Id)
                    ));
                if(counter == pageSize) {
                    results.indexToStartWith = u.Id;
                    break;
                }
                counter++;
            }
        }

        return results;
    }
}