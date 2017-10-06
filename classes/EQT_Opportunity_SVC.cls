/**
    About
    -----
    Opportunity service class

    Description: Provides methods for Opportunity object
    Created for: EQT POC
    Create date: May 2016
    
    Details / Methods
    -----------------        
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
**/
   
public with sharing class EQT_Opportunity_SVC {
    
    /*
    public static Map<Id, Opportunity> buildChildParentMap(Map<Id, Id> childParentIdMap) {
        
        Map<Id, Opportunity> childParentMap = new Map<Id, Opportunity>();
        
        Map<Id, Opportunity> parentMap = new Map<Id, Opportunity>
        (
            [
                SELECT Id, Name,
                    (SELECT Id, OpportunityId, OpportunityAccessLevel,
                    TeamMemberRole, UserId
                    FROM OpportunityTeamMembers)
                FROM Opportunity
                WHERE Id IN :childParentIdMap.values()
            ]
        );
        
        for(Id childId : childParentIdMap.keySet()) {
            Id parentId = childParentIdMap.get(childId);
            if(parentMap.containsKey(parentId)) {
                childParentMap.put(childId, parentMap.get(parentId));
            }
            else {
                childParentMap.put(childId, null);
            }
        }
        
        return childParentMap;
    }

    public static Map<Id, Opportunity> buildOpportunityWithTeamMembersMap(Set<Id> opportunitiesToProcessIds, String recordTypeId) {
        Map<Id, Opportunity> opportunityWithTeamMembersMap = new Map<Id, Opportunity>
        (
            [
                SELECT Id, Name,
                    (SELECT Id, OpportunityId, OpportunityAccessLevel,
                    TeamMemberRole, UserId
                    FROM OpportunityTeamMembers)
                FROM Opportunity
                WHERE Id IN :opportunitiesToProcessIds
                AND RecordTypeId = :recordTypeId
            ]
        );

        return opportunityWithTeamMembersMap;
    }

    public static Map<Id, List<Opportunity>> buildChildMapWithTeamMembers(Set<Id> opportunityParentIds) {
        Map<Id, List<Opportunity>> parentChildMap = new Map<Id, List<Opportunity>>();

        String childRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        for(Opportunity child : [SELECT Id, Name, EQT_Fundraise__c,
                                    (SELECT Id, OpportunityId, OpportunityAccessLevel,
                                    TeamMemberRole, UserId
                                    FROM OpportunityTeamMembers)
                                FROM Opportunity
                                WHERE EQT_Fundraise__c IN :opportunityParentIds
                                AND RecordTypeId = :childRecordTypeId]) {

            if(parentChildMap.containsKey(child.EQT_Fundraise__c)) {
                parentChildMap.get(child.EQT_Fundraise__c).add(child);
            }
            else {
                List<Opportunity> childList = new List<Opportunity>();
                childList.add(child);
                parentChildMap.put(child.EQT_Fundraise__c, childList);
            }
        }

        return parentChildMap;
    }
    
    public static List<OpportunityTeamMember> copyOpportunityTeamMembers(List<OpportunityTeamMember> parentMembersList, Id opportunityToAssignId) {
        List<OpportunityTeamMember> members = new List<OpportunityTeamMember>();
        
        for(OpportunityTeamMember m : parentMembersList) {
            members.add(new OpportunityTeamMember(OpportunityId = opportunityToAssignId, OpportunityAccessLevel = m.OpportunityAccessLevel, TeamMemberRole = m.TeamMemberRole, UserId = m.UserId));
        }
        
        return members;
    }
    */
}