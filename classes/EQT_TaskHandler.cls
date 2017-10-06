/**
    About
    -----
    Description: Trigger Handler for the Task SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: September 2016
    
    Details / Methods
    -----------------
    Use case 1. Set EQT_First_Interaction_Date__c on Opportunity if this field is empty and event is related to Opportunity 

    Update History
    --------------
    Created September 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_TaskHandler implements EQT_ITrigger {
	private Set<Id> opportunityIds = new Set<Id>();
    private Map<Id, Opportunity> opportunityTasks = new Map<Id, Opportunity>();
    private List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    private Map<Id, String> opportunityId2OwnerName = new Map<Id, String>();

	public EQT_TaskHandler() {}

	public void bulkBefore() {
        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(Trigger.isInsert || Trigger.isUpdate){
            for(sObject so : Trigger.new) {
                Task taskItem = (Task)so;

                if(Trigger.isInsert && taskItem.WhatId!=null && String.valueOf(taskItem.WhatId).startsWith('006')){
                    opportunityId2OwnerName.put(taskItem.WhatId, null);
                } else if(Trigger.isUpdate){
                    Task taskItemOld = (Task)Trigger.oldMap.get(taskItem.Id);
                    if(
                        taskItem.WhatId != taskItemOld.WhatId &&
                        String.valueOf(taskItem.WhatId).startsWith('006')
                    ){
                        opportunityId2OwnerName.put(taskItem.WhatId, null);
                    }
                }
            }

            if(!opportunityId2OwnerName.isEmpty()){
                List<Opportunity> oppResult = [
                        SELECT Id, Owner.Name
                        FROM Opportunity
                        WHERE Id IN :opportunityId2OwnerName.keySet()
                ];

                for(Opportunity oppItem : oppResult){
                    opportunityId2OwnerName.put(oppItem.Id, oppItem.Owner.Name);
                }
            }
        }
    }
    
    public void bulkAfter() {
        if(Trigger.isInsert) {
            for(sObject so : Trigger.new) {
                Task t = (Task)so;

                //if task is related to Opportunity
                if(t.WhatId != null && t.WhatId.getSobjectType() == Schema.Opportunity.SObjectType) {
                    opportunityIds.add(t.WhatId);
                }
            }
        }

        if(!opportunityIds.isEmpty()) {
            opportunityTasks = new Map<Id, Opportunity>
            (
                [
                    SELECT Id, EQT_First_Interaction_Date__c,
                        (SELECT Id, ActivityDate FROM Tasks ORDER BY ActivityDate LIMIT 1)
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
                ]
            );
        }
    }
        
    public void beforeInsert(SObject so) {
        Task t = (Task) so;

        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(t.WhatId!=null && String.valueOf(t.WhatId).startsWith('006')){
            if(opportunityId2OwnerName.get(t.WhatId)!=null) {
                t.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(t.WhatId);
            }
        }

    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Task tNew = (Task) so;
        Task tOld = (Task) oldSo;

        // trello card 173-related-to-card-168-create-opportunity-owner-field-on-activity-to-be-viewed-on-activity-report-type
        if(tNew.WhatId!=tOld.WhatId){
            // if WhatId has changed
            if(tNew.WhatId==null){
                tNew.EQT_Opportunity_Owner__c = null;
            } else {
                if(String.valueOf(tNew.WhatId).startsWith('006')){
                    tNew.EQT_Opportunity_Owner__c = opportunityId2OwnerName.get(tNew.WhatId);
                } else {
                    tNew.EQT_Opportunity_Owner__c = null;
                }
            }
        }
    }
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        Task t = (Task)so;

        //if task is related to opportunity and given opportunity have no interaction date
        if(t.WhatId != null && t.WhatId.getSobjectType() == Schema.Opportunity.SObjectType
            && opportunityTasks.containsKey(t.WhatId)
            && opportunityTasks.get(t.WhatId).EQT_First_Interaction_Date__c == null) {

            Opportunity opp = opportunityTasks.get(t.WhatId);
            opp.EQT_First_Interaction_Date__c = t.ActivityDate;

            if(!opp.Tasks.isEmpty() && opp.EQT_First_Interaction_Date__c > opp.Tasks[0].ActivityDate)  {
                opp.EQT_First_Interaction_Date__c = opp.Tasks[0].ActivityDate;
            }

            opportunitiesToUpdate.add(opp);
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        //use case 1 - update opportunities to set EQT_First_Interaction_Date__c
        if(!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}