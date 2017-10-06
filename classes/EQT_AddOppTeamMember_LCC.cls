/**
    About
    -----
    Description: Controller for adding team member lightning component
    Created for: EQT
    Create date: May 2017

    Details / Methods
    -----------------


    Update History
    --------------
    Created May 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AddOppTeamMember_LCC {
    @AuraEnabled
    public static void saveTeamMember(String userId, String opportunityId) {
        system.debug(LoggingLevel.INFO, 'userId=' + userId);
        system.debug(LoggingLevel.INFO, 'opportunityId=' + opportunityId);

        String teamRole = EQT_UTIL_Settings.getOpportunityTeamMemberDealTeamRoleName();

        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opportunityId;
        otm.UserId = userId;
        otm.TeamMemberRole = teamRole;

        try {
            insert otm;
        }
        catch(DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }
}