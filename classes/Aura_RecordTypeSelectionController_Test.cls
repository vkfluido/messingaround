@isTest
public class Aura_RecordTypeSelectionController_Test {
	@isTest
    static void Test_RecordType_Selection(){
        String objName = 'Contact';
        String jsonRecordTypes = Aura_RecordTypeSelectionController.findRecordTypes(objName);
        System.debug(objName + ' record types in JSON format:\n' + jsonRecordTypes);
        System.assert(String.isNotBlank(jsonRecordTypes));
    }

}