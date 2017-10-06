/**
    About
    -----
    Description: Handle logic for Intralinks callouts
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_IntralinksCallout {

    public class IntralinksException extends Exception {}

    public EQT_IntralinksCallout() {}

    public abstract class EQT_IntralinksResponse {
        public Boolean success {get;set;}
        public Integer errorCode {get;set;}
        public String errorMessage {get;set;}
    }

    public class EQT_IntralinksAuthenticateResponse extends EQT_IntralinksResponse {
        public String accessToken {get;set;}
        public String refreshToken {get;set;}
    }

    public class EQT_IntralinksWorkspaceResponse extends EQT_IntralinksResponse {
        public String workspaceId {get;set;}
    }

    public class EQT_IntralinksWorkspaceUsersResponse extends EQT_IntralinksResponse {
        public Map<String, String> workspaceUsers {get;set;}
    }

    public class EQT_IntralinksCoverageReportResponse extends EQT_IntralinksResponse {        
        public String role {get;set;}
        public Long dateAdded {get;set;}
        public Long firstAccess {get;set;}
        public Long lastAccess {get;set;}
    }

    public class EQT_IntralinksValidateTokenResponse extends EQT_IntralinksResponse {
        public Boolean validToken {get;set;}
    }

    public class EQT_EnterWorkspaceResponse extends EQT_IntralinksResponse {}
    public class EQT_AcceptSplasheResponse extends EQT_IntralinksResponse {}

    public static Boolean isConfigurationSet() {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();
        String clientId = EQT_UTIL_Settings.getIntralinksClientId();
        String clientSecret = EQT_UTIL_Settings.getIntralinksClientSecret();
        String refreshToken = EQT_UTIL_Settings.getIntralinksRefreshToken();
        String accessToken = EQT_UTIL_Settings.getIntralinksAccessToken();

        if(String.isEmpty(endpointURL) || String.isEmpty(clientId)
            || String.isEmpty(clientSecret) || String.isEmpty(refreshToken)
            || String.isEmpty(accessToken)) {
            return false;
        }

        return true;
    }

    public static Boolean validateToken() {
        Boolean validToken = false;
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();
        String clientId = EQT_UTIL_Settings.getIntralinksClientId();
        String accessToken = EQT_UTIL_Settings.getIntralinksAccessToken();
        if(endpointURL.endsWith('/')) {
            endpointURL = endpointURL.removeEnd('/');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setEndpoint(endpointURL +  '/v2/oauth/tokeninfo?client_id=' + clientId);

        Http http = new HTTP();
        HttpResponse response;

        try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'validateToken response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            if(response.getStatusCode() == 200) {                
                
                String tokenStatus = (String)results.get('status');
                Integer expiresIn = (Integer)results.get('expires_in');

                //if token is valid for more then 10min
                if(expiresIn > 600) {
                    validToken = true;
                }
            }
            
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to validate token cannot be sent from Salesforce: ' + e.getMessage());
        }

        return validToken;
    }

    //used on Intralinks login page for admin user
    public static PageReference authenticateUser() {
        //check configuration
        if(String.isEmpty(EQT_UTIL_Settings.getIntralinksEndpointURL())
            || String.isEmpty(EQT_UTIL_Settings.getIntralinksClientId())
            || String.isEmpty(EQT_UTIL_Settings.getIntralinksClientSecret())) {

            throw new IntralinksException(Label.EQT_InfoMessage_NoIntralinksConfiguration);
        }

        String loginURL = String.format('{0}/v2/oauth/authorize?client_id={1}', new List<String>
                            {
                                EQT_UTIL_Settings.getIntralinksEndpointURL(),
                                EQT_UTIL_Settings.getIntralinksClientId()
                            });

        return new PageReference(loginURL);
    }

    //used on Intralinks login page for admin user
    public static EQT_IntralinksAuthenticateResponse getTokens(String code) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();
        String clientId = EQT_UTIL_Settings.getIntralinksClientId();
        String clientSecret = EQT_UTIL_Settings.getIntralinksClientSecret();

        if(endpointURL.endsWith('/')) {
            endpointURL = endpointURL.removeEnd('/');
        }

        HttpRequest request = new HttpRequest();
        String content =    'code=' + EncodingUtil.urlEncode(code, 'UTF-8') +
                            '&grant_type=' + EncodingUtil.urlEncode('authorization_code', 'UTF-8') +
                            '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') + 
                            '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');

        request.setEndpoint(endpointURL +  '/v2/oauth/token');
        request.setHeader('Content-Type','application/x-www-form-urlencoded');
        request.setMethod('POST');
        request.setBody(content);

        Http http = new HTTP();
        HttpResponse response;
        EQT_IntralinksAuthenticateResponse intralinksResponse = new EQT_IntralinksAuthenticateResponse();

        try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'getTokens response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            //store generated tokens in custom settings
            if(response.getStatusCode() == 200) {                
                String accessToken = (String)results.get('access_token');
                String refreshToken = (String)results.get('refresh_token');

                intralinksResponse.success = true;
                intralinksResponse.accessToken = accessToken;
                intralinksResponse.refreshToken = refreshToken;
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('ErrorCode') != null && results.get('Error') != null) {
                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                        {
                            (String)results.get('ErrorCode'),
                            (String)results.get('Error')
                        });
                }
            }
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to get tokens cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_IntralinksAuthenticateResponse refreshTokens() {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();
        String clientId = EQT_UTIL_Settings.getIntralinksClientId();
        String clientSecret = EQT_UTIL_Settings.getIntralinksClientSecret();
        String refreshToken = EQT_UTIL_Settings.getIntralinksRefreshToken();

        if(endpointURL.endsWith('/')) {
            endpointURL = endpointURL.removeEnd('/');
        }

        HttpRequest request = new HttpRequest();
        String content =    'refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8') +
                            '&grant_type=' + EncodingUtil.urlEncode('refresh_token', 'UTF-8') +
                            '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') + 
                            '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');

        request.setEndpoint(endpointURL +  '/v2/oauth/refresh');
        request.setHeader('Content-Type','application/x-www-form-urlencoded');
        request.setMethod('POST');
        request.setBody(content);

        Http http = new HTTP();
        HttpResponse response;
        EQT_IntralinksAuthenticateResponse intralinksResponse = new EQT_IntralinksAuthenticateResponse();

        try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'refreshTokens response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            //store generated tokens in custom settings
            if(response.getStatusCode() == 200) {                
                String accessToken = (String)results.get('access_token');
                String newRefreshToken = (String)results.get('refresh_token');

                intralinksResponse.success = true;
                intralinksResponse.accessToken = accessToken;
                intralinksResponse.refreshToken = newRefreshToken;
            }
            else if(response.getStatusCode() == 500) {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('fault') != null) {
                    Map<String, Object> faultReason = (Map<String, Object>)results.get('fault');

                    if(faultReason.get('faultstring') != null) {
                        intralinksResponse.errorMessage = String.valueOf(faultReason.get('faultstring'));
                    }                  
                }
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('ErrorCode') != null && results.get('Error') != null) {
                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                        {
                            (String)results.get('ErrorCode'),
                            (String)results.get('Error')
                        });
                }
            }
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to refresh token cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_IntralinksWorkspaceResponse getWorkspaceByName(String name, String accessToken) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);

        request.setEndpoint(endpointURL +  '/v2/workspaces?name=' + EncodingUtil.urlEncode(name, 'UTF-8'));

        Http http = new HTTP();
        HttpResponse response;
        EQT_IntralinksWorkspaceResponse intralinksResponse = new EQT_IntralinksWorkspaceResponse();

         try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'getWorkspaceByName response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            //return workspace id for given name
            if(response.getStatusCode() == 200) {
                intralinksResponse.success = true;

                List<Object> workspaces = (List<Object>)results.get('workspace');

                for(Object workspace : workspaces) {
                    //get workspace attrubutes
                    Map<String, Object> memberAttributes = (Map<String, Object>)workspace;
                    String workspaceName = (String)memberAttributes.get('name');
                    if(name.equalsIgnoreCase(workspaceName)) {
                        intralinksResponse.workspaceId = String.valueOf((Integer)memberAttributes.get('id'));
                    }
                }
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('ErrorCode') != null && results.get('Error') != null) {
                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                        {
                            (String)results.get('ErrorCode'),
                            (String)results.get('Error')
                        });
                }
            }

        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to get workspace by name cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_IntralinksWorkspaceUsersResponse getWorkspaceUsers(String workspaceId, String accessToken) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setTimeout(20000);

        request.setEndpoint(endpointURL +  '/v2/workspaces/' + workspaceId + '/users');

        Http http = new HTTP();
        HttpResponse response;
        EQT_IntralinksWorkspaceUsersResponse intralinksResponse = new EQT_IntralinksWorkspaceUsersResponse();

        try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'getWorkspaceUsers response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            if(response.getStatusCode() == 200) {
                intralinksResponse.success = true;
                List<Object> users = (List<Object>)results.get('users');

                intralinksResponse.workspaceUsers = new Map<String, String>();
                String userId;
                String userEmail;
                
                for(Object workspaceUser : users) {
                    //get workspace users attrubutes
                    Map<String, Object> memberAttributes = (Map<String, Object>)workspaceUser;
                    userId = String.valueOf((Long)memberAttributes.get('id'));
                    userEmail = String.valueOf((String)memberAttributes.get('emailId'));

                    intralinksResponse.workspaceUsers.put(userEmail, userId);
                }
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('ErrorCode') != null && results.get('Error') != null) {
                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                        {
                            (String)results.get('ErrorCode'),
                            (String)results.get('Error')
                        });
                }
            }
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to get workspace users cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_IntralinksCoverageReportResponse getCoverageReport(String workspaceId, String userId, String accessToken) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setTimeout(120000);

        request.setEndpoint(endpointURL +  '/v2/workspaces/' + workspaceId + '/users/' + userId + '/coverageReport');

        Http http = new HTTP();
        HttpResponse response;
        EQT_IntralinksCoverageReportResponse intralinksResponse = new EQT_IntralinksCoverageReportResponse();

        try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'getCoverageReport response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            if(response.getStatusCode() == 200) {
                intralinksResponse.success = true;

                system.debug(LoggingLevel.INFO, 'getCoverageReport response success');
                if(results.containsKey('workspaceUserInfo')) {
                    Map<String,Object> workspaceUserInfo = (Map<String, Object>)results.get('workspaceUserInfo');
                    if(workspaceUserInfo != null && !workspaceUserInfo.isEmpty()) {
                        Map<String, Object> dateAddedMap = (Map<String, Object>)workspaceUserInfo.get('dateAdded');
                        Map<String, Object> firstAccessdMap = (Map<String, Object>)workspaceUserInfo.get('firstAccess');
                        Map<String, Object> lastAccessdMap = (Map<String, Object>)workspaceUserInfo.get('lastAccess');
    
                        intralinksResponse.role = String.valueOf(workspaceUserInfo.get('role'));
                        if(dateAddedMap != null && dateAddedMap.containsKey('milliseconds')) {
                            intralinksResponse.dateAdded = (Long)dateAddedMap.get('milliseconds');
                        }
                        if(firstAccessdMap != null && firstAccessdMap.containsKey('milliseconds')) {                  
                            intralinksResponse.firstAccess = (Long)firstAccessdMap.get('milliseconds');
                        }
                        if(lastAccessdMap != null && lastAccessdMap.containsKey('milliseconds')) {
                            intralinksResponse.lastAccess = (Long)lastAccessdMap.get('milliseconds');
                        }
                    }
                }
            }
            else {
                system.debug(LoggingLevel.INFO, 'getCoverageReport response fail');
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();

                if(results.containsKey('status')) {
                    Map<String,Object> statusObj = (Map<String,Object>)results.get('status');

                    String errorId = String.valueOf(statusObj.get('errorId'));
                    String message = String.valueOf(statusObj.get('message'));

                    intralinksResponse.errorMessage =  String.format('Error Id: {0}. <br/> Message: {1}', new List<String>
                    {
                        errorId,
                        message
                    });
                }
            }
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to get coverageReport cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_EnterWorkspaceResponse enterWorkspace(String workspaceId, String accessToken) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setEndpoint(endpointURL +  '/v2/workspaces/' + workspaceId + '/splash');
        //request.setBody('{"acceptSplash" : true}');

        Http http = new HTTP();
        HttpResponse response;
        EQT_EnterWorkspaceResponse intralinksResponse = new EQT_EnterWorkspaceResponse();
        
         try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'enterWorkspace response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            if(response.getStatusCode() == 200) {
                intralinksResponse.success = true;
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('ErrorCode') != null && results.get('Error') != null) {
                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                        {
                            (String)results.get('ErrorCode'),
                            (String)results.get('Error')
                        });
                }
            }            
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to enter workspace cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }

    public static EQT_AcceptSplasheResponse acceptSplash(String workspaceId, String accessToken) {
        String endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setEndpoint(endpointURL +  '/v2/workspaces/' + workspaceId + '/splash');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Accept','application/json');
        request.setBody('{"acceptSplash": true, "supportedStates": "ACCEPT_SPLASH"}');

        Http http = new HTTP();
        HttpResponse response;
        EQT_AcceptSplasheResponse intralinksResponse = new EQT_AcceptSplasheResponse();
        
         try {
            response = http.send(request);
            system.debug(LoggingLevel.INFO, 'acceptSplash response body=' + response.getBody());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            if(response.getStatusCode() == 201) {
                intralinksResponse.success = true;
            }
            else {
                intralinksResponse.success = false;
                intralinksResponse.errorCode = response.getStatusCode();
                if(results.get('errors') != null) {
                    Object error = (Object)results.get('errors');
                    String errorMsg = '';

                    List<Object> errorAttributes = (List<Object>)error;
                    Map<String, Object> errorVal = (Map<String, Object>)errorAttributes[0];

                    intralinksResponse.errorMessage =  String.format('Error code: {0}. <br/> Error: {1}', new List<String>
                    {
                        String.valueOf((Integer)errorVal.get('code')),
                        String.valueOf(errorVal.get('message'))
                    });
                }
            }
        }
        catch(Exception e) {
            throw new IntralinksException('EQT_IntralinksCallout: Request to accept splash cannot be sent from Salesforce: ' + e.getMessage());
        }

        return intralinksResponse;
    }
}