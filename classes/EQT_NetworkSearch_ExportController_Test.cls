@isTest
public class EQT_NetworkSearch_ExportController_Test {

    @isTest
    public static void testXmlDeclaration() {
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        final String xml = ctrl.getXmlDeclaration();
        System.assertEquals('<?xml version="1.0" ?>', xml);
    }
    
    @isTest
    public static void testInstanceUrl() {
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        final String url = ctrl.getInstanceURL();
        System.assert(url.endsWithIgnoreCase('salesforce.com'));
    }
    
    @isTest
    public static void testGenerateParamsFromKeyNullKey() {
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey(null);
        System.assert(null == params);
    }
    
    @isTest
    public static void testGenerateParamsFromKeyEmptyKey() {
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey('');
        System.assert(null == params);
    }
    
    @isTest
    public static void testGenerateParamsFromKeyUnknownKey() {
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey('foo');
        System.assert(null == params);
    }
    
    @isTest
    public static void testGenerateParamsFromKeyMoreRecordsForKeyKey() {
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>();
        searches.add(new EQT_IANetworkSearch_Save__c(Key__c='foo', Filters__c='dummy'));
        searches.add(new EQT_IANetworkSearch_Save__c(Key__c='foo', Filters__c='dummy'));
        insert searches;
        
        Test.startTest();
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey('foo');
        System.assert(null == params);
        Test.stopTest();
    }
    
    @isTest
    public static void testGenerateParamsFromKeyOneSavedSearchNotMine() {
        List<User> users = [SELECT Id FROM User where Id!=:UserInfo.getUserId()];
        
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>();
        searches.add(new EQT_IANetworkSearch_Save__c(Key__c='foo', Filters__c='dummy', SavedSearch__c=True, OwnerId=users[0].Id));
        insert searches;
        
        Test.startTest();
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey('foo');
        System.assert(null == params);
        Test.stopTest();
    }
    
    @isTest
    public static void testGenerateParamsFromKeyOneSearchAllTypes() {
        final String filters = generateFilters(new List<String>{'sectorId'}, new List<String>{'functionalId'}, new List<String>{'geoId'}, 
                                               new List<String>{'suitablePositionId'}, new List<String>{'existingRoleId'}, 
                                               new List<String>{'engagementLevelId'}, new List<String>{'accountId'}, new List<String>{'dealId'});
        EQT_IANetworkSearch_Save__c search = new EQT_IANetworkSearch_Save__c(Key__c='foo', Filters__c=filters, SavedSearch__c=True, OwnerId=UserInfo.getUserId());
        insert search;
        
        Test.startTest();
        EQT_NetworkSearch_ExportController ctrl = new EQT_NetworkSearch_ExportController();
        EQT_NetworkSearch_Wrapper.SearchParams params = ctrl.generateParamsFromKey('foo');
        System.assert(null != params);
        System.assert(1 == params.deals.size());
        System.assert(1 == params.accounts.size());
        System.assert(1 == params.sectorFilter.size());
        System.assert(1 == params.functionalFilter.size());
        System.assert(1 == params.geoFilter.size());
        System.assert(1 == params.engagementLevel.size());
        System.assert(1 == params.existingRoles.size());
        System.assert(1 == params.suitablePositions.size());
        Test.stopTest();
    }
    
    
    private static String generateFilters(List<String> sectors, List<String> functional, List<String> geos, List<String> suitablePositions, List<String> existingRoles, List<String> engagementLevels, List<String> accounts, List<String> deals) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();
        generateIds(sectors, 'sector', gen);
        generateIds(functional, 'functional', gen);
        generateIds(geos, 'geo', gen);
        generateIds(suitablePositions, 'suitablePosition', gen);
        generateIds(existingRoles, 'existingRole', gen);
        generateIds(engagementLevels, 'engagementLevel', gen);
        generateIds(accounts, 'account', gen);
        generateIds(deals, 'deal', gen);
        gen.writeEndArray();
        
        String jsonstr = gen.getAsString();
        return EncodingUtil.base64Encode(Blob.valueOf(jsonstr));
    }
    
    private static void generateIds(List<String> ids, String type, JSONGenerator gen) {
        if (null != ids) {
            for (String id : ids) {
                gen.writeStartObject();
                gen.writeStringField('type', type);
                gen.writeStringField('id', id);
                gen.writeEndObject();
            }
        }
    }
    
    
}