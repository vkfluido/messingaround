public with sharing class EQT_PostAccountToSlack_VFC {
    private final ApexPages.StandardSetController cntr;
    private final List<Account> selectedAccountsList;
    private final PageReference fromPage;

    public Boolean showToastMessage { get; set; } // if toast message should be shown
    public String toastMessage { get; set; } // toast message
    public String toastMessageSeverity { get; set; } // style of toast message
    
    public String messageForSlack { get; set; } // bind to text area field

    public EQT_PostAccountToSlack_VFC(ApexPages.StandardSetController controller) {
        showToastMessage = false;

        controller.setPageSize(1000);
        cntr = (ApexPages.StandardSetController)controller;
        fromPage = cntr.cancel();

        if (this.selectedAccountsList == null) {
            this.selectedAccountsList = (List<Account>)cntr.getSelected();
        }

        if (getRecordSize()<1) {
            String msg = 'No record was selected on the list view.  Please click Cancel button and select records.';
            showMessage('error', msg);
        }
    }

    /*
     * Return count of selected records
     */
    public integer getRecordSize() {
        if (selectedAccountsList!=null) {
            return selectedAccountsList.size();
        } else {
            return 0;
        }
    }

    /* 
     * Action method for cancel button
     */
    public PageReference cancel() {
        return fromPage;
    }

    /*
     * Action method for posting list of accounts to the Salck
     */
    public PageReference postToSlack() {

        String channelId = getSlackChannelId();
        //channelId = 'C73BJMCNA';    // TODO only for local testing
        system.debug('channelId: ' + channelId);

        if (getRecordSize()<1) {
            String msg = 'No record was selected on the list view.  Please click Cancel button and select records.';
            showMessage('error', msg);
            return null;
        }

        if( String.isEmpty(channelId) ){
            String msg = 'Invalid Slack channel settings. Please contact system administrator.';
            showMessage('error', msg);
            return null;
        }

        String message = getMesageBody();

        String responseJson;
        if(Test.isRunningTest()) {
            responseJson = '{"isSuccess":true,"errorMessage":null}';
        } else {
            responseJson = EQT_SlackCallout.postToChannel(channelId, message );
        }
        EQT_SlackCallout.SlackResponse response = (EQT_SlackCallout.SlackResponse)JSON.deserialize(responseJson, EQT_SlackCallout.SlackResponse.class);

        if(response.isSuccess) {
            String msg = 'Message was successfully posted to the Slack channel.';
            showMessage('success', msg);
        } else {
            showMessage('error', response.errorMessage);            
        }

        return null;
    }

    /* 
     * Get Channel name from custom settings for posting accounts list
     */
    private String getSlackChannelId(){
        String channelId = EQT_UTIL_Settings.getSlackAccountChannel();
        //String channelId = EQT_SlackCallout.checkIfChannelExists(slackChannelName);

        return channelId;
    }

    /* 
     * Generate Slack message
     */
    private String getMesageBody(){

        String message = '';

        if(!String.isEmpty(messageForSlack)){
            message += messageForSlack + '\n';
            message += '\n';
        }

        message += 'Accounts: ';
        message += '\n';

        for(Account a : selectedAccountsList){
            String accountURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + a.id;

            String aName = EncodingUtil.urlEncode(a.Name, 'UTF-8');

            message += '- <'+accountURL+'|'+aName+'>\n';
        }

        system.debug('message: ' + message);        

        return message;
    }

    /*
     * Set toast message for showing on VF page
     */
    private void showMessage(String severity, String message){
        showToastMessage = true;
        toastMessageSeverity = severity;
        toastMessage = message;
    }
}