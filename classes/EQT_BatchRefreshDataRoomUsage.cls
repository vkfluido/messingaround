/**
    About
    -----
    Description: Batch to refresh dataroom usage
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    - 
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_BatchRefreshDataRoomUsage implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private Fund__c fundToProcess;
    private String accessToken = EQT_UTIL_Settings.getIntralinksAccessToken();
    private String refreshToken = EQT_UTIL_Settings.getIntralinksRefreshToken();
    private Boolean storeTokens = false;
    private Boolean shouldLogCallouts = EQT_UTIL_Settings.getShouldLogIntralinksCallout();
    private static String LOGGING_PREFIX = 'Intralinks Log: ';
    private List<EQT_Event_Log__c> eventLogsToInsert = new List<EQT_Event_Log__c>();
    private List<EQT_Dataroom_Activity__c> dataroomToUpsert = new List<EQT_Dataroom_Activity__c>();
    private Map<Id, List<EQT_Dataroom_Activity__c>> drActivityMap = new Map<Id, List<EQT_Dataroom_Activity__c>>();
    private Map<Id, Id> opportunityAccountMap = new Map<Id, Id>();
    private Map<Id, Set<Id>> accountContactMap = new Map<Id, Set<Id>>();
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private Integer batchSize = EQT_UTIL_Settings.getIntralinksBatchSize();
    private Set<String> inactiveRoles = new Set<String>();

    //variables for test class
    @testVisible private Boolean testTokenRefreshStatus = false;
    @testVisible private Boolean testGetWorkspaceIdStatus = false;
    @testVisible private Boolean testGetWorkspaceUsersStatus = false;
    @testVisible private Boolean testEnterWorkspaceStatus = false;
    @testVisible private Boolean testAcceptSplashStatus = false;
    @testVisible private Boolean testCoverageReportStatus = false;

    public EQT_BatchRefreshDataRoomUsage() {}

    public Iterable<sObject> start(Database.BatchableContext BC) {      
        String fundStatuses = EQT_UTIL_Settings.getFundStatusesForDataroomRefresh();
        List<String> statusList = fundStatuses.split(';');
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        Boolean isWorkspaceAccessible = false;

        //get inactive roles
        inactiveRoles = new Set<String>();
        for(EQT_AccountContactRelationInactiveRoles__mdt r : [SELECT MasterLabel FROM EQT_AccountContactRelationInactiveRoles__mdt]) {
            inactiveRoles.add(r.MasterLabel);
        }
        
        List<Fund__c> fundToProcessList = new List<Fund__c>
        (
            [
                SELECT Id, Name, Intralinks_Workspace_ID__c, Dataroom_Workspace_Name__c
                FROM Fund__c
                WHERE Status__c IN :statusList
                AND Update_Dataroom_analytics__c = true
                ORDER BY Dataroom_Update_Request__c DESC
                LIMIT 1
            ]
        );

        if(!fundToProcessList.isEmpty()) {
            //get fund and process it
            fundToProcess = fundToProcessList[0];
            //log fund to process
            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Fund to process: ' + fundToProcess.Name);

            //if configuration is not set add error and do nothing
            if(!EQT_IntralinksCallout.isConfigurationSet()) {
                EQT_UtilApexLog.generateLog(LOGGING_PREFIX + Label.EQT_InfoMessage_NoIntralinksConfiguration, '');
            }
            else {
                opportunityMap = new Map<Id, Opportunity>
                (
                    [
                        SELECT Id, Name, AccountId, EQT_Fund__c
                        FROM Opportunity
                        WHERE EQT_Fund__c = :fundToProcess.Id
                    ]
                );

                //build opportunity account map
                for(Opportunity opp : opportunityMap.values()) {
                    opportunityAccountMap.put(opp.Id, opp.AccountId);
                }

                Set<Id> contactIds = new Set<Id>();

                //get contacts for all investors from opporunities
                for(AccountContactRelation acr : [SELECT Id, ContactId, AccountId
                                                    FROM AccountContactRelation
                                                    WHERE AccountId IN :opportunityAccountMap.values()
                                                    AND (Roles NOT IN :inactiveRoles OR isDirect = true)]) {
                    if(accountContactMap.containsKey(acr.AccountId)) {
                        accountContactMap.get(acr.AccountId).add(acr.ContactId);
                    }
                    else {
                        Set<Id> tmp = new Set<Id>();
                        tmp.add(acr.ContactId);
                        accountContactMap.put(acr.AccountId, tmp);
                    }

                    contactIds.add(acr.ContactId);
                }

                //get contacts details and build account contact map
                contactMap = new Map<Id, Contact>
                (
                    [
                        SELECT Id, Email
                        FROM Contact
                        WHERE Id IN :contactIds
                    ]
                );

                //get already existing dataroom records for opportunities in scope
                for(EQT_Dataroom_Activity__c dra : [SELECT Id, Contact__c, Dataroom_Access_Given__c, Date_added__c,
                                                    First_Access__c, Intralinks_Workspace_User_ID__c, Last_Access__c,
                                                    Opportunity__c, Role__c
                                                    FROM EQT_Dataroom_Activity__c
                                                    WHERE Opportunity__c IN :opportunityMap.keySet()]) {
                    if(drActivityMap.containsKey(dra.Opportunity__c)) {
                        drActivityMap.get(dra.Opportunity__c).add(dra);
                    }
                    else {
                        List<EQT_Dataroom_Activity__c> tmp = new List<EQT_Dataroom_Activity__c>();
                        tmp.add(dra);
                        drActivityMap.put(dra.Opportunity__c, tmp);
                    }                   
                }

                /* INITIAL CALLOUTS STARTS HERE */
                try {
                    //log callout if needed
                    if(shouldLogCallouts) {
                        EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling validate token method');
                    }
                    //before any callout will be made - check token status
                    Boolean validToken = false;
                    
                    if(!Test.isRunningTest()) {
                        validToken = EQT_IntralinksCallout.validateToken();
                    }

                    //if not valid refresh token first
                    if(!validToken) {
                        //log callout if needed
                        if(shouldLogCallouts) {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling refresh token method');
                        }

                        EQT_IntralinksCallout.EQT_IntralinksAuthenticateResponse refreshTokenResponse;

                        if(Test.isRunningTest()) {
                            refreshTokenResponse = new EQT_IntralinksCallout.EQT_IntralinksAuthenticateResponse();
                            refreshTokenResponse.success = testTokenRefreshStatus;
                        }
                        else {
                            refreshTokenResponse = EQT_IntralinksCallout.refreshTokens();
                        }

                        if(refreshTokenResponse.success) {
                            accessToken = refreshTokenResponse.accessToken;
                            refreshToken = refreshTokenResponse.refreshToken;
                            storeTokens = true;
                        }
                        else {
                            //notify admin
                            EQT_UtilApexLog.generateLog('Refresh Intralinks token failed.', refreshTokenResponse.errorMessage);
                            if(String.isNotEmpty(EQT_UTIL_Settings.getIntralinksAdminEmail())) {
                                List<String> emails = EQT_UTIL_Settings.getIntralinksAdminEmail().split(';');
                                String regenerateTokensURL = URL.getSalesforceBaseUrl().toExternalForm() + Page.EQT_IntralinksLogin.getUrl();

                                String emailBody = String.format(Label.EQT_Email_To_Regenerate_Intralinks_Tokens, new List<String> {regenerateTokensURL});
                                EQT_UtilApexLog.sendEmail('Intralinks Token Refresh', emailBody, emails);
                                return new List<EQT_Dataroom_Activity__c>();
                            }
                        }
                    }               

                    //check if there is already workspace id - if not get it
                    if(String.isEmpty(fundToProcess.Intralinks_Workspace_ID__c) && String.isNotEmpty(fundToProcess.Dataroom_Workspace_Name__c)) {
                        //log callout if needed
                        if(shouldLogCallouts) {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling get Workspace Id for ' + fundToProcess.Name + ' fund.');
                        }

                        EQT_IntralinksCallout.EQT_IntralinksWorkspaceResponse response;

                        if(Test.isRunningTest()) {
                            response = new EQT_IntralinksCallout.EQT_IntralinksWorkspaceResponse();
                            response.success = testGetWorkspaceIdStatus;
                            if(testGetWorkspaceIdStatus) {
                                response.workspaceId = '123456';
                            }
                        }
                        else {
                            response = EQT_IntralinksCallout.getWorkspaceByName(fundToProcess.Dataroom_Workspace_Name__c, accessToken);                         
                        }
     
                        if(response.success && String.isNotEmpty(response.workspaceId)) {
                            fundToProcess.Intralinks_Workspace_ID__c = response.workspaceId;
                        }
                        //log error
                        else {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling getWorkspaceByName: Error code=' + response.errorCode + '. Error message=' + response.errorMessage);
                        }
                    }

                    //get workspace users for given fund
                    if(String.isNotEmpty(fundToProcess.Intralinks_Workspace_ID__c)) {
                        //log callout if needed
                        if(shouldLogCallouts) {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling get Workspace Users for ' + fundToProcess.Name + ' fund.');
                        }

                        EQT_IntralinksCallout.EQT_IntralinksWorkspaceUsersResponse userResponse;

                        if(Test.isRunningTest()) {
                            userResponse = new EQT_IntralinksCallout.EQT_IntralinksWorkspaceUsersResponse();
                            userResponse.success = testGetWorkspaceUsersStatus;
                            if(testGetWorkspaceUsersStatus) {
                                userResponse.workspaceUsers = new Map<String, String>();
                                userResponse.workspaceUsers.put('r.biniek@polsource.com', '1111');
                            }
                        }
                        else {
                            userResponse = EQT_IntralinksCallout.getWorkspaceUsers(fundToProcess.Intralinks_Workspace_ID__c, accessToken);
                        }

                        if(userResponse.success && !userResponse.workspaceUsers.isEmpty()) {
                            for(Opportunity opp : opportunityMap.values()) {
                                String accountId = opportunityAccountMap.get(opp.Id);
                                //get related contacts for given account
                                if(accountContactMap.containsKey(accountId)) {
                                    //if there is no dataroom record for given opportunity - create it
                                    if(!drActivityMap.containsKey(opp.Id)) {
                                        //foreach related contact for opportunities account
                                        for(String contactId : accountContactMap.get(accountId)) {
                                            Contact c = contactMap.get(contactId);

                                            //try to find a march with investor and workspace users
                                            if(userResponse.workspaceUsers.containsKey(c.Email)) {
                                                EQT_Dataroom_Activity__c dra = new EQT_Dataroom_Activity__c();
                                                dra.Opportunity__c = opp.Id;
                                                dra.Contact__c = c.Id;
                                                dra.Intralinks_Workspace_User_ID__c = userResponse.workspaceUsers.get(c.Email);
                                                dra.Dataroom_Access_Given__c = true;

                                                dataroomToUpsert.add(dra);
                                            }
                                        }                            
                                    }
                                    //if there is a record for given opporutnity
                                    else {
                                        for(String contactId : accountContactMap.get(accountId)) {
                                            Contact c = contactMap.get(contactId);
                                            Boolean exists = false;

                                            for(EQT_Dataroom_Activity__c dra : drActivityMap.get(opp.Id)) {
                                                if(dra.Contact__c == c.Id) {
                                                    if(userResponse.workspaceUsers.containsKey(c.Email)) {
                                                        dra.Intralinks_Workspace_User_ID__c = userResponse.workspaceUsers.get(c.Email);
                                                        dra.Dataroom_Access_Given__c = true;

                                                        dataroomToUpsert.add(dra);
                                                    }
                                                    
                                                    exists = true;
                                                }
                                            }

                                            //if there is no record in dataroom entiries for given contact and this contact exists in intralinks - add it
                                            if(!exists && userResponse.workspaceUsers.containsKey(c.Email)) {
                                                EQT_Dataroom_Activity__c dra = new EQT_Dataroom_Activity__c();
                                                dra.Opportunity__c = opp.Id;
                                                dra.Contact__c = c.Id;
                                                dra.Intralinks_Workspace_User_ID__c = userResponse.workspaceUsers.get(c.Email);
                                                dra.Dataroom_Access_Given__c = true;

                                                dataroomToUpsert.add(dra);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        //log error
                        else {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling getWorkspaceUsers: Error code=' + userResponse.errorCode + '. Error message=' + userResponse.errorMessage);
                        }

                        //log callout if needed
                        if(shouldLogCallouts) {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling enterWorkspaceResponse for Fund="' + fundToProcess.Name + '" and workspaceId="' + fundToProcess.Intralinks_Workspace_ID__c + '"');
                        }

                        EQT_IntralinksCallout.EQT_EnterWorkspaceResponse enterWorkspaceResponse;
                        //enter workspace
                        if(Test.isRunningTest()) {
                            enterWorkspaceResponse = new EQT_IntralinksCallout.EQT_EnterWorkspaceResponse();
                            enterWorkspaceResponse.success = testEnterWorkspaceStatus;
                        }
                        else {
                            enterWorkspaceResponse = EQT_IntralinksCallout.enterWorkspace(fundToProcess.Intralinks_Workspace_ID__c, accessToken);
                        }

                        if(enterWorkspaceResponse.success) {
                            //log callout if needed
                            if(shouldLogCallouts) {
                                EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling acceptSplashResponse for Fund="' + fundToProcess.Name + '" and workspaceId="' + fundToProcess.Intralinks_Workspace_ID__c + '"');
                            }

                            //accept splash
                            EQT_IntralinksCallout.EQT_AcceptSplasheResponse acceptSplashResponse;

                            if(Test.isRunningTest()) {
                                acceptSplashResponse = new EQT_IntralinksCallout.EQT_AcceptSplasheResponse();
                                acceptSplashResponse.success = testAcceptSplashStatus;
                            }
                            else {
                                acceptSplashResponse = EQT_IntralinksCallout.acceptSplash(fundToProcess.Intralinks_Workspace_ID__c, accessToken);
                            }

                            if(acceptSplashResponse.success) {
                                isWorkspaceAccessible = true;
                            }
                            //log error
                            else {
                                EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling acceptSplash: Error code=' + acceptSplashResponse.errorCode + '. Error message=' + acceptSplashResponse.errorMessage);
                            }
                        }
                        //log error
                        else {
                            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling enterWorkspace: Error code=' + enterWorkspaceResponse.errorCode + '. Error message=' + enterWorkspaceResponse.errorMessage);
                        }
                    }
                }
                catch(Exception e) {
                    EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, e.getMessage());
                }
                /* INITIAL CALLOUTS ENDS HERE */
                //store new tokens if they were refreshed
                if(storeTokens) {
                    EQT_UTIL_Settings.setIntralinksAccessToken(accessToken);
                    EQT_UTIL_Settings.setIntralinksRefreshToken(refreshToken);
                }

                //store dataroom records
                if(!dataroomToUpsert.isEmpty()) {
                    upsert dataroomToUpsert;
                }

                if(isWorkspaceAccessible) {
                    //return list of dataroom records for given fund and related opportunities
                    return [SELECT Id, Contact__c, Dataroom_Access_Given__c, Date_added__c,
                            First_Access__c, Intralinks_Workspace_User_ID__c, Last_Access__c,
                            Opportunity__c, Role__c
                            FROM EQT_Dataroom_Activity__c
                            WHERE Opportunity__c IN :opportunityMap.keySet()];
                }
                else {
                    return new List<EQT_Dataroom_Activity__c>();
                }
            }
        }

        //if fund to process is empty
        return new List<EQT_Dataroom_Activity__c>();
    }

    public void execute(Database.BatchableContext BC, List<EQT_Dataroom_Activity__c> scope) {
        //system.debug('Radek scope=' + scope);
        dataroomToUpsert = new List<EQT_Dataroom_Activity__c>();

        for(EQT_Dataroom_Activity__c dra : scope) {
            if(String.isNotEmpty(dra.Opportunity__c)
                && String.isNotEmpty(dra.Intralinks_Workspace_User_ID__c)
                && String.isNotEmpty(fundToProcess.Intralinks_Workspace_ID__c)) {
                //call coverage report and store its results into dra record
                String workspaceId = fundToProcess.Intralinks_Workspace_ID__c;
                String workspaceUserId = dra.Intralinks_Workspace_User_ID__c;

                //log callout if needed
                if(shouldLogCallouts) {
                    EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling coverageReport for Fund="' + fundToProcess.Name + '" and workspaceId="' + workspaceId + '" and workspaceUserId="' + workspaceUserId + '"');
                }
                EQT_IntralinksCallout.EQT_IntralinksCoverageReportResponse coverageReportResult;

                if(Test.isRunningTest()) {
                    coverageReportResult = new EQT_IntralinksCallout.EQT_IntralinksCoverageReportResponse();
                    coverageReportResult.success = testCoverageReportStatus;
                    if(testCoverageReportStatus) {
                        String testTime = '1453207986000';// --> 2016-01-19
                        coverageReportResult.dateAdded = Long.valueOf(testTime);
                        coverageReportResult.firstAccess = Long.valueOf(testTime);
                        coverageReportResult.lastAccess = Long.valueOf(testTime);
                    }
                }
                else {
                    try {
                        coverageReportResult = EQT_IntralinksCallout.getCoverageReport(workspaceId, workspaceUserId, accessToken);
                    }
                    catch(Exception e) {
                        coverageReportResult = new EQT_IntralinksCallout.EQT_IntralinksCoverageReportResponse();
                        coverageReportResult.success = false;
                        coverageReportResult.errorMessage = e.getMessage();
                    }
                }

                if(coverageReportResult.success) {
                    //get and store data
                    if(coverageReportResult.dateAdded != null) {
                        dra.Date_added__c = Datetime.newInstance(coverageReportResult.dateAdded).date();
                    }
                    if(coverageReportResult.firstAccess != null) {
                        dra.First_Access__c = Datetime.newInstance(coverageReportResult.firstAccess);
                    }
                    if(coverageReportResult.lastAccess != null) {
                        dra.Last_Access__c = Datetime.newInstance(coverageReportResult.lastAccess);
                    }
                    //dra.Role__c = coverageReportResult.role;

                    dataroomToUpsert.add(dra);
                }
                //log error
                else {
                    EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'Calling getCoverageReport: Error code=' + coverageReportResult.errorCode + '. Error message=' + coverageReportResult.errorMessage);
                }
            }
        }

        if(!dataroomToUpsert.isEmpty()) {
            upsert dataroomToUpsert;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if(fundToProcess != null) {
            //save changes on processed fund
            fundToProcess.Update_Dataroom_analytics__c = false;
            update fundToProcess;

            //log numbers of updated users
            EQT_UtilApexLog.setEventLogsToInsert(eventLogsToInsert, LOGGING_PREFIX + 'For Fund: "' + fundToProcess.Name + '" there were: "' + dataroomToUpsert.size() + '" updates of users in Dataroom records.');
        }
        //insert logs if there was any
        //system.debug('Radek inserting log list');
        EQT_UtilApexLog.insertEventLogList(eventLogsToInsert);

        //check if there are some more funds to process
        List<Fund__c> funds = [SELECT Id FROM Fund__c WHERE Update_Dataroom_analytics__c = true];
        if(!funds.isEmpty()) {
            //check if batch is not running or is about to run
            List<AsyncApexJob> runningRefreshDataRoomBatches = [SELECT Id FROM AsyncApexJob
                                                                WHERE JobType = 'BatchApex'
                                                                AND ApexClass.Name = 'EQT_BatchRefreshDataRoomUsage'
                                                                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
            //if batch is not running and is not about to run - schedule it
            if(runningRefreshDataRoomBatches.isEmpty()) {
                if(!Test.isRunningTest()) {
                    Database.executeBatch(new EQT_BatchRefreshDataRoomUsage(), batchSize);
                }
            }
        }
    }
}