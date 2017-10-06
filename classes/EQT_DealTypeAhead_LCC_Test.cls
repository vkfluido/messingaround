@isTest
public class EQT_DealTypeAhead_LCC_Test {
	@isTest
    public static void testSearchNoKeyword() {
        List<Opportunity> result = EQT_DealTypeAhead_LCC.search('', 100);
        System.assert(result == null);
    }
    
    @isTest
    public static void testSearchKeyword() {
        List<Opportunity> result = EQT_DealTypeAhead_LCC.search('foo', 100);
        System.assert(result.size() == 0);
    }
}