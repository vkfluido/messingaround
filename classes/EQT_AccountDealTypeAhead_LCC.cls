public class EQT_AccountDealTypeAhead_LCC {

    @auraEnabled
    public static List<SObject> accountSearch(String keyword, Decimal maxResults) {
        return EQT_AccountTypeAhead_LCC.search(keyword, maxResults);
    }
    
    @auraEnabled
    public static List<SObject> dealSearch(String keyword, Decimal maxResults) {
        return EQT_DealTypeAhead_LCC.search(keyword, maxResults);
    }
    
}