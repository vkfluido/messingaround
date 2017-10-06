/**
    About
    -----
    Description: Trigger Handler for the Opportunity Team Member SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2017

    Details / Methods
    -----------------
    Use Case 1. User with Deal Member role should have read/write access to give opportunity upon creation

    Update History
    --------------
    Created May 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_OpportunityTeamMemberHandler implements EQT_ITrigger {

    private static Id creditOpportunityRTId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCreditRecordTypeName());
    private static Id dealOpportunityRTId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityDealRecordTypeName());
    private static Id mmcSdOpportunityRTId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityMMCSeniorDebtRecordTypeName()); //MidMarket Credit or Senior Debt opportunity
    private static String dealTeamMemberRole = EQT_UTIL_Settings.getOpportunityTeamMemberDealTeamRoleName();

    private Set<Id> opportunityIds = new Set<Id>();
    private Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

    // Constructor
    public EQT_OpportunityTeamMemberHandler() {}

    public void bulkBefore() {
        if(Trigger.isInsert) {
            for(sObject so : Trigger.new) {
                OpportunityTeamMember otm = (OpportunityTeamMember)so;

                opportunityIds.add(otm.OpportunityId);
            }
        }

        if(!opportunityIds.isEmpty()) {
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, RecordTypeId FROM Opportunity WHERE Id IN :opportunityIds]);
        }
    }

    public void bulkAfter() {}

    public void beforeInsert(SObject so) {
        OpportunityTeamMember otm = (OpportunityTeamMember)so;

        //Use case 1
        changeMemberAccessLevel(otm);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {}

    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {}

    public void afterUpdate(SObject oldSo, SObject so) {}

    public void afterDelete(SObject so) {}

    public void andFinally() {}

    private void changeMemberAccessLevel(OpportunityTeamMember otm) {
        //if related Opportunity is in the map and related opportunity record type is in (credit, deal, mmc) and team member role is set to given role
        //change access level to Edit
        if(opportunityMap.containsKey(otm.OpportunityId) && otm.TeamMemberRole == dealTeamMemberRole) {
            Opportunity relatedOpportunity = opportunityMap.get(otm.OpportunityId);

            if(relatedOpportunity.RecordTypeId == creditOpportunityRTId
                    || relatedOpportunity.RecordTypeId == dealOpportunityRTId
                    || relatedOpportunity.RecordTypeId == mmcSdOpportunityRTId) {

                otm.OpportunityAccessLevel = 'Edit';
            }
        }
    }
}