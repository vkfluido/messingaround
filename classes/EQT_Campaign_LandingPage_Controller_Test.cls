@isTest
private class EQT_Campaign_LandingPage_Controller_Test
{
	@testSetup static void setupCampaign() {
		System.debug('>> Data Setup <<');	
		/* Create a public Document for the Invitation Background Image */
		Id folderId;
		List<Folder> folders = [SELECT Id FROM Folder WHERE DeveloperName = 'EQT_Campaign_Email_Templates' LIMIT 1];
		folderId = (folders.size() == 1?folders[0].Id:UserInfo.getUserId());

		Document document = EQT_TestFactory.createSampleDocument(folderId, true);
		System.debug(document);
		
		/* Create a new Campaign of record type 'Contact Event' */
		Id contactEventRTId = EQT_UTIL_Meta.getRecordTypeId('Campaign.EQT_Contact_Event');
		Campaign camp = EQT_TestFactory.createSampleCampaign('Test Campaign',contactEventRTId,false);
		camp.EQT_Campaign_Text_Before__c = 'Sample text before.';
		camp.EQT_Campaign_Text_After__c = 'Sample text after.';
		camp.EQT_Campaign_Text_Footer__c = 'Sample text footer.';
		camp.EQT_Campaign_Attendance_Label__c = 'Sample Label';
		// Fields normally configured from Campaign Document Select Page
		camp.EQT_Invitation_Background_Image_Id__c = document.Id;
		camp.EQT_Invitation_Form_Fields__c = 'eqt_x_dietaryrequirements__c;eqt_x_membertype__c';
		camp.IsActive = true;
		camp.Status = 'In Progress';
		insert camp;
		System.debug(camp);
		
		/* Add Test Campaign Member Status */
		List<CampaignMemberStatus> statusOptions = new List<CampaignMemberStatus>(); 
		statusOptions.add(new CampaignMemberStatus(CampaignId=camp.Id, HasResponded=true, Label='Attending', SortOrder=3));
		statusOptions.add(new CampaignMemberStatus(CampaignId=camp.Id, HasResponded=true, Label='Not Attending', SortOrder=4));
		System.debug(statusOptions);
		insert statusOptions;
		
	}
	
	@isTest static void testLandingPage() {
		System.debug('>> Starting test ** testLandingPage ** <<');
		Campaign camp = [SELECT Id, Name, RecordTypeId, StartDate,
							EQT_Campaign_Text_Before__c,
							EQT_Campaign_Text_After__c,
							EQT_Campaign_Text_Footer__c,
							EQT_Campaign_Attendance_Label__c,
							EQT_Invitation_Background_Image_Id__c,
							EQT_Invitation_Form_Fields__c,
							IsActive, Status
						FROM Campaign WHERE IsActive = true AND Status = 'In Progress' LIMIT 1];
		/* Create Contacts that will become Campaign Members */
		Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor','Test Account'); // includes DML
		
		Contact cont = EQT_TestFactory.createSampleContact('test','test1', a.Id, false);
		cont.Email = 'test1@example.com';
		insert cont;
		System.debug(cont);

		CampaignMember m = new CampaignMember();
			m.ContactId = cont.Id;
			m.CampaignId = camp.Id;
			m.Status = 'Sent';
		insert m;

		
		Id campaignMemberId;
		Test.startTest();
		
			PageReference campaignPageIC = Page.EQT_Campaign_Page_Footer_Layout;
			campaignPageIC.getParameters().put('id', camp.Id);
			campaignPageIC.getParameters().put('cid', cont.Id);
			Test.setCurrentPage(campaignPageIC);
			ApexPages.StandardController stdController = new ApexPages.StandardController(camp);
			EQT_Campaign_LandingPage_Controller controllerExt = new EQT_Campaign_LandingPage_Controller(stdController);
			
			// Page variables
			System.debug('isCampaignValid:' + controllerExt.isCampaignValid);
			List<SelectOption> selectOptions = controllerExt.getCampaignMemberStatusOptions();
			System.debug('selectOptions:\n' + selectOptions);
			Boolean showExtraFields = controllerExt.getShowExtraFields();
			System.debug('showExtraFields: ' + showExtraFields);
			List<String> fields = controllerExt.displayedFields;
			System.debug('isNewCampaignMember: ' + controllerExt.isNewCampaignMember);
			System.debug('CampaignMember:\n' + controllerExt.cm);

			// ** USER INPUT
			CampaignMember member = controllerExt.cm;
			// Fill-in response
			controllerExt.attendValue = selectOptions[0].getValue();

			// Fill-in dynamic fields with test data
			Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.CampaignMember.fields.getMap();
			for(String field : fields){

				Schema.SObjectField sObjField = fieldsMap.get(field);
				String fieldType = String.valueOf(sObjField.getDescribe().getType());
				// Only Picklist, String and TextArea are Implemented as of when test class was implemented
				if(fieldType == 'TextArea' || fieldType == 'String')
					member.put(field,'test value');
				else{
					if(fieldType == 'Picklist'){
						List<Schema.PicklistEntry> pick_list_values = sObjField.getDescribe().getPickListValues();
						member.put(field,pick_list_values[0].getLabel());
					}
				}
			}
			// Submit form
			System.debug('CampaignMember Before Submit:\n' + member);
			campaignMemberId = member.Id;
			controllerExt.submit();

			// Reload Page
			Campaign camp2 = [SELECT Id, Name, RecordTypeId, StartDate,
							EQT_Campaign_Text_Before__c,
							EQT_Campaign_Text_After__c,
							EQT_Campaign_Text_Footer__c,
							EQT_Campaign_Attendance_Label__c,
							EQT_Invitation_Background_Image_Id__c,
							EQT_Invitation_Form_Fields__c,
							IsActive, Status
						FROM Campaign WHERE IsActive = true AND Status = 'In Progress' LIMIT 1];
			ApexPages.StandardController stdController2 = new ApexPages.StandardController(camp2);
			EQT_Campaign_LandingPage_Controller controllerExt2 = new EQT_Campaign_LandingPage_Controller(stdController2);

		Test.stopTest();

		CampaignMember cm = controllerExt.getCurrentCampaignMember(fields, camp.Id, cont.Id);

		System.debug('CampaignMember After Submit:\n' + cm);
		
		System.assert(controllerExt.isCampaignValid);
		System.assert(showExtraFields);
		System.assert(!controllerExt.isNewCampaignMember);

		System.assert(cm.HasResponded);
		for(String field : fields){
			System.assert(cm.get(field) != null);
		}
		System.assertEquals(selectOptions[0].getValue(),cm.Status);
		
	}

	@isTest static void testLandingPageError1() {
		System.debug('>> Starting test ** testLandingPageError1 ** <<');
		// CampaignId is Blank

		Campaign c = new Campaign();
		PageReference campaignPageIC = Page.EQT_Campaign_Page_Footer_Layout;
		Test.setCurrentPage(campaignPageIC);
		ApexPages.StandardController stdController = new ApexPages.StandardController(c);
		EQT_Campaign_LandingPage_Controller controllerExt = new EQT_Campaign_LandingPage_Controller(stdController);
		
		// Page variables
			System.debug('isCampaignValid:' + controllerExt.isCampaignValid);
			System.assert(!controllerExt.isCampaignValid);
			System.debug('CampaignMember:\n' + controllerExt.cm);
			System.assertEquals(null,controllerExt.cm);			
	}

	@isTest static void testLandingPageError2() {
		System.debug('>> Starting test ** testLandingPageError2 ** <<');
		// Campaign is inactive

		Campaign camp = [SELECT Id, Name, RecordTypeId, StartDate,
							EQT_Campaign_Text_Before__c,
							EQT_Campaign_Text_After__c,
							EQT_Campaign_Text_Footer__c,
							EQT_Campaign_Attendance_Label__c,
							EQT_Invitation_Background_Image_Id__c,
							EQT_Invitation_Form_Fields__c,
							IsActive, Status
						FROM Campaign WHERE IsActive = true AND Status = 'In Progress' LIMIT 1];
		camp.IsActive = false;
		update camp;

		PageReference campaignPageIC = Page.EQT_Campaign_Page_Footer_Layout;
		campaignPageIC.getParameters().put('id', camp.Id);
		Test.setCurrentPage(campaignPageIC);
		ApexPages.StandardController stdController = new ApexPages.StandardController(camp);
		EQT_Campaign_LandingPage_Controller controllerExt = new EQT_Campaign_LandingPage_Controller(stdController);
		
		// Page variables
			System.debug('isCampaignValid:' + controllerExt.isCampaignValid);
			System.assert(!controllerExt.isCampaignValid);
			System.debug('CampaignMember:\n' + controllerExt.cm);
			System.assertEquals(null,controllerExt.cm);			
	}

	@isTest static void testLandingPageError3() {
		System.debug('>> Starting test ** testLandingPageError3 ** <<');
		// Contact Id is blank/invalid

		Campaign camp = [SELECT Id, Name, RecordTypeId, StartDate,
							EQT_Campaign_Text_Before__c,
							EQT_Campaign_Text_After__c,
							EQT_Campaign_Text_Footer__c,
							EQT_Campaign_Attendance_Label__c,
							EQT_Invitation_Background_Image_Id__c,
							EQT_Invitation_Form_Fields__c,
							IsActive, Status
						FROM Campaign WHERE IsActive = true AND Status = 'In Progress' LIMIT 1];
		
		PageReference campaignPageIC = Page.EQT_Campaign_Page_Footer_Layout;
		campaignPageIC.getParameters().put('id', camp.Id);
		campaignPageIC.getParameters().put('cid', '');
		Test.setCurrentPage(campaignPageIC);
		ApexPages.StandardController stdController = new ApexPages.StandardController(camp);
		EQT_Campaign_LandingPage_Controller controllerExt = new EQT_Campaign_LandingPage_Controller(stdController);
		controllerExt.submit(); // Invitation reference not Found
		// Page variables
			System.debug('isCampaignValid:' + controllerExt.isCampaignValid);
			System.assert(controllerExt.isCampaignValid);
			System.debug('isNewCampaignMember: ' + controllerExt.isNewCampaignMember);
			System.assert(controllerExt.isNewCampaignMember);
			System.debug('CampaignMember:\n' + controllerExt.cm);
			System.assertEquals(camp.Id,controllerExt.cm.CampaignId);			
	}

	@isTest static void testLandingPageError4() {
		System.debug('>> Starting test ** testLandingPageError4 ** <<');
		// Contact Id is not a Campaign Member
		Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor','Test Account'); // includes DML
		Contact c = EQT_TestFactory.createSampleContact('test','test1', a.Id, false);
					c.Email = 'test1@example.com';
		insert c;

		Campaign camp = [SELECT Id, Name, RecordTypeId, StartDate,
							EQT_Campaign_Text_Before__c,
							EQT_Campaign_Text_After__c,
							EQT_Campaign_Text_Footer__c,
							EQT_Campaign_Attendance_Label__c,
							EQT_Invitation_Background_Image_Id__c,
							EQT_Invitation_Form_Fields__c,
							IsActive, Status
						FROM Campaign WHERE IsActive = true AND Status = 'In Progress' LIMIT 1];
		
		PageReference campaignPageIC = Page.EQT_Campaign_Page_Footer_Layout;
		campaignPageIC.getParameters().put('id', camp.Id);
		campaignPageIC.getParameters().put('cid', c.Id);
		Test.setCurrentPage(campaignPageIC);
		ApexPages.StandardController stdController = new ApexPages.StandardController(camp);
		EQT_Campaign_LandingPage_Controller controllerExt = new EQT_Campaign_LandingPage_Controller(stdController);
		controllerExt.submit(); // Please select an attendance option
		// Page variables
			System.debug('isCampaignValid:' + controllerExt.isCampaignValid);
			System.assert(!controllerExt.isCampaignValid);
	}






}