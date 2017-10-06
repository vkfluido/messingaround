/**
    About
    -----
    Description: Apex meta data (describes, record type maps etc.) calls. Cached to reduce repeted calls.
    Created for: EQT POC
    Create date: April 2016
    
    Details / Methods
    -----------------

    Update History
    --------------
    Created April 2016 - R.B.
    
    Issues / TODOs
    --------------
*/
public with sharing class EQT_UTIL_Meta {
    
    /**** Profiles ****/
    // Get profile ID by Name
    static Map<String,String>profileIds = new Map<String,String>();
    public static ID profileId(String profileName) {
        if (profileIds.containsKey(profileName)) {
            return profileIds.get(profileName);
        }
        else {
            ID profileID = [select id,Name from Profile where name = :profileName  limit 1].id;
            profileIds.put(profileName,profileID);
        }

        return profileIds.get(profileName);
    }
    
    // Get profile Name by Id
    static Map<String,String>profileNames = new Map<String,String>();
    public static String profileName(Id profileID) {
        if (profileNames.containsKey(profileID)) {
            return profileNames.get(profileID);
        }
        else {
            String profileName = [select id,Name from Profile where Id = :profileId  limit 1].Name;
            profileNames.put(profileID,profileName);
        }
        
        return profileNames.get(profileID);
    }

    // Get Queue Id by Name
    static Map<String,Id> queueNameIdMap = new Map<String,Id>();
    public static String getQueueId(String queueName) {
        if (queueNameIdMap.containsKey(queueName)) {
            return queueNameIdMap.get(queueName);
        }
        else {
            Id queueId = [SELECT Id, QueueId, Queue.Name FROM QueueSobject where Queue.Name = :queueName  limit 1].QueueId;
            queueNameIdMap.put(queueName, queueId);
        }
        
        return queueNameIdMap.get(queueName);
    }
    
    /**** Record Types ****/
    static Map<String,Id> recordTypesMap = new Map<String,Id>();
    public static Map<String,Id> getRecordTypesMap() {
        if(recordTypesMap.isEmpty()) {
            RecordType[] rtList = [select DeveloperName,Name,Id,SobjectType from RecordType LIMIT 100];
            for(RecordType rt : rtList) {
                recordTypesMap.put(rt.SobjectType+'.'+rt.DeveloperName,rt.Id);
            }
        }

        return recordTypesMap;
    }

    public static id getRecordTypeId(String sObjectDotRecordTypeName) {
        return (getRecordTypesMap().get(sObjectDotRecordTypeName));
    }
    
    // Get Record Type name by ID
    static map<String, String> recordTypeNames_Map = new map<String, String>();
    public static String getRTName(ID recordTypeId) {
        String name = '';
        if (recordTypeNames_Map.containsKey(recordTypeId)) {
            name =  recordTypeNames_Map.get(recordTypeId);
        }
        else {
            try {
                RecordType r = [select id, toLabel(Name), DeveloperName from RecordType where id=:recordTypeId];
                name = r.DeveloperName;
                recordTypeNames_Map.put(recordTypeId,name);
            }
            catch (exception e){}
        }

        return name;
    }
        
    /**** Describe Info ****/
    // Get global describe (cached)
    public static Map<String, Schema.SObjectType> globalDescibe_Map {
        get {
            if(globalDescibe_Map==null) {
                globalDescibe_Map = Schema.getGlobalDescribe();
            }

            return globalDescibe_Map;
        }
        set;
    }
    
    // Get field map for object - object API name >> <field API name, describe info>
    static map<String, Map<String, Schema.SObjectField>> objectField_Map = new map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, Schema.SObjectField> getFieldMap(String typeName) {
        if (objectField_Map.containsKey(typeName)) {
            return objectField_Map.get(typeName);
        }
        else if(globalDescibe_Map.containsKey(typeName)) {
            Schema.SObjectType productSchema = globalDescibe_Map.get(typeName);
            Map<String, Schema.SObjectField> fieldMap = productSchema.getDescribe().fields.getMap();
            objectField_Map.put(typeName,fieldMap);
            return fieldMap;
        }

        return null;
    }
    
    // Get field describe
    static map<Schema.SObjectField, Schema.DescribeFieldResult> objectFieldDescribe_Map = new map<Schema.SObjectField, Schema.DescribeFieldResult>();
    public static Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectField field) {
        if (objectFieldDescribe_Map.containsKey(field)) {
            return objectFieldDescribe_Map.get(field);
        }
        else if(field!=null) {
            Schema.DescribeFieldResult describeResult = field.getDescribe();
            objectFieldDescribe_Map.put(field,describeResult);
            return describeResult;
        }

        return null;
    }
    
    // Get field describe by object type name and field name
    public static Schema.DescribeFieldResult getFieldDescribe(String typeName, String fieldName) {
        Map<String, Schema.SObjectField> fieldMap = getFieldMap(typeName);
        if (fieldMap.containsKey(fieldName)!=null) {
            Schema.DescribeFieldResult fieldResult = getFieldDescribe(fieldMap.get(fieldName));
            if (fieldResult!=null) {
                return fieldResult;
            }
        }

        return null;
    }
    
    // Get field label for object and field - context of executing user
    public static String getFieldLabel(String typeName, String fieldName) {
        Schema.DescribeFieldResult field = getFieldDescribe(typeName, fieldName);
        if (field!=null) {
            return field.getLabel();
        }

        return '';
    }
    
    // get the sobject type by id - SObjectField >> DescribeFieldResult
    static map<String, Schema.SObjectType> prefixType_Map = new map<String, Schema.SObjectType>();
    public static Schema.SObjectType getObjectType(String whatId) {
        
        if(whatId == null) {
            return null;
        }
        
        for(String keyPrefix : prefixType_Map.keySet()) {
            if (keyPrefix != null && whatId.startsWith(keyPrefix)) {
                return prefixType_Map.get(keyPrefix);
            }
        }
        
        for(Schema.SObjectType describe: globalDescibe_Map.values()) {
            String keyPrefix = describe.getDescribe().getKeyPrefix();
            prefixType_Map.put(keyPrefix, describe);
            if(keyPrefix != null && whatId.startsWith(keyPrefix)) {
                return describe;
            }
        }
        
        return null;
    }

    //get fields from given field set - fieldSet Name >> list of fields
    static map<String, List<Schema.FieldSetMember>> fieldSet_Map = new Map<String, List<Schema.FieldSetMember>>();
    public static List<Schema.FieldSetMember> getFieldSetFields(String objectName, String fieldSetName) {

        if(fieldSetName == null) {
            return null;
        }

        for(String fsName : fieldSet_Map.keySet()) {
            if(fsName != null && fsName.toLowerCase().equals(fieldSetName.toLowerCase())) {
                return fieldSet_Map.get(fsName);
            }
        }

        if(String.isNotEmpty(objectName)) {
            Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
            Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
            fieldSet_Map.put(fieldSetName, fieldSetObj.getFields());
            return fieldSetObj.getFields();
        }

        return null;
    }
    
    /**** ORG Wide Info ****/
    static Organization org;
    public static Organization getOrgInfo() {
        if (org==null) {
            org = [Select Id, DefaultAccountAccess, DefaultCaseAccess, DefaultOpportunityAccess from Organization limit 1];
        }

        return org;
    }
}