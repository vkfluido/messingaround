/**
    About
    -----
    Description: Handle logic for sync fund team with slack
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    	- syncTeamWithSlack // check if slack channel exists for given name and show messages to user
    	- addUsersToChannel // invite team users to channel (and) based on user response delete non-salesforce user from channel
    						// except integration user and Iris bot. Also update fields on fund object and store any sync errors
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_SyncTeamWithSlack_VFCx {

	private String fundId;
	public Fund__c currentFund {get;set;}
	public Boolean showContinueButton {get;set;}
	public Boolean showSyncButton {get;set;}
	@testVisible private String channelId;

	public EQT_SyncTeamWithSlack_VFCx(ApexPages.StandardController stdController) {
		fundId = stdController.getId();
		loadFundRecord();

		currentFund.Slack_SalesforceIsMemberMaster__c = false;
		showContinueButton = false;
		showSyncButton = true;
	}

	private void loadFundRecord() {
		currentFund = [SELECT Id, Name, Slack_Channel__c, Slack_SalesforceIsMemberMaster__c,
						Slack_connected__c, Slack_Last_Sync__c, Slack_Sync_Errors__c,
						Slack_Channel_Id__c
						FROM Fund__c
						WHERE Id = :fundId];
	}

	public PageReference syncTeamWithSlack() {
		try {
			if(!Test.isRunningTest()) {
				channelId = EQT_SlackCallout.checkIfChannelExists(currentFund.Slack_Channel__c);
			}
			else {
				//just for testing exception
				if(channelId == 'throw sync') {
					throw new EQT_SlackCallout.SlackException('testing exception');
				}
			}

			Boolean channelExist = String.isNotEmpty(channelId);

			if(!channelExist) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_ChannelNotExists));
				showContinueButton = false;
				return null;
			}
			else {
				String message = String.format(Label.EQT_InfoMessage_SyncTeamWithSlack, new List<String> {Label.EQT_Button_Continue});
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, message));
				showContinueButton = true;
				return null;
			}
		}
		catch(Exception e) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
			return null;
		}
	}

	public PageReference addUsersToChannel() {
		PageReference pr = new PageReference('/' + fundId);
		pr.setRedirect(true);
		try {

			Boolean shoulddelete = Boolean.valueOf(Apexpages.currentPage().getParameters().get('shoulddelete'));

			if(!Test.isRunningTest()) {
				EQT_SlackCallout.inviteUserToChannel(fundId, channelId, shoulddelete);
			}
			else {
				//just for testing exception
				if(channelId == 'throw') {
					throw new EQT_SlackCallout.SlackException('testing exception');
				}
			}

			//if no errors occurs update fund record
			currentFund.Slack_connected__c = true;
			currentFund.Slack_Last_Sync__c = Datetime.now();
			currentFund.Slack_Sync_Errors__c = null;
			currentFund.Slack_Channel_Id__c = channelId;
			update currentFund;
		}
		catch(Exception e) {
			//update fund record
			currentFund.Slack_Channel_Id__c = channelId;
			currentFund.Slack_connected__c = false;
			currentFund.Slack_Last_Sync__c = Datetime.now();
			currentFund.Slack_Sync_Errors__c = e.getMessage().length() > 255 ? e.getMessage().substring(0, 255) : e.getMessage();
			update currentFund;	
		}

		return pr;
	}
}