/**
    About
    -----
    Description: Trigger Handler for the Investran Contact List Import SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    Use case 1. Delete imported records

    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public without sharing class EQT_InvestranContactListImportHandler implements EQT_ITrigger {
	
	//set of records to delete after successfull import
	private Set<Id> ids = new Set<Id>();

	public EQT_InvestranContactListImportHandler() {}

	public void bulkBefore() {}
    
    public void bulkAfter() {}
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {}
    
    public void afterUpdate(SObject oldSo, SObject so) {
    	EQT_Investran_Contact_List_Import__c cliNew = (EQT_Investran_Contact_List_Import__c)so;
    	EQT_Investran_Contact_List_Import__c cliOld = (EQT_Investran_Contact_List_Import__c)oldSo;

    	if(cliNew.Imported__c && !cliOld.Imported__c) {
    		ids.add(cliNew.Id);
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
    	if(!ids.isEmpty()) {
    		delete [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Id IN :ids];
    	}
    }
}