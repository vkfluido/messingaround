@isTest
private class EQT_AccountHandler_Test {

    @isTest static void accountSetOwnerByPersonIdFromEPM() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        User responsibleUser1 = EQT_TestFactory.createUser('responsibleUser1@example.eqt', 'EQT Investor Relations');
        responsibleUser1.EQT_EPM_User_ID__c = '11111';

        User responsibleUser2 = EQT_TestFactory.createUser('responsibleUser2@example.eqt', 'EQT Investor Relations');
        responsibleUser2.EQT_EPM_User_ID__c = '22222';

        User irDefaultUser = EQT_TestFactory.createUser('irDefaultUser@example.eqt', 'EQT Investor Relations');
        irDefaultUser.IR_default_user__c = true;

        update new List<User> {responsibleUser1, responsibleUser2, irDefaultUser};

        System.debug(LoggingLevel.INFO, '@@ responsibleUser1 '+responsibleUser1);
        System.debug(LoggingLevel.INFO, '@@ responsibleUser2 '+responsibleUser2);
        System.debug(LoggingLevel.INFO, '@@ irDefaultUser '+irDefaultUser);

        Account a2;
        Contact c2;

        //set default account
        Account undefinedCompany = EQT_TestFactory.createSampleAccount('Account.EQT_Placeholder', 'Undefined Company');
        system.assert(undefinedCompany.Id != null);
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('EQT_Default_Account_ID__c', undefinedCompany.Id);
        update appSettings;

        system.runAs(u) {
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');

            Contact c = new Contact();
            c.LastName = 'Generic Contact, will get default RT';
            c.EQT_EPM_PersonID__c = '1234';
            c.EQT_EPM_User_ID__c = responsibleUser1.EQT_EPM_User_ID__c;
            c.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
            insert c;
            System.debug(LoggingLevel.INFO, '@@ c'+c);

            c2 = new Contact();
            c2.LastName = 'Generic Contact2, will get default RT';
            c2.EQT_EPM_PersonID__c = '4321';
            c2.EQT_EPM_User_ID__c = responsibleUser2.EQT_EPM_User_ID__c;
            c2.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
            insert c2;
            System.debug(LoggingLevel.INFO, '@@ c2 '+c2);

            // Set some User ID on the users to connect with
            // See if the Owner field is set
            a2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account', false);
            a2.EQT_EPM_Responsible__c = c.EQT_EPM_PersonID__c; 
            insert a2;
            
            Account aResult = [select id,OwnerId,EQT_EPM_Responsible__c from Account where id=:a2.id];
            system.assertEquals(responsibleUser1.Id, aResult.OwnerId);  
        }

        system.runAs(responsibleUser1) {
            a2.EQT_EPM_Responsible__c = c2.EQT_EPM_PersonID__c;
            update a2;
            a2 = [select id,OwnerId,EQT_EPM_Responsible__c from Account where id=:a2.id];
            system.assertEquals(responsibleUser2.Id, a2.OwnerId);
        }

        system.runAs(responsibleUser2) {
            a2.EQT_EPM_Responsible__c = '12789';
            update a2;
            a2 = [select id,OwnerId,EQT_EPM_Responsible__c from Account where id=:a2.id];
            system.assertEquals(true, [SELECT IR_default_user__c FROM User WHERE Id = :a2.OwnerId].IR_default_user__c);
        }
    }
    
    @isTest static void accountSetRecordIDByNamefromEPM() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        system.runAs(u) {
            //Create sample account and check the record type is set
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', accountName, false);
            a.EQT_EPM_Record_Type_Name__c = 'EQT_Investor';
            insert a;
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor'), [SELECT Id, RecordTypeId FROM Account WHERE Id = :a.Id].RecordTypeId);
            
            //Update sample account with other record type name and check the record type is set
            a.EQT_EPM_Record_Type_Name__c = 'EQT_Investor_Gatekeeper';
            update a;
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor_Gatekeeper'), [SELECT Id, RecordTypeId FROM Account WHERE Id = :a.Id].RecordTypeId);
            //system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor_Gatekeeper'), a.RecordTypeId);    
        }
    }

    @isTest static void accountDateComparisionTest() {
        User u = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        User integrationUser = EQT_TestFactory.createUser('testIntegrationUser@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :integrationUser.Id].size());
        Account a;

        system.runAs(u) {
            String accountName = 'test account';
            a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, true);
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor'), [SELECT Id, RecordTypeId FROM Account WHERE Id = :a.Id].RecordTypeId);
        }

        /*
        system.runAs(integrationUser) {
            //try to update account without emp last modified date
            try {
                a.EQT_Equity__c = true;
                update a;
            }
            catch(Exception e) {
                system.assert(e.getMessage().contains('EQT_EPM_LastModifiedDate__c date field must be supplied to avoid accidental overwrite'));
            }
        }
        */

        //now update date on account as regular user and set it before standard last modified date
        system.runAs(u) {
            Datetime epmDT = Datetime.now().addDays(-1);
            a.EQT_EPM_LastModifiedDate__c = epmDT;
            update a;
            system.assertEquals(epmDT, [SELECT Id, EQT_EPM_LastModifiedDate__c FROM Account WHERE Id = :a.Id].EQT_EPM_LastModifiedDate__c);
        }

        /*
        //try update
        system.runAs(integrationUser) {
            try {
                a.EQT_Equity__c = true;
                update a;
            }
            catch(Exception e) {
                system.assert(e.getMessage().contains('Record is more recent in Salesforce'));
            }
        }
        */

        //now update date after last modified date
        system.runAs(u) {
            Datetime epmDT = Datetime.now().addDays(1);
            a.EQT_EPM_LastModifiedDate__c = epmDT;
            update a;
            system.assertEquals(epmDT, [SELECT Id, EQT_EPM_LastModifiedDate__c FROM Account WHERE Id = :a.Id].EQT_EPM_LastModifiedDate__c);
        }

        /*
        //try update
        system.runAs(integrationUser) {
            a.EQT_Equity__c = true;
            update a;

            system.assertEquals(true, [SELECT Id, EQT_Equity__c FROM Account WHERE Id = :a.Id].EQT_Equity__c);
        }
        */
    }

    @isTest static void accountContactNoTriggerCreationTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //create new contact based on Account
            SObject newSobject = Schema.getGlobalDescribe().get('Contact').newSObject();
            newSobject.put('LastName', insertedAccount[0].Name.length() > 80 ? insertedAccount[0].Name.substring(0, 80) : insertedAccount[0].Name);
            newSobject.put('EQT_Full_Company_Name__c', insertedAccount[0].Name);
            newSobject.put(mapping.EQT_Contact_Company_Email_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            newSobject.put(mapping.EQT_Contact_Company_Phone_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            newSobject.put('RecordTypeId', EQT_UTIL_Meta.getRecordTypeId('Contact.Company'));
            
            insert newSobject;
            
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());          
        }
    }
    
    @isTest static void accountContactTriggerCreationTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, 'email@example.test', null);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify new contact with the same name was created           
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());          
        }
    }
    
    @isTest static void accountContactTriggerNoCreationTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            //create account without company email and company phone
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify no new contact was created        
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());          
        }
    }
    
    @isTest static void accountContactNonTriggerUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, 'test@example.test', null);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //create new contact based on Account
            SObject newSobject = Schema.getGlobalDescribe().get('Contact').newSObject();
            newSobject.put('LastName', insertedAccount[0].Name.length() > 80 ? insertedAccount[0].Name.substring(0, 80) : insertedAccount[0].Name);
            newSobject.put('EQT_Full_Company_Name__c', insertedAccount[0].Name);
            newSobject.put(mapping.EQT_Contact_Company_Email_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            newSobject.put(mapping.EQT_Contact_Company_Phone_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            newSobject.put('RecordTypeId', EQT_UTIL_Meta.getRecordTypeId('Contact.Company'));
            
            insert newSobject;
            
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            
            //update account name
            String newAccountName = 'new test account';
            a.Name = newAccountName;
            update a;
            
            system.assertEquals(0, [SELECT Id FROM Account WHERE Name = :accountName].size());
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :newAccountName].size());
            
            //update "connected" contact
            Contact toUpdate = [SELECT Id, LastName, EQT_Full_Company_Name__c FROM Contact WHERE EQT_Full_Company_Name__c = :accountName];
            toUpdate.EQT_Full_Company_Name__c = newAccountName;
            toUpdate.LastName = newAccountName.length() > 80 ? newAccountName.substring(0,80) : newAccountName;
            
            update toUpdate;
            
            //verify update
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :newAccountName].size());                     
        }
    }
    
    @isTest static void accountContactNonTriggerDeleteTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, 'test@example.test', '+123456789');
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //create new contact based on Account
            SObject newSobject = Schema.getGlobalDescribe().get('Contact').newSObject();
            newSobject.put('LastName', insertedAccount[0].Name.length() > 80 ? insertedAccount[0].Name.substring(0, 80) : insertedAccount[0].Name);
            newSobject.put('EQT_Full_Company_Name__c', insertedAccount[0].Name);
            newSobject.put(mapping.EQT_Contact_Company_Email_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            newSobject.put(mapping.EQT_Contact_Company_Phone_field__c, insertedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            newSobject.put('RecordTypeId', EQT_UTIL_Meta.getRecordTypeId('Contact.Company'));
            
            insert newSobject;
            
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            
            //update account name and remove email and phone
            String newAccountName = 'new test account';
            a.put(mapping.EQT_Account_Company_Email_field__c, null);
            a.put(mapping.EQT_Account_Company_Phone_field__c, null);
            update a;
            
            insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            system.assertEquals(null, insertedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            system.assertEquals(null, insertedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            
            //delete "connected" contact
            Contact toDelete = [SELECT Id, LastName, EQT_Full_Company_Name__c FROM Contact WHERE EQT_Full_Company_Name__c = :accountName];            
            delete toDelete;
            
            //verify delete
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :newAccountName].size());                     
        }
    }
    
    @isTest static void accountContactTriggerUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, 'email@example.test', '+987654');
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify new contact with the same name was created           
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            //update account
            String newAccountName = 'test account 123';
            String newAccountEmail = 'test@example.test';
            String newAccountPhone = '+012345678'; // Validation rule on contact requires phone to start with + and not contain characters "(). ".
            a.Name = newAccountName;
            a.put(mapping.EQT_Account_Company_Email_field__c, newAccountEmail);
            a.put(mapping.EQT_Account_Company_Phone_field__c, newAccountPhone);
            update a;
            //verify account and contact update
            system.assertEquals(0, [SELECT Id FROM Account where Name = :accountName].size());
            system.assertEquals(1, [SELECT Id FROM Account where Name = :newAccountName].size());
            system.assertEquals(0, [SELECT Id FROM Contact where EQT_Full_Company_Name__c = :accountName].size());
            String contactQ = 'SELECT Id, LastName, EQT_Full_Company_Name__c, ' +
                                mapping.EQT_Contact_Company_Email_field__c + ', ' +
                                mapping.EQT_Contact_Company_Phone_field__c +
                                ' FROM Contact WHERE EQT_Full_Company_Name__c = :newAccountName';
            List<Contact> updateContact = Database.query(contactQ);
            system.assertEquals(1, updateContact.size());
            system.assertEquals(newAccountEmail, updateContact[0].get(mapping.EQT_Contact_Company_Email_field__c));
            system.assertEquals(newAccountPhone, updateContact[0].get(mapping.EQT_Contact_Company_Phone_field__c));
        }
    }
    
    @isTest static void accountContactTriggerContactCreationTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, null, null);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify no contact was created           
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            
            //update account
            String newAccountEmail = 'test@example.test';
            String newAccountPhone = '+012345678';
            a.put(mapping.EQT_Account_Company_Email_field__c, newAccountEmail);
            a.put(mapping.EQT_Account_Company_Phone_field__c, newAccountPhone);
            update a;
            //verify account update and new contact creation
            system.assertEquals(1, [SELECT Id FROM Account where Name = :accountName].size());
            String contactQ = 'SELECT Id, LastName, EQT_Full_Company_Name__c, ' +
                                mapping.EQT_Contact_Company_Email_field__c + ', ' +
                                mapping.EQT_Contact_Company_Phone_field__c +
                                ' FROM Contact WHERE EQT_Full_Company_Name__c = :accountName';
            List<Contact> newContact = Database.query(contactQ);
            system.assertEquals(1, newContact.size());
            system.assertEquals(newAccountEmail, newContact[0].get(mapping.EQT_Contact_Company_Email_field__c));
            system.assertEquals(newAccountPhone, newContact[0].get(mapping.EQT_Contact_Company_Phone_field__c));    
        }
    }
    
    @isTest static void accountContactTriggerContactDeleteTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, 'email@example.test', '+012345678');
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify new contact with the same name was created           
            system.assertEquals(1, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            
            //erase account email and phone
            a.put(mapping.EQT_Account_Company_Email_field__c, null);
            a.put(mapping.EQT_Account_Company_Phone_field__c, null);
            update a;
            
            List<Account> updatedAccount = Database.query(query);
            system.assertEquals(1, updatedAccount.size());
            system.assertEquals(null, updatedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            system.assertEquals(null, updatedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            //verify contact was deleted
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
        }
    }
    
    @isTest static void accountContactTriggerUpdateContactCreationTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            //verify there is no contact with above name
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName, null, null);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            //verify no contact was created           
            system.assertEquals(0, [SELECT Id FROM Contact WHERE EQT_Full_Company_Name__c = :accountName].size());
            
            //update account
            String newAccountName = 'company test';
            String newAccountEmail = 'test@example.test';
            String newAccountPhone = '+012345678';
            a.Name = newAccountName;
            a.put(mapping.EQT_Account_Company_Email_field__c, newAccountEmail);
            a.put(mapping.EQT_Account_Company_Phone_field__c, newAccountPhone);
            update a;
            //verify account update and new contact creation
            system.assertEquals(0, [SELECT Id FROM Account where Name = :accountName].size());
            String accountQ = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ', ' +
                                mapping.EQT_Account_Company_Phone_field__c +
                                ' FROM Account WHERE Name = :newAccountName';

            List<Account> updatedAccount = Database.query(accountQ);
            system.assertEquals(1, updatedAccount.size());
            system.assertEquals(newAccountName, updatedAccount[0].Name);
            system.assertEquals(newAccountEmail, updatedAccount[0].get(mapping.EQT_Account_Company_Email_field__c));
            system.assertEquals(newAccountPhone, updatedAccount[0].get(mapping.EQT_Account_Company_Phone_field__c));
            
            String contactQ = 'SELECT Id, LastName, EQT_Full_Company_Name__c, ' +
                                mapping.EQT_Contact_Company_Email_field__c + ', ' +
                                mapping.EQT_Contact_Company_Phone_field__c +
                                ' FROM Contact WHERE EQT_Full_Company_Name__c = :newAccountName';
            List<Contact> newContact = Database.query(contactQ);
            system.assertEquals(1, newContact.size());
            system.assertEquals(newAccountEmail, newContact[0].get(mapping.EQT_Contact_Company_Email_field__c));
            system.assertEquals(newAccountPhone, newContact[0].get(mapping.EQT_Contact_Company_Phone_field__c));    
        }
    }

    @isTest static void mergeAccountsTest() {
        EQT_TestFactory.setUpOrg();

        User integrationUser = EQT_TestFactory.createUser('testIntegrationUser@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testIntegrationUser@example.eqt'].size());

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        Account a1, a2;
        Fund__c fund1, fund2;

        system.runAs(u) {
            //create sample accounts
            a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 1');
            a2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account 2');

            // create funds
            fund1 = EQT_TestFactory.createSampleFund('fund 1', 'Credit');
            fund2 = EQT_TestFactory.createSampleFund('fund 2', 'Private Capital');
        }

        system.runAs(integrationUser) {
            // create commitment
            EQT_Commitment__c commitment11 = EQT_TestFactory.createSampleCommitment(fund1.Id, a1.Id);
            EQT_Commitment__c commitment12 = EQT_TestFactory.createSampleCommitment(fund2.Id, a1.Id);

            EQT_Commitment__c commitment21 = EQT_TestFactory.createSampleCommitment(fund1.Id, a2.Id);
            EQT_Commitment__c commitment22 = EQT_TestFactory.createSampleCommitment(fund2.Id, a2.Id);
        }

        system.runAs(u) {
            Test.startTest();
            merge a1 a2;
            Test.stopTest();

            List<Account> resultAccList = [SELECT Id, Name FROM Account];
            List<EQT_Commitment__c> resultCommitmentList = [SELECT Id, EQT_Investor__c  FROM EQT_Commitment__c];

            system.debug('test resultAccList: ' + resultAccList);
            system.assertEquals(1, resultAccList.size());

            system.debug('test resultCommitmentList: ' + resultCommitmentList);
            system.assertEquals(2, resultCommitmentList.size());
        }

    }
    
    /*
    @isTest static void deleteRoleTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        
        system.runAs(u) {
            //create sample account
            Account a = EQT_TestFactory.createSampleAccount('Account.Investor', 'test account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            //create sample contact
            Contact c = EQT_TestFactory.createSampleContact('firstName', 'lastName', a.Id);
            
            //validate there is no relationship between contact and account
            system.assertEquals(1, [SELECT Id FROM Contact WHERE LastName = :'lastName'].size());
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'test account'].size());
            system.assertEquals(0, [SELECT Id FROM Contact WHERE AccountId = :a.Id AND LastName = :'lastName'].size());
            //verify role creation
            system.assertEquals(1, [SELECT Id FROM EQT_AccountContactRole__c WHERE AccountId__c = :a.Id AND ContactId__c = :c.Id AND Active__c = true].size());
            //delete account
            delete a;
            //verify contact exist and role was deleted
            system.assertEquals(1, [SELECT Id FROM Contact WHERE LastName = :'lastName'].size());
            system.assertEquals(0, [SELECT Id FROM EQT_AccountContactRole__c WHERE AccountId__c = :a.Id AND ContactId__c = :c.Id AND Active__c = true].size());
        }
    }
    */
}