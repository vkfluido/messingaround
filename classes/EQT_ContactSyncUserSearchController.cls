/**
    Update History
    --------------
    2017-05-29 felix.guerrero@fluidogroup.com - Updated search query to find users also by first or lastname, instead of only by 'Name'
*/
public with sharing class EQT_ContactSyncUserSearchController {
    
	@AuraEnabled
	public static List<User> searchUsers(String searchKeyWord) {
		String searchKey = searchKeyWord + '%';
		List <User> result = new List<User> ();
		List <User> lst = [select id, Name from User where IsActive=True and (FirstName LIKE : searchKey OR LastName LIKE: searchKey OR Name LIKE: searchKey) LIMIT 20];

		for (User user : lst) {
			result.add(user);
		}
		return result;
	}
    
    /*
    Commented out to avoid writing test cases as the code is not used.

    private static String getObjectTypeFromID(Id recordId) {
        Map<String,String> keys = new Map<String,String>();
		Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
        for (String s : describe.keyset()) {
			keys.put(describe.get(s).getDescribe().getKeyPrefix(), s);
        }
        String type = keys.get(String.valueOf(recordId).substring(0,3));
        return type;
    }
    */
}