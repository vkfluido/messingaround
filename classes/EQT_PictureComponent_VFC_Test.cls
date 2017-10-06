@isTest
private class EQT_PictureComponent_VFC_Test {
	
	@isTest static void getPhotoTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

		//set default account
		Account undefinedCompany = EQT_TestFactory.createSampleAccount('Account.EQT_Placeholder', 'Undefined Company');
		system.assert(undefinedCompany.Id != null);
		EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
		appSettings.put('EQT_Default_Account_ID__c', undefinedCompany.Id);
		update appSettings;

        system.runAs(u) {
        	Contact c = new Contact();
	        c.LastName = 'test contact';
	        c.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person');
	        insert c;
	        system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());

	        Attachment attach = new Attachment();
			attach.contentType = 'image/jpeg';
			attach.name = 'test1';
			attach.parentId = c.Id;
			attach.body = EncodingUtil.base64Decode('test image');
			insert attach;
			system.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId = :c.Id].size());

        	Attachment picture =  EQT_PictureComponent_VFC.getPhoto(c.Id);
        	system.assert(picture != null);
        }            
	}
	
	@isTest static void savePhotoTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

		//set default account
		Account undefinedCompany = EQT_TestFactory.createSampleAccount('Account.EQT_Placeholder', 'Undefined Company');
		system.assert(undefinedCompany.Id != null);
		EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
		appSettings.put('EQT_Default_Account_ID__c', undefinedCompany.Id);
		update appSettings;

        system.runAs(u) {
        	Contact c = new Contact();
	        c.LastName = 'test contact';
	        c.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person');
	        insert c;
	        system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c.Id].size());
        	
        	//verify there is no attachment on given record
        	system.assertEquals(0, [SELECT Id FROM Attachment WHERE ParentId = :c.Id].size());
        	
        	//add attachment
        	Id attachmentId = EQT_PictureComponent_VFC.savePhoto(c.Id, 'myPicture', 'test image', 'image/jpeg');
        	
        	//verify attachment was created
        	system.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId = :c.Id].size());
        	system.assert(attachmentId != null);
        }
	}	
}