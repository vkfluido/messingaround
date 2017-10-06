/**
    About
    -----
    Description: Trigger Handler for the Fund SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Set Owner based on the EPM Responsible field
   
    Update History
    --------------
    Created May 2016 - M.E.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_FundHandler implements EQT_ITrigger {  
    
    /* 
        Custom meta data mappings
    */

    /*
        Itteration lists for processing trigger records
    */
    
    // Fund map to set owner based on EPM Person ID (Record -> PersonID)
    private Map<sObject, String> fundsToSetOwnerbyEPMPersonID = new Map<sObject,String>();

    // Constructor
    public EQT_FundHandler() {}

    public void bulkBefore() {
        /*
        if(Trigger.isInsert || Trigger.isUpdate) {
            if (Trigger.isInsert) {
                
                for(sObject a : Trigger.new) {
                    Fund__c theFund = (Fund__c) a;

                    // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
                    // using their own external ID. Default otherwise is current user.
                    if (theFund.ownerId==null)  theFund.OwnerId = UserInfo.getUserId();
                    if (theFund.EQT_EPM_Responsible__c!=null)
                    {
                        System.Debug(LoggingLevel.INFO,'@@ Funds with EQT Responsible set: '+theFund);
                        fundsToSetOwnerbyEPMPersonID.put(a, theFund.EQT_EPM_Responsible__c);
                        System.Debug(LoggingLevel.INFO,'@@ fundsToSetOwnerbyEPMPersonID: '+fundsToSetOwnerbyEPMPersonID);
                    }
                    
                }
            }
            if (Trigger.isUpdate) {
                for(sObject a : Trigger.new) {
                    Fund__c theFund = (Fund__c) a;
                    Fund__c theFund_old = (Fund__c) Trigger.oldMap.get(a.Id);
                    // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
                    // using their own external ID. Default otherwise is current user.
                    if (theFund.EQT_EPM_Responsible__c!=null && (theFund.EQT_EPM_Responsible__c != theFund_old.EQT_EPM_Responsible__c)) 
                    {
                        System.Debug(LoggingLevel.INFO,'@@ Funds with EQT Responsible set: '+theFund);
                        fundsToSetOwnerbyEPMPersonID.put(a, theFund.EQT_EPM_Responsible__c);
                        System.Debug(LoggingLevel.INFO,'@@ fundsToSetOwnerbyEPMPersonID: '+fundsToSetOwnerbyEPMPersonID);
                    }
                }
            }
            System.Debug(LoggingLevel.INFO,'@@ Call setOwnerByEPMPersonId: '+fundsToSetOwnerbyEPMPersonID);
            EQT_DataTransformation_SVC.setOwnerByEPMPersonId(fundsToSetOwnerbyEPMPersonID);
            System.Debug(LoggingLevel.INFO,'@@ Result setOwnerByEPMPersonId: '+fundsToSetOwnerbyEPMPersonID);
        }
        */
    }
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {
        Fund__c theFund = (Fund__c) so;

        // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
        // using their own external ID. Default otherwise is current user.
        if(theFund.ownerId == null) {
            theFund.OwnerId = UserInfo.getUserId();
        }

        if(theFund.EQT_EPM_Responsible__c != null) {
            System.Debug(LoggingLevel.INFO,'@@ Funds with EQT Responsible set: '+theFund);
            fundsToSetOwnerbyEPMPersonID.put(so, theFund.EQT_EPM_Responsible__c);
            System.Debug(LoggingLevel.INFO,'@@ fundsToSetOwnerbyEPMPersonID: '+fundsToSetOwnerbyEPMPersonID);
        }

        // Use case 2. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theFund.EQT_EPM_Record_Type_Name__c!=null) {
            try {
                // -Set record type ID
                theFund.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.'+theFund.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        Fund__c theFund = (Fund__c) so;
        Fund__c theFund_old = (Fund__c) oldSo;
        // Use case 1. Check if the external system has tried to set an owner on EQT_EPM_Responsible__c 
        // using their own external ID. Default otherwise is current user.
        if (theFund.EQT_EPM_Responsible__c!=null && (theFund.EQT_EPM_Responsible__c != theFund_old.EQT_EPM_Responsible__c)) {
            System.Debug(LoggingLevel.INFO,'@@ Funds with EQT Responsible set: '+theFund);
            fundsToSetOwnerbyEPMPersonID.put(so, theFund.EQT_EPM_Responsible__c);
            System.Debug(LoggingLevel.INFO,'@@ fundsToSetOwnerbyEPMPersonID: '+fundsToSetOwnerbyEPMPersonID);
        }

        // Use case 2. Set record type ID based on record type name provided by external system (EPM)
        // - Checks for EPM Record Type Name set by external system & set record type ID on record
        if(theFund.EQT_EPM_Record_Type_Name__c != null && (theFund.EQT_EPM_Record_Type_Name__c != theFund_old.EQT_EPM_Record_Type_Name__c)) {
            try {
                // -Set record type ID
                theFund.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.'+theFund.EQT_EPM_Record_Type_Name__c); // Cached static query, so OK in a loop
            } catch (Exception e) {
                // -Do nothing if no match found
            }
        }
    }
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {}
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        if(!fundsToSetOwnerbyEPMPersonID.isEmpty()) {
            System.Debug(LoggingLevel.INFO,'@@ Call setOwnerByEPMPersonId: '+fundsToSetOwnerbyEPMPersonID);
            EQT_DataTransformation_SVC.setOwnerByEPMPersonId(fundsToSetOwnerbyEPMPersonID);
            System.Debug(LoggingLevel.INFO,'@@ Result setOwnerByEPMPersonId: '+fundsToSetOwnerbyEPMPersonID);
        }
    }
}