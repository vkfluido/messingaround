@isTest
public class EQT_AccountTypeAhead_LCC_Test {
	@isTest
    public static void testSearchNoKeyword() {
        List<Account> result = EQT_AccountTypeAhead_LCC.search('', 100);
        System.assert(result == null);
    }
    
    @isTest
    public static void testSearchKeyword() {
        List<Account> result = EQT_AccountTypeAhead_LCC.search('foo', 100);
        System.assert(result.size() == 0);
    }
}