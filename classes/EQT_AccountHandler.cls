/**
    About
    -----
    Description: Trigger Handler for the Account SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Automatically created Contact (of type Company) for given account based on metadata type settings (EQT_Admin_Business_Mapping__mdt) when new Account is created
        or edited and metadata fields are not empty.
    Use case 2. Delete associated contact when metadata fields are empty
    Use case 3. Set record type ID based on record type name provided by external system (EPM)
    Use case 4. Set the owner based on the EPM User ID on incoming record when set and a matching user is found
    Use case 5. Make sure an updated record, if from EPM is the latest version

    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AccountHandler implements EQT_ITrigger {  
    
    /* 
        Custom meta data mappings 
    */
    private EQT_Admin_Business_Mapping__mdt mapping;
    

    /*
        Itteration lists for processing trigger records
    */
    
    // List of contacts to create
    private List<sObject> contactsToInsert = new List<sObject>();
    
    // List of contact to update
    private List<Contact> contactsToUpdate = new List<Contact>();

    // Set of contact names for later update
    private Set<String> accountNamesUpdate = new Set<String>();
    
    // Set of contact names for later delete
    private Set<String> accountNamesDelete = new Set<String>();
    
    // Contact map to check if contact already exists (EQT_Full_Company_Name__c -> true)
    private Map<String, Contact> contactMap = new Map<String, Contact>();
    
    // Account map to set owner based on EPM Person ID (Record -> PersonID)
    private Map<sObject, String> accountsToSetOwnerbyEPMPersonID = new Map<sObject,String>();

    /* TA387 Rollback customizations for Summer 16 m:m Account Contact functionality
    //account role map
    private Map<Id, EQT_AccountContactRole__c> accountRoleMap = new Map<Id, EQT_AccountContactRole__c>();
    //roles to delete
    private List<EQT_AccountContactRole__c> rolesToDelete = new List<EQT_AccountContactRole__c>();
    */

    // trello card 159-commitments-in-the-same-fund-s-for-danske-wm-not-aggregated-in-account-related
    private Set<String> mergedAccountNames = new Set<String>();
    private Set<Id> commitmentsToDelete = new Set<Id>();
    private Map<Id, List<EQT_Commitment__c>> accountId2CommitmentsList = new Map<Id, List<EQT_Commitment__c>>();

    private Id integrationUserId {
        get {
            if(integrationUserId == null){

                String integrationUsername = EQT_UTIL_Settings.getEPMIntegrationUsername();
                List<User> userList = [SELECT Id FROM User WHERE Username =:integrationUsername];
                if(userList.size()==1){
                    integrationUserId = userList.get(0).Id;
                }
            }
            System.Debug('@@ integrationUserId: ' + integrationUserId);

            return integrationUserId;
        }
        set;
    }

    // Constructor
    public EQT_AccountHandler() {}

    public void bulkBefore() {
        /* TA387 Rollback customizations for Summer 16 m:m Account Contact functionality
        if(Trigger.isDelete) {
            for(EQT_AccountContactRole__c role : [SELECT Id, ContactId__c, AccountId__c
                                                    FROM EQT_AccountContactRole__c
                                                    WHERE AccountId__c IN :Trigger.oldMap.keySet()]) {
                                                    
                accountRoleMap.put(role.AccountId__c, role);
            }
        }
        */

        /*
        if(Trigger.isInsert || Trigger.isUpdate) {
            if (Trigger.isInsert) {
                
                for(sObject a : Trigger.new) {
                    Account theAcc = (Account) a;
                    // Use case 3. Set record type ID based on record type name provided by external system (EPM)
                    // - Checks for EPM Record Type Name set by external system & set record type ID on record
                    if (theAcc.EQT_EPM_Record_Type_Name__c!=null) {
                        try {
                            // -Set record type ID
                            theAcc.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Account.'+theAcc.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
                        } catch (Exception e) {
                            // -Do nothing if no match found
                        }
                    }
                    // Use case 4. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
                    // using their own external ID. Default otherwise is current user.
                    if (theAcc.ownerId==null)  theAcc.OwnerId = UserInfo.getUserId();
                    if (theAcc.EQT_EPM_Responsible__c!=null)
                    {
                        System.Debug(LoggingLevel.INFO,'@@ Accout with EQT Repsonsible set: '+theAcc);
                        accountsToSetOwnerbyEPMPersonID.put(a, theAcc.EQT_EPM_Responsible__c);
                        System.Debug(LoggingLevel.INFO,'@@ accountsToSetOwnerbyEPMPersonID: '+accountsToSetOwnerbyEPMPersonID);
                    }
                }
            }
            if (Trigger.isUpdate) {
                for(sObject a : Trigger.new) {
                    Account theAcc = (Account) a;
                    Account theAcc_old = (Account) Trigger.oldMap.get(a.Id);
                    
                    // Use case 5. Make sure an updated record, if from EPM is the latest version
                    EQT_DataTransformation_SVC.acceptOverwriteFromEPM(a, theAcc.EQT_EPM_LastModifiedDate__c, theAcc_old.LastModifiedDate);

                    // Use case 3. Set record type ID based on record type name provided by external system (EPM)
                    // - Checks for EPM Record Type Name set by external system & set record type ID on record
                    if (theAcc.EQT_EPM_Record_Type_Name__c!=null && (theAcc.EQT_EPM_Record_Type_Name__c != theAcc_old.EQT_EPM_Record_Type_Name__c)) {
                        try {
                            // -Set record type ID
                            theAcc.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Account.'+theAcc.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
                        } catch (Exception e) {
                            // -Do nothing if no match found
                        }
                    }

                    // Use case 4. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
                    // using their own external ID. Default otherwise is current user.
                    if (theAcc.EQT_EPM_Responsible__c!=null && (theAcc.EQT_EPM_Responsible__c != theAcc_old.EQT_EPM_Responsible__c)) 
                    {
                        System.Debug(LoggingLevel.INFO,'@@ Accout with EQT Repsonsible updated: '+theAcc);
                        accountsToSetOwnerbyEPMPersonID.put(a, theAcc.EQT_EPM_Responsible__c);
                        System.Debug(LoggingLevel.INFO,'@@ accountsToSetOwnerbyEPMPersonID: '+accountsToSetOwnerbyEPMPersonID);
                    }
                }
            }
            System.Debug(LoggingLevel.INFO,'@@ Call setOwnerByEPMPersonId: '+accountsToSetOwnerbyEPMPersonID);
            EQT_DataTransformation_SVC.setOwnerByEPMPersonId(accountsToSetOwnerbyEPMPersonID);
            System.Debug(LoggingLevel.INFO,'@@ Result setOwnerByEPMPersonId: '+accountsToSetOwnerbyEPMPersonID);
        }
        */
    }
    
    public void bulkAfter() {
        System.Debug('@@ starting bulkAfter');

        if(Trigger.isInsert || Trigger.isUpdate) {
            System.Debug('@@ isInsert || isUpdate');
            //Use case 1.
            // Get metadata object type fields
            mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
            
            if(Trigger.isUpdate) {
                Set<String> accountNames = new Set<String>();
                //Use case 1
                //Build contact map "before" change was made on account
                //This map is later use to determine which contacts should be updated according to account change
                for(sObject a : Trigger.old) {
                    accountNames.add((String) a.get('Name'));
                }
                
                String contactQuery = 'SELECT Id, LastName, EQT_Full_Company_Name__c, ' +
                                        mapping.EQT_Contact_Company_Email_field__c + ', ' +
                                        mapping.EQT_Contact_Company_Phone_field__c +
                                        ' FROM Contact WHERE EQT_Full_Company_Name__c IN :accountNames';
                                        
                system.debug('AccountHandler contactQ=' + contactQuery);
                                        
                for(Contact c : Database.query(contactQuery)) {            
                    contactMap.put(c.EQT_Full_Company_Name__c, c);
                }
            }
        }

        if(Trigger.isDelete) {
            System.Debug('@@ isDelete');

            // trello card 159-commitments-in-the-same-fund-s-for-danske-wm-not-aggregated-in-account-related
            Set<Id> mergedAccountMasterIds = new Set<Id>();
            for(sObject so : Trigger.old) {
                Account acc = (Account) so;

                if (acc.MasterRecordId != null) { // Trigger.old field MasterRecordId = Id of winning record after merge
                    mergedAccountMasterIds.add(acc.MasterRecordId); // remember master account ids for merged records
                    mergedAccountNames.add(acc.Name);
                }
            }
            System.Debug('@@ mergedAccountMasterIds: ' + mergedAccountMasterIds);

            if( !mergedAccountMasterIds.isEmpty() ){
                // if there are at least one merged account
                List<Account> masterAccountsList = [SELECT Id,Name FROM Account WHERE Id IN :mergedAccountMasterIds];
                for(Account a : masterAccountsList){
                    mergedAccountNames.add(a.Name);
                }

                // select all commitments for winning account (it already contains old and also merged commitments)
                List<EQT_Commitment__c> masterAccCommitments = [
                        SELECT Id, EQT_Fund__c, EQT_Investor__c, CreatedDate, CreatedById, LastModifiedById
                        FROM EQT_Commitment__c
                        WHERE EQT_Investor__c IN :mergedAccountMasterIds
                        ORDER BY EQT_Investor__c, EQT_Fund__c, CreatedDate DESC
                ];
                system.debug('@@ masterAccCommitments : ' + masterAccCommitments);

                for(EQT_Commitment__c commitment : masterAccCommitments){
                    // remember selected commitments splitted by account
                    if( !accountId2CommitmentsList.containsKey(commitment.EQT_Investor__c) ){
                        accountId2CommitmentsList.put(commitment.EQT_Investor__c, new List<EQT_Commitment__c>() );
                    }

                    accountId2CommitmentsList.get(commitment.EQT_Investor__c).add(commitment);
                }
                System.Debug('@@ accountId2CommitmentsList: ' + accountId2CommitmentsList);
            }
        }
    }
        
    public void beforeInsert(SObject so) {
        Account theAcc = (Account) so;

        // Use case 3. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theAcc.EQT_EPM_Record_Type_Name__c!=null) {
            try {
                // -Set record type ID
                theAcc.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Account.'+theAcc.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }
        // Use case 4. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
        // using their own external ID. Default otherwise is current user.
        if(theAcc.ownerId==null) {
            theAcc.OwnerId = UserInfo.getUserId();
        }

        if(theAcc.EQT_EPM_Responsible__c != null) {
            System.Debug(LoggingLevel.INFO,'@@ Accout with EQT Repsonsible set: '+theAcc);
            accountsToSetOwnerbyEPMPersonID.put(so, theAcc.EQT_EPM_Responsible__c);
            System.Debug(LoggingLevel.INFO,'@@ accountsToSetOwnerbyEPMPersonID: '+accountsToSetOwnerbyEPMPersonID);
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Account theAcc = (Account) so;
        Account theAcc_old = (Account) oldSo;

        // Use case 5. Make sure an updated record, if from EPM is the latest version
        EQT_DataTransformation_SVC.acceptOverwriteFromEPM(theAcc, theAcc.EQT_EPM_LastModifiedDate__c, theAcc_old.LastModifiedDate);

        // Use case 3. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theAcc.EQT_EPM_Record_Type_Name__c != null && (theAcc.EQT_EPM_Record_Type_Name__c != theAcc_old.EQT_EPM_Record_Type_Name__c)) {
            try {
                // -Set record type ID
                theAcc.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Account.'+theAcc.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }

        // Use case 4. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
        // using their own external ID. Default otherwise is current user.
        if(theAcc.EQT_EPM_Responsible__c != null && (theAcc.EQT_EPM_Responsible__c != theAcc_old.EQT_EPM_Responsible__c)) {
            System.Debug(LoggingLevel.INFO,'@@ Accout with EQT Repsonsible updated: '+theAcc);
            accountsToSetOwnerbyEPMPersonID.put(so, theAcc.EQT_EPM_Responsible__c);
            System.Debug(LoggingLevel.INFO,'@@ accountsToSetOwnerbyEPMPersonID: '+accountsToSetOwnerbyEPMPersonID);
        }
    }
    
    public void beforeDelete(SObject so) {
        /* TA387 Rollback customizations for Summer 16 m:m Account Contact functionality
        Account account = (Account) so;
        
        if(accountRoleMap.containsKey(account.Id)) {
            rolesToDelete.add(accountRoleMap.get(account.Id));
        }
        */
    }
    
    public void afterInsert(SObject so) {
        //Use case 1.
        //check if Account have values for fields defined in metadata - if so create contact
        Account account = (Account)so;
        
        if(mapping != null &&
            (account.get(mapping.EQT_Account_Company_Email_field__c) != null ||
            account.get(mapping.EQT_Account_Company_Phone_field__c) != null)) {
            
            //create new contact and add to list for later insert
            createNewContact(account);
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        //Use case 1.
        Account newAccount = (Account) so;
        Account oldAccount = (Account) oldSo;
        
        //if company email and phone was deleted from account - add related contact name for deletion
        if(newAccount.get(mapping.EQT_Account_Company_Email_field__c) == null &&
            newAccount.get(mapping.EQT_Account_Company_Phone_field__c) == null &&
            (oldAccount.get(mapping.EQT_Account_Company_Email_field__c) != null ||
            oldAccount.get(mapping.EQT_Account_Company_Phone_field__c) != null)
            ) {
         
            //contact delete
            accountNamesDelete.add(oldAccount.Name);   
        }
        else if(oldAccount.Name != newAccount.Name ||
                (
                    oldAccount.get(mapping.EQT_Account_Company_Email_field__c) != null &&
                    newAccount.get(mapping.EQT_Account_Company_Email_field__c) != null &&
                    oldAccount.get(mapping.EQT_Account_Company_Email_field__c) != newAccount.get(mapping.EQT_Account_Company_Email_field__c)
                ) ||
                (
                    oldAccount.get(mapping.EQT_Account_Company_Phone_field__c) != null &&
                    newAccount.get(mapping.EQT_Account_Company_Phone_field__c) != null &&
                    oldAccount.get(mapping.EQT_Account_Company_Phone_field__c) != newAccount.get(mapping.EQT_Account_Company_Phone_field__c)
                )) {
        
            //if contact exist - update
            if(contactMap.containsKey(oldAccount.Name)) {
                Contact toUpdate = contactMap.get(oldAccount.Name);
                toUpdate.LastName = newAccount.Name.length() > 80 ? newAccount.Name.substring(0,80) : newAccount.Name;
                toUpdate.EQT_Full_Company_Name__c = newAccount.Name;
                toUpdate.put(mapping.EQT_Contact_Company_Email_field__c, newAccount.get(mapping.EQT_Account_Company_Email_field__c));
                toUpdate.put(mapping.EQT_Contact_Company_Phone_field__c, newAccount.get(mapping.EQT_Account_Company_Phone_field__c));
                
                contactsToUpdate.add(toUpdate);
            }
            //if contact for account does not exists and account was updated with company phone or company info
            else if(!contactMap.containsKey(oldAccount.Name) &&
                    (newAccount.get(mapping.EQT_Account_Company_Phone_field__c) != null ||
                    newAccount.get(mapping.EQT_Account_Company_Email_field__c) != null)) {
                
                createNewContact(newAccount);
            }
        }
        else if((oldAccount.get(mapping.EQT_Account_Company_Email_field__c) == null &&
                newAccount.get(mapping.EQT_Account_Company_Email_field__c) != null) ||
                (oldAccount.get(mapping.EQT_Account_Company_Phone_field__c) == null &&
                newAccount.get(mapping.EQT_Account_Company_Phone_field__c) != null)) {
                
            //create new contact and add to list for later insert
            if(!contactMap.containsKey(newAccount.Name)) {
                createNewContact(newAccount);
            }
        }
    }
    
    public void afterDelete(SObject so) {
        System.Debug('@@ starting afterDelete account: ' + so);
        System.Debug('@@ starting accountId2CommitmentsList: ' + accountId2CommitmentsList);

        Account acc = (Account) so;

        // trello card 159-commitments-in-the-same-fund-s-for-danske-wm-not-aggregated-in-account-related
        if(
            acc.MasterRecordId != null &&
            accountId2CommitmentsList.containsKey(acc.MasterRecordId) &&
            accountId2CommitmentsList.get(acc.MasterRecordId)!=null &&
            !accountId2CommitmentsList.get(acc.MasterRecordId).isEmpty()
        ){
            // if there are at least one commitment for winning account
            Map<Id, List<EQT_Commitment__c>> fundIdToCommitment = new Map<Id, List<EQT_Commitment__c>>();
            for(EQT_Commitment__c commitment : accountId2CommitmentsList.get(acc.MasterRecordId)){
                // split commitments for winning account based on the fund
                if( !fundIdToCommitment.containsKey(commitment.EQT_Fund__c) ){
                    fundIdToCommitment.put( commitment.EQT_Fund__c, new List<EQT_Commitment__c>() );
                }
                fundIdToCommitment.get(commitment.EQT_Fund__c).add(commitment);
            }
            System.Debug('@@ fundIdToCommitment: ' + fundIdToCommitment);

            if( !fundIdToCommitment.isEmpty() ){
                for( Id fundId : fundIdToCommitment.keySet() ){
                    // loop through funds

                    Integer fundCommitmentsCount = fundIdToCommitment.get(fundId).size();

                    if(fundCommitmentsCount > 1){
                        // if there are at least two commitments for current fund
                        // it is needed to delete one
                        List<Id> commitmentIds2Del = new List<Id>();

                        for( EQT_Commitment__c commitment : fundIdToCommitment.get(fundId) ){
                            // loop through commitment for one fund, commitments are ordered by CreatedDate, so older are last
                            System.Debug('@@ Delete evalueation commitment : ' + commitment);
                            if(
                                commitment.CreatedById == integrationUserId ||
                                commitment.LastModifiedById == integrationUserId
                            ){
                                // delete commitmnet only if it was created by integration user, or updated by integration user
                                if(commitmentIds2Del.size() < (fundCommitmentsCount-1) ) {
                                    // add only if one record stays undelete - last one newest one has to stay untouched
                                    commitmentIds2Del.add(commitment.Id);
                                }
                            }
                        }

                        commitmentsToDelete.addAll(commitmentIds2Del);
                    }
                }
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
        //Use case 1. insert contacts
        if(!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
        
        //Use case 1. delete contacts
        if(!accountNamesDelete.isEmpty()) {
            delete [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c IN :accountNamesDelete];
        }
        
        //Use case 1. update contacts
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }

        if(!accountsToSetOwnerbyEPMPersonID.isEmpty()) {
            System.Debug(LoggingLevel.INFO,'@@ Call setOwnerByEPMPersonId: '+accountsToSetOwnerbyEPMPersonID);
            EQT_DataTransformation_SVC.setOwnerByEPMPersonId(accountsToSetOwnerbyEPMPersonID);
            System.Debug(LoggingLevel.INFO,'@@ Result setOwnerByEPMPersonId: '+accountsToSetOwnerbyEPMPersonID);
        }
        
        /* TA387 Rollback customizations for Summer 16 m:m Account Contact functionality
        //delete roles
        if(!rolesToDelete.isEmpty()) {
            delete rolesToDelete;
        }
        */

        // trello card 159-commitments-in-the-same-fund-s-for-danske-wm-not-aggregated-in-account-related
        if( !commitmentsToDelete.isEmpty() ){
            System.Debug('@@ Deleting commitments: ' + commitmentsToDelete);

            deleteCommitments(commitmentsToDelete); // needs to be performed in the future method, due to a relation to currently processing master account

            // send email to current user
            String emailSubject = 'Merge accounts';
            String emailBody = 'Following accounts has been merged: \r\n\r\n';
            for(String aName : mergedAccountNames){
                emailBody += aName + '\r\n';
            }
            emailBody += '\r\nAll related commitments will be updated on next investran integration process run. \r\n';

            String[] emailTo = new String[] {UserInfo.getUserEmail()};

            system.debug('@@ emailTo: ' + emailTo);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailTo);
            mail.setSubject(emailSubject);
            mail.setPlainTextBody(emailBody);

            Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.Email[] { mail }, false);

        }
    }
    
    //Use case 1. Method for creating contact
    private void createNewContact(Account account) {
        SObject newSobject = Schema.getGlobalDescribe().get('Contact').newSObject();
        newSobject.put('LastName', account.Name.length() > 80 ? account.Name.substring(0, 80) : account.Name);
        newSobject.put('EQT_Full_Company_Name__c', account.Name);
        newSobject.put(mapping.EQT_Contact_Company_Email_field__c, account.get(mapping.EQT_Account_Company_Email_field__c));
        newSobject.put(mapping.EQT_Contact_Company_Phone_field__c, account.get(mapping.EQT_Account_Company_Phone_field__c));
        newSobject.put('RecordTypeId', EQT_UTIL_Meta.getRecordTypeId('Contact.Company'));
        
        contactsToInsert.add(newSObject);
    }

    // trello card 159-commitments-in-the-same-fund-s-for-danske-wm-not-aggregated-in-account-related
    @future
    public static void deleteCommitments(Set<Id> commitmentIds2Del) {
        List<EQT_Commitment__c> cList = [SELECT Id FROM EQT_Commitment__c WHERE Id IN :commitmentIds2Del];
        if(cList.size()>0){
            delete cList;
        }
    }
}