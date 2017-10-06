/**
    About
    -----
    Description: IA's network search component controller
    Created for: EQT
    Create date: March 2017

    Details / Methods
    -----------------

    Update History
    --------------
    Created March 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_NetworkSearch_LCC {
    public enum SEARCH_TRACKING_TYPE {
        TYPE_ADHOC, TYPE_SHARED, TYPE_SAVED, TYPE_EXPORT
    }
    
    /**
     * Tracks the opening of a contact.
     */
    @AuraEnabled
    public static boolean trackContactOpen(String contactId, String contactName) {
        // validate input
        if (String.isEmpty(contactId) || String.isEmpty(contactName)) {
            throw new AuraHandledException('Must supply both contact id and contact name');
        }
        
        // get user profile and user role
        final String userRole = getCurrentUserRole();
        final String userProfile = getCurrentUserProfile();
        
        // save
        EQT_IANetworkSearch_Track_ContactOpen__c open = new EQT_IANetworkSearch_Track_ContactOpen__c();
        open.Contact__c = contactId;
        open.Name = contactName;
        open.Role_Name__c = userRole;
        open.Profile_Name__c = userProfile;
        insert open;
        return true;
    }
    
    public static String getCurrentUserRole() {
        If (!String.isEmpty(UserInfo.getUserRoleId())) {
            List<UserRole> roles = [select Name from UserRole where id =: UserInfo.getUserRoleId()];
            if (roles.size() >= 1) return roles[0].Name;
        }
        return 'None';
    }
    
    public static String getCurrentUserProfile() {
        If (!String.isEmpty(UserInfo.getProfileId())) {
            List<Profile> profiles = [select Name from Profile where id =: UserInfo.getProfileId()];
            if (profiles.size() >= 1) return profiles[0].Name;
        }
        return 'None';
    }
	
    /**
     * Get all saved searches for the current user.
     */
    @AuraEnabled
    public static List<EQT_IANetworkSearch_Save__c> getSearchesForCurrentUser() {
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Id, Name, Filters__c, Key__c from EQT_IANetworkSearch_Save__c WHERE SavedSearch__c = True AND OwnerId =: UserInfo.getUserId()];
        return searches;
    }
    
    /**
     * Supplied with a key return the base64 encoded filters if found or throw an exception otherwise.
     */
    @AuraEnabled
    public static String getFiltersFromKey(String key) {
        // lookup
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT OwnerId, SavedSearch__c, Filters__c from EQT_IANetworkSearch_Save__c WHERE Key__c =: key];
        if (searches.size() == 1) {
            // get search
            EQT_IANetworkSearch_Save__c search = searches[0];
            
            // if this is a saved search make sure the current user is the owner
            if (search.SavedSearch__c && search.OwnerId != UserInfo.getUserId()) {
                // oooops - a saved search and current user not the owner
                throw new AuraHandledException('Attempting to load a saved search not owned by the current user');
            }
            
            // return filters
            return search.Filters__c;
        }
        
        // throw exception
        throw new AuraHandledException('Unable to find search for key');
    }
    
    /**
     * Save this search for sharing and return the sharing key.
     */
    @AuraEnabled
    public static String shareSearch(String filters) {
        // generate key
        final Blob b = Crypto.GenerateAESKey(128);
		final String usedKey = EncodingUtil.ConvertTohex(b);
        EQT_IANetworkSearch_Save__c obj = new EQT_IANetworkSearch_Save__c();
        obj.Key__c = usedKey;
        obj.Filters__c = filters;
        Database.insert(obj);
        return usedKey;
    }
    
    /**
     * Delete a saved or shared search for the current user.
     */
    @AuraEnabled
    public static boolean deleteSearch(String key) {
        // sanity
        if (String.isEmpty(key)) throw new AuraHandledException('No key supplied');
        
        // find search
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Id from EQT_IANetworkSearch_Save__c WHERE Key__c =: key AND OwnerId =: UserInfo.getUserId()];
        if (searches.size() != 1) {
            throw new AuraHandledException('Unknown key or key doesn\'t below to the user');
        }
        
        // delete
        Database.delete(searches[0]);
        return true;
    }
    
    /**
     * Save or update a saved search for the current user.
     */
    @AuraEnabled
    public static String upsertSearch(String key, String name, String filters) {
        EQT_IANetworkSearch_Save__c obj = null;
        String usedKey = null;
        if (String.isEmpty(filters)) {
            throw new AuraHandledException('Missing filters');
        }
        if (String.isNotEmpty(key)) {
            try {
                obj = [SELECT Id, Name, Filters__c, Key__c from EQT_IANetworkSearch_Save__c WHERE Key__c =: key LIMIT 1];
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Unable to find saved search by key');
                throw new AuraHandledException('Unable to find saved search by key <' + key + '>');
            }
        }
        if (null == obj) {
            Blob b = Crypto.GenerateAESKey(128);
			usedKey = EncodingUtil.ConvertTohex(b);
            obj = new EQT_IANetworkSearch_Save__c();
            obj.Key__c = usedKey;
            obj.SavedSearch__c = true;
        } else {
            usedKey = key;
        }
        obj.Filters__c = filters;
        if (String.isEmpty(name)) {
            Datetime dt = Datetime.now();
            obj.Name = 'Saved search on ' + dt.format('d MMM yyyy HH:mm');
        } else {
            obj.Name = name;
        }
        Database.upsert(obj);
        return usedKey;
    }
    
    /**
     * This is the controller method called from the Lightning component. This method 
     * deserializes the parameters from JSON into objects and forwards the request.
     */
    @AuraEnabled
    public static EQT_NetworkSearch_Wrapper.PageResult searchWithPagination(Map<String, Object> filterParams, Decimal pageNumber, Boolean makeIntersection) {
        return searchWithPagination(filterParams, pageNumber, makeIntersection, false, false, false, false);
    }

    @AuraEnabled
    public static EQT_NetworkSearch_Wrapper.PageResult searchWithPagination(Map<String, Object> filterParams, Decimal pageNumber, Boolean makeIntersection, Boolean includePCCandidates, Boolean includeIACandidates, Boolean sectorTeamRecommendedIAs, Boolean sectorExpertiseRecommendedIAs) {
        // parse
        EQT_NetworkSearch_Wrapper.SearchParams params = (EQT_NetworkSearch_Wrapper.SearchParams) JSON.deserialize(JSON.serialize(filterParams), EQT_NetworkSearch_Wrapper.SearchParams.class);

        // result
        EQT_NetworkSearch_Wrapper.PageResult result = EQT_NetworkSearch_LCC.searchWithPagination2(params, pageNumber, makeIntersection, includePCCandidates, includeIACandidates, sectorTeamRecommendedIAs, sectorExpertiseRecommendedIAs);
        
        try {
            // log
            EQT_NetworkSearch_LCC.logSearch(params, result);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unable to log search due to exception');
        }
        
        // return
        return result;
    }
    
    /**
     * Utility method to perform searching based on parameters.
     */
    public static EQT_NetworkSearch_Wrapper.PageResult searchWithPagination2(EQT_NetworkSearch_Wrapper.SearchParams params, Decimal pageNumber, Boolean makeIntersection, Boolean includePCCandidates, Boolean includeIACandidates, Boolean sectorTeamRecommendedIAs, Boolean sectorExpertiseRecommendedIAs) {
        final Integer pageSize = 100000;
        final Integer offset = ((pageNumber - 1) * pageSize).intValue();
        system.debug(LoggingLevel.INFO, 'params=' + params);

        final Datetime dtStart = Datetime.now();
        Set<Id> contactIds = new Set<Id>();
        Boolean filterSearch = false;

        if(!params.deals.isEmpty()
                || !params.accounts.isEmpty()
                || (params.existingRoles != null && !params.existingRoles.isEmpty())) {

            contactIds = EQT_NetworkSearch_SVC.filterByConnectedObjects(params.deals, params.accounts, params.isBoardMember, params.existingRoles);

            if(!filterSearch) {
                filterSearch = true;
            }
        }

        //filter by sector
        if(params.sectorFilter != null && !params.sectorFilter.isEmpty()) {
            Set<Id> resultIds = EQT_NetworkSearch_SVC.filterBySector(params.sectorFilter, sectorExpertiseRecommendedIAs);

            contactIds = EQT_NetworkSearch_SVC.calculateResultIds(contactIds, resultIds, makeIntersection, filterSearch);

            if(!filterSearch) {
                filterSearch = true;
            }
        }

        //filter by functional
        if(params.functionalFilter != null && !params.functionalFilter.isEmpty()) {
            Set<Id> resultIds = EQT_NetworkSearch_SVC.filterByFunctional(params.functionalFilter);

            contactIds = EQT_NetworkSearch_SVC.calculateResultIds(contactIds, resultIds, makeIntersection, filterSearch);

            if(!filterSearch) {
                filterSearch = true;
            }
        }

        //filter by geographical
        if(params.geoFilter != null && !params.geoFilter.isEmpty()) {
            Set<Id> resultIds = EQT_NetworkSearch_SVC.filterByGeographical(params.geoFilter);

            contactIds = EQT_NetworkSearch_SVC.calculateResultIds(contactIds, resultIds, makeIntersection, filterSearch);

            if(!filterSearch) {
                filterSearch = true;
            }
        }

        // start - network search by sector team
        if(params.sectorTeam != null && !params.sectorTeam.isEmpty() ){
            Set<Id> resultIds = EQT_NetworkSearch_SVC.filterBySectorTeam(params.sectorTeam, sectorTeamRecommendedIAs);

            contactIds = EQT_NetworkSearch_SVC.calculateResultIds(contactIds, resultIds, makeIntersection, filterSearch);

            if(!filterSearch) {
                filterSearch = true;
            }
        }
        // end - network search by sector team

        if(
            (params.suitablePositions != null && !params.suitablePositions.isEmpty()) ||
            (params.engagementLevel != null && !params.engagementLevel.isEmpty()) ||
            (params.residence != null && !params.residence.isEmpty())
        ) {

            // network search by country of residence
            Set<Id> resultIds = EQT_NetworkSearch_SVC.filterByContactFields(params.suitablePositions, params.engagementLevel, params.residence);
			
            contactIds = EQT_NetworkSearch_SVC.calculateResultIds(contactIds, resultIds, makeIntersection, filterSearch);
        }


        //get results
        EQT_NetworkSearch_Wrapper.PageResult result = EQT_NetworkSearch_SVC.loadSearchResultsWithPagination(contactIds, pageSize, offset, includePCCandidates, includeIACandidates);
        result.page = (Integer) pageNumber;
		
        // calc duration
        final Datetime dtEnd = Datetime.now();
        result.duration = dtEnd.getTime() - dtStart.getTime();
        system.debug(LoggingLevel.INFO, 'All queries took: ' + result.duration + ' ms.');
        
        // return
        return result;
    }
    
    public static void logSearch(EQT_NetworkSearch_Wrapper.SearchParams params, EQT_NetworkSearch_Wrapper.PageResult result) {
        final String userRole = getCurrentUserRole();
        final String userProfile = getCurrentUserProfile();
        
        // create main log object
        EQT_IANetworkSearch_Track_Search__c log = new EQT_IANetworkSearch_Track_Search__c();
        log.Profile_Name__c = userProfile;
        log.Role_Name__c = userRole;
        if (2 == params.type) {
            log.Type__c = 'Shared';
        } else if (3 == params.type) {
            log.Type__c = 'Saved';
        } else if (4 == params.type) {
            log.Type__c = 'Export';
        } else {
            log.Type__c = 'Ad-hoc';
        }
        log.Result_Count__c = result.total;
        log.Duration__c = result.duration;
        insert log;
        
        // add filters
        List<sObject> objects = new List<SObject>();
        if (null != params.deals) {
            for (String dealId : params.deals) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = dealId, Name = dealId, ElementType__c = 'deal'
                ));
            }
        }
        if (null != params.accounts) {
            for (String accountId : params.accounts) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = accountId, Name = accountId, ElementType__c = 'account'
                ));
            }
        }
        if (null != params.sectorFilter) {
            for (String sectorId : params.sectorFilter) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = sectorId, Name = sectorId, ElementType__c = 'sector'
                ));
            }
        }
        if (null != params.functionalFilter) {
            for (String funcId : params.functionalFilter) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = funcId, Name = funcId, ElementType__c = 'functional'
                ));
            }
        }
        if (null != params.geoFilter) {
            for (String geoId : params.geoFilter) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = geoId, Name = geoId, ElementType__c = 'geo'
                ));
            }
        }
        if (null != params.suitablePositions) {
            for (String sp : params.suitablePositions) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = sp, Name = sp, ElementType__c = 'suitablePosition'
                ));
            }
        }
        if (null != params.existingRoles) {
            for (String er : params.existingRoles) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = er, Name = er, ElementType__c = 'existingRole'
                ));
            }
        }
        if (null != params.engagementLevel) {
            for (String el : params.engagementLevel) {
                objects.add(new EQT_IANetworkSearch_Track_SearchFilter__c(
                    Search__c=log.Id, ElementId__c = el, Name = el, ElementType__c = 'engagementLevel'
                ));
            }
        }
        
        // insert
        insert objects;
    }

    @AuraEnabled
    public static List<String> getPositions() {
        List<String> options = new List<String>();
        options.addAll(EQT_NetworkSearch_SVC.getPicklistValues(Contact.EQT_Suitable_Positions__c.getDescribe()));

        return options;
    }

    @AuraEnabled
    public static List<String> getRoles() {
        List<String> options = new List<String>();
        options.addAll(EQT_NetworkSearch_SVC.getPicklistValues(EQT_Affiliation__c.Role__c.getDescribe()));

        return options;
    }

    @AuraEnabled
    public static List<String> getEngagementLevels() {
        List<String> options = new List<String>();
        options.addAll(EQT_NetworkSearch_SVC.getPicklistValues(Contact.Engagement_Level__c.getDescribe()));

        return options;
    }

    @AuraEnabled
    public static List<EQT_Competence_SVC.Competence> getSectorCompetences() {
        return EQT_Competence_SVC.loadSectorCompetences();
    }

    @AuraEnabled
    public static List<EQT_Competence_SVC.Competence> getFunctionalCompetences() {
        return EQT_Competence_SVC.loadFunctionalCompetences();
    }

    @AuraEnabled
    public static List<EQT_Competence_SVC.Competence> getGeographicalCompetences() {
        return EQT_Competence_SVC.loadGeographicalCompetences();
    }

    // start - network search by country of residence
    @AuraEnabled
    public static List<String> getCountryOfResidenceCompetences() {
        List<String> options = new List<String>();
        options.addAll(EQT_NetworkSearch_SVC.getPicklistValues(Contact.EQT_Country_of_Residence__c.getDescribe()));

        return options;
    }
    // end - network search by country of residence

    // start - network search by sector team
    @AuraEnabled
    public static List<EQT_Competence_SVC.Competence> getSectoTeamCompetences() {
        return EQT_Competence_SVC.loadSectorTeamCompetences();
    }
    // end - network search by sector team
}