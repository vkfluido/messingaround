/**
    About
    -----
    Description: Trigger Handler for the EQT Proxy EventRelation SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Match event relation based on EPM external ids (EPM Contact Id and EPM External Event Id)

    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_ProxyEventRelationHandler implements EQT_ITrigger {
    //set of epm person ids
    private Set<String> epmPersonIDs = new Set<String>();
    //set of epm event ids
    private Set<String> eventExternalIds = new Set<String>();
    //map of contacts based on PersonID
    private Map<String, Contact> contactMap = new Map<String, Contact>();
    //map of events based on external id
    private Map<String, Event> eventMap = new Map<String, Event>();
    //set of related contacts
    private Set<Id> contactIds = new Set<Id>();
    //set of related events
    private Set<Id> eventIds = new Set<Id>();
    //set of already existing eventRelation
    private Set<String> eventRelations = new Set<String>();
    //map of event realtions to create
    private Map<String, EventRelation> relationsToAdd = new Map<String, EventRelation>();
    //set of processed records
    private Set<Id> processedIds = new Set<Id>();

    public EQT_ProxyEventRelationHandler() {}

    public void bulkBefore() {}
    
    public void bulkAfter() {
        if(Trigger.isInsert) {
            for(SObject so : Trigger.new) {
                if(so.get('EQT_EPM_EventExternalID__c') != null) {
                    eventExternalIds.add((String)so.get('EQT_EPM_EventExternalID__c'));
                }

                if(so.get('EQT_EPM_PersonID__c') != null) {
                    epmPersonIDs.add((String)so.get('EQT_EPM_PersonID__c'));
                }

                processedIds.add((Id)so.get('Id'));
            }

            //build maps for contacts and tasks
            if(!epmPersonIDs.isEmpty()) {
                for(Contact c : [SELECT Id, EQT_EPM_PersonID__c FROM Contact
                                    WHERE EQT_EPM_PersonID__c IN :epmPersonIDs]) {
                    contactMap.put(c.EQT_EPM_PersonID__c, c);
                    contactIds.add(c.Id);
                }
            }

            if(!eventExternalIds.isEmpty()) {
                for(Event e : [SELECT Id, EQT_EPM_External_ID__c FROM Event
                                WHERE EQT_EPM_External_ID__c IN :eventExternalIds]) {
                    eventMap.put(e.EQT_EPM_External_ID__c, e);
                    eventIds.add(e.Id);
                }
            }

            //build map of task relation table based on taskid and relation id
            for(EventRelation er : [SELECT Id, EventId, RelationId FROM EventRelation
                                    WHERE EventId IN :eventIds
                                    AND RelationId IN :contactIds]) {
                eventRelations.add(er.EventId + ':' + er.RelationId);
            }
        }
    }
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        EQT_Proxy_EventRelation__c epr = (EQT_Proxy_EventRelation__c)so;

        if(epr.EQT_EPM_EventExternalID__c == null ||  epr.EQT_EPM_PersonID__c == null) {
            epr.addError('External Id or Peron Id is null.');
        }

        if(epr.EQT_EPM_PersonID__c != null && !contactMap.containsKey(epr.EQT_EPM_PersonID__c)) {
            epr.addError('Contact not found for EMP PersonID=' + epr.EQT_EPM_PersonID__c);
        }

        if(epr.EQT_EPM_EventExternalID__c != null && !eventMap.containsKey(epr.EQT_EPM_EventExternalID__c)) {
            epr.addError('Event not found for EPM Event External Id=' + epr.EQT_EPM_EventExternalID__c);
        }

        if(epr.EQT_EPM_EventExternalID__c != null && epr.EQT_EPM_PersonID__c != null
            && contactMap.containsKey(epr.EQT_EPM_PersonID__c)
            && eventMap.containsKey(epr.EQT_EPM_EventExternalID__c)) {

            String key = eventMap.get(epr.EQT_EPM_EventExternalID__c).Id + ':' + contactMap.get(epr.EQT_EPM_PersonID__c).Id;

            //if there is no event relation for above key - create it
            if(!eventRelations.contains(key)) {
                EventRelation er = new EventRelation
                (
                    EventId = eventMap.get(epr.EQT_EPM_EventExternalID__c).Id,
                    RelationId = contactMap.get(epr.EQT_EPM_PersonID__c).Id,
                    IsParent = true,
                    IsInvitee = false
                );

                relationsToAdd.put(er.EventId + ':' + er.RelationId, er);
            }
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
        if(!relationsToAdd.isEmpty()) {
            insert relationsToAdd.values();
        }

        if(!processedIds.isEmpty()) {
            delete [SELECT Id FROM EQT_Proxy_EventRelation__c WHERE Id IN :processedIds];
        }
    }
}