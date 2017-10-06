/*
 * @name			EQT_IndustrialAdvisorRatingDetails_LCC
 * @date			Dec 21, 2016
 * @description		The IA Rating Details component's controller, used to edit industrial advisor competences	 
 */

public class EQT_IndustrialAdvisorRatingDetails_LCC {
    
    /*
     * 
	 */
	@AuraEnabled
    public static list<EQT_Geographical_Rating__c> getGeographicalRatings(String contactId) {
        list<EQT_Geographical_Rating__c> results = [
            SELECT 	Id, Name, Rating__c
            FROM	EQT_Geographical_Rating__c
            WHERE	Contact__c = :contactId
        ];
        return results;
    }
    
    /*
     * 
	 */
	@AuraEnabled
    public static list<EQT_Functional_Rating__c> getFunctionalRatings(String contactId) {
        list<EQT_Functional_Rating__c> results = [
            SELECT 	Id, Name, Rating__c
            FROM	EQT_Functional_Rating__c
            WHERE	Contact__c = :contactId
        ];
        return results;
    }
    
    /*
     * 
	 */
	@AuraEnabled
    public static list<EQT_Sector_Rating__c> getSectorialRatings(String contactId) {
        list<EQT_Sector_Rating__c> results = [
            SELECT 	Id, Name, Rating__c
            FROM	EQT_Sector_Rating__c
            WHERE	Contact__c = :contactId
        ];
        return results;
    }

}