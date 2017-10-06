/**
    About
    -----
    Description: Controller for custom Input lookup lightning component
                 Based on https://developer.salesforce.com/blogs/developer-relations/2015/06/salesforce-lightning-inputlookup-missing-component.html
    Created for: EQT
    Create date: April 2017

    Details / Methods
    -----------------
    getCurrentValue - Loads the initial value of the given SObject type with ID "value"
    getSobjectNameField - Returns the "Name" field for a given SObject
    searchSObject - Searchs (using SOSL) for a given Sobject type

    Update History
    --------------
    Created April 2017- R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_InputLookupAuraController {

    public class SearchResult{
        public String value {get;set;}
        public String id {get;set;}
    }

    @AuraEnabled
    public static String getCurrentValue(String type, String value) {
        if(String.isBlank(type)){
            return null;
        }

        Id lookupId = null;

        try {
            lookupId = (Id)value;
        }
        catch(Exception e) {
            return null;
        }

        if(String.isBlank(lookupId)) {
            return null;
        }

        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null) {
            return null;
        }

        String nameField = getSobjectNameField(objType);
        String query = 'SELECT Id, '+nameField+' FROM '+type+' WHERE Id = \''+lookupId+'\'';
        System.debug(LoggingLevel.INFO, 'Query='+query);
        List<SObject> oList = Database.query(query);
        if(oList.size() == 0) {
            return null;
        }

        return (String) oList[0].get(nameField);
    }

    private static String getSobjectNameField(SobjectType sobjType) {
        //describes lookup obj and gets its name field
        String nameField = 'Name';
        Schema.DescribeSObjectResult dfrLkp = sobjType.getDescribe();
        for(schema.SObjectField sotype : dfrLkp.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescObj = sotype.getDescribe();
            if(fieldDescObj.isNameField() ) {
                nameField = fieldDescObj.getName();
                break;
            }
        }

        return nameField;
    }

    @AuraEnabled
    public static String searchSObject(String type, String searchString) {
        if(String.isBlank(type) || String.isBlank(searchString)) {
            return null;
        }

        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null) {
            return null;
        }

        String nameField = getSobjectNameField(objType);
        searchString = '\'*'+searchString+'*\'';
        String soslQuery = 'FIND :searchString IN NAME FIELDS RETURNING '
                + type + '(Id, ' + nameField + ' ORDER BY '+nameField+') LIMIT 10';
        System.debug(LoggingLevel.INFO, 'SOSL QUERY: '+soslQuery);
        List<List<SObject>> results =  Search.query(soslQuery);

        List<SearchResult> output = new List<SearchResult>();
        if(!results.isEmpty()) {
            for(SObject sobj : results[0]) {
                SearchResult sr = new SearchResult();
                sr.id = (String)sobj.get('Id');
                sr.value = (String)sobj.get(nameField);
                output.add(sr);
            }
        }

        return JSON.serialize(output);
    }
}