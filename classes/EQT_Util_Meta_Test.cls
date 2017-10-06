@isTest
private class EQT_Util_Meta_Test {	
	@isTest static void metaTest() {
        Organization org = EQT_Util_Meta.getOrgInfo();
        system.assert(org != null);
        
        //create Account
        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'account name', true);
        system.assert(a.Id != null);
        //give null as an argument
        Schema.SObjectType objType = EQT_Util_Meta.getObjectType(null);
        system.assertEquals(null, objType);
        objType = EQT_Util_Meta.getObjectType(a.Id);
        system.assertEquals(Schema.Account.SObjectType, objType);
        //get value from static map
        objType = EQT_Util_Meta.getObjectType(a.Id);
        system.assertEquals(Schema.Account.SObjectType, objType);
        
        //check record type        
        Id investorRecordType = EQT_Util_Meta.getRecordTypeId('Account.EQT_Investor');
        String recordTypeName = EQT_Util_Meta.getRTName(investorRecordType);
        system.assertEquals('EQT_Investor', recordTypeName);
        //get value from static map
        recordTypeName = EQT_Util_Meta.getRTName(investorRecordType);
        system.assertEquals('EQT_Investor', recordTypeName);
        
        //field set
        List<Schema.FieldSetMember> fieldList = EQT_Util_Meta.getFieldSetFields('Account','Investor');
        system.assert(fieldList.size() > 0);
        //get value from static map
        fieldList = EQT_Util_Meta.getFieldSetFields('Account','Investor');
        system.assert(fieldList.size() > 0);
        
        //fieldLabel
        String fieldLabel = EQT_Util_Meta.getFieldLabel('Account','Name');
        system.assert(fieldLabel == 'Account Name');
        //get value from static map
        fieldLabel = EQT_Util_Meta.getFieldLabel('Account','Name');
        system.assert(fieldLabel == 'Account Name');

        //profile
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
        String sysAdminProfileName = EQT_Util_Meta.profileName(p.Id);
        system.assertEquals(p.Name, sysAdminProfileName);
    }	
}