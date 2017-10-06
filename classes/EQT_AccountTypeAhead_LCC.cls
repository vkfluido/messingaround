public class EQT_AccountTypeAhead_LCC {
    @auraEnabled
    public static List<Account> search(String keyword, Decimal maxResults) {
        if (String.isEmpty(keyword)) {
            return null;
        }
        
		// adjust max results
        final integer maxResultsUse = (maxResults <= 0 ? 500 : maxResults.intValue() + 1);
        
        // search
        final String searchfor = keyword.toLowerCase() + '%';
        List<Account> results = [SELECT Id, Name FROM Account WHERE Name LIKE :searchfor ORDER BY Name ASC LIMIT :maxResultsUse];
        return results;
    }
}