@isTest
private class EQT_Campaign_Email_Controller_Test
{
	@testSetup
	static void setupCampaign(){

		// Create Setup Objects
		
		// 1. Create Campaign Email Template
		Folder irFolder;
		try{
			irFolder = [SELECT Id FROM Folder WHERE Type = 'Email' AND DeveloperName = 'IR_Templates' LIMIT 1];
		}catch(Exception e){
			System.debug('irFolder error message: ' + e.getMessage());
		}
		System.assert(irFolder != null,'A Folder with the DeveloperName of IR_Templates should exist in the org. This is where Email Templates for Campaigns are retrieved.');

		EmailTemplate template = new EmailTemplate();
		template.IsActive = true;
		template.Name = 'Unit Test Campaign Email Template';
		template.DeveloperName = 'Test_Campaign_Email_Template';
		template.TemplateType = 'text';
		template.FolderId = irFolder.Id;
		template.Subject = 'Test Subject';
		template.Body = 'Testing Email Template';

		insert template;

	}

	@isTest
	static void test_send_campaign_email()
	{
	
	String templateName = 'Unit Test Campaign Email Template';
	String campaignName = 'Test Campaign';
	Integer totalContacts = 100;


	// 2. Create an active campaign
		// 2.1 Create Campaign of type Contact Event		
		String campaignRecordTypeId;
		List<RecordType> campaignRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType Where SObjectType = 'Campaign' And DeveloperName = 'EQT_Contact_Event' LIMIT 1];
		if(campaignRecordTypes.size() == 1)
			campaignRecordTypeId = campaignRecordTypes[0].Id;
		Campaign newTestCampaign = EQT_TestFactory.createSampleCampaign(campaignName, campaignRecordTypeId, true);
	
		// 2.2 Create different Status for members
		List<CampaignMemberStatus> cmStatusList = new List<CampaignMemberStatus>{
			new CampaignMemberStatus(CampaignId = newTestCampaign.Id, Label='Not Sent', HasResponded = false, IsDefault=true, SortOrder=0),
			new CampaignMemberStatus(CampaignId = newTestCampaign.Id, Label='Sent', HasResponded = false, IsDefault=false, SortOrder=1),
			new CampaignMemberStatus(CampaignId = newTestCampaign.Id, Label='Responded', HasResponded = true, IsDefault=false, SortOrder=2)
		};
		insert cmStatusList;

	// 3. Add campaign members from a list of contacts
		//	3.1 Create an account
		Account a = EQT_TestFactory.createSampleAccount('','Test Account', true);
		//  3.2 Create contacts
		List<Contact> contacts = new List<Contact>();
		for(Integer i = 0; i < totalContacts; i++){
			Contact c = EQT_TestFactory.createSampleContact('Test','Contact '+i,a.Id, false);
			c.Email = 'test.contact.'+i+'@example.com';
			contacts.add(c);
		}
		insert contacts;
		//  3.3 Add contacts as campaign members
		List<CampaignMember> campaignMembers = new List<CampaignMember>();
		for(Contact c : contacts){
			campaignMembers.add(new CampaignMember(CampaignId = newTestCampaign.Id, ContactId = c.Id));
		}
		insert campaignMembers;


	/* Run tests */
	Test.startTest();
		String campaignId = String.valueOf(newTestCampaign.Id);
		// a) Method "getCampaign"
		Campaign testCampaign = EQT_Campaign_Email_Controller.getCampaign(campaignId);
		// Check that the name of the campaign is retrieved from the campaign Id
		System.assertEquals(campaignName,testCampaign.Name);
		
		// b) getJSONEmailTemplates
		String jsonEmailTemplates = EQT_Campaign_Email_Controller.getJSONEmailTemplates();
		Object[] emailTemplateList = (List<Object>)JSON.deserializeUntyped(jsonEmailTemplates);
		System.debug('emailTemplateList.size(): ' + emailTemplateList.size());
		// At least one template should exist because we have created one in the test setup
		System.assert(emailTemplateList.size() > 0);

		Id testTemplateId;
		for(Object o : emailTemplateList){
			Map<String,Object> obj = (Map<String,Object>) o;
			String tName = String.valueOf(obj.get('name'));
			if(tName.equals(templateName))
				testTemplateId = String.valueOf(obj.get('id'));

		}
		System.debug('testTemplateId: ' + testTemplateId);
		// The test template ahould be on the template list so the Id shouldn't be null
		System.assert(testTemplateId != null);

		// c) getJSONMemberStatus
		String jsonMemberStatus = EQT_Campaign_Email_Controller.getJSONMemberStatus(campaignId);
		Object[] memberStatusList = (List<Object>)JSON.deserializeUntyped(jsonMemberStatus);
		// Three status were created: Not Sent, Sent, Responded. List should have only the 2 that are not HasResponded.
		System.assertEquals(2, memberStatusList.size());

		// d) getCampaignMemberCount
		String defaultStatus = 'Not Sent'; // This is the default status for new campaign members
		Integer campaignMemberCount = EQT_Campaign_Email_Controller.getCampaignMemberCount(campaignId, defaultStatus);
		// There should be as many campaign members as Contacts created
		System.assertEquals(totalContacts,campaignMemberCount);

		// e) Send Emails w/o updating
		String result;
		result = EQT_Campaign_Email_Controller.sendMassEmails(campaignId, testTemplateId, 'Not Sent', '');
		System.debug('sendMassEmails: ' + result);
		System.assert(result.contains('Campaign e-mail sent'));
		System.assert(!result.contains('status was updated'));

		// f) Send Emails and update status
		result = EQT_Campaign_Email_Controller.sendMassEmails(campaignId, testTemplateId, 'Not Sent', 'Sent');
		System.debug('sendMassEmails 2: ' + result);
		System.assert(result.contains('Campaign e-mail sent'));
		System.assert(result.contains('status was updated'));

		Integer sentCampaignMemberCount = EQT_Campaign_Email_Controller.getCampaignMemberCount(campaignId, 'Sent');
		System.debug('getCampaignMemberCount: ' + sentCampaignMemberCount);
		System.assertEquals(totalContacts,sentCampaignMemberCount);

	Test.stopTest();

	}
}