@IsTest
private class EQT_InputLookupAuraController_Test {
    @isTest static void getCurrentValueTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');

            a = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

            String ret = EQT_InputLookupAuraController.getCurrentValue(null, null);
            system.assert(String.isBlank(ret));

            ret = EQT_InputLookupAuraController.getCurrentValue('INVALID_OBJECT', 'INVALID_ID');
            system.assert(String.isBlank(ret));

            ret = EQT_InputLookupAuraController.getCurrentValue('INVALID_OBJECT', '000000000000000');
            system.assert(String.isBlank(ret));

            ret = EQT_InputLookupAuraController.getCurrentValue('Account', '000000000000000');
            system.assert(String.isBlank(ret));

            ret = EQT_InputLookupAuraController.getCurrentValue('Account', a.Id);
            system.assert(ret == a.Name);
        }
    }

    @isTest static void searchTest() {
        User u1 = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
        User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
        User u3 = EQT_TestFactory.createUser('testuser3@example.eqt', 'EQT Investor Relations');

        system.runAs(u1) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');

            String ret = EQT_InputLookupAuraController.searchSObject(null, null);
            system.assert(String.isBlank(ret));

            ret = EQT_InputLookupAuraController.searchSObject('INVALID_OBJECT', 'NO_RESULT_SEARCH_STRING');
            system.assert(String.isBlank(ret));
            String s = '\'*test*\'';

            Test.setFixedSearchResults(new List<String>{u1.Id,u2.Id,u3.Id});

            ret = EQT_InputLookupAuraController.searchSObject('User', 'test');
            system.assert(String.isNotEmpty(ret));
            List<EQT_InputLookupAuraController.SearchResult> sResList = (List<EQT_InputLookupAuraController.SearchResult>)JSON.deserialize(ret, List<EQT_InputLookupAuraController.SearchResult>.class);
            system.assert(sResList.size() == 3);
        }
    }
}