/**
    About
    -----
    Description: Trigger Handler for the EQT_Assignment SObject.
                 This class implements the EQT_ITrigger interface to help ensure 
                 the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: January 2017
    
    Details / Methods
    -----------------
    Use case 1. Set Engagement Level By Assignment
   
    Update History
    --------------
    Created January 2017 - rmohr
    Update January 20, 2017 - bwilliams
    Updated March 2017 - R.B.
    Updated April 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AssignmentHandler implements EQT_ITrigger {

    private static Id boardManagementRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
    private static Id dealRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentDealRecordTypeName());
    private static Id operativeRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentOperativeRecordTypeName());

    private Set<Id> contactIds = new Set<Id>();
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

    public EQT_AssignmentHandler() {}

    public void bulkBefore() {}
    
    public void bulkAfter() {
        EQT_Assignment__c assignment;

        //Use case 1
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(SObject sobj : Trigger.new) {
                assignment = (EQT_Assignment__c)sobj;

                if(assignment.RecordTypeId == boardManagementRTId || assignment.RecordTypeId == dealRTId || assignment.RecordTypeId == operativeRTId) {
                    contactIds.add(assignment.Contact__c);
                }
            }

            if(!contactIds.isEmpty()) {
                contactMap = new Map<Id, Contact>([SELECT Id, Engagement_Level__c FROM Contact WHERE Id IN :contactIds]);
            }
        }
    }
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {
        EQT_Assignment__c assignment = (EQT_Assignment__c)so;
        system.debug(LoggingLevel.INFO, 'After insert');
        //Use case 1
        //if enagagement level values are in (blank or IA prospect or IA candidate)
        if(contactMap.containsKey(assignment.Contact__c)
            && (String.isEmpty(contactMap.get(assignment.Contact__c).Engagement_Level__c)
                || contactMap.get(assignment.Contact__c).Engagement_Level__c == EQT_UTIL_Settings.getIAProspectEngagementLevelName()
                || contactMap.get(assignment.Contact__c).Engagement_Level__c == EQT_UTIL_Settings.getIACandidateEngagementLevelName())) {

            Contact relatedContact = contactMap.get(assignment.Contact__c);

            if(assignment.RecordTypeId == boardManagementRTId || assignment.RecordTypeId == operativeRTId) {
                system.debug(LoggingLevel.INFO, 'Radek EQT_UTIL_Settings.getIABoardIEEngagementLevelName()=' + EQT_UTIL_Settings.getIABoardIEEngagementLevelName());
                relatedContact.Engagement_Level__c = EQT_UTIL_Settings.getIABoardIEEngagementLevelName();

                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }
            else if(assignment.RecordTypeId == dealRTId) {
                relatedContact.Engagement_Level__c = EQT_UTIL_Settings.getIADealEngagementLevelName();

                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        EQT_Assignment__c assignmentNew = (EQT_Assignment__c)so;
        EQT_Assignment__c assignmentOld = (EQT_Assignment__c)oldSo;

        //Use case 1
        if(contactMap.containsKey(assignmentNew.Contact__c) && String.isEmpty(contactMap.get(assignmentNew.Contact__c).Engagement_Level__c)) {
            Contact relatedContact = contactMap.get(assignmentNew.Contact__c);

            if(assignmentNew.RecordTypeId == boardManagementRTId || assignmentNew.RecordTypeId == operativeRTId) {
                relatedContact.Engagement_Level__c = EQT_UTIL_Settings.getIABoardIEEngagementLevelName();

                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }
            else if(assignmentNew.RecordTypeId == dealRTId) {
                relatedContact.Engagement_Level__c = EQT_UTIL_Settings.getIADealEngagementLevelName();

                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }
        }
    }
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        //Use case 1
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
    }
}