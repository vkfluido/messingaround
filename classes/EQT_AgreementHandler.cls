/**
    About
    -----
    Description: Trigger Handler for the EQT_IA_Contract__c SObject.
                 This class implements the EQT_ITrigger interface to help ensure
                 the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: March 2017

    Details / Methods
    -----------------
    Use case 1. Set IA status or Engagement Level
    Use case 2. Agreement Expires for IA's
    Use case 3. Set Counterpart on Company Agreement
    Use case 4. Set Engagement Level for IA's

    Update History
    --------------
    Created March 2017 - R.B.
    Updated March 2017 - RMOHR, functionality replaced with Process Builder, this class should not be used anymore
    Updated March 2017 - R.B. flow logic implementation
    Updated June 2017 - F.A. generating of the Name field
    Updated August 2017 - felix.guerrero@fluidogroup.com update Name on record update
    Issues / TODOs
    --------------
*/
public with sharing class EQT_AgreementHandler implements EQT_ITrigger {

    /*
    private Set<Id> agreementContactIds = new Set<Id>();
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private static Id externalContactRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getExternalContactRecordTypeName());
    private static Id boardMngAssignmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
    private List<Contact> contactsToUpdate = new List<Contact>();
    */

    private static Id externalContactRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getExternalContactRecordTypeName());
    private static Id boardMngAssignmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
    private static Id agreementCompanyRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('EQT_IA_Contract__c.' + EQT_UTIL_Settings.getAgreementCompanyRecordTypeName());
    private Set<Id> contactIds = new Set<Id>();
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
    private Map<Id, Contact> allIAsIdToContactMap = new Map<Id, Contact>();
    private static Map<String,String> typeValuesApiToLabel = new Map<String,String>();

    public EQT_AgreementHandler() {
        list<Schema.PicklistEntry> PicklistEntries = EQT_IA_Contract__c.EQT_Type__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pe : PicklistEntries){
            typeValuesApiToLabel.put(pe.getValue(),pe.getLabel());
        }
    }

    public void bulkBefore() {
        contactsToUpdate = new Map<Id, Contact>();

        if(Trigger.isInsert) {
            EQT_IA_Contract__c agreement;

            for(SObject sobj : Trigger.new) {
                agreement = (EQT_IA_Contract__c)sobj;

                if(agreement.EQT_Company_ID__c == null && agreement.RecordTypeId == agreementCompanyRecordTypeId) {
                    contactIds.add(agreement.EQT_Industrial_Advisor__c);
                }

                allIAsIdToContactMap.put(agreement.EQT_Industrial_Advisor__c, null);
            }

            if(!contactIds.isEmpty()) {
                contactMap = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]);
            }

            if(!allIAsIdToContactMap.isEmpty()){
                allIAsIdToContactMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :allIAsIdToContactMap.keySet()]);
            }
        }
        if(Trigger.isUpdate) {
            Map<Id,EQT_IA_Contract__c> newAgreementMap = (Map<Id,EQT_IA_Contract__c>)Trigger.newMap;
            Map<Id,EQT_IA_Contract__c> oldAgreementMap = (Map<Id,EQT_IA_Contract__c>)Trigger.oldMap;
            for(Id agreementId : newAgreementMap.keySet()){
                EQT_IA_Contract__c agreementNew = newAgreementMap.get(agreementId);
                EQT_IA_Contract__c agreementOld = oldAgreementMap.get(agreementId);
                if( agreementOld.EQT_Type__c != agreementNew.EQT_Type__c ||
                    agreementOld.EQT_Start_Date__c != agreementNew.EQT_Start_Date__c ||
                    agreementOld.EQT_End_Date__c != agreementNew.EQT_End_Date__c ||
                    agreementOld.EQT_Status__c != agreementNew.EQT_Status__c )
                contactIds.add(agreementNew.EQT_Industrial_Advisor__c);
            
            }
            allIAsIdToContactMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactIds]);
        }
    }

    public void bulkAfter() {
        contactsToUpdate = new Map<Id, Contact>();

        if(Trigger.isInsert || Trigger.isUpdate) {
            EQT_IA_Contract__c agreement;

            for(SObject sobj : Trigger.new) {
                agreement = (EQT_IA_Contract__c)sobj;
                contactIds.add(agreement.EQT_Industrial_Advisor__c);
            }

            if(!contactIds.isEmpty()) {
                String assignmentRole = EQT_UTIL_Settings.getAssignmentRolesToSetIAEngagementLevelToBoardIE();
                Set<String> assignmentRoles = new Set<String>();

                if(assignmentRole.contains(';')) {
                    for(String role : assignmentRole.split(';')) {
                        assignmentRoles.add(role.trim());
                    }
                }
                else {
                    assignmentRoles.add(assignmentRole);
                }

                contactMap = new Map<Id, Contact>([SELECT Id, EQT_IA_Status__c, Engagement_Level__c, RecordTypeId,
                                                    (SELECT Id FROM Assignments__r
                                                    WHERE EQT_Is_Active__c = true
                                                    AND RecordTypeId = :boardMngAssignmentRecordTypeId
                                                    AND EQT_Role__c IN :assignmentRoles),
                                                    (SELECT Id FROM EQT_IA_Contracts__r WHERE EQT_Status__c = :EQT_UTIL_Settings.getAgreementActiveStatusName())
                                                    FROM Contact WHERE Id IN :contactIds]);
            }
        }
    }

    public void beforeInsert(SObject so) {
        EQT_IA_Contract__c agreement = (EQT_IA_Contract__c)so;

        if(agreement.EQT_Company_ID__c == null && agreement.RecordTypeId == agreementCompanyRecordTypeId && contactMap.containsKey(agreement.EQT_Industrial_Advisor__c)) {
            agreement.EQT_IA_Agreement_Counterpart__c = contactMap.get(agreement.EQT_Industrial_Advisor__c).AccountId;
        }

        String contactName = '';
        if( allIAsIdToContactMap.containsKey(agreement.EQT_Industrial_Advisor__c) ){
            contactName  = allIAsIdToContactMap.get(agreement.EQT_Industrial_Advisor__c).Name;
        }

        agreement.Name = EQT_AgreementHandler.getAgreementName(agreement, contactName);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        EQT_IA_Contract__c agreementNew = (EQT_IA_Contract__c)so;
        EQT_IA_Contract__c agreementOld = (EQT_IA_Contract__c)oldSo;

        if(
            agreementNew.EQT_End_Date__c != agreementOld.EQT_End_Date__c && 
            agreementNew.EQT_End_Date__c < Date.today() &&
            agreementNew.EQT_Status__c != EQT_UTIL_Settings.getAgreementTerminatedByIAStatusName() &&
            agreementNew.EQT_Status__c != EQT_UTIL_Settings.getAgreementTerminatedByEQTStatusName()
        ) {
            agreementNew.EQT_Status__c = EQT_UTIL_Settings.getAgreementExpiredStatusName();
        }
        //Use case 1 - set end date when agreement is expired or delete end date if it is back active
        if(agreementNew.EQT_Status__c != agreementOld.EQT_Status__c) {
            if(agreementNew.EQT_Status__c == EQT_UTIL_Settings.getAgreementExpiredStatusName() && agreementOld.EQT_End_Date__c == null) {
                agreementNew.EQT_End_Date__c = Date.today();
            }
            else if(agreementNew.EQT_Status__c == EQT_UTIL_Settings.getAgreementActiveStatusName()
                && agreementNew.EQT_End_Date__c < Date.today()) {

                agreementNew.EQT_End_Date__c = null;
            }
        }
        
        if(agreementNew.Name != agreementOld.Name)
            agreementNew.Name = agreementOld.Name;
        if(allIAsIdToContactMap.containsKey(agreementNew.EQT_Industrial_Advisor__c)){
            String contactName = allIAsIdToContactMap.get(agreementNew.EQT_Industrial_Advisor__c).Name;
            agreementNew.Name = EQT_AgreementHandler.getAgreementName(agreementNew, contactName);
        }

    }

    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {
        EQT_IA_Contract__c agreement = (EQT_IA_Contract__c)so;

        if(contactMap.containsKey(agreement.EQT_Industrial_Advisor__c)) {
            Contact relatedContact = contactMap.get(agreement.EQT_Industrial_Advisor__c);

            //Use case 2
            if(agreement.EQT_Status__c == EQT_UTIL_Settings.getAgreementExpiredStatusName()
                    && relatedContact.EQT_IA_Contracts__r.size() == 0) {

                relatedContact.EQT_IA_Status__c = EQT_UTIL_Settings.getIAContractingExpiredStatus();
                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }

            /* Use case 4
               query for metadata for given agreement record
                It can be done here as custom metadata records can have unlimited SOQL queries
             */
            List<EQT_Agreement_Engagement_Level_Mapping__mdt> mapping = [
                    SELECT Id, EQT_IA_Agreement_Status__c, EQT_IA_Engagement_Level__c
                    FROM EQT_Agreement_Engagement_Level_Mapping__mdt
                    WHERE EQT_Agreement_Status__c = :agreement.EQT_Status__c
                    AND EQT_Agreement_Type__c = :agreement.EQT_Type__c
            ];

            if(!mapping.isEmpty()) {
                relatedContact.EQT_IA_Status__c = mapping[0].EQT_IA_Agreement_Status__c;
                relatedContact.Engagement_Level__c = mapping[0].EQT_IA_Engagement_Level__c;

                contactsToUpdate.put(relatedContact.Id, relatedContact);
            }
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        EQT_IA_Contract__c agreementNew = (EQT_IA_Contract__c)so;
        EQT_IA_Contract__c agreementOld = (EQT_IA_Contract__c)oldSo;

        if(contactMap.containsKey(agreementNew.EQT_Industrial_Advisor__c)) {
            Contact relatedContact = contactMap.get(agreementNew.EQT_Industrial_Advisor__c);

            if(agreementNew.EQT_Status__c != agreementOld.EQT_Status__c) {
                if(agreementNew.EQT_Status__c == EQT_UTIL_Settings.getAgreementExpiredStatusName()) {
                    //Use case 1
                    if(relatedContact.RecordTypeId == externalContactRecordTypeId) {
                        if (!relatedContact.Assignments__r.isEmpty()) {
                            relatedContact.Engagement_Level__c = EQT_UTIL_Settings.getIABoardIEEngagementLevelName();
                        }
                    }

                    //Use case 2
                    if(relatedContact.EQT_IA_Contracts__r.size() == 0) {

                        relatedContact.EQT_IA_Status__c = EQT_UTIL_Settings.getIAContractingExpiredStatus();
                    }

                    contactsToUpdate.put(relatedContact.Id, relatedContact);
                }
                //Use case 1
                else if(agreementNew.EQT_Status__c == EQT_UTIL_Settings.getAgreementActiveStatusName()
                        && relatedContact.RecordTypeId == externalContactRecordTypeId) {

                    relatedContact.Engagement_Level__c = agreementNew.EQT_Type__c;
                    contactsToUpdate.put(relatedContact.Id, relatedContact);
                }
            }

            /* Use case 4
               query for metadata for given agreement record
                It can be done here as custom metadata records can have unlimited SOQL queries
             */
            List<EQT_Agreement_Engagement_Level_Mapping__mdt> mapping = [
                    SELECT Id, EQT_IA_Agreement_Status__c, EQT_IA_Engagement_Level__c
                    FROM EQT_Agreement_Engagement_Level_Mapping__mdt
                    WHERE EQT_Agreement_Status__c = :agreementNew.EQT_Status__c
                    AND EQT_Agreement_Type__c = :agreementNew.EQT_Type__c
            ];

            if(!mapping.isEmpty()) {
                relatedContact.EQT_IA_Status__c = mapping[0].EQT_IA_Agreement_Status__c;
                relatedContact.Engagement_Level__c = mapping[0].EQT_IA_Engagement_Level__c;

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
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
    }

    /*
     * This method generate value for Name field from fields Industrial Advisor name + Agreement Type + Start Date + End Date
     */
    public static String getAgreementName(EQT_IA_Contract__c agreement, String contactName){
        String agreementName = '';

        if( !String.isBlank(contactName) ){
            agreementName += contactName;
        }

        if( !String.isBlank(agreement.EQT_Type__c) ){
            agreementName += (agreementName.length()>0) ? '-' : '';
            agreementName += typeValuesApiToLabel.get(agreement.EQT_Type__c);
        }

        if( agreement.EQT_Start_Date__c!=null ){
            agreementName += (agreementName.length()>0) ? '-' : '';

            if(agreement.EQT_End_Date__c == null){
                agreementName += 'from ';
            }

            agreementName += formatDate(agreement.EQT_Start_Date__c);
        }

        if( agreement.EQT_End_Date__c!=null){
            agreementName += (agreementName.length()>0) ? '-' : '';

            if(agreement.EQT_Start_Date__c == null){
                agreementName += 'to ';
            }
            agreementName += formatDate(agreement.EQT_End_Date__c);
        }

        // max length 80
        if(agreementName.length() > 80) {
            agreementName = agreementName.left(77) + '...';
        }

        return agreementName;
    }

    /*
     * formate date to specific string format
     */
    public static String formatDate(Date dateObj){
        return dateObj.day() + '/' +  dateObj.month() + '/' + dateObj.year();
    }
}