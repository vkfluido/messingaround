@isTest
private class EQT_MoveEmailFromCaseController_Test {

	@testSetup static void setup() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        system.runAs(u) {
        	system.assertEquals(0, [SELECT Id FROM EntitySubscription LIMIT 100].size());
        	Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'test account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());

        	// Create 3 Cases
            String deadlineDate = '2018-10-01';
        	Case masterCase = EQT_TestFactory.createSampleSlackCase('master', 'test desc', deadlineDate, null, 'test@test.test');
        	system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :masterCase.Id].size());
        	Case duplicateCase = EQT_TestFactory.createSampleSlackCase('duplicate', 'test desc', deadlineDate, null, 'test@test.test');
        	system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :duplicateCase.Id].size());
        	Case duplicateCase2 = EQT_TestFactory.createSampleSlackCase('duplicate2', 'test desc', deadlineDate, null, 'test@test.test');
        	system.assertEquals(1, [SELECT Id FROM Case WHERE Id = :duplicateCase2.Id].size());

        	// Create one email and add one Attachment and one ContentVersion
        	EmailMessage em = new EmailMessage();
			em.Subject = 'Subject';
			em.Textbody = 'Textbody';
			em.HtmlBody = 'HtmlBody';
			em.ParentId = duplicateCase.Id;
			em.Incoming = true;
			em.FromName = 'test';
			em.FromAddress = 'test@test.test';
			em.ToAddress = 'test@eqt.com';
			insert em;
        	system.assertEquals(1, [SELECT Id FROM EmailMessage WHERE ParentId = :duplicateCase.Id].size());

			Attachment attach = new Attachment();   	
			attach.Name = 'Unit Test Attachment';
			attach.ContentType = 'text/plain';
			Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
			attach.Body = bodyBlob;
			attach.ParentId = em.Id;
			insert attach;
        	system.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId = :em.Id].size());

        	ContentVersion content = new ContentVersion(); 
            content.Title = 'Header_Picture1'; 
            content.PathOnClient = '/' + content.Title + '.jpg'; 
            bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
            content.VersionData = bodyBlob; 
            content.origin = 'H';
	        insert content;

	        ContentDocumentLink contentlink = new ContentDocumentLink();
	            contentlink.LinkedEntityId = em.Id;
	            contentlink.ShareType = 'V';
	            contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: content.Id].contentdocumentid;
	        insert contentlink;
	        System.assertEquals(1, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :em.Id].size()); 

        }
    }

    @isTest static void getCases() {
    	// Test that we get the list of 2 cases
    	Case masterCase = [SELECT Id FROM Case WHERE Subject = 'master'];
    	Case duplicateCase = [SELECT Id FROM Case WHERE Subject = 'duplicate'];
    	test.startTest();
        	List<EQT_MoveEmailFromCaseController.EQT_Case> cases = EQT_MoveEmailFromCaseController.getCases(duplicateCase.Id);
        	system.assertEquals(2, cases.size());
        	system.assert(new Set<Id>{cases[0].cs.Id, cases[1].cs.Id}.contains(masterCase.Id));
        test.stopTest();
    }

    @isTest static void moveEmailandDeleteCase() {
    	// Test that we can move the email with attachment to the master case
    	Case masterCase = [SELECT Id FROM Case WHERE Subject = 'master'];
    	Case duplicateCase = [SELECT Id FROM Case WHERE Subject = 'duplicate'];
    	
    	test.startTest();
    		String response = EQT_MoveEmailFromCaseController.moveEmailandDeleteCase(duplicateCase.Id, masterCase.Id);
        	system.assertEquals('SUCCESS', response);
        	system.assertEquals(1, [SELECT Id FROM EmailMessage WHERE ParentId = :masterCase.Id].size());
        	system.assertEquals(1, [SELECT Id FROM Attachment WHERE ParentId in (SELECT Id FROM EmailMessage WHERE ParentId = :masterCase.Id)].size());
        	system.assertEquals(1, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId in (SELECT Id FROM EmailMessage WHERE ParentId = :masterCase.Id)].size());
        	system.assertEquals(0, [SELECT Id FROM Case WHERE Id = :duplicateCase.Id].size());

        	delete masterCase;
    		response = EQT_MoveEmailFromCaseController.moveEmailandDeleteCase(duplicateCase.Id, masterCase.Id);
        	system.assert('SUCCESS' != response);
        test.stopTest();
    }
}