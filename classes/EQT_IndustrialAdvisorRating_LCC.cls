/*
 * @name			EQT_IndustrialAdvisorRating_LCC
 * @date			Dec 12, 2016
 * @description		The IA Rating component's controller, used to capture industrial advisor competences	 
 */

public with sharing class EQT_IndustrialAdvisorRating_LCC {
    
    public enum RatingType {GEOGRAPHICAL, FUNCTIONAL, SECTORIAL}
    
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
    
	@AuraEnabled
    public static List<String> getGeographicalRatings(String contactId) {
        // get ratings
        final List<String> results = new List<String>();
        final List<EQT_Geographical_Rating__c> ratings = [
            SELECT Geography__c, Geography__r.Region__c, Geography__r.Country__c 
            FROM EQT_Geographical_Rating__c 
            WHERE Contact__c =: contactID
        ];
        
        // build id list
        for (EQT_Geographical_Rating__c rating : ratings) {
            String id = null;
            if (String.isEmpty(rating.Geography__r.Country__c)) {
                // only region
                id = rating.Geography__r.Region__c;
            } else {
                id = rating.Geography__r.Region__c + '#' + rating.Geography__r.Country__c;
            }
            results.add(id);
        }
        
        // return
        return results;
    }
    
	@AuraEnabled
    public static List<String> getFunctionalRatings(String contactId) {
        // get ratings
        final List<String> results = new List<String>();
        final List<EQT_Functional_Rating__c> ratings = [
            SELECT Functional_Topic__r.Name, Functional_Subtopic__r.Name, Functional_Topic__c, Functional_Subtopic__c, Id 
            FROM EQT_Functional_Rating__c 
            WHERE Contact__c =: contactId 
            ORDER BY Functional_Topic__r.Name ASC, Functional_Subtopic__r.Name ASC
        ];
        
        // build competence objects
        for (EQT_Functional_Rating__c rating : ratings) {
            String id = null;
            if (String.isEmpty(rating.Functional_Subtopic__c)) {
                id = rating.Functional_Topic__c;
            } else {
                id = rating.Functional_Topic__c + '#' + rating.Functional_Subtopic__c;
            }
            results.add(id);
        }
        
        // return
        return results;
    }
    
	@AuraEnabled
    public static List<String> getSectorRatings(String contactId) {
        // get ratings
        final List<String> results = new List<String>();
        final List<EQT_Sector_Rating__c> ratings = [
            SELECT Sector__c, Sector__r.Name, Subsector__c, Subsector__r.Name, Subsector_Segment__c, Subsector_Segment__r.Name 
            FROM EQT_Sector_Rating__c 
            WHERE Contact__c =: contactId
        ];
        
        // build id list
        for (EQT_Sector_Rating__c rating : ratings) {
            String id = null;
            if (String.isEmpty(rating.Subsector__c) && String.isEmpty(rating.Subsector_Segment__c)) {
                // no subsector and no segment
                id = rating.Sector__c;
            } else if (String.isEmpty(rating.Subsector_Segment__c)) {
                // no segment
                id = rating.Sector__c + '#' + rating.Subsector__c;
            } else {
                id = rating.Sector__c + '#' + rating.Subsector__c + '#' + rating.Subsector_Segment__c;
            }
            results.add(id);
        }
        
        // return
        return results;
    }
    
    @AuraEnabled
    public static boolean saveCompetences(String contactId, List<String> sectors, List<String> functionals, List<String> geos) {
        // make sure there is only a single contact matching the supplied id
        if ([SELECT Id,Name FROM Contact WHERE Id =: contactId].size() != 1) throw new AuraHandledException('Found 0 or multiple contacts matching the supplied record id');        
        
        // hold deletes
        final List<SObject> deletes = new List<SObject>();
        final List<SObject> inserts = new List<SObject>();
        
        // delete the sector ratings and create new ones
        for (EQT_Sector_Rating__c rating : [SELECT Id FROM EQT_Sector_Rating__c where Contact__c =: contactId]) {
	        deletes.add(rating);
        }
        for (String sector : sectors) {
            final List<String> ids = sector.split('#');
            EQT_Sector_Rating__c rating = new EQT_Sector_Rating__c();
            rating.Contact__c = contactId;
            rating.Sector__c = ids[0];
            if (ids.size() >= 2) {
                rating.Subsector__c = ids[1];
            }
            if (ids.size() >= 3) {
                rating.Subsector_Segment__c = ids[2];
            }
            inserts.add(rating);
        }
        
        // delete the functional ratings and create new ones
        for (EQT_Functional_Rating__c rating : [SELECT Id FROM EQT_Functional_Rating__c where Contact__c =: contactId]) {
            deletes.add(rating);
        }
        for (String func : functionals) {
            final List<String> ids = func.split('#');
            EQT_Functional_Rating__c rating = new EQT_Functional_Rating__c();
            rating.Contact__c = contactId;
            rating.Functional_Topic__c = ids[0];
            if (ids.size() >= 2) {
                rating.Functional_Subtopic__c = ids[1];
            }
            inserts.add(rating);
        }
        
        // delete the geo ratings
        for (EQT_Geographical_Rating__c rating : [SELECT Id FROM EQT_Geographical_Rating__c where Contact__c =: contactId]) {
            deletes.add(rating);
        }
        
        // loop the current geos and build map
        final Map<String, EQT_Geography__c> geoMap = new Map<String, EQT_Geography__c>();
        for (EQT_Geography__c geo : [SELECT Id, Region__c, Country__c FROM EQT_Geography__c]) {
            if (String.isEmpty(geo.Country__c)) {
                // add by region
                geoMap.put(geo.Region__c, geo);
            } else {
                // add by region#country
                geoMap.put(geo.Region__c + '#' + geo.Country__c, geo);
            }
        }
        for (String geo : geos) {
            EQT_Geography__c geoObj = geoMap.get(geo);
            if (null == geoObj) {
                // couldn't find geo object - raise error
                throw new AuraHandledException('Could not find EQT_Geography__c object instance for supplied region/country mapping (' + geo + ')');
            }
            EQT_Geographical_Rating__c rating = new EQT_Geographical_Rating__c();
            rating.Contact__c = contactId;
            rating.Geography__c = geoObj.Id;
            inserts.Add(rating);
        }
        
        // do the deletes and the inserts
        delete deletes;
        insert inserts;
        
        // return
        return true;
    }
}