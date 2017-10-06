@isTest
private class EQT_Proxy_AccountContactRelationHandle_T {
	
	@isTest static void contactWithAccountRelationTest() {
		User integrationUser = EQT_TestFactory.createUser('integrationuser@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :integrationUser.Id].size());

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        Account a1;
        Account a2;
        Account a3;
        Contact c1;
        Contact c2;
        Contact c3;
        Contact c4;
        Contact c5;

        EQT_UTIL_Settings.getAccountTriggerDisabled();

        system.runAs(u) {
        	a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 1', false);
        	a2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 2', false);
        	a3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 3', false);

        	List<Account> accountsToInsert = new List<Account> {a1,a2,a3};
        	insert accountsToInsert;
        	system.assertEquals(3, [SELECT Id FROM Account].size());

        	c1 = EQT_TestFactory.createSampleContact('first', 'contact', a1.Id, false);
        	c2 = EQT_TestFactory.createSampleContact('second', 'contact', a1.Id, false);
        	c3 = EQT_TestFactory.createSampleContact('third', 'contact', a2.Id, false);
        	c4 = EQT_TestFactory.createSampleContact('fourth', 'contact', a3.Id, false);
        	c5 = EQT_TestFactory.createSampleContact('fifth', 'contact', a3.Id, false);

        	List<Contact> contactsToInsert = new List<Contact> {c1,c2,c3,c4,c5};
        	insert contactsToInsert;
        	system.assertEquals(5, [SELECT Id FROM Contact].size());

        	//verify records in account contact relationships table
        	system.assertEquals(5, [SELECT Id FROM AccountContactRelation].size());
        	//delete records for account1 and account2
        	//*** The following was commented to fix INVALID_OPERATION, A direct relationship can't be deleted.
                //delete [SELECT Id FROM AccountContactRelation WHERE AccountId IN (:a1.Id, :a2.Id)];
        	//system.assertEquals(2, [SELECT Id FROM AccountContactRelation].size());
        }

        system.runAs(integrationUser) {
        	List<EQT_Proxy_AccountContactRelation__c> proxyList = new List<EQT_Proxy_AccountContactRelation__c>();
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a1.Id, IsActive__c = true, Contact__c = c1.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '1',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a1.Id, IsActive__c = true, Contact__c = c2.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = false, EQT_EPM_CounterpartPersonID__c = '2',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a2.Id, IsActive__c = true, Contact__c = c3.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '3',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a3.Id, IsActive__c = true, Contact__c = c4.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = false, EQT_EPM_CounterpartPersonID__c = '4',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a3.Id, IsActive__c = true, Contact__c = c5.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '5',
        															Roles__c = '1;2;4'));

        	//system.assertEquals(0, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a1.Id].size());
        	//system.assertEquals(0, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a2.Id].size());
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a3.Id].size());
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c4.Id].EQT_Key_Contact__c);
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c5.Id].EQT_Key_Contact__c);

        	Test.startTest();
        	insert proxyList;
        	Test.stopTest();

        	//verify results
        	system.assertEquals(5, [SELECT Id FROM AccountContactRelation].size());
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a1.Id].size());
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a1.Id AND ContactId = :c1.Id].EQT_Key_Contact__c);
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a1.Id AND ContactId = :c2.Id].EQT_Key_Contact__c);
        	system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a2.Id].size());
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a2.Id].EQT_Key_Contact__c);
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a3.Id].size());
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c4.Id].EQT_Key_Contact__c);
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c5.Id].EQT_Key_Contact__c);

        	//verify proxy table is empty after processing
        	system.assertEquals(0, [SELECT Id FROM EQT_Proxy_AccountContactRelation__c].size());
        }
	}

	@isTest static void privateContactRelationTest() {
		User integrationUser = EQT_TestFactory.createUser('integrationuser@example.eqt', 'Integration User');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :integrationUser.Id].size());

        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        Account a1;
        Account a2;
        Account a3;
        Contact c1;
        Contact c2;
        Contact c3;
        Contact c4;
        Contact c5;

        EQT_UTIL_Settings.getAccountTriggerDisabled();

		//set default account
		Account undefinedCompany = EQT_TestFactory.createSampleAccount('Account.EQT_Placeholder', 'Undefined Company');
		system.assert(undefinedCompany.Id != null);
		EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
		appSettings.put('EQT_Default_Account_ID__c', undefinedCompany.Id);
		update appSettings;

        system.runAs(u) {
        	a1 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 1', false);
        	a2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 2', false);
        	a3 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account 3', false);

        	List<Account> accountsToInsert = new List<Account> {a1,a2,a3};
        	insert accountsToInsert;
        	system.assertEquals(4, [SELECT Id FROM Account].size());

        	c1 = EQT_TestFactory.createSampleContact('first', 'contact', a1.Id, false);
        	c2 = EQT_TestFactory.createSampleContact('second', 'contact', a1.Id, false);
        	c3 = EQT_TestFactory.createSampleContact('third', 'contact', a2.Id, false);
        	c4 = EQT_TestFactory.createSampleContact('fourth', 'contact', a3.Id, false);
        	c5 = EQT_TestFactory.createSampleContact('fifth', 'contact', a3.Id, false);

        	List<Contact> contactsToInsert = new List<Contact> {c1,c2,c3,c4,c5};
        	insert contactsToInsert;
        	system.assertEquals(5, [SELECT Id FROM Contact].size());

        	//verify records in account contact relationships table
        	system.assertEquals(5, [SELECT Id FROM AccountContactRelation].size());
        	//delete records for account1 and account2
        	//*** The following was commented to fix INVALID_OPERATION, A direct relationship can't be deleted.
                //delete [SELECT Id FROM AccountContactRelation WHERE AccountId IN (:a1.Id, :a2.Id)];
        	//system.assertEquals(2, [SELECT Id FROM AccountContactRelation].size());

        	//break relationship between contact and account
        	c3.AccountId = null;
        	update c3;
        	system.assertEquals(undefinedCompany.Id, [SELECT AccountId FROM Contact WHERE Id = :c3.Id].AccountId);
        }

        system.runAs(integrationUser) {
        	List<EQT_Proxy_AccountContactRelation__c> proxyList = new List<EQT_Proxy_AccountContactRelation__c>();
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a1.Id, IsActive__c = true, Contact__c = c1.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '1',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a1.Id, IsActive__c = true, Contact__c = c2.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = false, EQT_EPM_CounterpartPersonID__c = '2',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a2.Id, IsActive__c = true, Contact__c = c3.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '3',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a3.Id, IsActive__c = true, Contact__c = c4.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = false, EQT_EPM_CounterpartPersonID__c = '4',
        															Roles__c = '1;2;4'));
        	proxyList.add(new EQT_Proxy_AccountContactRelation__c(Account__c = a3.Id, IsActive__c = true, Contact__c = c5.Id,
        															StartDate__c = Date.today(), EndDate__c = Date.today().addDays(5),
        															EQT_Key_Contact__c = true, EQT_EPM_CounterpartPersonID__c = '5',
        															Roles__c = '1;2;4'));

        	//system.assertEquals(0, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a1.Id].size());
        	//system.assertEquals(0, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a2.Id].size());
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a3.Id].size());
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c4.Id].EQT_Key_Contact__c);
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c5.Id].EQT_Key_Contact__c);

        	Test.startTest();
        	insert proxyList;
        	Test.stopTest();

	        system.debug('@@ AccountContactRelation: ' +  [SELECT Id,AccountId,ContactId,EQT_EPM_CounterpartPersonID__c,EQT_Key_Contact__c FROM AccountContactRelation]);

        	//verify results
        	//system.assertEquals(5, [SELECT Id FROM AccountContactRelation].size());
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a1.Id].size());
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a1.Id AND ContactId = :c1.Id].EQT_Key_Contact__c);
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a1.Id AND ContactId = :c2.Id].EQT_Key_Contact__c);
        	system.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a2.Id].size());
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a2.Id].EQT_Key_Contact__c);
        	system.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE AccountId = :a3.Id].size());
        	system.assertEquals(false, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c4.Id].EQT_Key_Contact__c);
        	system.assertEquals(true, [SELECT EQT_Key_Contact__c FROM AccountContactRelation WHERE AccountId = :a3.Id AND ContactId = :c5.Id].EQT_Key_Contact__c);

        	//verify proxy table is empty after processing
        	system.assertEquals(0, [SELECT Id FROM EQT_Proxy_AccountContactRelation__c].size());
        }
	}
}