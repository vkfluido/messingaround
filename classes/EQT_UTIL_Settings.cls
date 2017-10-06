/**
    About
    -----
    Description: Org wide settings to be used by all code
    Created for: EQT POC
    Create date: April 2016
    
    Details / Methods
    -----------------
   
    Update History
    --------------
    Created April 2016 - R.B.
    Updated May 2017 - R.B.
    
    Issues / TODOs
    --------------
    Implement for existing custom setting and custom meta data 
*/
public with sharing class EQT_UTIL_Settings {
    /**** Get custom metadata types that can easily be cached ****/


    // Admin business Mapping
    // Maps account to contact fields for generating a company contact - Label >> list of fields
    static Map<String, EQT_Admin_Business_Mapping__mdt> accountContactField_Map = new Map<String, EQT_Admin_Business_Mapping__mdt>();
    public static EQT_Admin_Business_Mapping__mdt getAccountContactMap(String labelName) {
        if (accountContactField_Map.containsKey(labelName)) {
            return accountContactField_Map.get(labelName);
        }
        else if(String.isNotEmpty(labelName)) {
            List<EQT_Admin_Business_Mapping__mdt> metadata = [SELECT Id, Label, EQT_Account_Company_Email_field__c, EQT_Account_Company_Phone_field__c,
                                                                EQT_Contact_Company_Email_field__c, EQT_Contact_Company_Phone_field__c
                                                                FROM EQT_Admin_Business_Mapping__mdt
                                                                WHERE Label = :labelName];
            if(!metadata.isEmpty()) {
                accountContactField_Map.put(labelName, metadata[0]);
                return accountContactField_Map.get(labelName);
            }
        }
        return null;
    }

    /**** Get custom settings from EQT_Admin_Settings__c object ****/
    static Object customSettings(String field, Object defaultValue) {
        Object value = customSettings(field);
        return value == null ? defaultValue : value;
    }
    
    static Object customSettings(String field) {
        Object value = EQT_Admin_Settings__c.getOrgDefaults().get(field);
        return value;
    }
    
    public static String getEPMIntegrationUsername() {
        return (String)customSettings('EPM_Integration_Username__c','');
    }

    public static Boolean getLoggingEnabled() {
        return (Boolean)customSettings('Event_Logging__c',FALSE);
    }
    
    public static Boolean getDateComparisonDisabled() {
        return (Boolean)customSettings('Disable_Date_Compare__c',FALSE);
    }

    public static Boolean getContactTriggerDisabled() {
        return (Boolean)customSettings('Disable_Contact_Trigger__c',FALSE);
    }
    
    public static Boolean getSectorTeamMemberTriggerDisabled() {
        return (Boolean)customSettings('Disable_Sector_Team_Member_Trigger__c',FALSE);
    }

    public static Boolean getUserTriggerDisabled() {
        return (Boolean)customSettings('Disable_User_Trigger__c',FALSE);
    }

    public static Boolean getClearLogsEnabled() {
        return (Boolean)customSettings('Clear_Event_Logs__c',FALSE);
    }
    
    public static Boolean getFundTriggerDisabled() {
        return (Boolean)customSettings('Disable_Fund_Trigger__c',FALSE);
    }

    public static Boolean getAccountTriggerDisabled() {
        return (Boolean)customSettings('Disable_Account_Trigger__c',FALSE);
    }

    public static Boolean getOpportunityTriggerDisabled() {
        return (Boolean)customSettings('Disable_Opportunity_Trigger__c',FALSE);
    }

    public static Boolean getOpportunityTeamMemberTriggerDisabled() {
        return (Boolean)customSettings('Disable_Opportunity_Team_Member_Trigger__c',FALSE);
    }

    public static Boolean getCommitmentTriggerDisabled() {
        return (Boolean)customSettings('Disable_Commitment_Trigger__c',FALSE);
    }

    public static Boolean getInvestorLPCodeTriggerDisabled() {
        return (Boolean)customSettings('Disable_Investor_LP_Code_Trigger__c', FALSE);
    }

    public static Boolean getFundPartnershipTriggerDisabled() {
        return (Boolean)customSettings('Disable_Fund_Partnership_Trigger__c', FALSE);
    }

    public static Boolean getFundCommitmentTriggerDisabled() {
        return (Boolean)customSettings('Disable_Fund_Commitment_Trigger__c', FALSE);
    }

    public static Boolean getInvestranContactListTriggerDisabled() {
        return (Boolean)customSettings('Disable_Investran_Contact_List_Trigger__c', FALSE);
    }

    public static Boolean getEventTriggerDisabled() {
        return (Boolean)customSettings('Disable_Event_Trigger__c', FALSE);
    }

    public static Boolean getProxyEventRelationTriggerDisabled() {
        return (Boolean)customSettings('Disable_Proxy_Event_Relation_Trigger__c', FALSE);
    }
    
    public static String getOpportunityCloseValue() {
        return (String)customSettings('Opportunity_Close_Value__c','');
    }
    
    public static String getOpportunityFundraisingRequestDefaultStage() {
        return (String)customSettings('Opp_Fundraising_Request_default_Stage__c','');
    }

    public static String getOpportunityFundraisingRequestRecordTypeName() {
        return (String)customSettings('Opportunity_Fundraising_Record_Type_Name__c','');
    }

    public static String getFundPlanningFundraisingRecordTypeName() {
        return (String)customSettings('Fund_Planning_Fundraising_Record_Type__c','');
    }

    public static String getFundStatusesForDataroomRefresh() {
        return (String)customSettings('Fund_Statuses_for_DateRoom_Refresh__c','');
    }

    public static String getFundPlanningFundraisingStatuseName() {
        return (String)customSettings('Fund_Planning_Fundraising_Status__c','');
    }

    public static String getSlackEndpointURL() {
        return (String)customSettings('Slack_endpoint_URL__c','');
    }

    public static String getSlackIntegrationUserToken() {
        return (String)customSettings('Slack_Integration_User_Token__c','');
    }

    public static String getIrisBotName() {
        return (String)customSettings('Slack_Bot_Name__c','');
    }

    public static String getSlackAccountChannel() {
        return (String)customSettings('Slack_Account_Channel__c','');
    }

    public static String getIntralinksEndpointURL() {
        return (String)customSettings('Intralinks_Endpoint_URL__c','');
    }

    public static String getIntralinksClientId() {
        return (String)customSettings('Intralinks_Client_Id__c','');
    }

    public static String getIntralinksClientSecret() {
        return (String)customSettings('Intralinks_Client_Secret__c','');
    }

    public static String getIntralinksAccessToken() {
        return (String)customSettings('Intralinks_Access_Token__c','');
    }

    public static void setIntralinksAccessToken(String accessToken) {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Access_Token__c', accessToken);
        update appSettings;
    }

    public static String getIntralinksRefreshToken() {
        return (String)customSettings('Intralinks_Refresh_Token__c','');
    }

    public static void setIntralinksRefreshToken(String refreshToken) {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Refresh_Token__c', refreshToken);
        update appSettings;
    }

    public static String getIntralinksAdminEmail() {
        return (String)customSettings('Intralinks_Admin_email__c','');
    }

    public static Boolean getShouldLogIntralinksCallout() {
        return (Boolean)customSettings('Log_Intralinks_Callout__c', false);
    }

    public static Integer getIntralinksBatchSize() {
        return Integer.valueOf(customSettings('Intralinks_Batch_Size__c', 30));
    }

    public static Boolean getIntralinksWeeklyRefresh() {
        return (Boolean)customSettings('Intralinks_Weekly_Refresh__c', true);
    }

    public static String getStagesForPipelineVolumeWeightedCalculation() {
        return (String)customSettings('Opportunity_Pipeline_Volume_Weight_Stage__c','');
    }

    public static String getStagesForPipelineVolumeUnweightedCalculation() {
        return (String)customSettings('Opportunity_Pipeline_Volume_Unweight_Sta__c','');
    }

    public static String getStagesForCommittedCapitalCalculation() {
        return (String)customSettings('Opportunity_Committed_Capital_Stages__c','');
    }

    public static Boolean getCaseTriggerDisabled() {
        return (Boolean)customSettings('Disable_Case_Trigger__c', FALSE);
    }

    public static String getCampaignInvestorEventRecordTypeName() {
        return (String)customSettings('Campaign_Investor_Event_Record_Type_Name__c', '');
    }

    public static String getOpportunityCoInvestmentRecordTypeName() {
        return (String)customSettings('Opportunity_Co_Investme_Record_Type_Name__c', '');
    }

    public static String getFundCoInvestmentFundraiseRecordTypeName() {
        return (String)customSettings('Fund_Co_Investment_Fundraise_Record_Type__c', '');
    }

    public static String getOpportunityCoInvestmentDefaultStage() {
        return (String)customSettings('Opportunity_Co_Investment_Default_Stage__c', '');
    }

    public static String getOpportynityCoInvestmentDefaultType() {
        return (String)customSettings('Opportunity_Co_Investment_Default_Type__c', '');
    }

    public static String getOpportunityCoInvestmentLikelyHoodForClose() {
        return (String)customSettings('Opportunity_Co_Investment_LikelyHood__c', '');
    }

    public static String getOpportunityCoInvestmentPreSignType() {
        return (String)customSettings('Opportunity_Co_Investment_Pre_Sign_Type__c', 'Pre-signing');
    }

    public static String getOpportunityCoInvestmentPostSignType() {
        return (String)customSettings('Opportunity_Co_Investment_Post_Sign_Type__c', 'Post-signing');
    }

    public static Boolean getTaskTriggerDisabled() {
        return (Boolean)customSettings('Disable_Task_Trigger__c', FALSE);
    }

    public static Boolean getBespokeReportingTriggerDisabled() {
        return (Boolean)customSettings('Disable_Bespoke_Reporting_Trigger__c', FALSE);
    }

    public static String getIrisApplicationId() {
        return (String)customSettings('Iris_application_Id__c','');
    }

    public static void setIrisApplicationId(String applicationId) {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Iris_application_Id__c', applicationId);
        update appSettings;
    }
    public static String getStageNameForNotInterestedOpportunity() {
        return (String)customSettings('Opportunity_Not_Interested_Stage_Name__c','');
    }

    public static String getDeclineReasonForNotInterestedOpportunity() {
        return (String)customSettings('Opportunity_Not_Interested_DeclineReason__c','');
    }

    public static String getDeclineReasonTextForNotInterestedOpportunity() {
        return (String)customSettings('Opportunity_Not_Interested_DR_Text__c','');
    }
    public static Boolean getSectorRatingTriggerDisabled() {
        return (Boolean)customSettings('Disable_Sector_Rating_Trigger__c', FALSE);
    }
    
    public static Boolean getAssignmentTriggerDisabled() {
        return (Boolean)customSettings('Disable_Assignment_Trigger__c', FALSE);
    }

    public static Boolean getAgreementTriggerDisabled() {
        return (Boolean)customSettings('Disable_Agreement_Trigger__c', FALSE);
    }

    public static String getExternalContactRecordTypeName() {
        return (String)customSettings('External_Contact_Record_Type_Name__c','EQT_Person');
    }

    public static String getAssignmentBoardMngRecordTypeName() {
        return (String)customSettings('Assignment_Board_Management_Record_Type__c', 'Board_Management_Assignment');
    }

    public static String getIAContractingExpiredStatus() {
        return (String)customSettings('IA_Contracting_Expired_Status__c', 'Expired Agreement');
    }

    public static String getIABoardIEEngagementLevelName() {
        return (String)customSettings('IA_Engagement_Level_Board_IE_Name__c', 'Board IE/CEO');
    }

    public static String getAssignmentRolesToSetIAEngagementLevelToBoardIE() {
        return (String)customSettings('Assignment_Roles_for_IE_Engagement_Level__c', 'Board Member;CEO;Chairman;Vice Chairman');
    }

    public static String getAgreementExpiredStatusName() {
        return (String)customSettings('Agreement_Expired_Status_Name__c', 'Expired');
    }

    public static String getAgreementActiveStatusName() {
        return (String)customSettings('Agreement_Active_Status_Name__c', 'Active');
    }
    
    public static String getAgreementTerminatedByIAStatusName() {
        return (String)customSettings('Agreement_Terminated_By_IA_Status_Name__c', 'Terminated by IA');
    }

    public static String getAgreementTerminatedByEQTStatusName() {
        return (String)customSettings('Agreement_Terminated_By_EQT_Status_Name__c', 'Terminated by EQT');
    }

    public static String getDefaultAccountId() {
        return (String)customSettings('EQT_Default_Account_ID__c');
    }

    public static String getAgreementCompanyRecordTypeName() {
        return (String)customSettings('Agreement_Company_Record_Type_Name__c', 'EQT_Company');
    }

    public static String getIndustrialAdvisorRecordTypeName() {
        return (String)customSettings('IA_Contact_Record_Type_Name__c', 'EQT_Industrial_Advisor');
    }

    public static String getAssignmentDealRecordTypeName() {
        return (String)customSettings('Assignment_Deal_Record_Type_Name__c', 'EQT_Project_Assignment');
    }

    public static String getAssignmentOperativeRecordTypeName() {
        return (String)customSettings('Assignment_Operative_Record_Type_Name__c', 'Operative_Assignment');
    }

    public static String getIADealEngagementLevelName() {
        return (String)customSettings('IA_Engagement_Level_Deal_IE_Name__c', 'Deal IE');
    }

    public static String getIAProspectEngagementLevelName() {
        return (String)customSettings('IA_Engagement_Level_Prospect_Name__c', 'IA Prospect');
    }

    public static String getIACandidateEngagementLevelName() {
        return (String)customSettings('IA_Engagement_Level_Candidate_Name__c', 'IA Candidate');
    }

    public static String getAgreementInProgressStatusName() {
        return (String)customSettings('Agreement_In_progress_Status_Name__c', 'In Progress');
    }

    public static String getOpportunityDealRecordTypeName() {
        return (String)customSettings('Opportunity_Deal_Record_Type_Name__c', 'EQT_Deal');
    }

    public static String getOpportunityCreditRecordTypeName() {
        return (String)customSettings('Opportunity_Credit_Record_Type_Name__c', 'EQT_Credit_Opportunity');
    }

    public static String getOpportunityMMCSeniorDebtRecordTypeName() {
        return (String)customSettings('Opportunity_MMC_Senior_Debt_Record_Type__c', 'EQT_MMC_Senior_Debt_opportunity');
    }

    public static String getOpportunityTeamMemberDealTeamRoleName() {
        return (String)customSettings('Opportunity_Team_Member_Deal_Team_Role__c', 'Deal Team');
    }
}