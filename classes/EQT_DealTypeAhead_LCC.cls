public class EQT_DealTypeAhead_LCC {
    @auraEnabled
    public static List<Opportunity> search(String keyword, Decimal maxResults) {
        if (String.isEmpty(keyword)) {
            return null;
        }
        
        // adjust max results
        final integer maxResultsUse = (maxResults <= 0 ? 500 : maxResults.intValue() + 1);
        
        // search
        final String searchfor = keyword.toLowerCase() + '%';
        List<Opportunity> results = [SELECT Id, Name, Account.Name FROM Opportunity WHERE Name LIKE :searchfor OR Account.name like :searchfor ORDER BY Name ASC LIMIT :maxResultsUse];
        return results;
    }
}