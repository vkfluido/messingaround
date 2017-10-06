/*
 * @name			EQT_IndustrialAdvisorCompetence_LCC
 * @date			Dec 22, 2016
 * @description		The IA Competence component's controller, used to edit an industrial advisor competence
 */

public class EQT_IndustrialAdvisorCompetence_LCC {
    
    @AuraEnabled
    public static List<String> getRatings() {
		list<String> options = new list<String>();
		Schema.DescribeFieldResult fieldResult = EQT_Geographical_Rating__c.Rating__c.getDescribe();
		list<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        options.add('');
		for (Schema.PicklistEntry entry : entries) {
    		options.add(entry.getLabel());
		}

		return options;
    }
    
    @AuraEnabled
    public static boolean updateCompetence(String objectType, String objectId, String rating) {
        System.debug('### ' + objectType + '#' + objectId + '#' + rating);
        SObject theObject = Schema.getGlobalDescribe().get(objectType).newSObject(objectId);
        theObject.put('Rating__c' , rating) ;
        try {
        	update theObject;
        }
        catch (Exception theException) {
            System.debug(theException);
            return false;
        }
		return true;
    }
    
    @AuraEnabled
    public static boolean deleteCompetence(String objectType, String objectId) {
        System.debug('### ' + objectType + '#' + objectId);
        SObject theObject = Schema.getGlobalDescribe().get(objectType).newSObject(objectId);
        try {
        	delete theObject;
        }
        catch (Exception theException) {
            System.debug(theException);
            return false;
        }
		return true;
    }

}