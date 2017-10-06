/**
 * @description Assessing IA Contacts' relationship recency, i.e. freshness, with EQT (Agreement)
 * Recency is based on the first agreement with EQT, and it's length.
 * Thus an agreement longer than 12 months makes an IA contact old. A shorter agreement categorizes the IA contact as new and fresh!
 *
 *
 * This class is part of a weekly batch job.
 *
 *
 * @see EQT_ContactStatusSchedulable
 * @author Rishendra Tiwari
 * @author Vadim Koroliov
 * */
global class EQT_ContactStatusUpdate implements Database.Batchable <sObject> {

    private final String CONTACT_STATUS_NEW = 'New';
    private final String CONTACT_STATUS_OLD = 'Old';
    private final String AGREEMENT_TERMINATED_BY_IA = 'Terminated by IA';
    private final String AGREEMENT_TERMINATED_BY_EQT = 'Terminated by EQT';

    /*
     * Fetching IA Contacts
     *
     * */
	global Database.QueryLocator start(Database.BatchableContext BC) {
        String industrialAdvisoryRecordType = ''+ EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Industrial_Advisor');
        String query = 'SELECT Id,ContactStatus__c,Number_of_Contracts__c, (SELECT Id,EQT_Industrial_Advisor__c,EQT_Industrial_Advisor__r.ContactStatus__c,EQT_Status__c,EQT_Start_Date__c,EQT_End_Date__c FROM EQT_IA_Contracts__r order by EQT_Industrial_Advisor__c, EQT_Start_Date__c ASC) FROM Contact WHERE RecordTypeId =:industrialAdvisoryRecordType  AND (Number_of_Contracts__c > 0 OR ContactStatus__c <> NULL)';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){

		Date presentDay = Date.today();
        List<Contact> updatedContacts = new List<Contact>();
        Map<Id,Contact> contactsById = new Map<Id,Contact>();

        Map<Id,Contact> updateContactsByIds = new Map<Id,Contact>();

        for(Contact contactRecord : (List<Contact>) scope){
            if(contactRecord.Number_of_Contracts__c == 0 && contactRecord.ContactStatus__c != null){
                contactRecord.ContactStatus__c = null;
                updatedContacts.add(contactRecord);
            } else if(contactRecord.Number_of_Contracts__c > 0){
                for(EQT_IA_Contract__c industrialAdvisorContract : contactRecord.EQT_IA_Contracts__r){

                }
            }
        }



        for(Contact c : (List<Contact>)scope){
            if(c.ContactStatus__c <> NULL && c.Number_of_Contracts__c == 0){
                c.ContactStatus__c = null;
                updatedContacts.add(c);
            }else{
                contactsById.put(c.Id, c);
            }
        }
        Set<Id> processedContacts = new Set<Id>();

		for(EQT_IA_Contract__c clist: [SELECT Id,EQT_Industrial_Advisor__c,EQT_Industrial_Advisor__r.ContactStatus__c,EQT_Status__c,EQT_Start_Date__c,EQT_End_Date__c 
                                  FROM EQT_IA_Contract__c 
                                  WHERE EQT_Industrial_Advisor__c IN :contactsById.keySet() order by EQT_Industrial_Advisor__c, EQT_Start_Date__c ASC]){
                Id contactId = clist.EQT_Industrial_Advisor__c;
                if (!processedContacts.contains(contactId)){
                    processedContacts.add(contactId);
                    Contact c = contactsById.get(contactId);
                    if ((clist.EQT_Status__c == 'Terminated by IA') || (clist.EQT_Status__c == 'Terminated by EQT')){
                        c.ContactStatus__c = null;
                        updatedContacts.add(c);
                    }else if ((clist.EQT_End_Date__c >= presentDay) && (clist.EQT_Start_Date__c <= presentDay)){ //
                        if(clist.EQT_Start_Date__c.daysBetween(presentDay) >= 365){
                            if(c.ContactStatus__c != CONTACT_STATUS_OLD){
                                c.ContactStatus__c = CONTACT_STATUS_OLD;
                                updatedContacts.add(c);
                            }
                        }else if (clist.EQT_Start_Date__c.daysBetween(presentDay) < 365){
                            if(c.ContactStatus__c != CONTACT_STATUS_NEW){
                                c.ContactStatus__c = CONTACT_STATUS_NEW;
                                updatedContacts.add(c);
                            }
                        }
                    }else if ((clist.EQT_End_Date__c >= presentDay) && (clist.EQT_Start_Date__c >= presentDay)){
                        if(c.ContactStatus__c != CONTACT_STATUS_NEW){
                                c.ContactStatus__c = CONTACT_STATUS_NEW;
                                updatedContacts.add(c);
                            }
                    }else if (clist.EQT_End_Date__c <= presentDay){
                        if(clist.EQT_Start_Date__c.daysBetween(clist.EQT_End_Date__c) >= 365){
                            if(c.ContactStatus__c != CONTACT_STATUS_OLD){
                                c.ContactStatus__c = CONTACT_STATUS_OLD;
                                updatedContacts.add(c);
                            }
                        }else if (clist.EQT_Start_Date__c.daysBetween(clist.EQT_End_Date__c) < 365){
                            if(c.ContactStatus__c != CONTACT_STATUS_NEW){
                                c.ContactStatus__c = CONTACT_STATUS_NEW;
                                updatedContacts.add(c);
                            }
                        }
                    }
                }
            }
        update updatedContacts;
	}
    
	global void finish(Database.BatchableContext BC)
    {
       
    }
	
}