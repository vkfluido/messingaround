public class EQT_ContactSyncController {
    @AuraEnabled
    public static String getInitializationInfo(Id activeRecordId) {
        // figure out if we are allowed to managed on behalf of
        final boolean manageOnBehalf = manageOnBehalfOf();
        
        // get subscription status
        final boolean subscriptionStatus = getSubscriptionStatus(activeRecordId);
        
        // is this user opted into all IA's
        final boolean optinAllIAs = optinAllIAsStatus();

        // get list of subscribson by secotr
        final List<String> existingSectorSubscrption = getSubscriptionBySectorStatus();

        // get list of available sectors
        List<EQT_Sector__c> availSectors = getAvailableSectors();
        
        // get Id of Subscription Report
        Id reportId;
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where DeveloperName = 'Report_Contact_Sync_Subscriptions'];
        if(reportList.size()>0){
            reportId = reportList[0].Id;
        }
        // return
        InitializationData obj = new InitializationData();
        obj.subscriptionStatus = subscriptionStatus;
        obj.manageOnBehalf = manageOnBehalf;
        obj.optinAllIAs = optinAllIAs;
        obj.optinBySectorIAs = existingSectorSubscrption.size()>0 ? String.join(existingSectorSubscrption, ';') : '';
        obj.availableSectors = availSectors;
        obj.contactSyncReportId = reportId;
        return JSON.serialize(obj);
    }
    
    @AuraEnabled
    public static String optinAllIAs(boolean optinAllIAs, List<String> userIds) {
        // define result
		AllIAsResult result = new AllIAsResult();
        result.optin = optinAllIAs;
        
        // sanity
        if (null != userIds && userIds.size() > 0) {
            // user sent us userids meaning an opt-in/out request onbehalf - check 
            // user is allowed to work onbehalf
            if (!manageOnBehalfOf()) {
                // user is not allowed - throw exception
                throw new AuraHandledException('You are not allowed to work onbehalf of others');
            }
            result.allowOnBehalf = true;
            
            // query
            List<EQT_ContactSyncUserSettings__c> objects = [select Id,Opt_in_All_IAs__c,User__c from EQT_ContactSyncUserSettings__c where user__c in :userIds order by user__r.Id asc];
            if (!optinAllIAs) {
                // opt out of all IAs for all users - simply update objects we found and update
                for (EQT_ContactSyncUserSettings__c obj : objects) {
                    obj.Opt_in_All_IAs__c = false;
                }
                update objects;
                
            } else {
                // loop objects and see if we can find objects for some users - if we can 
                // update the status and if not create the junction object
                userIds.sort();
                List<EQT_ContactSyncUserSettings__c> objectsToInsert = new List<EQT_ContactSyncUserSettings__c>();
                List<EQT_ContactSyncUserSettings__c> objectsToUpdate = new List<EQT_ContactSyncUserSettings__c>();
                for (String userId : userIds) {
                    boolean found = false;
                    for (EQT_ContactSyncUserSettings__c obj : objects) {
                        if (obj.User__c.equals(userId)) {
                            // found
                            obj.Opt_in_All_IAs__c = optinAllIAs;
                            objectsToUpdate.add(obj);
                            result.updated.add(userId);
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        // not found - create
						EQT_ContactSyncUserSettings__c obj = new EQT_ContactSyncUserSettings__c();
                        obj.Opt_in_All_IAs__c = optinAllIAs;
                        obj.User__c = userId;
						objectsToInsert.add(obj);
                        result.inserted.add(userId);
                    }
                }
                
                // insert and update objects
                insert objectsToInsert;
                update objectsToUpdate;
            }
            
        } else {
            // no userids supplied - user is working for him/her self
        	// update data model
            List<EQT_ContactSyncUserSettings__c> settings = [select Id,Opt_in_All_IAs__c,User__c from EQT_ContactSyncUserSettings__c];
            if (settings.size() == 0) {
                EQT_ContactSyncUserSettings__c setting = new EQT_ContactSyncUserSettings__c();
                setting.Opt_in_All_IAs__c = optinAllIAs;
                setting.User__c = UserInfo.getUserId();
                insert setting;
                
            } else if (settings.size() != 0) {
                EQT_ContactSyncUserSettings__c setting = settings[0];
                setting.Opt_in_All_IAs__c = optinAllIAs;
                setting.User__c = UserInfo.getUserId();
                update setting;
                
            }
        }
        
        // serialize result back to caller
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static void optinBySectorIAs(String optinBySectorIAs, List<String> userIds, boolean optinIAs) {
        system.debug('optinBySectorIAs: ' + optinBySectorIAs);

        List<String> sectorIds = optinBySectorIAs.split(';');
        Set<String> optinSectorIdsSet = new Set<String>();
        for(String secorId : sectorIds){
            optinSectorIdsSet.add(secorId);
        }

        // sanity
        if (null != userIds && userIds.size() > 0) {
            // user sent us userids meaning an opt-in/out request onbehalf - check 
            // user is allowed to work onbehalf
            system.debug('opt in/out by sector multiple users ');

            if (!manageOnBehalfOf()) {
                // user is not allowed - throw exception
                throw new AuraHandledException('You are not allowed to work onbehalf of others');
            }

            List<EQT_ContactSyncSectorSubscription__c> existingSubscriptionList = [
                SELECT Id, Sector__c, User__c
                FROM EQT_ContactSyncSectorSubscription__c
                WHERE User__c IN :userIds AND Sector__c IN :optinSectorIdsSet
                ORDER BY User__c
            ];

            system.debug('existingSubscriptionList: ' + existingSubscriptionList);

            if(optinIAs==false){ // opt out
                delete existingSubscriptionList;
                return;
            }

            // opt in
            Map<String, Map<String, EQT_ContactSyncSectorSubscription__c>> existingSubsriptionMap = new Map<String, Map<String, EQT_ContactSyncSectorSubscription__c>>();
            // map <User__c, Map <Sector__c, EQT_ContactSyncSectorSubscription__c>>
            for(EQT_ContactSyncSectorSubscription__c tmpExistingSub : existingSubscriptionList){
                
                if( !existingSubsriptionMap.containsKey(tmpExistingSub.User__c) ){
                    existingSubsriptionMap.put(tmpExistingSub.User__c, new Map<String, EQT_ContactSyncSectorSubscription__c>() );
                }

                existingSubsriptionMap.get(tmpExistingSub.User__c).put(tmpExistingSub.Sector__c, tmpExistingSub);
            }

            List<EQT_ContactSyncSectorSubscription__c> subscriptionForInsert = new List<EQT_ContactSyncSectorSubscription__c>();
            for(String userId : userIds){
                
                Map<String, EQT_ContactSyncSectorSubscription__c> existingSubscriptionForUserMap = existingSubsriptionMap.get(userId);

                for(String sectorId : optinSectorIdsSet){
                    // create record for each sector if doesn't exists
                    if( existingSubscriptionForUserMap!=null && existingSubscriptionForUserMap.containsKey(sectorId) ){
                        continue; // skip creating because already existis
                    }

                    EQT_ContactSyncSectorSubscription__c newSubscription = new EQT_ContactSyncSectorSubscription__c();

                    newSubscription.Sector__c = sectorId;
                    newSubscription.User__c = userId;

                    subscriptionForInsert.add(newSubscription);
                }

            }

            if( !subscriptionForInsert.isEmpty() ){
                try {
                    insert subscriptionForInsert;
                } catch (Exception e){
                    throw new AuraHandledException('Unable to insert subscription');
                }
            }
        } else {
            // no userids supplied - user is working for him/her self
            system.debug('opt in/out by sector single users ');

            List<EQT_ContactSyncSectorSubscription__c> existingSubscriptionList = [
                SELECT Id, Sector__c, User__c
                FROM EQT_ContactSyncSectorSubscription__c
                WHERE User__c = :UserInfo.getUserId()
            ];

            system.debug('existingSubscriptionList: ' + existingSubscriptionList);

            if(optinBySectorIAs==null || optinBySectorIAs.length()==0){
                delete existingSubscriptionList;
                return;
            }

            // find existing subscriptions for delete
            List<EQT_ContactSyncSectorSubscription__c> subscriptionForDelete = new List<EQT_ContactSyncSectorSubscription__c>();

            for(EQT_ContactSyncSectorSubscription__c existingSubscription : existingSubscriptionList){
                if( !optinSectorIdsSet.contains(existingSubscription.Sector__c) ){
                    subscriptionForDelete.add(existingSubscription);
                }
            }
            system.debug('subscriptionForDelete: ' + subscriptionForDelete);

            // find subscriptions for insert
            List<EQT_ContactSyncSectorSubscription__c> subscriptionForInsert = new List<EQT_ContactSyncSectorSubscription__c>();

            Set<String> existingSectorIdsSet = new Set<String>();
            for(EQT_ContactSyncSectorSubscription__c subscription : existingSubscriptionList){
                existingSectorIdsSet.add( subscription.Sector__c );
            }

            for(String optinSectorId : optinSectorIdsSet){
                if( existingSectorIdsSet.contains(optinSectorId) ){
                    continue;
                }

                EQT_ContactSyncSectorSubscription__c newSubscription = new EQT_ContactSyncSectorSubscription__c();

                newSubscription.Sector__c = optinSectorId;
                newSubscription.User__c = UserInfo.getUserId();

                subscriptionForInsert.add(newSubscription);
            }

            system.debug('subscriptionForInsert: ' + subscriptionForInsert);

            try {
                if (!subscriptionForDelete.isEmpty()) {
                    delete subscriptionForDelete;
                }
                if (!subscriptionForInsert.isEmpty()) {
                    insert subscriptionForInsert;
                }
            } catch (Exception e){
                throw new AuraHandledException('Unable to insert or delete subscription');
            }
        }

        return;
    }
    
    @AuraEnabled
    public static String setSubscriptionStatus(Id contactId, boolean subscribe, List<String> userIds) {
        final SubscriptionResult result = new SubscriptionResult();
        result.contactId = contactId;
        
        // sanity
        if (null == contactId) {
            throw new AuraHandledException('You must supply a contact ID');
        }
        if (null != userIds && userIds.size() > 0) {
            // user sent us userids meaning a subscription request onbehalf - check 
            // user is allowed to work onbehalf
            if (!manageOnBehalfOf()) {
                // user is not allowed - throw exception
                throw new AuraHandledException('You are not allowed to work onbehalf of others');
            }
            result.allowOnBehalf = true;
            
            // sort supplied userids and query
            userIds.sort();
            List<EQT_ContactSyncSubscription__c> objects = [select user__c from EQT_ContactSyncSubscription__c where contact__c =: contactId and user__c in :userIds order by user__r.Id asc];
            if (!subscribe) {
                // unsubscribing - delete
                for (EQT_ContactSyncSubscription__c obj : objects) result.deleted.add(obj.User__c);
                delete objects;
            } else {
                // loop supplied ids and see if we found them in the db
                List<EQT_ContactSyncSubscription__c> objectsToInsert = new List<EQT_ContactSyncSubscription__c>();
                for (String userId : userIds) {
                    boolean found = false;
                    for (EQT_ContactSyncSubscription__c obj : objects) {
                        if (obj.user__c.equals(userId)) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        // not found - create
						EQT_ContactSyncSubscription__c sub = new EQT_ContactSyncSubscription__c();
						sub.Contact__c = contactId;
						sub.User__c = userId;
						objectsToInsert.add(sub);
                        result.inserted.add(userId);
                    }
                }
                
                // insert result
                insert objectsToInsert;
            }
            
        } else {
            // process current user 
            final String userid = UserInfo.getUserId();
            List<EQT_ContactSyncSubscription__c> ids = [select id from EQT_ContactSyncSubscription__c where contact__c =: contactId and user__c =: userId];
            if (ids.size() == 0 && subscribe) {
                // insert
                EQT_ContactSyncSubscription__c obj = new EQT_ContactSyncSubscription__c();
                obj.Contact__c = contactId;
                obj.User__c = userId;
                result.inserted.add(userId);
                insert obj;
            } else if (ids.size() == 0 && !subscribe) {
                // no records and user is unsubscribing - nothing to do
            } else if (ids.size() != 0 && !subscribe) {
                // user is unsubscribing
                result.deleted.add(userId);
                delete ids;
            }
        }
        
        // return
        return JSON.serialize(result);
    }
    
    private static boolean getSubscriptionStatus(Id contactId) {
        final String userid = UserInfo.getUserId();
        List<EQT_ContactSyncSubscription__c> ids = [select id from EQT_ContactSyncSubscription__c where contact__c =: contactId and user__c =: userId];
        if (ids.size() == 1) {
            // record already present - user subscribe
            return true;
        } else if (ids.size() == 0) {
            // record not found - user does not subscribe
            return false;
        } else {
            // shouldn't be possible - clean up
            List<EQT_ContactSyncSubscription__c> remove = new List<EQT_ContactSyncSubscription__c>();
            for (integer i=1; i<ids.size(); i++) {
                remove.add(ids[i]);
            }
            delete remove;
            
            // return true as user must subscribe
            return true;
        }
    }
    
    private static boolean manageOnBehalfOf() {
        return true;
    }
    
    private static boolean optinAllIAsStatus() {
        final String userid = UserInfo.getUserId();
        List<EQT_ContactSyncUserSettings__c> settings = [select Opt_in_All_IAs__c from EQT_ContactSyncUserSettings__c where User__c =: userid];
        if (null != settings && settings.size() == 1) {
            return settings[0].Opt_in_All_IAs__c;
        }
        return false;
    }

    private static List<String> getSubscriptionBySectorStatus(){
        List<String> sectorSubscriptionList = new List<String>();

        List<EQT_ContactSyncSectorSubscription__c> existingSubscriptionList = [
            SELECT Id, Sector__c, User__c
            FROM EQT_ContactSyncSectorSubscription__c
            WHERE User__c = :UserInfo.getUserId()
        ];

        for(EQT_ContactSyncSectorSubscription__c subscription : existingSubscriptionList){
            sectorSubscriptionList.add(subscription.Sector__c);
        }

        return sectorSubscriptionList;
    }
    
    private static List<EQT_Sector__c> getAvailableSectors(){
        return [SELECT Id, Name FROM EQT_Sector__c ORDER BY Name];
    }
    
    public class InitializationData {
        public String userFullName = UserInfo.getName();
        public Id contactSyncReportId;
        public boolean subscriptionStatus = false;
        public boolean manageOnBehalf = false;
        public boolean optinAllIAs = false;
        public String optinBySectorIAs = '';
        public List<EQT_Sector__c> availableSectors = new List<EQT_Sector__c>();
    }

    /**
     * Utility class used when returning data back to the caller from 
     * the "opt in/out of all IA's".
     */
    private class AllIAsResult {
        public boolean optin = false;
        public boolean allowOnBehalf = false;
        public List<String> inserted = new List<String>();
        public List<String> updated = new List<String>();
    }
    
    private class SubscriptionResult {
        public boolean allowOnBehalf = false;
        public String contactId = null;
        public List<String> inserted = new List<String>();
        public List<String> deleted = new List<String>();
    }
}