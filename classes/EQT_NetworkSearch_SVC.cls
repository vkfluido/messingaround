/**
    About
    -----
    Description: IA's network search service class
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
public with sharing class EQT_NetworkSearch_SVC {

    public static Set<Id> filterByConnectedObjects(List<String> dealIds, List<String> accountIds, Boolean isBoardMember, List<String> roleFilter) {
        final Set<Id> resultSet = new Set<Id>();
        final Boolean dealParam = !dealIds.isEmpty();
        final Boolean accountParam = !accountIds.isEmpty();
        boolean assignmentQueryFirstWhere = true;
        boolean affiliationQueryFirstWhere = true;
        
        String assignmentQuery = 'SELECT Id, Contact__c FROM EQT_Assignment__c WHERE';
        String affiliationQuery = 'SELECT Id, Contact__c FROM EQT_Affiliation__c WHERE';

        if(dealParam) {
            if(!assignmentQueryFirstWhere) {
                assignmentQuery += ' AND';
            }
            assignmentQuery += ' Project__c IN :dealIds';
            assignmentQueryFirstWhere = false;
        }

        if(accountParam) {
            // look at assignment query
            if (!assignmentQueryFirstWhere) {
                assignmentQuery += ' AND';
            }
            assignmentQuery +=  ' Company__c IN :accountIds';
            assignmentQueryFirstWhere = false;
            
            // look at affiliation query
            if (!affiliationQueryFirstWhere) {
                affiliationQuery += ' AND';
            }
            affiliationQuery += ' Account__c IN :accountIds';
            affiliationQueryFirstWhere = false;
            
            // query add contacts associated with the account
            List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId IN :accountIds];
            resultSet.addAll(fetchIds(contactList, 'Id'));
        }

        if(!roleFilter.isEmpty()) {
            // add role filter to assignment query
            if (!assignmentQueryFirstWhere) {
                assignmentQuery += ' AND';
            }
            assignmentQuery += ' EQT_Role__c IN ' + stringArrayify(roleFilter);
            assignmentQueryFirstWhere = false;
            
            // add role filter to affiliation query
            if (!affiliationQueryFirstWhere) {
                affiliationQuery += ' AND';
            }
            affiliationQuery += ' Role__c IN ' + stringArrayify(roleFilter);
            affiliationQueryFirstWhere = false;
        }
        
        // log and execute queries
        system.debug(LoggingLevel.INFO, 'Assignment query=' + assignmentQuery);
        if (!assignmentQueryFirstWhere) {
            List<EQT_Assignment__c> assignmentList = Database.query(assignmentQuery);
            System.debug('Found ' + assignmentList.size() + ' contacts matching assignment query');
            resultSet.addAll(fetchIds(assignmentList, 'Contact__c'));
        } else {
            System.debug('Ignoring assignment query for contacts as no WHERE clauses added');
        }

        system.debug(LoggingLevel.INFO, 'affiliationQuery query=' + affiliationQuery);
        if (!affiliationQueryFirstWhere) {
            List<EQT_Affiliation__c> affiliationList = Database.query(affiliationQuery);
            System.debug('Found ' + affiliationList.size() + ' contacts matching affiliation query');
            resultSet.addAll(fetchIds(affiliationList, 'Contact__c'));
        } else {
            System.debug('Ignoring affiliation query for contacts as no WHERE clauses added');
        }

        // return
        return resultSet;
    }

    public static Set<Id> filterBySector(List<String> sectorFilter, Boolean sectorExpertiseRecommendedIAs) {
        // log
        System.debug('Received sector filters from caller');
        System.debug(sectorFilter);
        
        // sort filters (will make less specific filters come before more specific ones)
        sectorFilter.sort();
        List<String> specificityChecked = new List<String>();
        for (String s : sectorFilter) {
            boolean ignore = false;
            for (String s2 : specificityChecked) {
                if (s.startsWithIgnoreCase(s2)) {
                    ignore = true;
                    break;
                }
            }
            if (!ignore) specificityChecked.add(s);
        }
        System.debug('Made sure we only have the most unspecific filters left');
        System.debug(specificityChecked);
        
        
        
        
        List<String> sectorIds = new List<String>();
        List<List<String>> sectorSubsectorIds = new List<List<String>>();
        List<List<String>> sectorSubsectorSubsegmentIds = new List<List<String>>();

        for(String s : specificityChecked) {
            System.debug('Processing sector: ' + s);
            List<String> ids = s.split('#');
            if (ids.size() == 1) {
                System.debug('Parameter is a sector id only - adding: ' + ids);
                sectorIds.add(ids[0]);
            }
            if (ids.size() == 2) {
                System.debug('Parameter is a sector/subsector id combo - adding: ' + ids);
                sectorSubsectorIds.add(ids);
            }
            if (ids.size() == 3) {
                System.debug('Parameter is a sector/subsector/subsegment combo - adding: ' + ids);
                sectorSubsectorSubsegmentIds.add(ids);
            }
        }

        // filter
        Set<Id> resultSet = new Set<Id>();
        List<EQT_Sector_Rating__c> sectors;
        List<EQT_Sector_Rating__c> subsectors;
        List<EQT_Sector_Rating__c> segments;

        List<EQT_SectorTeamMemberExpertise__c> sectorsRecommended;
        List<EQT_SectorTeamMemberExpertise__c> subsectorsRecommended;
        List<EQT_SectorTeamMemberExpertise__c> segmentsRecommended;

        if (!sectorSubsectorSubsegmentIds.isEmpty()) {
            final List<String> sIds = new List<String>();
            final List<String> ssIds = new List<String>();
            final List<String> sssIds = new List<String>();
            for (List<String> ss : sectorSubsectorSubsegmentIds) {
                sIds.Add(ss[0]);
                ssIds.Add(ss[1]);
                sssIds.Add(ss[2]);
            }

            if(sectorExpertiseRecommendedIAs){
                segmentsRecommended = [
                        SELECT Sector_Expertise__r.Contact__c
                        FROM EQT_SectorTeamMemberExpertise__c
                        WHERE
                            Sector_Expertise__r.Sector__c IN :sIds AND
                            Sector_Expertise__r.Subsector__c IN :ssIds AND
                            Sector_Expertise__r.Subsector_Segment__c IN :sssIds AND
                            Recommended__c = true
                ];
            } else {
                segments = [SELECT Id, Contact__c FROM EQT_Sector_Rating__c WHERE Sector__c IN :sIds AND Subsector__c IN :ssIds AND Subsector_Segment__c IN :sssIds];
            }
        }
        if(!sectorSubsectorIds.isEmpty()) {
            final List<String> sIds = new List<String>();
            final List<String> ssIds = new List<String>();
            for (List<String> ss : sectorSubsectorIds) {
                sIds.Add(ss[0]);
                ssIds.Add(ss[1]);
            }

            if(sectorExpertiseRecommendedIAs){
                subsectorsRecommended = [
                        SELECT Sector_Expertise__r.Contact__c
                        FROM EQT_SectorTeamMemberExpertise__c
                        WHERE
                            Sector_Expertise__r.Sector__c IN :sIds AND
                            Sector_Expertise__r.Subsector__c IN :ssIds AND
                            Recommended__c = true
                ];
            } else {
                subsectors = [SELECT Id, Contact__c FROM EQT_Sector_Rating__c WHERE Sector__c IN :sIds AND Subsector__c IN :ssIds];
            }
        }
        if (!sectorIds.isEmpty()) {
            if(sectorExpertiseRecommendedIAs){
                sectorsRecommended = [
                        SELECT Sector_Expertise__r.Contact__c
                        FROM EQT_SectorTeamMemberExpertise__c
                        WHERE
                                Sector_Expertise__r.Sector__c IN :sectorIds AND
                                Recommended__c = true
                ];
            } else {
                sectors = [SELECT Id, Contact__c FROM EQT_Sector_Rating__c WHERE Sector__c IN :sectorIds];
            }
        }
        
        // get the union of all lists
        Map<Id, SObject> union = new Map<Id, SObject>();
        if (null != sectors) {
            for (EQT_Sector_Rating__c r : sectors) {
                union.put(r.Contact__c, r);
            }
        }
        if (null != subsectors) {
            for (EQT_Sector_Rating__c r : subsectors) {
                if (!union.containsKey(r.Contact__c)) union.put(r.Contact__c, r);
            }
        }
        if (null != segments) {
            for (EQT_Sector_Rating__c r : segments) {
                if (!union.containsKey(r.Contact__c)) union.put(r.Contact__c, r);
            }
        }

        if (null != sectorsRecommended) {
            for (EQT_SectorTeamMemberExpertise__c r : sectorsRecommended) {
                union.put(r.Sector_Expertise__r.Contact__c, r);
            }
        }
        if (null != subsectorsRecommended) {
            for (EQT_SectorTeamMemberExpertise__c r : subsectorsRecommended) {
                if (!union.containsKey(r.Sector_Expertise__r.Contact__c)) union.put(r.Sector_Expertise__r.Contact__c, r);
            }
        }
        if (null != segmentsRecommended) {
            for (EQT_SectorTeamMemberExpertise__c r : segmentsRecommended) {
                if (!union.containsKey(r.Sector_Expertise__r.Contact__c)) union.put(r.Sector_Expertise__r.Contact__c, r);
            }
        }


        if(!union.isEmpty()) {
            resultSet.addAll(union.keySet());
        }

        // return
        return resultSet;
    }

    public static Set<Id> filterByFunctional(List<String> functionalFilter) {
        Set<Id> resultSet = new Set<Id>();
		Set<String> topicOnly = new Set<String>();
        Set<String> topic = new Set<String>();
        Set<String> subTopic = new Set<String>();

        for(String s : functionalFilter) {
            if(s.contains('#')) {
                List<String> ids = s.split('#');
                topic.add(ids[0]);
                subTopic.add(ids[1]);
            }
            else { //only parent was selected
                topicOnly.add(s);
            }
        }
        
        List<EQT_Functional_Rating__c> functionals = null;
        if (subTopic.isEmpty() && !topicOnly.isEmpty()) {
            // this is a topic only search
            functionals = [SELECT Id, Contact__c
                            FROM EQT_Functional_Rating__c
                            WHERE Functional_Topic__c IN :topicOnly];
        } else if (topicOnly.isEmpty()) {
            // this is a sub-topic only search
            functionals = [SELECT Id, Contact__c
                      FROM EQT_Functional_Rating__c
                      WHERE Functional_Topic__c IN :topic AND Functional_Subtopic__c IN :subTopic];
        } else {
            // this is a topic AND topic/sub-topic search
            functionals = [SELECT Id, Contact__c
                            FROM EQT_Functional_Rating__c
                            WHERE ((Functional_Topic__c IN :topic AND Functional_Subtopic__c IN :subTopic) OR (Functional_Topic__c IN :topicOnly))];
        }
        
        if(!functionals.isEmpty()) {
            resultSet.addAll(fetchIds(functionals, 'Contact__c'));
        }
        
        return resultSet;
        
    }

    public static Set<Id> filterByGeographical(List<String> geoFilter) {
        Set<Id> resultSet = new Set<Id>();
        Set<String> regionOnly = new Set<String>();
        Set<String> regions = new Set<String>();
        Set<String> country = new Set<String>();

        for(String s : geoFilter) {
            if(s.contains('#')) {
                List<String> items = s.split('#');
                regions.add(items[0]);
                country.add(items[1]);
            }
            else { //only parent was selected
                regionOnly.add(s);
            }
        }
        
        List<EQT_Geographical_Rating__c> grList = null;
        if (country.isEmpty() && !regionOnly.isEmpty()) {
            // this is a region only search
            grList = [SELECT Id, Contact__c
                            FROM EQT_Geographical_Rating__c
                            WHERE Geography__c IN (SELECT Id FROM EQT_Geography__c WHERE (Region__c IN :regionOnly))];
        } else if (regionOnly.isEmpty()) {
            // this is a country only search
            grList = [SELECT Id, Contact__c
                      FROM EQT_Geographical_Rating__c
                      WHERE Geography__c IN (SELECT Id FROM EQT_Geography__c WHERE Region__c IN :regions AND Country__c IN :country)];
        } else {
            // this is a region AND country search
            grList = [SELECT Id, Contact__c
                            FROM EQT_Geographical_Rating__c
                            WHERE Geography__c IN (SELECT Id FROM EQT_Geography__c WHERE (Region__c IN :regions AND Country__c IN :country) OR (Region__c IN :regionOnly))];
        }
        
        if(!grList.isEmpty()) {
            resultSet.addAll(fetchIds(grList, 'Contact__c'));
        }
        
        return resultSet;
    }
    
    // start - network search by sector team
    public static Set<Id> filterBySectorTeam(List<String> sectorTeamFilter, Boolean sectorTeamRecommendedIAs) {
        Set<Id> resultSet = new Set<Id>();

        if ( sectorTeamFilter!=null && !sectorTeamFilter.isEmpty() ) {
            if(sectorTeamRecommendedIAs){
                // only recomended IAs
                List<EQT_SectorTeamMemberExpertise__c> stmeList = null;
                stmeList = [
                    SELECT
                        SectorTeamMember__r.EQT_Contact__c
                    FROM EQT_SectorTeamMemberExpertise__c
                    WHERE
                        SectorTeamMember__r.EQT_Sector_Team__c IN :sectorTeamFilter AND
                        Recommended__c = true
                ];
                if(!stmeList.isEmpty()) {
                    resultSet.addAll(fetchIds(stmeList, 'SectorTeamMember__r.EQT_Contact__c'));
                }
            } else {
                List<EQT_Sector_Team_Member__c> stList = null;
                stList = [
                        SELECT EQT_Contact__c
                        FROM EQT_Sector_Team_Member__c
                        WHERE EQT_Sector_Team__c IN :sectorTeamFilter
                ];

                if(!stList.isEmpty()) {
                    resultSet.addAll(fetchIds(stList, 'EQT_Contact__c'));
                }
            }
        }

        return resultSet;
    }
    // end - network search by sector team

    public static Set<Id> filterByContactFields(List<String> suitablePositions, List<String> engagementLevel, List<String> countryOfResidence) {
        Set<Id> resultSet = new Set<Id>();

        String contactQuery = 'SELECT Id FROM Contact WHERE';

        Boolean positionParam = false;
        Boolean engagementParam = false;
        Boolean residenceParam = false;

        if(!suitablePositions.isEmpty()) {
            System.debug(suitablePositions);
            contactQuery += ' EQT_Suitable_Positions__c INCLUDES ' + stringArrayify(suitablePositions);
            positionParam = true;
        }

        if(!engagementLevel.isEmpty()) {
            if(positionParam) {
                contactQuery += ' AND Engagement_Level__c IN (' + getStringForQueryIN(stringArrayify(engagementLevel)) + ')';
                engagementParam = true;
            }
            else {
                contactQuery += ' Engagement_Level__c IN (' + getStringForQueryIN(stringArrayify(engagementLevel)) + ')';
            }
        }

        if(!countryOfResidence.isEmpty()) {
            if(positionParam || engagementParam) {
                contactQuery += ' AND EQT_Country_of_Residence__c IN (' + getStringForQueryIN(stringArrayify(countryOfResidence)) + ')';
                residenceParam = true;
            }
            else {
                contactQuery += ' EQT_Country_of_Residence__c IN (' + getStringForQueryIN(stringArrayify(countryOfResidence)) + ')';
            }
        }

        system.debug(LoggingLevel.INFO, 'Contact query=' + contactQuery);

        List<Contact> contactList = Database.query(contactQuery);

        if(!contactList.isEmpty()) {
            resultSet.addAll(fetchIds(contactList, 'Id'));
        }

        return resultSet;
    }

    public static Set<Id> fetchIds(List<sObject> sObjectList, String fieldName){
        Set<Id> idSet = new Set<Id>();

        List<String> fieldNameParts = fieldName.split('\\.');

        for(sObject sObjectItem : sObjectList) {

            if(fieldNameParts.size() == 1){
                idSet.add((Id)sObjectItem.get(fieldName));
            } else if(fieldNameParts.size() > 1){
                SObject tmpSObject = sObjectItem.getSObject(fieldNameParts[0]);

                for(Integer namePartCounter = 1; namePartCounter<fieldNameParts.size(); namePartCounter++){

                    if(namePartCounter >= (fieldNameParts.size()-1) ){
                        idSet.add((Id)tmpSObject.get(fieldNameParts[namePartCounter]));
                    } else {
                        tmpSObject = tmpSObject.getSObject(fieldNameParts[namePartCounter]);
                    }
                }
            }
        }

        return idSet;
    }

    public static Set<Id> makeIntersection(Set<Id> firstSet, Set<Id> secondSet) {
        Set<Id> intersection = new Set<Id>();

        if(firstSet.isEmpty() || secondSet.isEmpty()) {
            return intersection;
        }

        for(Id idVal : firstSet) {
            if(secondSet.contains(idVal)) {
                intersection.add(idVal);
            }
        }

        return intersection;
    }

    public static Set<Id> calculateResultIds(Set<Id> originalSet, Set<Id> querySet, Boolean makeIntersection, Boolean filterApplied) {
        if(querySet.isEmpty()) {
            return new Set<Id>();
        }
        else {
            if(makeIntersection) {
                //if there was no Ids in original filter check if any filter was previously applied
                if(originalSet.isEmpty()) {
                    //if was applied return empty set as intersection with nothing gives nothing
                    if(filterApplied) {
                        return new Set<Id>();
                    }
                    else { //if there was no filter applied before, return query set
                        return querySet;
                    }
                }
                else {
                    return makeIntersection(originalSet, querySet);
                }
            }
            else {
                //if no intersection add both sets to result set
                Set<Id> resultSet = new Set<Id>();
                resultSet.addAll(originalSet);
                resultSet.addAll(querySet);
                return  resultSet;
            }
        }
    }

    private static List<String> stringArrayify(List<String> input) {
        List<String> result = new List<String>();
        if (null != input) {
            for (String s : input) result.Add('\'' + s + '\'');
        }

        return result;
    }
    
    public static EQT_NetworkSearch_Wrapper.PageResult loadSearchResultsWithPagination(Set<Id> contactIds, Integer pageSize, Integer offset, Boolean includePCCandidates, Boolean includeIACandidates) {
        EQT_NetworkSearch_Wrapper.PageResult result = new EQT_NetworkSearch_Wrapper.PageResult();
        result.pageSize = pageSize;

        List<EQT_NetworkSearch_Wrapper.SearchResults> searchResults = new List<EQT_NetworkSearch_Wrapper.SearchResults>();

        Id industrialAdvisorRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());
        Id externalContactRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getExternalContactRecordTypeName());

        String queryString = '';
        queryString += 'SELECT Id, Name, Email, Phone, Title, OwnerId, Owner.Name, EQT_LinkedIn_Profile__c, Engagement_Level__c, EQT_IA_Status__c, ';
        queryString += 'EQT_Assessment_Rating_Number__c, EQT_Assessment_Rating_Total__c, EQT_Average_Assessment_Rating__c, EQT_Country_of_Residence__c, ';
        queryString += 'toLabel(EQT_Suitable_Positions__c), ';

        queryString += '(SELECT Id, Name, ContentType ';
        queryString += 'FROM Attachments ';
        queryString += 'WHERE ContentType IN (\'image/png\', \'image/jpeg\', \'image/gif\', \'image/bmp\', \'image/jpg\') ';
        queryString += 'ORDER BY LastModifiedDate DESC LIMIT 1), ';

        queryString += '(SELECT Id, Company__c, Company__r.Name, Project__c, Project__r.Name, Project__r.Account.Id, Project__r.Account.Name, ';
        queryString += 'Start_Date__c, EQT_End_Date__c, EQT_Role__c, Project__r.EQT_Business_Line_Sub_Strategy__c, Project__r.Account.Industry, Operative__c ';
        queryString += 'FROM Assignments__r ';
        queryString += 'order by Start_Date__c desc, EQT_End_Date__c desc), ';

        queryString += '(SELECT id, Sector__r.Name, Subsector__r.Name, Subsector_Segment__r.Name FROM Sector_Ratings__r), ';

        queryString += '(SELECT id, Functional_Topic__r.Name, Functional_Subtopic__r.Name FROM Functional_Ratings__r), ';

        queryString += '(SELECT id, Geography__r.Name, toLabel(Geography__r.Region__c) FROM Geographical_Ratings__r ORDER BY Geography__r.Region__c ASC), ';

        queryString += '(Select Id, Role__c, Account__r.Name, Start_Date__c, End_Date__c ';
        queryString += 'FROM Affiliations__r ';
        queryString += 'ORDER BY Start_Date__c desc, End_Date__c desc LIMIT 3) ';

        queryString += 'FROM Contact ';
        queryString += 'WHERE Id IN :contactIds ';

        if(includePCCandidates || includeIACandidates) {
            queryString += ' AND (RecordTypeId =:industrialAdvisorRecordTypeId OR RecordTypeId =:externalContactRecordTypeId) ';
            if(includePCCandidates && includeIACandidates){
                queryString += ' AND (Portfolio_Company_Management_Candidate__c = true OR IA_Candidate__c = true) ';
            } else if(includePCCandidates){
                queryString += ' AND Portfolio_Company_Management_Candidate__c = true ';
            } else if(includeIACandidates){
                queryString += ' AND IA_Candidate__c = true ';
            }
        } else {
            queryString += 'AND RecordTypeId =:industrialAdvisorRecordTypeId ';
        }

        queryString += 'ORDER BY Name';

        system.debug(LoggingLevel.DEBUG , 'contactIds: ' + contactIds);
        system.debug(LoggingLevel.DEBUG , 'queryString: ' + queryString);

        List<Contact> queryResults = (List<Contact>) Database.query(queryString);

        system.debug(LoggingLevel.DEBUG , 'queryResults: ' + queryResults);

        // start SFAM-177
        Set<Id> sectorRatingIdsSet = new Set<Id>();
        for(Contact c : queryResults) {
            for(EQT_Sector_Rating__c sr : c.Sector_Ratings__r) {
                sectorRatingIdsSet.add(sr.Id);
            }
        }
        Map<Id, Boolean> sectorRatingIdRecommendedMap = new Map<Id, Boolean>();
        if(!sectorRatingIdsSet.isEmpty()){
            List<EQT_SectorTeamMemberExpertise__c> sectorTeamMemberExpertiesList = [
                SELECT Sector_Expertise__c, Recommended__c FROM EQT_SectorTeamMemberExpertise__c WHERE Sector_Expertise__c IN :sectorRatingIdsSet
            ];

            for(EQT_SectorTeamMemberExpertise__c stmeItem : sectorTeamMemberExpertiesList){
                sectorRatingIdRecommendedMap.put(stmeItem.Sector_Expertise__c, stmeItem.Recommended__c);
            }
        }
        // end SFAM-177

        for(Contact c : queryResults) {

            List<String> suitablePositions = null;
            if (!String.isEmpty(c.EQT_Suitable_Positions__c)) {
                suitablePositions = c.EQT_Suitable_Positions__c.split(';');
            }
            
            EQT_NetworkSearch_Wrapper.SearchResults contactResult = new EQT_NetworkSearch_Wrapper.SearchResults();
            contactResult.cDetail = new EQT_NetworkSearch_Wrapper.ContactDetails();
            contactResult.cDetail.id = c.Id;
            contactResult.cDetail.name = c.Name;
            contactResult.cDetail.title = c.Title;
            contactResult.cDetail.email = c.Email;
            contactResult.cDetail.phone = c.Phone;
            contactResult.cDetail.countryOfResidence = c.EQT_Country_of_Residence__c;
            contactResult.cDetail.suitablePositions = suitablePositions;
            contactResult.cDetail.ratingCount = c.EQT_Assessment_Rating_Number__c; 
            contactResult.cDetail.ratingTotal = c.EQT_Assessment_Rating_Total__c; 
            contactResult.cDetail.ratingAverage = c.EQT_Average_Assessment_Rating__c;
            contactResult.cDetail.status = c.EQT_IA_Status__c;
            contactResult.cDetail.engagementLevel = c.Engagement_Level__c;
            contactResult.cDetail.linkedinProfile = c.EQT_LinkedIn_Profile__c;
            contactResult.cDetail.ownerId = c.OwnerId;
            contactResult.cDetail.ownerName = c.Owner.Name;
            contactResult.photoId = c.Attachments.isEmpty() ? null : c.Attachments[0].Id;
            contactResult.sectorExpertise = new List<EQT_NetworkSearch_Wrapper.SectorExpertise>();
            contactResult.functionalExpertise = new List<String>();
            contactResult.geographicalExpertise = new List<String>();

            // add sector expertise (only top level)
            Set<EQT_NetworkSearch_Wrapper.SectorExpertise> sectors = new Set<EQT_NetworkSearch_Wrapper.SectorExpertise>();
            for(EQT_Sector_Rating__c sr : c.Sector_Ratings__r) {
                String value = sr.Sector__r.Name;

                if(String.isNotEmpty(sr.Subsector__r.Name)) {
                    value += ' > ' + sr.Subsector__r.Name;
                }
                if(String.isNotEmpty(sr.Subsector_Segment__r.Name)) {
                    value += ' > ' + sr.Subsector_Segment__r.Name;
                }

                sectors.add(new EQT_NetworkSearch_Wrapper.SectorExpertise(value, sectorRatingIdRecommendedMap.get(sr.Id) ) );
            }
            contactResult.sectorExpertise = new List<EQT_NetworkSearch_Wrapper.SectorExpertise>(sectors);
            
            // add functional expertise (only top level)
            Set<String> functional = new Set<String>();
            for(EQT_Functional_Rating__c fr : c.Functional_Ratings__r) {
                String value = fr.Functional_Topic__r.Name;
                /*
                if(String.isNotEmpty(fr.Functional_Subtopic__r.Name)) {
                    value += ' > ' + fr.Functional_Subtopic__r.Name;
                }
                */
                functional.add(value);
            }
            contactResult.functionalExpertise = new List<String>(functional);

            // add geo expertise (only by region)
            Set<String> regions = new Set<String>();
            for(EQT_Geographical_Rating__c gr : c.Geographical_Ratings__r) {
                regions.add(gr.Geography__r.Region__c);
            }
            contactResult.geographicalExpertise = new List<String>(regions);
            
            contactResult.experience = buildExperience(c.Assignments__r, c.Affiliations__r);

            contactResult.assessments = new List<Object>();
            contactResult.assignments = new List<Object>();

            searchResults.add(contactResult);
        }
        result.total = searchResults.size();
        result.contacts = searchResults;

        return result;
    }

    private static List<EQT_NetworkSearch_Wrapper.Experience> buildExperience(List<EQT_Assignment__c> assignmentList, List<EQT_Affiliation__c> affiliationList) {
        List<EQT_NetworkSearch_Wrapper.Experience> result = new List<EQT_NetworkSearch_Wrapper.Experience>();
        List<EQT_NetworkSearch_Wrapper.Experience> experience = new List<EQT_NetworkSearch_Wrapper.Experience>();

        for(EQT_Assignment__c assignment : assignmentList) {
            if(String.isEmpty(assignment.Project__c)) {
                system.debug(LoggingLevel.INFO, 'assignment=' + assignment);
                experience.add(new EQT_NetworkSearch_Wrapper.Experience(assignment.EQT_Role__c, assignment.Company__r.Name, assignment.Start_Date__c, assignment.EQT_End_Date__c));
            }
        }

        for(EQT_Affiliation__c affiliation : affiliationList) {
            system.debug(LoggingLevel.INFO, 'affiliation=' + affiliation);
            experience.add(new EQT_NetworkSearch_Wrapper.Experience(affiliation.Role__c, affiliation.Account__r.Name, affiliation.Start_Date__c, affiliation.End_Date__c));
        }

        if(!experience.isEmpty()) {
            system.debug(LoggingLevel.INFO, 'Experience=' + experience);
            experience.sort();

            Integer experienceCounter = 0;
            for(EQT_NetworkSearch_Wrapper.Experience exp : experience) {
                if(experienceCounter == 3) {
                    break;
                }

                result.add(exp);
                experienceCounter++;
            }

            return result;
        }

        return experience;
    }
    
    public static List<String> getPicklistValues(Schema.DescribeFieldResult fieldResult) {
        List<String> options = new List<String>();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            options.add(entry.getLabel());
        }

        return options;
    }

    public static String getStringForQueryIN(List<String> stringList){
        String resultString = '';

        for(String s : stringList) {
            if(resultString.length() > 0){
                resultString += ',';
            }
            resultString += s;
        }

        return resultString;
    }
}