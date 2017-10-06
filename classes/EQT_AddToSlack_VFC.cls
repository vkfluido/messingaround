/**
    About
    -----
    Description: Authentication for adding Iris to team
    Created for: EQT
    Create date: September 2016
    
    Details / Methods
    -----------------
    - Page actions
    	addToSlack //runs authentication
    	cancel //go to home page
   
    Update History
    --------------
    Created September 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AddToSlack_VFC {
	
	public Boolean irisClientIdExists {get; private set;}
	public String irisClientId {get; set;}
	private String teamId;

	public EQT_AddToSlack_VFC() {
		irisClientIdExists = false;
		irisClientId = EQT_UTIL_Settings.getIrisApplicationId();

		if(String.isNotEmpty(irisClientId)) {
			irisClientIdExists = true;
		}

		if(String.isNotEmpty(ApexPages.currentPage().getParameters().get('success'))
			&& ApexPages.currentPage().getParameters().get('success') == '1') {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.EQT_InfoMessage_SlackAppAuthenticationSuccess));
		}
	}

	public PageReference addToSlack() {
		PageReference pr;
		//get team Id based on Integration user token
		EQT_SlackTeamID_WS.SlackTeamResult teamResult = EQT_SlackTeamID_WS.getSlackTeamId();
		if(String.isEmpty(teamResult.message) && String.isNotEmpty(teamResult.teamId)) {
			teamId = teamResult.teamId;
		}
		else {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, teamResult.message));
			return null;
		}

		//store client Id if it does not exists
		if(!irisClientIdExists && String.isNotEmpty(irisClientId)) {
			EQT_UTIL_Settings.setIrisApplicationId(irisClientId);
		}

		//add to slack
		if(String.isNotEmpty(irisClientId) && String.isNotEmpty(teamId)) {
			String addToSlackURL = String.format('https://slack.com/oauth/authorize?scope=bot&client_id={0}&team={1}', new List<String>
                            {
                                irisClientId,
                                teamId
                            });

        	pr = new PageReference(addToSlackURL);
        	pr.setRedirect(true);
		}
		else if(String.isEmpty(irisClientId)){
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EQT_ErrorMessage_SlackClientIdIsMissing));
			return null;
		}

		return pr;
	}

	public PageReference cancel() {
		PageReference pr = new PageReference('/');
		pr.setRedirect(true);

		return pr;
	}
}