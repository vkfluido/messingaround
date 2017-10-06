/**
    About
    -----
    Description: Trigger Handler for the Contact SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Set record type ID based on record type name provided by external system (EPM)
    Use case 2. Ensure contact mailing address
    Use case 3. Ensure no private contacts - set default account on contacts with blank account
    SFAM-1 - populating of Assistant To field
    Use case 4. Set Contact Sync last modified date (SFAM-136)
   
    Update History
    --------------
    Created May 2016 - R.B.
    Updated March 2017 - R.B.
    Updated 2017-03-29 - RMOHR
    Updated 2017-05-24 - F.A.
    Updated 2017-05-29 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_ContactHandler implements EQT_ITrigger {  
    
    private Set<Id> accountIds = new Set<Id>();
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Set<Id> contactsToUpdateTitle = new Set<Id>(); // Set of Ids of Contacts where Formal Title was updated.

    private Set<Id> contactIdsForAssistanToEvaluation = new Set<Id>(); // SFAM-1

    private static String employeeContactRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee');
    private static String extContactRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getExternalContactRecordTypeName());
    private static String iaContactRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());

    // Constructor
    public EQT_ContactHandler() {}

    public void bulkBefore() {

        //Use case 2 - get all accounts associated with contacts
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(SObject so : Trigger.new) {
                Contact contact = (Contact)so;

                if(contact.AccountId != null) {
                    accountIds.add(contact.AccountId);
                }
                if((Trigger.isInsert && (contact.EQT_Formal_Title__c != null)) ||
                   (Trigger.isUpdate && (contact.EQT_Formal_Title__c != contact.Salutation))){
                    contactsToUpdateTitle.add(contact.Id);
                }
            }

            if(!accountIds.isEmpty()) {
                accountMap = new Map<Id, Account>([SELECT Id, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet FROM Account WHERE Id IN :accountIds]);
            }
        }
    }
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {
        Contact theCon = (Contact) so;
        // Use case 1. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theCon.EQT_EPM_Record_Type_Name__c != null) {
            try {
                // Set record type ID
                theCon.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.'+theCon.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // Do nothing if no match found
            }
        }
        
        // Use case 3 - set default account if account field is blank
        theCon = checkAndSetAccount(theCon);

        //Use case 2 - set contact fields if needed based on related account
        if(theCon.AccountId != null
                && accountMap.containsKey(theCon.AccountId)
                && String.isEmpty(theCon.MailingPostalCode)
                && String.isEmpty(theCon.MailingCity)
                && String.isEmpty(theCon.MailingCountry)
                && String.isEmpty(theCon.MailingState)
                && String.isEmpty(theCon.MailingStreet)) {

            theCon.MailingCity = accountMap.get(theCon.AccountId).BillingCity;
            theCon.MailingCountry = accountMap.get(theCon.AccountId).BillingCountry;
            theCon.MailingPostalCode = accountMap.get(theCon.AccountId).BillingPostalCode;
            theCon.MailingState = accountMap.get(theCon.AccountId).BillingState;
            theCon.MailingStreet = accountMap.get(theCon.AccountId).BillingStreet;

        }

        // Set contact Formal Title
        if(contactsToUpdateTitle.contains(theCon.Id)){
            theCon.Salutation = theCon.EQT_Formal_Title__c;
        }

        //Use case 4 - Set contact sync last modified date
        setContactSyncLastModifiedDate(theCon, null);

        // SFAM-234
        if(theCon.RecordTypeId==employeeContactRTId && theCon.EQT_Ex_Employee__c==true){
            theCon.RecordTypeId = extContactRTId;
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Contact theCon = (Contact) so;
        Contact theCon_old = (Contact) oldSo;
        
        // Use case 5. Make sure an updated record, if from EPM is the latest version
        EQT_DataTransformation_SVC.acceptOverwriteFromEPM(so, theCon.EQT_EPM_LastModifiedDate__c, theCon_old.LastModifiedDate);

        // Use case 3. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theCon.EQT_EPM_Record_Type_Name__c != null && (theCon.EQT_EPM_Record_Type_Name__c != theCon_old.EQT_EPM_Record_Type_Name__c)) {
            try {
                // Set record type ID
                theCon.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.'+theCon.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // Do nothing if no match found
            }
        }
        
        // Use case 3 - set default account if account field is blank
        theCon = checkAndSetAccount(theCon);

        //Use case 2 - set contact fields if needed based on related account it was changed
        if(theCon.AccountId != theCon_old.AccountId
            && theCon.AccountId != null
            && accountMap.containsKey(theCon.AccountId)
            && String.isEmpty(theCon.MailingPostalCode)
            && String.isEmpty(theCon.MailingCity)
            && String.isEmpty(theCon.MailingCountry)
            && String.isEmpty(theCon.MailingState)
            && String.isEmpty(theCon.MailingStreet)) {

            theCon.MailingCity = accountMap.get(theCon.AccountId).BillingCity;
            theCon.MailingCountry = accountMap.get(theCon.AccountId).BillingCountry;
            theCon.MailingPostalCode = accountMap.get(theCon.AccountId).BillingPostalCode;
            theCon.MailingState = accountMap.get(theCon.AccountId).BillingState;
            theCon.MailingStreet = accountMap.get(theCon.AccountId).BillingStreet;

        }

        // Set contact Formal Title
        if(contactsToUpdateTitle.contains(theCon.Id)){
            if(theCon.EQT_Formal_Title__c != null || theCon_old.EQT_Formal_Title__c == theCon.Salutation)
                theCon.Salutation = theCon.EQT_Formal_Title__c;
        }

        //Use case 4 - Set contact sync last modified date
        setContactSyncLastModifiedDate(theCon, theCon_old);

        // SFAM-234
        if(
            theCon.RecordTypeId==employeeContactRTId &&
            theCon.EQT_Ex_Employee__c==true &&
            theCon_old.EQT_Ex_Employee__c!=true
        ){
            theCon.RecordTypeId = extContactRTId;
        }
    }
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        Contact c = (Contact) so;

        // SFAM-1
        if(c.EQT_Primary_Assistant__c!=null){
            contactIdsForAssistanToEvaluation.add(c.EQT_Primary_Assistant__c);
        }
        if(c.Secondary_Assistant__c!=null){
            contactIdsForAssistanToEvaluation.add(c.Secondary_Assistant__c);
        }
        system.debug('afterInsert contactIdsForAssistanToEvaluation: ' + contactIdsForAssistanToEvaluation);
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        Contact c = (Contact) so;
        Contact cOld = (Contact) oldSo;

        // SFAM-1 - populating of Assistant To field
        if(c.EQT_Primary_Assistant__c!=cOld.EQT_Primary_Assistant__c){
            if(c.EQT_Primary_Assistant__c!=null) {
                contactIdsForAssistanToEvaluation.add(c.EQT_Primary_Assistant__c);
            }
            if(cOld.EQT_Primary_Assistant__c!=null) {
                contactIdsForAssistanToEvaluation.add(cOld.EQT_Primary_Assistant__c);
            }
        }

        if(c.Secondary_Assistant__c!=cOld.Secondary_Assistant__c){
            if(c.Secondary_Assistant__c!=null) {
                contactIdsForAssistanToEvaluation.add(c.Secondary_Assistant__c);
            }
            if(cOld.Secondary_Assistant__c!=null) {
                contactIdsForAssistanToEvaluation.add(cOld.Secondary_Assistant__c);
            }
        }

        system.debug('afterUpdate contactIdsForAssistanToEvaluation: ' + contactIdsForAssistanToEvaluation);
    }
    
    public void afterDelete(SObject so) {
        Contact c = (Contact) so;

        // SFAM-1
        if(c.EQT_Primary_Assistant__c!=null){
            contactIdsForAssistanToEvaluation.add(c.EQT_Primary_Assistant__c);
        }
        if(c.Secondary_Assistant__c!=null){
            contactIdsForAssistanToEvaluation.add(c.Secondary_Assistant__c);
        }
        system.debug('afterDelete contactIdsForAssistanToEvaluation: ' + contactIdsForAssistanToEvaluation);
    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {

        // SFAM-1
        system.debug('andFinally contactIdsForAssistanToEvaluation: ' + contactIdsForAssistanToEvaluation);
        List<Contact> contactsToUpdate = evaluateAssistantTo();

        system.debug('andFinally contactsToUpdate: ' + contactsToUpdate);
        if(contactsToUpdate!=null && contactsToUpdate.size()>0){
            update contactsToUpdate;
        }
    }
    
    private Contact checkAndSetAccount(Contact theCon) {
        // Use case 3 - set default account if account field is blank
        // Only applies to External Contact and IA contact types        
        if (theCon.AccountId == null && (theCon.RecordTypeId == extContactRTId || theCon.RecordTypeId == iaContactRTId)) {
            // Default account is defined in custom settings
            theCon.AccountId = EQT_Util_Settings.getDefaultAccountId();
            System.debug(LoggingLevel.DEBUG, '@@ Account ID set to default (' + theCon.AccountId + ') for contact ' + theCon);
        }
        return theCon;
    }

    private List<Contact> evaluateAssistantTo(){
        if(contactIdsForAssistanToEvaluation==null || contactIdsForAssistanToEvaluation.size()<=0){
            return null;
        }

        List<Contact> contactsToUpdate = [
            SELECT
                Id, EQT_Assistant_To__c,
                (SELECT Name FROM Executives__r),
                (SELECT Name FROM Secondary_Executives__r)
            FROM Contact
            WHERE Id IN :contactIdsForAssistanToEvaluation
        ];
        system.debug('evaluateAssistantTo contactsToUpdate: ' + contactsToUpdate);

        if(contactsToUpdate.size()<=0){
            return null;
        }


        for(Contact c : contactsToUpdate){
            c.EQT_Assistant_To__c = '';

            for(Contact executive : c.Executives__r){
                if(c.EQT_Assistant_To__c.length()>0){
                    c.EQT_Assistant_To__c += ' & ';
                }
                c.EQT_Assistant_To__c += executive.Name;
            }

            for(Contact secExecutive : c.Secondary_Executives__r){
                if(c.EQT_Assistant_To__c.length()>0){
                    c.EQT_Assistant_To__c += ' & ';
                }
                c.EQT_Assistant_To__c += secExecutive.Name;
            }

            system.debug('evaluateAssistantTo c.EQT_Assistant_To__c: ' + c.EQT_Assistant_To__c);

            if(c.EQT_Assistant_To__c.length()>255){
                c.EQT_Assistant_To__c = c.EQT_Assistant_To__c.left(252) + '...';
            }
            system.debug('evaluateAssistantTo c.EQT_Assistant_To__c: ' + c.EQT_Assistant_To__c);
        }

        return contactsToUpdate;
    }

    private void setContactSyncLastModifiedDate(Contact cNew, Contact cOld) {
        //insert call
        if(cOld == null) {
            cNew.EQT_Contact_Sync_Last_Modified_Date__c = Datetime.now();
        }
        else { //update call
            if(cNew.FirstName != cOld.FirstName
                    || cNew.MiddleName != cOld.MiddleName
                    || cNew.LastName != cOld.LastName
                    || cNew.AccountId != cOld.AccountId
                    || cNew.Title != cOld.Title
                    || cNew.Email != cOld.Email
                    || cNew.EQT_Email_2__c != cOld.EQT_Email_2__c
                    || cNew.EQT_Email_3__c != cOld.EQT_Email_3__c
                    || cNew.Phone != cOld.Phone
                    || cNew.MobilePhone != cOld.MobilePhone
                    || cNew.OtherPhone != cOld.OtherPhone
                    || cNew.MailingCity != cOld.MailingCity
                    || cNew.MailingCountry != cOld.MailingCountry
                    || cNew.MailingPostalCode != cOld.MailingPostalCode
                    || cNew.MailingState != cOld.MailingState
                    || cNew.MailingStreet != cOld.MailingStreet
                    || cNew.OtherCity != cOld.OtherCity
                    || cNew.OtherCountry != cOld.OtherCountry
                    || cNew.OtherPostalCode != cOld.OtherPostalCode
                    || cNew.OtherState != cOld.OtherState
                    || cNew.OtherStreet != cOld.OtherStreet
                    || cNew.EQT_Alternative_Address__c != cOld.EQT_Alternative_Address__c) {

                cNew.EQT_Contact_Sync_Last_Modified_Date__c = Datetime.now();
            }
        }
    }
}