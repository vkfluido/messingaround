public class Aura_RecordTypeSelectionController {
	@AuraEnabled
    public static String findRecordTypes(String objName){
        System.debug(objName);
        String returnString='';
        String queryString='Select Id, Name from RecordType where sObjectType =: objName and IsActive=true';
        List<SObject> recordTypeList= Database.query(queryString);
        List<RecordTypeWrapper> wrapperList=new List<RecordTypeWrapper>();
        for(SObject sb : recordTypeList)  {
            RecordTypeWrapper rw=new RecordTypeWrapper();
            rw.recordTypeLabel=String.valueOf(sb.get('Name'));
            rw.recordTypeId=String.valueOf(sb.get('Id'));
            wrapperList.add(rw);
        } 
        returnString= JSON.serialize(wrapperList);
        return returnString;
    }
    public class RecordTypeWrapper{
        public String recordTypeLabel{get;set;}
        public String recordTypeId{get;set;}
    }
}