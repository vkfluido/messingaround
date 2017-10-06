@isTest
private class EQT_ContactHandler_Test {
    
    @isTest static void contactSetRecordIDByNamefromEPM() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        system.runAs(u) {
            //create sample account
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account', true);
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //Create sample contact and check the record type is set
            Contact c = new Contact();
            c.LastName = 'Generic Contact, will get default RT';
            c.EQT_EPM_Record_Type_Name__c = 'EQT_Employee';
            c.AccountId = a.Id;
            insert c;
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee'), [SELECT Id, RecordTypeId FROM Contact WHERE Id = :c.Id].RecordTypeId);    

            //Update sample contact with other record type name and check the record type is set
            c.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
            update c;
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person'), [SELECT Id, RecordTypeId FROM Contact WHERE Id = :c.Id].RecordTypeId);    

        }
    }

    @isTest static void accountDateComparisionTest() {
        User u = EQT_TestFactory.createUser('testuser1@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        User integrationUser = EQT_TestFactory.createUser('testIntegrationUser@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :integrationUser.Id].size());
        Contact c;

        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('EQT_Disable_Validation_Rule_Contact__c', true);
        update appSettings;

        system.runAs(u) {
            c = EQT_TestFactory.createSampleContact('firstName', 'lastName', '', true);
            system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());
        }

        system.runAs(integrationUser) {
            //try to update account without emp last modified date
            try {
                c.MobilePhone = '123456789';
                update c;
            }
            catch(Exception e) {
                system.assert(e.getMessage().contains('EQT_EPM_LastModifiedDate__c date field must be supplied to avoid accidental overwrite'));
            }
        }

        //now update date on account as regular user and set it before standard last modified date
        system.runAs(u) {
            Datetime epmDT = Datetime.now().addDays(-1);
            c.EQT_EPM_LastModifiedDate__c = epmDT;
            update c;
            system.assertEquals(epmDT, [SELECT Id, EQT_EPM_LastModifiedDate__c FROM Contact WHERE Id = :c.Id].EQT_EPM_LastModifiedDate__c);
        }

        //try update
        system.runAs(integrationUser) {
            try {
                c.MobilePhone = '123456789';
                update c;
            }
            catch(Exception e) {
                system.assert(e.getMessage().contains('Record is more recent in Salesforce'));
            }
        }

        //now update date after last modified date
        system.runAs(u) {
            Datetime epmDT = Datetime.now().addDays(1);
            c.EQT_EPM_LastModifiedDate__c = epmDT;
            update c;
            system.assertEquals(epmDT, [SELECT Id, EQT_EPM_LastModifiedDate__c FROM Contact WHERE Id = :c.Id].EQT_EPM_LastModifiedDate__c);
        }

        //try update
        system.runAs(integrationUser) {
            c.MobilePhone = '123456789';
            update c;

            system.assertEquals('123456789', [SELECT Id, MobilePhone FROM Contact WHERE Id = :c.Id].MobilePhone);
        }
    }

    @isTest static void ensureMailingAddressInsertTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            String city = 'sample city';
            String country = 'sample country';
            String postalCode = '123';
            String state = 'sample state';
            String street = 'sample street';

            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account', false);
            a.BillingStreet = street;
            a.BillingCountry = country;
            a.BillingPostalCode = postalCode;
            a.BillingState = state;
            a.BillingCity = city;

            insert a;
            system.assertEquals(1, [SELECT Id FROM Account WHERE BillingStreet = :street].size());

            //create new contact with empty mailing address fields
            Contact c = EQT_TestFactory.createSampleContact('contact', 'test', a.Id, true);
            system.assertEquals(1, [SELECT Id FROM Contact
                                    WHERE AccountId = :a.Id
                                    AND MailingCity = :city
                                    AND MailingCountry = :country
                                    AND MailingPostalCode = :postalCode
                                    AND MailingState = :state
                                    AND MailingStreet = :street].size());
        }
    }

    @isTest static void ensureMailingAddressUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            String city = 'sample city';
            String country = 'sample country';
            String postalCode = '123';
            String state = 'sample state';
            String street = 'sample street';

            Account a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 1', false);
            Account a2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 2', false);
            a2.BillingStreet = street;
            a2.BillingCountry = country;
            a2.BillingPostalCode = postalCode;
            a2.BillingState = state;
            a2.BillingCity = city;

            insert new List<Account> {a1, a2};
            system.assertEquals(2, [SELECT Id FROM Account].size());

            //create new contact with empty mailing address fields
            Contact c = EQT_TestFactory.createSampleContact('contact', 'test', a1.Id, true);
            system.assertEquals(1, [SELECT Id FROM Contact
            WHERE AccountId = :a1.Id
            AND MailingCity = null
            AND MailingCountry = null
            AND MailingPostalCode = null
            AND MailingState = null
            AND MailingStreet = null].size());

            //update account on contact record
            c.AccountId = a2.Id;
            update c;

            system.assertEquals(1, [SELECT Id FROM Contact
            WHERE AccountId = :a2.Id
            AND MailingCity = :city
            AND MailingCountry = :country
            AND MailingPostalCode = :postalCode
            AND MailingState = :state
            AND MailingStreet = :street].size());
        }
    }

    @isTest static void setContactFormalTitleTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT IA Manager Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        String title1 = 'Doktor';
        String title2 = 'Dr Rechtsanwä';
        system.runAs(u) {

            Account a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Sample account 1', true);
        //create new contact with a Formal title
            Contact c = EQT_TestFactory.createSampleContact('contact', 'test', a1.Id, false);
            c.EQT_Formal_Title__c = title1;
            insert c;

            Contact newContact1 = [SELECT Id, Name, Salutation FROM Contact WHERE Id = :c.Id];
            System.assertEquals(title1, newContact1.Salutation);


            c.EQT_Formal_Title__c = title2;
            update c;

            Contact newContact2 = [SELECT Id, Name, Salutation FROM Contact WHERE Id = :c.Id];
            System.assertEquals(title2, newContact2.Salutation);
        }
    }

    @isTest static void testAssistantTo() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT IA Manager Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Sample account 1', true);


            Contact c = EQT_TestFactory.createSampleContact('contact', 'Assistant Primary', a1.Id, false);
            insert c;

            Contact c2 = EQT_TestFactory.createSampleContact('contact', 'Assistant Secondary', a1.Id, false);
            insert c2;

            Contact cPartner = EQT_TestFactory.createSampleContact('contact', 'Partner 1', a1.Id, false);
            cPartner.EQT_Primary_Assistant__c = c.id;
            cPartner.Secondary_Assistant__c = c2.id;
            insert cPartner;

            Contact cUpdated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c.Id];
            Contact c2Updated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c2.Id];

            system.assertEquals('contact Partner 1', cUpdated.EQT_Assistant_To__c);
            system.assertEquals('contact Partner 1', c2Updated.EQT_Assistant_To__c);

            cPartner.EQT_Primary_Assistant__c = c2.id;
            cPartner.Secondary_Assistant__c = c.id;
            update cPartner;

            cUpdated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c.Id];
            c2Updated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c2.Id];

            system.assertEquals('contact Partner 1', cUpdated.EQT_Assistant_To__c);
            system.assertEquals('contact Partner 1', c2Updated.EQT_Assistant_To__c);

            delete cPartner;
            cUpdated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c.Id];
            c2Updated = [SELECT EQT_Assistant_To__c FROM Contact WHERE Id = :c2.Id];

            system.assertEquals(null, cUpdated.EQT_Assistant_To__c);
            system.assertEquals(null, c2Updated.EQT_Assistant_To__c);
        }
    }

    @isTest static void setExEmployeeOnCreateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Sample account 1', true);

            Contact c = EQT_TestFactory.createSampleContact('Name', 'Last', a1.Id, 'Contact.EQT_Employee', false);
            c.EQT_Ex_Employee__c = true;
            insert c;

            Contact cRes = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :c.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person'), cRes.RecordTypeId);
        }
    }

    @isTest static void setExEmployeeOnUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT System Administrator');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            Account a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Sample account 1', true);

            Contact c = EQT_TestFactory.createSampleContact('Name', 'Last', a1.Id, 'Contact.EQT_Employee', false);
            insert c;

            Contact cRes = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :c.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Employee'), cRes.RecordTypeId);

            c.EQT_Ex_Employee__c = true;
            update c;

            Contact cRes2 = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :c.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person'), cRes2.RecordTypeId);
        }
    }
}