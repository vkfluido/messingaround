/**
    About
    -----
    Description: Rest API to get team id to which Iris can be connected
    Created for: EQT
    Create date: September 2016
    
    Details / Methods
    -----------------
    - Actions
    	getSlackTeamId //get slack team id based on integration user slack token
   
    Update History
    --------------
    Created September 2016 - R.B.

    Issues / TODOs
    --------------
*/
@RestResource(urlMapping='/SlackTeamID/*')
global with sharing class EQT_SlackTeamID_WS {

	global class SlackTeamResult {
		public String teamId;
		public String message; 
	} 

	@HttpGet
	global static SlackTeamResult getSlackTeamId() {
		SlackTeamResult result = new SlackTeamResult();
		result.message = 'Failed to get slack team Id';

		try {
			result = EQT_SlackCallout.getSlackTeamId();
		}
		catch(Exception e) {
			result.message = e.getMessage();
		}

		return result;
	}
}