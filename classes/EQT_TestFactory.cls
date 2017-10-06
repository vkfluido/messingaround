/**
    About
    -----
    Description: This class is used to create test data in objects
    Created for: EQT POC
    Create date: April 2016
    
    Details
    -------
    Helper class used to create test data for objects used in test classes
    
    Update History
    --------------
    Create April 2016 - R.B.
    2016-11-07 added createSampleDocument -felix.guerrero@fluidogroup.com

    Issues / TODOs
    --------------
    Create sets of methods
*/
@isTest
public class EQT_TestFactory {
    
    static boolean setUpOrg_done = false;

    //Set up the org for a test
    public static void setUpOrg() {
        if (!setUpOrg_done) {
            createCustomSettings();
        }
        setUpOrg_done = true;
    }

    //create Custom Setting for the org
    public static void createCustomSettings() {   
        //get default org settings
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        
        // mark all fields null, which should result in a default value set
        Map<String, Schema.SobjectField> fieldMap = Schema.SObjectType.EQT_Admin_Settings__c.fields.getMap();
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable()) {
                if(!fieldMap.get(fieldName).getDescribe().isDefaultedOnCreate()) {
                    appSettings.put(fieldName, null);
                }
            }
        }

        // set non defaulting fields to relevant values as required
        appSettings.put('Disable_Contact_Trigger__c', false);
        appSettings.put('Event_Logging__c', false);
        appSettings.put('Clear_Event_Logs__c', false);
        appSettings.put('Disable_Account_Trigger__c', false);
        appSettings.put('Opportunity_Close_Value__c', '1st Close');
        appSettings.put('Disable_Opportunity_Trigger__c', false);
        //appSettings.put('Opportunity_Parent_Record_Type_Name__c', 'Fundraise');
        appSettings.put('Opportunity_Fundraising_Record_Type_Name__c', 'EQT_Fundraising_Request');
        appSettings.put('Opp_Fundraising_Request_default_Stage__c', 'No Interest');
        appSettings.put('Disable_Commitment_Trigger__c', false);
        appSettings.put('Fund_Planning_Fundraising_Record_Type__c', 'EQT_Planning_Fundraising');
        appSettings.put('Slack_endpoint_URL__c','https://slack.com/api');
        appSettings.put('Slack_Integration_User_Token__c','xxx');
        appSettings.put('Slack_Account_Channel__c','test_channel');
        appSettings.put('EPM_Integration_Username__c', 'testIntegrationUser@example.eqt');
        appSettings.put('Disable_Investor_LP_Code_Trigger__c', false);
        appSettings.put('Disable_Fund_Partnership_Trigger__c', false);
        appSettings.put('Disable_Fund_Commitment_Trigger__c', false);
        appSettings.put('Disable_Investran_Contact_List_Trigger__c', false);
        appSettings.put('Disable_Event_Trigger__c', false);
        appSettings.put('Disable_Proxy_Event_Relation_Trigger__c', false);
        appSettings.put('Fund_Planning_Fundraising_Status__c', 'Planning;In Fundraising');
        appSettings.put('Fund_Statuses_for_DateRoom_Refresh__c', 'Planning;In Fundraising');
        appSettings.put('Opportunity_Pipeline_Volume_Weight_Stage__c', 'Decline;Closed Out');
        appSettings.put('Opportunity_Pipeline_Volume_Unweight_Sta__c', 'Decline;Closed Out;Closed Won');
        appSettings.put('Opportunity_Committed_Capital_Stages__c', 'Closed Out');
        appSettings.put('Campaign_Investor_Event_Record_Type_Name__c', 'EQT_Investor_Event');
        appSettings.put('Opportunity_Co_Investme_Record_Type_Name__c', 'EQT_Co_Investment_Fundraise_request');
        appSettings.put('Fund_Co_Investment_Fundraise_Record_Type__c', 'EQT_Co_Investment_Fundraise');
        appSettings.put('Opportunity_Co_Investment_Default_Stage__c', '01 - IR First Call');
        appSettings.put('Opportunity_Co_Investment_Default_Type__c', 'Pre-signing');
        appSettings.put('Opportunity_Co_Investment_LikelyHood__c', '3- Less Likely');
        appSettings.put('Disable_Task_Trigger__c', false);

        appSettings.put('Opportunity_Not_Interested_DeclineReason__c', 'Other');
        appSettings.put('Opportunity_Not_Interested_Stage_Name__c', 'Decline');
        appSettings.put('Opportunity_Not_Interested_DR_Text__c', 'Automatically decline in Fundraising considering investor preferences');
    	appSettings.put('Disable_Sector_Rating_Trigger__c', false);
        appSettings.put('Disable_Agreement_Trigger__c', false);
        appSettings.put('External_Contact_Record_Type_Name__c','EQT_Person');
        appSettings.put('Assignment_Board_Management_Record_Type__c', 'Board_Management_Assignment');
        appSettings.put('IA_Contracting_Expired_Status__c', 'Expired Agreement');
        appSettings.put('IA_Engagement_Level_Board_IE_Name__c', 'Board IE/CEO');
        appSettings.put('Assignment_Roles_for_IE_Engagement_Level__c', 'Board Member;CEO;Chairman;Vice Chairman');
        appSettings.put('Agreement_Expired_Status_Name__c', 'Expired');
        appSettings.put('Agreement_Active_Status_Name__c', 'Active');
        appSettings.put('Agreement_Terminated_By_IA_Status_Name__c', 'Terminated by IA');
        appSettings.put('Agreement_Terminated_By_EQT_Status_Name__c', 'Terminated by EQT');
        appSettings.put('Agreement_Company_Record_Type_Name__c', 'EQT_Company');
        appSettings.put('IA_Contact_Record_Type_Name__c', 'EQT_Industrial_Advisor');
        appSettings.put('Assignment_Deal_Record_Type_Name__c', 'EQT_Project_Assignment');
        appSettings.put('Assignment_Operative_Record_Type_Name__c', 'Operative_Assignment');
        appSettings.put('IA_Engagement_Level_Deal_IE_Name__c', 'Deal IE');
        appSettings.put('Disable_Assignment_Trigger__c', false);
        appSettings.put('IA_Engagement_Level_Prospect_Name__c', 'IA Prospect');
        appSettings.put('IA_Engagement_Level_Candidate_Name__c', 'IA Candidate');
        appSettings.put('Agreement_In_progress_Status_Name__c','In Progress');

        upsert appSettings;
    }

    //create sample Account
    public static Account createSampleAccount(String recordTypeName, String name, Boolean doDML) {
        Account testAccount = new Account();
        testAccount.Name = String.isEmpty(name) ? 'sample name' : name;
        testAccount.RecordTypeId = String.isEmpty(recordTypeName) ? EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor') : EQT_UTIL_Meta.getRecordTypeId(recordTypeName);
        testAccount.OwnerId = UserInfo.getUserId();
        /* TA768 remove fields on Account
        testAccount.EQT_Equity__c = false;
        testAccount.EQT_Mid_Market__c = false;
        testAccount.EQT_Credit__c = false;
        testAccount.EQT_Infrastructure__c = false;
        testAccount.EQT_Credit__c = false;
        */
        testAccount.EQT_EPM_LastModifiedDate__c = null;
        testAccount.EQT_EPM_Responsible__c = null;
        testAccount.EQT_EPM_CounterpartID__c = null;
        
        if (doDML) insert testAccount;
        
        return testAccount;
    }
    public static Account createSampleAccount(String recordTypeName, String name) {
        return createSampleAccount( recordTypeName, name, true);
    }
    public static Account createSampleAccount(String recordTypeName, String name, String email, String phone) {
        Account testAccount = new Account();
        testAccount.Name = String.isEmpty(name) ? 'sample name' : name;
        testAccount.RecordTypeId = String.isEmpty(recordTypeName) ? EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor') : EQT_UTIL_Meta.getRecordTypeId(recordTypeName);
        testAccount.EQT_Company_Email__c = email;
        testAccount.EQT_Company_Phone__c = phone;
        
        insert testAccount;
        
        return testAccount;
    }

    //create sample Accounts
    public static void createSetOfSampleAccounts(String recordTypeName, Integer count) {
        List<Account> accountToInsert = new List<Account>();
        for(Integer i=1; i <= count; i++) {
            accountToInsert.add(new Account(
                Name = 'sample name'  + i,
                RecordTypeId = String.isEmpty(recordTypeName) ? EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Investor') : EQT_UTIL_Meta.getRecordTypeId(recordTypeName),
                OwnerId = UserInfo.getUserId()//,
                /* TA768 remove fields on Account
                EQT_Equity__c = false,
                EQT_Mid_Market__c = false,
                EQT_Credit__c = false,
                EQT_Infrastructure__c = false
                */
            ));
        }
        
        if(!accountToInsert.isEmpty()) {
            insert accountToInsert;
        }
    }

    //create sample Contact
    /*
    public static Contact createSamplePrivateContact(String firstName, String lastName, Boolean doDML) {
        Contact testContact = new Contact();
        testContact.FirstName = String.isEmpty(firstName) ? 'sampleFirstName' : firstName;
        testContact.LastName = String.isEmpty(lastName) ? 'sampleLastName' : lastName;
        testContact.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.Person');
        if (doDML) insert testContact;
        return testContact;
    }
    */
    public static Contact createSampleContact(String firstName, String lastName, String accountId, Boolean doDML) {
        Contact testContact = new Contact();
        testContact.FirstName = String.isEmpty(firstName) ? 'sampleFirstName' : firstName;
        testContact.LastName = String.isEmpty(lastName) ? 'sampleLastName' : lastName;
        testContact.AccountId = String.isEmpty(accountId) ? createSampleAccount('Account.EQT_Investor', 'test account for contact').Id : accountId;
        testContact.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person');
        testContact.MobilePhone = null;
        testContact.EQT_EPM_LastModifiedDate__c = null;
        testContact.EQT_EPM_PersonID__c = null;
        
        if (doDML) insert testContact;
        return testContact;
    }
    public static Contact createSampleContact(String firstName, String lastName, String accountId) {
        return createSampleContact( firstName,  lastName,  accountId,  true);
    }
    
    //create sample Contact
    public static Contact createSampleContact(String firstName, String lastName, String accountId, String recordTypeName) {
        return createSampleContact( firstName,  lastName,  accountId, recordTypeName, true);
    }

    public static Contact createSampleContact(String firstName, String lastName, String accountId, String recordTypeName, Boolean doDML) {
        Contact testContact = new Contact();
        testContact.FirstName = String.isEmpty(firstName) ? 'sampleFirstName' : firstName;
        testContact.LastName = String.isEmpty(lastName) ? 'sampleLastName' : lastName;
        testContact.AccountId = String.isEmpty(accountId) ? createSampleAccount('Account.EQT_Investor', 'test account for contact').Id : accountId;
        testContact.RecordTypeId = String.isEmpty(recordTypeName) ? EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person') : EQT_UTIL_Meta.getRecordTypeId(recordTypeName);

        if (doDML) insert testContact;
        return testContact;
    }


    //create sample User
    public static User createUser(String uName, String profileName) {
        //set up org first
        setUpOrg();
        
        User u = new User();
        u.username= String.isEmpty(uName) ? '' : uName;
        u.email ='test123456789QW@test.com';
        u.localeSidKey = 'en_US';
        u.languageLocaleKey = 'en_US';
        u.profileId = EQT_UTIL_Meta.profileId(profileName);
        u.lastname='test';
        u.TimeZoneSidKey='GMT';
        u.EmailEncodingKey='UTF-8';
        u.Alias = 'utu';
        insert u;

        return u;
    }
    
    //create test logs
    public static void createSampleLogs() {
        List<EQT_Event_Log__c> logs = new List<EQT_Event_Log__c>();
        logs.add(new EQT_Event_Log__c(EQT_Log_Detail__c = 'test log'));
        
        insert logs;
    }
    
    //enable logging feature
    public static void enableLoggingFeature() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Event_Logging__c', true);
        update appSettings;
    }
    
    //disable Contact trigger
    public static void disableContactTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Contact_Trigger__c', true);
        update appSettings;
    }
    
    //enable Contact trigger
    public static void enableContactTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Contact_Trigger__c', false);
        update appSettings;
    }
    
    //disable Account trigger
    public static void disableAccountTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Account_Trigger__c', true);
        update appSettings;
    }
    
    //enable Account trigger
    public static void enableAccountTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Account_Trigger__c', false);
        update appSettings;
    }

    //disable Opportunity trigger
    public static void disableOpportunityTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Opportunity_Trigger__c', true);
        update appSettings;
    }
    
    //enable Opportunity trigger
    public static void enableOpportunityTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Opportunity_Trigger__c', false);
        update appSettings;
    }

    //disable Commitment trigger
    public static void disableCommitmentTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Commitment_Trigger__c', true);
        update appSettings;
    }
    
    //enable Commitment trigger
    public static void enableCommitmentTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Commitment_Trigger__c', false);
        update appSettings;
    }

    //disable Investor LP Code trigger
    public static void disableInvestorLPCodeTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Investor_LP_Code_Trigger__c', true);
        update appSettings;
    }

    //enable Investor LP Code trigger
    public static void enableInvestorLPCodeTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Investor_LP_Code_Trigger__c', false);
        update appSettings;
    }

    //disable Fund Commitment trigger
    public static void disableFundCommitmentTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Fund_Commitment_Trigger__c', true);
        update appSettings;
    }

    //enable Fund Commitment trigger
    public static void enableFundCommitmentTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Fund_Commitment_Trigger__c', false);
        update appSettings;
    }

    //disable Investran Contact List  trigger
    public static void disableInvestranContactListTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Investran_Contact_List_Trigger__c', true);
        update appSettings;
    }

    //enable Investran Contact List  trigger
    public static void enableInvestranContactListTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Investran_Contact_List_Trigger__c', false);
        update appSettings;
    }

    public static void setDefaultAccountId(Id accountId){
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('EQT_Default_Account_ID__c', accountId);
        update appSettings;
    }
    /* TA387 Rollback customizations for Summer 16 m:m Account Contact functionality
    public static void createRole(Contact c, String accountId, Date roleStart, Date roleEnd, Boolean keyContact) {
        EQT_AccountContactRole__c relation = new EQT_AccountContactRole__c();
        relation.AccountId__c = accountId;
        relation.ContactId__c = c.Id;
        relation.Active__c = true;
        relation.Role_Start_Date__c = roleStart;
        relation.Role_End_Date__c = roleEnd;
        relation.Key_Contact__c = keyContact;
        relation.Role_name__c = c.Title;
        
        insert relation;
    }
    */
    
    /*
    public static Campaign createFundriserCampaing(String name) {
        Campaign c = new Campaign();
        c.Name = name;
        c.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.EQT_Fundraiser');
        c.Type = EQT_UTIL_Settings.getCampaignTypeForRollupSummary();
        
        insert c;
        
        return c;
    }
    */
    
    public static Fund__c createSampleFund(String name) {
        Fund__c fund = new Fund__c();
        fund.Name = String.isEmpty(name) ? 'test fund' : name;
        
        insert fund;
        
        return fund;
    }

    public static Fund__c createSamplePlanningFundraisingFund(String name) {
        return createSamplePlanningFundraisingFund(name, true);
    }
    public static Fund__c createSamplePlanningFundraisingFund(String name, Boolean doDML) {
        Fund__c fund = new Fund__c();
        fund.Name = String.isEmpty(name) ? 'test fund' : name;
        fund.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundPlanningFundraisingRecordTypeName());
        fund.EQT_Final_Close_Date__c = Date.today().addDays(2);
        
        if (doDML) insert fund;
        
        return fund;
    }

    public static Fund__c createSampleFund(String name, String strategyCode) {
        Fund__c fund = new Fund__c();
        fund.Name = String.isEmpty(name) ? 'test fund' : name;
        fund.EQT_Fund_Strategy__c = strategyCode;
        /*
            3  -> Equity
            6  -> Credit
            7  -> Infrastructure
            10 -> Mid Market
            11 -> Senior Debt
        */

        insert fund;
        
        return fund;
    }

    public static Fund__c createSampleFundWithPreviousFund(String name, String strategyCode, String prevFundId) {
        Fund__c fund = new Fund__c();
        fund.Name = String.isEmpty(name) ? 'test fund' : name;
        fund.EQT_Fund_Strategy__c = strategyCode;
        fund.EQT_Previous_Fund__c = String.isEmpty(prevFundId) ? createSampleFund('prev fund', strategyCode).Id : prevFundId;
        /*
            3  -> Equity
            6  -> Credit
            7  -> Infrastructure
            10 -> Mid Market
            11 -> Senior Debt
        */

        insert fund;
        
        return fund;
    }
    
    public static Opportunity createSampleOpportunity(String name, String fundId, String stage, Boolean doDML) {
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.CloseDate = Date.today().addDays(14);
        opp.EQT_Fund__c = fundId;
        opp.StageName = stage;
        opp.OwnerId = UserInfo.getUserId();
        if (doDML) insert opp;
        return opp;
    }

    public static Opportunity createSampleFundraiseOpportunity(String name, String fundId, String stage) {
        return createSampleFundraiseOpportunity( name,  fundId,  stage, true);
    }
    public static Opportunity createSampleFundraiseOpportunity(String name, String fundId, String stage, Boolean doDML) {
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.CloseDate = Date.today().addDays(14);
        opp.EQT_Fund__c = fundId;
        opp.StageName = stage;
        opp.OwnerId = UserInfo.getUserId();
        
        if (doDML) insert opp;
        
        return opp;
    }
    
    public static OpportunityTeamMember createSampleOppTeamMember(String opportunityId, String userId) {
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opportunityId;
        otm.OpportunityAccessLevel = 'Read';
        otm.TeamMemberRole = 'Account Manager';
        otm.UserId = userId;
        
        insert otm;
        return otm;
    }

    public static OpportunityTeamMember createSampleOppTeamMember(String opportunityId, String userId, String role, String accessLevel, Boolean doDML) {
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opportunityId;
        otm.OpportunityAccessLevel = accessLevel;
        otm.TeamMemberRole = role;
        otm.UserId = userId;

        if(doDML) {
            insert otm;
        }

        return otm;
    }
    
    public static Opportunity createSampleFundraisingRequestOpportunity(String name, String accountId, String stage, String fundId) {
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.CloseDate = Date.today().addDays(14);
        opp.AccountId = accountId;
        opp.StageName = stage;
        opp.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());
        opp.EQT_Close__c = EQT_UTIL_Settings.getOpportunityCloseValue();
        opp.EQT_Fund__c = fundId;
        
        insert opp;
        
        return opp;
    }
    
    public static Opportunity createOpportunityForCampaign(String campaignId, String accountId, String stage, Decimal amount) {
        Opportunity toInsert = new Opportunity();
        toInsert.Name = 'testOpportunity';
        toInsert.AccountId = accountId;
        toInsert.CampaignId = campaignId;
        toInsert.CloseDate = Date.today().addDays(7);
        toInsert.StageName = stage;
        toInsert.Amount = amount;
        toInsert.EQT_Close__c = EQT_UTIL_Settings.getOpportunityCloseValue();
        
        insert toInsert;
        
        return toInsert;
    }
    
    public static List<Opportunity> createMultipleOpportunitiesForCampaing(String campaignId, String accountId, String stage, Integer count, Decimal amount) {
        List<Opportunity> toInsert = new List<Opportunity>();
        for(Integer i=1; i <= count; i++) {
            toInsert.add(new Opportunity(Name = 'testOpportunity-' + i, AccountId = accountId, CampaignId = campaignId, CloseDate = Date.today().addDays(7), StageName = stage, Amount = amount,
                            EQT_Close__c = EQT_UTIL_Settings.getOpportunityCloseValue()));
        }
        
        insert toInsert;
        
        return toInsert;
    }

    public static List<Opportunity> createMultipleOpportunitiesEQTCloseForFund(String fundId, String accountId, String stage, Integer count, Decimal amount) {
        List<Opportunity> toInsert = new List<Opportunity>();
        for(Integer i=1; i <= count; i++) {
            toInsert.add(new Opportunity(
                Name = 'testOpportunity-' + i,
                AccountId = accountId,
                EQT_Fund__c = fundId,
                CloseDate = Date.today().addDays(7),
                StageName = stage,
                Amount = amount,
                EQT_Close__c = EQT_UTIL_Settings.getOpportunityCloseValue()
                //RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName())
                ));
        }

        insert toInsert;

        return toInsert;
    }

    /*
    public static List<Opportunity> createMultipleOpportunitiesEQTCloseForParent(String parentId, String accountId, String stage, Integer count, Decimal amount) {
        List<Opportunity> toInsert = new List<Opportunity>();
        for(Integer i=1; i <= count; i++) {
            toInsert.add(new Opportunity(
                Name = 'testOpportunity-' + i,
                AccountId = accountId,
                EQT_Fundraise__c = parentId,
                CloseDate = Date.today().addDays(7),
                StageName = stage,
                Amount = amount,
                EQT_Close__c = EQT_UTIL_Settings.getOpportunityCloseValue(),
                RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName())
                ));
        }
        
        insert toInsert;
        
        return toInsert;
    }
    */

    public static EQT_Commitment__c createSampleCommitment(String accountId, String fundId, String investorId) {
        EQT_Commitment__c commitment = new EQT_Commitment__c();
        //commitment.EQT_Account__c = String.isEmpty(accountId) ? createSampleAccount('Account.EQT_Investor_Legal_Entity', 'legal entity account').Id : accountId;
        commitment.EQT_Fund__c = String.isEmpty(fundId) ? createSampleFund('sample fund', '3').Id : fundId;
        commitment.EQT_Investor__c = String.isEmpty(investorId) ? createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account').Id : investorId;

        insert commitment;

        return commitment;
    }

    public static EQT_Commitment__c createSampleCommitment(String fundId, String investorId) {
        EQT_Commitment__c commitment = new EQT_Commitment__c();
        commitment.EQT_Fund__c = String.isEmpty(fundId) ? createSampleFund('sample fund', '3').Id : fundId;
        commitment.EQT_Investor__c = String.isEmpty(investorId) ? createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account').Id : investorId;

        insert commitment;

        return commitment;
    }

    public static void createFundTeamForSlackSync(String fundId, Set<String> userIds) {
        List<EQT_Team_Member_Association__c> toInsert = new List<EQT_Team_Member_Association__c>();
        for(String userId : userIds) {
            toInsert.add(new EQT_Team_Member_Association__c(EQT_Fund__c = fundId, User__c = userId));
        }
        insert toInsert;
    }

    public static void createSampleInvestorLPCodes(Integer count) {
        List<EQT_Investor_LP_Code__c> toInsert = new List<EQT_Investor_LP_Code__c>();
        for(Integer i=1; i <= count; i++) {
            toInsert.add(new EQT_Investor_LP_Code__c(Name = 'Lp Code ' + i, EQT_Vehicle_Name__c = 'Vehicle Name ' + i));
        }

        insert toInsert;
    }

    public static void createSampleFundPartnerships(Integer count) {
        List<EQT_Fund_Partnership__c> toInsert = new List<EQT_Fund_Partnership__c>();
        for(Integer i=1; i <= count; i++) {
            toInsert.add(new EQT_Fund_Partnership__c(Partnership_Name__c = 'Fund Partnership ' + i, EQT_Investran_Partnership_Legal_EntityID__c = String.valueOf(i)));
        }

        insert toInsert;
    }

    @future
    public static void assignUserToPermissionSet(Id userId, Id permissionSetId) {
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSetId);
    }

    public static void setIntralinksConfiguration() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Intralinks_Endpoint_URL__c', 'https://api.intralinks.com');
        appSettings.put('Intralinks_Client_Id__c', '123');
        appSettings.put('Intralinks_Client_Secret__c', '123');
        appSettings.put('Intralinks_Access_Token__c', 'abc');
        appSettings.put('Intralinks_Refresh_Token__c', 'def');
        appSettings.put('Intralinks_Admin_email__c', 'some@emailexampletest.p');
        appSettings.put('Log_Intralinks_Callout__c', true);
        update appSettings;
    }

    public static Case createSampleSlackCase(String subject, String description, String dateBy, Id opportunityId, String suppliedEmail) {
        Case c = new Case();
        c.Origin = 'Slack';
        c.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Case.RFI');
        c.Subject = subject;
        c.Description = description;
        c.Slack_date__c = dateBy;
        c.Opportunity__c = opportunityId;
        c.SuppliedEmail = suppliedEmail;

        insert c;

        return c;
    }

    public static Campaign createSampleCampaign(String name, String recordTypeId, Boolean doDML) {
        Campaign c = new Campaign();
        c.Name = name;
        c.RecordTypeId = recordTypeId;
        c.IsActive = true;
        c.StartDate = Date.today();

        if(doDML) {
            insert c;
        }

        return c;
    }

    public static Fund__c createSampleCoInvestmentFund(String name, Boolean doDML) {
        Fund__c fund = new Fund__c();
        fund.Name = String.isEmpty(name) ? 'test fund' : name;
        fund.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundCoInvestmentFundraiseRecordTypeName());
        fund.EQT_Final_Close_Date__c = Date.today().addDays(2);
        
        if (doDML) insert fund;
        
        return fund;
    }

    public static void disableTaskTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Task_Trigger__c', true);
        update appSettings;
    }

    public static void enableTaskTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Task_Trigger__c', false);
        update appSettings;
    }

    public static void disableEventTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Event_Trigger__c', true);
        update appSettings;
    }

    public static void enableEventTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Event_Trigger__c', false);
        update appSettings;
    }

    public static Task createSampleTask(String relatedToId, Date activityDate, Boolean doDML) {
        Task t = new Task();
        t.WhatId = relatedToId;
        t.Subject = 'Other';
        t.ActivityDate = activityDate;

        if(doDML) {
            insert t;
        }

        return t;
    }

    public static Event createSampleEvent(String relatedToId, String fundId, Datetime eventStartDate, Boolean doDML) {
        Event e = new Event();
        e.WhatId = relatedToId;
        e.Subject = 'Other';
        e.EQT_Fund__c = fundId;
        e.DurationInMinutes = 60;
        e.ActivityDateTime = eventStartDate;
        e.StartDateTime = eventStartDate;

        if(doDML) {
            insert e;
        }

        return e;
    }

    public static Document createSampleDocument(Id folderId, Boolean doDML){
        Document document = new Document(Name='Sample Image '+string.valueof(math.roundtolong(math.random()*1000000)));
        document.Body = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
        document.ContentType = 'image/png';
        document.Type = 'png';
        document.FolderId = folderId;
        document.IsPublic = true;
        if(doDML)
            insert document;
        return document;
    }

    public static EQT_Investor_Preference_PE__c createSampleInvestorPreference(String accountId, String strategy, String interestedNotInterested, Boolean interestedCoInvestment){
        EQT_Investor_Preference_PE__c investorPref = new EQT_Investor_Preference_PE__c();

        investorPref.EQT_Account__c = accountId;
        investorPref.EQT_Strategy__c = strategy;
        investorPref.EQT_Interested_Not_Interested__c = interestedNotInterested;
        investorPref.EQT_Interested_in_Co_Investment__c = interestedCoInvestment;

        insert investorPref;

        return investorPref;
    }
    
    //disable sector rating trigger
    public static void disableSectorRatingTrigger() {
        EQT_Admin_Settings__c appSettings = EQT_Admin_Settings__c.getInstance(UserInfo.getOrganizationId());
        appSettings.put('Disable_Sector_Rating_Trigger__c', true);
        update appSettings;
    }
    
    // Account Object //
    
    public static list<Account> createTestAccounts(integer nb, String recordTypeDeveloperName, boolean doInsert) {
        list<Account> results = new list<Account>();
        String recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND SObjectType = 'Account' LIMIT 1].Id;
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new Account(
                    Name = 'Test' + i,
                    RecordTypeId = recordTypeId,
                    Industry = 'Technology',
                    BillingCountry = 'Sweden'
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Contact Object //
    
    public static list<Contact> createTestContacts(integer nb, String recordTypeDeveloperName, list<Account> accounts, boolean doInsert) {
        list<Contact> results = new list<Contact>();
        Integer accountsSize = accounts.size();
        String recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND SObjectType = 'Contact' LIMIT 1].Id;
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new Contact(
                    LastName = 'Test' + i,
                    AccountId = accounts[Math.mod(i, accountsSize)].Id,
                    RecordTypeId = recordTypeId,
                    EQT_Suitable_Positions__c = 'CEO',
                    MailingCountry = 'Sweden',
                    EQT_IA_Status__c = 'Candidate',
                    Engagement_Level__c = 'Tier 1',
                    EQT_Rock_Star__c = (Math.mod(i, 2) == 1)
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Opportunity Object //
    
    public static list<Opportunity> createTestOpportunities(integer nb, String recordTypeDeveloperName, list<Account> accounts, boolean doInsert) {
        list<Opportunity> results = new list<Opportunity>();
        Integer accountsSize = accounts.size();
        String recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND SObjectType = 'Opportunity' LIMIT 1].Id;
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new Opportunity(
                    Name = 'Test' + i,
                    AccountId = accounts[Math.mod(i, accountsSize)].Id,
                    RecordTypeId = recordTypeId,
                    StageName = 'Qualification',
                    CloseDate = Date.today().addMonths(2),
                    EQT_Sector__c = 'Services'
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Assignment Object
    
    public static list<EQT_Assignment__c> createTestAssignments(integer nb, String recordTypeDeveloperName, list<Opportunity> deals, list<Account> accounts, list<Contact> contacts, boolean doInsert) {
        list<EQT_Assignment__c> results = new list<EQT_Assignment__c>();
        Integer accountsSize = accounts.size();
        Integer contactsSize = contacts.size();
        Integer dealsSize = deals.size();
        String recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND SObjectType = 'EQT_Assignment__c' LIMIT 1].Id;
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Assignment__c(
                    Company__c = accounts[Math.mod(i, accountsSize)].Id,
                    Contact__c = contacts[Math.mod(i, contactsSize)].Id,
                    Project__c = deals[Math.mod(i, dealsSize)].Id,
                    RecordTypeId = recordTypeId,
                    Start_Date__c = Date.today(),
                    EQT_Role__c = 'Chairman'
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Sector Object
    
    public static list<EQT_Sector__c> createTestSectors(integer nb, boolean doInsert) {
        list<EQT_Sector__c> results = new list<EQT_Sector__c>();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Sector__c(
                    Name = 'Test' + i
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // SubSector Object
    
    public static list<EQT_SubSector__c> createTestSubSectors(integer nb, list<EQT_Sector__c> sectors, boolean doInsert) {
        list<EQT_SubSector__c> results = new list<EQT_SubSector__c>();
        integer sectorsSize = sectors.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_SubSector__c(
                    Name = 'Test' + i,
                    Sector__c = sectors[Math.mod(i, sectorsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Segment Object
    
    public static list<EQT_Subsector_Segment__c> createTestSegments(integer nb, list<EQT_SubSector__c> subSectors, boolean doInsert) {
        list<EQT_Subsector_Segment__c> results = new list<EQT_Subsector_Segment__c>();
        integer subSectorsSize = subSectors.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Subsector_Segment__c(
                    Name = 'Test' + i,
                    SubSector__c = subSectors[Math.mod(i, subSectorsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Topic Object
    
    public static list<EQT_Functional_Topic__c> createTestTopics(integer nb, boolean doInsert) {
        list<EQT_Functional_Topic__c> results = new list<EQT_Functional_Topic__c>();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Functional_Topic__c(
                    Name = 'Test' + i
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // SubTopic Object
    
    public static list<EQT_Functional_SubTopic__c> createTestSubTopics(integer nb, list<EQT_Functional_Topic__c> topics, boolean doInsert) {
        list<EQT_Functional_SubTopic__c> results = new list<EQT_Functional_SubTopic__c>();
        integer topicsSize = topics.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Functional_SubTopic__c(
                    Name = 'Test' + i,
                    Functional_Topic__c = topics[Math.mod(i, topicsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Geography Object
    
    public static list<EQT_Geography__c> createTestGeographies(integer nb, boolean doInsert) {
        list<EQT_Geography__c> results = new list<EQT_Geography__c>();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Geography__c(
                    Name = 'Test' + i
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Sector Rating Object
    
    public static list<EQT_Sector_Rating__c> createTestSectorRatings(integer nb, list<EQT_Sector__c> sectors, list<Contact> contacts, boolean doInsert) {
        list<EQT_Sector_Rating__c> results = new list<EQT_Sector_Rating__c>();
        integer sectorsSize = sectors.size();
        integer contactsSize = contacts.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Sector_Rating__c(
                    Name = 'Test' + i,
                    Sector__c = sectors[Math.mod(i, sectorsSize)].Id,
                    Contact__c = contacts[Math.mod(i, contactsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Functional Rating Object
     
    public static list<EQT_Functional_Rating__c> createTestFunctionalRatings(integer nb, list<EQT_Functional_Topic__c> topics, list<Contact> contacts, boolean doInsert) {
        list<EQT_Functional_Rating__c> results = new list<EQT_Functional_Rating__c>();
        integer topicsSize = topics.size();
        integer contactsSize = contacts.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Functional_Rating__c(
                    Name = 'Test' + i,
                    Functional_Topic__c = topics[Math.mod(i, topicsSize)].Id,
                    Contact__c = contacts[Math.mod(i, contactsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }
    
    // Geographical Rating Object
    
    public static list<EQT_Geographical_Rating__c> createTestGeographicalRatings(integer nb, list<EQT_Geography__c> geos, list<Contact> contacts, boolean doInsert) {
        list<EQT_Geographical_Rating__c> results = new list<EQT_Geographical_Rating__c>();
        integer geosSize = geos.size();
        integer contactsSize = contacts.size();
        
        for (integer i = 0; i < nb; i++) {
            results.add(
                new EQT_Geographical_Rating__c(
                    Name = 'Test' + i,
                    Geography__c = geos[Math.mod(i, geosSize)].Id,
                    Contact__c = contacts[Math.mod(i, contactsSize)].Id
                )
            );
        }
        
        if (doInsert) insert results;
        return results;
    }

    public static EQT_Assignment__c createSampleAssignment(String accountId, String contactId, String recordTypeId, String role, Boolean doDML) {
        EQT_Assignment__c assignment = new EQT_Assignment__c();
        assignment.Company__c = accountId;
        assignment.Contact__c = contactId;
        if(String.isNotEmpty(recordTypeId)) {
            assignment.RecordTypeId = recordTypeId;
        }
        assignment.EQT_Role__c = role;

        if(doDML) {
            insert assignment;
        }

        return assignment;
    }

    public static EQT_IA_Contract__c createSampleAgreement(String contactId, String agreementType, String agreementStatus, Boolean doDML) {
        EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
        agreement.EQT_Industrial_Advisor__c = contactId;
        agreement.EQT_Type__c = agreementType;
        agreement.EQT_Status__c = agreementStatus;
        agreement.EQT_Start_Date__c = Date.today();
        agreement.EQT_End_Date__c = Date.today().addMonths(1);

        if(doDML) {
            insert agreement;
        }

        return agreement;
    }

    public static EQT_Sector_Rating__c createSampleSectorRating(String name, String sectorId, String subSectorId, String contactId, Boolean doDML) {
        EQT_Sector_Rating__c sr = new EQT_Sector_Rating__c();
        sr.Name = name;
        sr.Sector__c = sectorId;
        sr.Subsector__c = subSectorId;
        sr.Contact__c = contactId;

        if(doDML) {
            insert sr;
        }

        return sr;
    }

    public static EQT_Functional_Rating__c createSampleFunctionalRating(String name, String topicId, String subTopicId, String contactId, Boolean doDML) {
        EQT_Functional_Rating__c fr = new EQT_Functional_Rating__c();
        fr.Name = name;
        fr.Functional_Topic__c = topicId;
        fr.Functional_Subtopic__c = subTopicId;
        fr.Contact__c = contactId;

        if(doDML) {
            insert fr;
        }

        return fr;
    }

    public static EQT_Geographical_Rating__c createSampleGeographicalRating(String name, String geographyId, String contactId, Boolean doDML) {
        EQT_Geographical_Rating__c gr = new EQT_Geographical_Rating__c();
        gr.Name = name;
        gr.Geography__c = geographyId;
        gr.Contact__c = contactId;

        if(doDML) {
            insert gr;
        }

        return gr;
    }

    public static EQT_Sector_Team__c createSampleSectorTeam(String name, Boolean doDML){
        EQT_Sector_Team__c st = new EQT_Sector_Team__c();
        st.Name = name;

        if(doDML) {
            insert st;
        }

        return st;
    }

    public static EQT_Sector_Team_Member__c createSampleSectorTeamMember(Id contactId, Id sectorTeamId, String position, Boolean isPrimary, Boolean doDML){
        EQT_Sector_Team_Member__c stm = new EQT_Sector_Team_Member__c();
        stm.EQT_Contact__c = contactId;
        stm.EQT_Sector_Team__c = sectorTeamId;
        stm.EQT_Position__c = position;
        stm.EQT_Primary__c = isPrimary;

        if(doDML) {
            insert stm;
        }

        return stm;
    }

    public static EQT_Affiliation__c createSampleAffiliation(String accountId, String contactId, String role, Date startDate, Date endDate, Boolean doDML) {
        EQT_Affiliation__c af = new EQT_Affiliation__c();
        af.Account__c = accountId;
        af.Contact__c = contactId;
        af.Role__c = role;
        af.Start_Date__c = startDate;
        af.End_Date__c = endDate;

        if(doDML) {
            insert af;
        }

        return af;
    }

    // Creates 10X number of Investran ContactListImport records
    // for an X number of investors in Y funds, where Y <= X
    public static List<EQT_Investran_Contact_List_Import__c> createContactListImportRecords(Integer investors, Integer funds){
        List<EQT_Investran_Contact_List_Import__c> contactListImports = new List<EQT_Investran_Contact_List_Import__c>();
        Integer count = investors*10;
        for(Integer i = 1; i <= count; i++) {
            Integer investorIndex = Math.mod(i,investors);
            Integer fundIndex = Math.mod(i,funds);
            contactListImports.add(
                new EQT_Investran_Contact_List_Import__c(
                    Total_Commitment__c = Math.mod(1+investorIndex*fundIndex,10)*100000,
                    Invester_ID__c = String.valueOf(investorIndex),
                    Investor_Reference__c = 'LP000' + investorIndex,
                    Legal_Entity_ID__c = 'LE'+fundIndex,
                    Legal_Entity__c = 'Fund '+fundIndex+' Partnership',
                    Investor__c = 'Investor ' + investorIndex,
                    Imported__c = false)
                );
        }
        return contactListImports;
    }
}