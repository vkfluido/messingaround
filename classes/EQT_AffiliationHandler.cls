/**
    About
    -----
    Description: Trigger Handler for the EQT_Affiliation SObject.
                 This class implements the EQT_ITrigger interface to help ensure 
                 the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: March 2017
    
    Details / Methods
    -----------------
    Use case 1. Make the account on affiliation the primary Account on Contact if
                the primary flag is set, on unset primary flag on any existing 
		        affiliations
   
    Update History
    --------------
    2017-03-16: Created, rmohr

    Issues / TODOs
    --------------
	- Handling deletes - unsure what should happen (RMOHR 2017-03-16)
*/
public with sharing class EQT_AffiliationHandler implements EQT_ITrigger {  
    
    private List<Contact> changedContacts = new List<Contact>();
    private List<EQT_Affiliation__c> changedAffiliations = new List<EQT_Affiliation__c>();
    private Map<Id, List<EQT_Affiliation__c>> contactAffiliationMap = new Map<Id, List<EQT_Affiliation__c>>();
   
    public EQT_AffiliationHandler() {}

    public void bulkBefore() {}
    
    public void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Id> contactIds = new List<Id>();
            for (SObject o : Trigger.new) {
                EQT_Affiliation__c af = (EQT_Affiliation__c) o;
                if (af.Active__c && af.Primary__c) {
                    contactIds.add(af.Contact__c);    
                }        
            }
            // Use Case 1: Collect all affiliations marked as primary for a given contact
            List<EQT_Affiliation__c> affiliations = [
                SELECT Id, Account__c, Contact__c, Primary__c FROM EQT_Affiliation__c 
                WHERE Contact__c IN :contactIds AND Primary__c = true AND Active__c = true
                ORDER BY Start_Date__c DESC
            ];
            System.debug(LoggingLevel.DEBUG, affiliations.size() + ' existing affiliations found for contacts ' + contactIds);
            // Create a map of affiliations by contacts for use in cleaning up previous primaries
            for (EQT_Affiliation__c af : affiliations) {
                List<EQT_Affiliation__c> afList = contactAffiliationMap.get(af.Contact__c);
                if (afList == null) {
                    afList = new List<EQT_Affiliation__c>();
                }
                afList.add(af);
                contactAffiliationMap.put(af.Contact__c, afList);
            }
        }
    }
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {
        setPrimaryAccount((EQT_Affiliation__c) so);
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
    	setPrimaryAccount((EQT_Affiliation__c) so);
    }
    
    public void afterDelete(SObject so) {
        // RMOHR: Unsure what to do here - should we prevent user from deleting affiliations and only allow deactivation?
    }
   	
    /**
     * Use Case 1: If primary flag is set make this affiliation the primary account.
     */
    private void setPrimaryAccount(EQT_Affiliation__c affiliation) {
        if (affiliation.Primary__c) {
            Contact contact = new Contact(id = affiliation.Contact__c);
            contact.AccountId = affiliation.Account__c;
            changedContacts.add(contact);
            // Find previous primaries
            unsetPrimaryAccount(contactAffiliationMap.get(contact.Id));
        }
    }
    
    /**
     * Sets all existing affiliations for the contact to not-primary.
     */ 
    private void unsetPrimaryAccount(List<EQT_Affiliation__c> affiliations) {
        if (affiliations.size() > 0) {
            for (EQT_Affiliation__c p : affiliations) {
                p.Primary__c = false; // Unset from primary
                System.debug(LoggingLevel.DEBUG, 'Primary set false for Affiliation ' + p);
                changedAffiliations.add(p); // store for bulk update
            }
        }
    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        if (changedContacts.size() > 0) {
            update changedContacts;
        }
        if (changedAffiliations.size() > 0) {
            update changedAffiliations;
        }
    }
}