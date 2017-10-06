public with sharing class EQT_IntralinksLogin_VFC {
	
	private String authorizationCode;
	public Boolean showAuthorizeButton {get; set;}
	public String accessToken {get; private set;}
	public String refreshToken {get; private set;}
	public String endpointURL {get; private set;}
	public String clientId {get; private set;}
	@testVisible private Boolean testAuthenticationStatus = false;

	public EQT_IntralinksLogin_VFC() {
		showAuthorizeButton = false;

		accessToken = EQT_UTIL_Settings.getIntralinksAccessToken();
		refreshToken = EQT_UTIL_Settings.getIntralinksRefreshToken();
		endpointURL = EQT_UTIL_Settings.getIntralinksEndpointURL();
		clientId = EQT_UTIL_Settings.getIntralinksClientId();
		
		//get authorization code from url (after successful intralinks login)
		authorizationCode = ApexPages.currentPage().getParameters().get('code');

		if(String.isNotEmpty(authorizationCode)) {
			showAuthorizeButton = false;
		}
	}

	public PageReference AuthenticateWithIntralinks() {
		return EQT_IntralinksCallout.authenticateUser();
	}

	public PageReference getAndStoreTokens() {
		if(String.isNotEmpty(authorizationCode)) {
			
			EQT_IntralinksCallout.EQT_IntralinksAuthenticateResponse response;

			if(Test.isRunningTest()) {
				response = new EQT_IntralinksCallout.EQT_IntralinksAuthenticateResponse();
				response.success = testAuthenticationStatus;
				if(testAuthenticationStatus) {
					response.accessToken = '123';
					response.refreshToken = '321';
				}
				else {
					response.errorMessage = 'test error message';
				}
			}
			else {
				response = EQT_IntralinksCallout.getTokens(authorizationCode);
			}

			if(response.success) {
				//get tokens from response
				accessToken = response.accessToken;
				refreshToken = response.refreshToken;
				//store tokens in custom settings
				EQT_UTIL_Settings.setIntralinksAccessToken(accessToken);
                EQT_UTIL_Settings.setIntralinksRefreshToken(refreshToken);
                //show confirmation message
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.EQT_InfoMessage_TokensGeneratedSuccessfully));
			}
			else {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response.errorMessage));
			}
			
		}

		return null;
	}

	public PageReference cancel() {
		PageReference pr = new PageReference('/');
		pr.setRedirect(true);

		return pr;
	}
}