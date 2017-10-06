@isTest
private class EQT_UTIL_Settings_Test {
	@isTest static void settingsTest() {
		EQT_TestFactory.setUpOrg();

		system.assertEquals(false, EQT_UTIL_Settings.getOpportunityTeamMemberTriggerDisabled());
		system.assertEquals('', EQT_UTIL_Settings.getIntralinksEndpointURL());
		system.assertEquals('', EQT_UTIL_Settings.getIntralinksClientId());
		system.assertEquals('', EQT_UTIL_Settings.getIntralinksClientSecret());
		system.assertEquals('', EQT_UTIL_Settings.getIntralinksAccessToken());
		system.assertEquals('', EQT_UTIL_Settings.getIntralinksRefreshToken());
		//set access token
		EQT_UTIL_Settings.setIntralinksAccessToken('123');
		system.assertEquals('123', EQT_UTIL_Settings.getIntralinksAccessToken());
		//set refresh token
		EQT_UTIL_Settings.setIntralinksRefreshToken('321');
		system.assertEquals('321', EQT_UTIL_Settings.getIntralinksRefreshToken());

		system.assertEquals('', EQT_UTIL_Settings.getIntralinksAdminEmail());
        system.assertEquals(false, EQT_UTIL_Settings.getShouldLogIntralinksCallout());
        system.assertEquals(30, EQT_UTIL_Settings.getIntralinksBatchSize());
        system.assertEquals(true, EQT_UTIL_Settings.getIntralinksWeeklyRefresh());
        system.assertEquals('Iris', EQT_UTIL_Settings.getIrisBotName());
        system.assertEquals('xxx', EQT_UTIL_Settings.getSlackIntegrationUserToken());
        system.assertEquals('https://slack.com/api', EQT_UTIL_Settings.getSlackEndpointURL());
        system.assertEquals('test_channel', EQT_UTIL_Settings.getSlackAccountChannel());
        system.assertEquals('Planning;In Fundraising', EQT_UTIL_Settings.getFundPlanningFundraisingStatuseName());
        system.assertEquals('EQT_Planning_Fundraising', EQT_UTIL_Settings.getFundPlanningFundraisingRecordTypeName());
        system.assertEquals('EQT_Fundraising_Request', EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());
        system.assertEquals('No Interest', EQT_UTIL_Settings.getOpportunityFundraisingRequestDefaultStage());
        system.assertEquals('1st Close', EQT_UTIL_Settings.getOpportunityCloseValue());
        system.assertEquals(false, EQT_UTIL_Settings.getProxyEventRelationTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getEventTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getInvestranContactListTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getFundCommitmentTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getFundPartnershipTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getInvestorLPCodeTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getCommitmentTriggerDisabled());
        system.assertEquals('Planning;In Fundraising', EQT_UTIL_Settings.getFundStatusesForDataroomRefresh());
        system.assertEquals(false, EQT_UTIL_Settings.getOpportunityTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getAccountTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getFundTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getClearLogsEnabled());
        system.assertEquals(false, EQT_UTIL_Settings.getContactTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getSectorTeamMemberTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getUserTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getDateComparisonDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getLoggingEnabled());
        system.assertEquals('testIntegrationUser@example.eqt', EQT_UTIL_Settings.getEPMIntegrationUsername());
        system.assertEquals('Decline;Closed Out', EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation());
        system.assertEquals('Decline;Closed Out;Closed Won', EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation());
        system.assertEquals('Closed Out', EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation());
        system.assertEquals(false, EQT_UTIL_Settings.getCaseTriggerDisabled());
        system.assertEquals('EQT_Investor_Event', EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());
        system.assertEquals('EQT_Co_Investment_Fundraise_request', EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName());
        system.assertEquals('EQT_Co_Investment_Fundraise', EQT_UTIL_Settings.getFundCoInvestmentFundraiseRecordTypeName());
        system.assertEquals('01 - IR First Call', EQT_UTIL_Settings.getOpportunityCoInvestmentDefaultStage());
        system.assertEquals('3- Less Likely', EQT_UTIL_Settings.getOpportunityCoInvestmentLikelyHoodForClose());
        system.assertEquals('Pre-signing', EQT_UTIL_Settings.getOpportunityCoInvestmentPreSignType());
        system.assertEquals('Post-signing', EQT_UTIL_Settings.getOpportunityCoInvestmentPostSignType());
        system.assertEquals(false, EQT_UTIL_Settings.getTaskTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getBespokeReportingTriggerDisabled());
        system.assertEquals('', EQT_UTIL_Settings.getIrisApplicationId());
        system.assertEquals(false, EQT_UTIL_Settings.getSectorRatingTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getAssignmentTriggerDisabled());
        system.assertEquals(false, EQT_UTIL_Settings.getAgreementTriggerDisabled());
        system.assertEquals('EQT_Person', EQT_UTIL_Settings.getExternalContactRecordTypeName());
        system.assertEquals('Board_Management_Assignment', EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
        system.assertEquals('Expired Agreement', EQT_UTIL_Settings.getIAContractingExpiredStatus());
        system.assertEquals('Board IE/CEO', EQT_UTIL_Settings.getIABoardIEEngagementLevelName());
        system.assertEquals('Board Member;CEO;Chairman;Vice Chairman', EQT_UTIL_Settings.getAssignmentRolesToSetIAEngagementLevelToBoardIE());
        system.assertEquals('Expired', EQT_UTIL_Settings.getAgreementExpiredStatusName());
        system.assertEquals('Active', EQT_UTIL_Settings.getAgreementActiveStatusName());
        system.assertEquals('Terminated by IA', EQT_UTIL_Settings.getAgreementTerminatedByIAStatusName());
        system.assertEquals('Terminated by EQT', EQT_UTIL_Settings.getAgreementTerminatedByEQTStatusName());
        system.assertEquals('Pre-signing', EQT_UTIL_Settings.getOpportynityCoInvestmentDefaultType());
        String irisAppId = 'test_app_id';
        EQT_UTIL_Settings.setIrisApplicationId(irisAppId);
        system.assertEquals(irisAppId, EQT_UTIL_Settings.getIrisApplicationId());
	}
}