@isTest
public class EQT_AffiliationHandler_Test {
	/**
	 * Test the creation of a new affiliation set as primary with no previous primary
	 * affiliations. Expected outcome: The account of the affiliation becomes the account
	 * on the contact.
     */
    @isTest static void NewPrimaryAffiliationTest() {
    	User u = getTestUser();
        system.runAs(u) {
            Account orgAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Original Account');
        	Account newAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'New Primary Account');
			System.assert(orgAccount.Id != null && newAccount.Id != null);
            
        	Contact contact = EQT_TestFactory.createSampleContact('John', 'Doe', orgAccount.Id);
            System.assert(contact.Id != null && contact.AccountId == orgAccount.Id);
        
            // Create an insert a new affiliation related to newAccount
            EQT_Affiliation__c affiliation = getTestAffiliation(newAccount, contact, 'Other', true);
            insert affiliation;

            // Test that the account of the affiliation is set as primary account of the contact
            contact = [SELECT Id, AccountId FROM Contact WHERE Id = :contact.Id];
            System.assert(contact.AccountId == newAccount.Id);
        }
    }
    
    /**
     * Test creation of a new primary account when there is already an active primary affiliation in place.
     */
    @isTest static void ReplacePrimaryAffiliationTest() {
    	User u = getTestUser();
        system.runAs(u) {
            Account orgAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Original Account');
        	Account newAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'New Primary Account');
			System.assert(orgAccount.Id != null && newAccount.Id != null);
            
        	Contact contact = EQT_TestFactory.createSampleContact('John', 'Doe', orgAccount.Id);
            System.assert(contact.Id != null && contact.AccountId == orgAccount.Id);
            
            // Create a bunch of non-active/non-primary
            List<EQT_Affiliation__c> nonPrimaries = getMultipleAffiliations(contact);
            insert nonPrimaries;
            
            // Create active affiliation with a start date in the past
            EQT_Affiliation__c oldPrimary = getTestAffiliation(orgAccount, contact, 'Other', true, Date.newInstance(2010, 10, 10), null);
            insert oldPrimary;
            // Test that the account of the affiliation is set as primary account of the contact
            contact = [SELECT Id, AccountId FROM Contact WHERE Id = :contact.Id];
            System.assert(contact.AccountId == orgAccount.Id);
            
            // Insert the new affiliation
            EQT_Affiliation__c newPrimary = getTestAffiliation(newAccount, contact, 'Other', true);
            insert newPrimary;

            // Test that the account of the affiliation is set as primary account of the contact
            contact = [SELECT Id, AccountId FROM Contact WHERE Id = :contact.Id];
            System.assert(contact.AccountId == newAccount.Id);
            
            // Test that no other affiliations are marked primary for this contact
            Integer cnt = [SELECT COUNT() FROM EQT_Affiliation__c 
                           WHERE Id != :newPrimary.Id AND Primary__c = true AND Contact__c = :contact.Id];
            System.assert(cnt == 0);
           
        }
    }

    private static EQT_Affiliation__c getTestAffiliation(Account account, Contact contact, String role, Boolean primary) {
        return getTestAffiliation(account, contact, role, primary, Date.today(), null);
    }    
    private static EQT_Affiliation__c getTestAffiliation(Account account, Contact contact, String role, Boolean primary, Date startDate, Date endDate) {
        EQT_Affiliation__c affiliation = new EQT_Affiliation__c (
                Contact__c = contact.Id,
                Account__c = account.Id,
                Role__c = role,
                Primary__c = primary,
                Start_Date__c = startDate,
                End_Date__c = endDate
            );
        return affiliation;
    }
    
    private static List<EQT_Affiliation__c> getMultipleAffiliations(Contact contact) {
        // Create a bunch of non-primary affiliations
        List<EQT_Affiliation__c> nonPrimaries = new List<EQT_Affiliation__c>();
        for (Integer i = 0; i < 10; i++) {
            nonPrimaries.add(
                getTestAffiliation(
            		EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Account_'+i),
                    contact,
                    'Other',
                    false,
                    Date.newInstance((2000 + i), (i+1), (25-i)),
                    Date.newInstance((2000 + (i+2)), (i+1), (25-i))
            	)
            );
        }
        return nonPrimaries;
    }
    private static User getTestUser() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Business Line Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        return u;
    }

}