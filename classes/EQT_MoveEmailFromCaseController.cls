/**
About
-----
Description: Controller to Ligthning Component EQT_MoveEmailFromCaseComp
Get cases that are potentially are duplicate
Get the emails from the selected Cases and move to the main Case
Created for: EQT
Create date: November 2016

Details / Methods
-----------------
1) User visit case B and click the MOVE EMAIL TO tab.
2) The Lightning tab(EQT_MoveEmailFromCaseComp) shows the current Case at the same Account with Subject, Status and Created Date.
3) User select the Case where the Emails on the current Case will be moved to
4) Code check if the Case is new and then move all Emails from the old Case to the new and remove the case
5) The user get sent to case A which she had selected from the list

Update History
--------------
Created November 2016 - Fredrik Burlin

Issues / TODOs
--------------

*/
public without sharing class EQT_MoveEmailFromCaseController {
    /**
    * @description  Get all Invoice Categories
    * @param        Date interwal of the Invoice Expire Date
    * @return       List of Case with related Installed Base
    */
    @AuraEnabled
    public static List<EQT_Case> getCases(String CaseId){
        List<EQT_Case> csList = new List<EQT_Case>();
        Case currentCase = [SELECT Id, AccountId 
                            FROM Case 
                            WHERE Id=:CaseId LIMIT 1];
        List<Case> cases = [SELECT Id, CaseNumber, Subject, CreatedDate, Status 
                            FROM Case 
                            WHERE AccountId=:currentCase.AccountId 
                            AND Id !=: CaseId
                            ORDER BY CreatedDate desc];
        System.debug(CaseId);
        System.debug(cases);
        if(cases.size() > 0)
            csList = EQT_CaseSObjToObj(cases);
        return csList;
    }
    /**
    * @description  Moves all email to the master case and create a chatter post confirming the action
    * @param        Current Case Id where the user are located, the duplicate case
    * @param        Master Case Id where the user want to move the emails to
    * @return       SUCCESS or Error message
    */
    @AuraEnabled
    public static String moveEmailandDeleteCase(String currentCaseId, String masterCaseId){
        try{
            Map<Id,EmailMessage> oldIdEmailMap = new Map<Id,EmailMessage>();
            Case currentCase = [SELECT Id, AccountId, CaseNumber
                                FROM Case 
                                WHERE Id =: currentCaseId LIMIT 1];
            
            List<EmailMessage> emails = [SELECT Id, ParentId, TextBody, HtmlBody, Headers, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Incoming, HasAttachment, Status, MessageDate
                                         FROM EmailMessage
                                         WHERE ParentId =: currentCaseId];
            
            List<Attachment> attachments = [SELECT Id, ParentId, Name, IsPrivate, ContentType, BodyLength, Body, OwnerId, Description 
                                            FROM Attachment
                                            WHERE ParentId in: emails];
            
            // Salesforce does not support a List<Id> or List<EmailMessage> as IN parameter henc Database.query workaround
            List<ContentDocumentLink> contentDocumentLinks = Database.query(
                'SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility ' +
                'FROM ContentDocumentLink ' +
                'WHERE LinkedEntityId in (\'' + emailIdString(emails) + '\')');
            
            FeedItem fi = new FeedItem();
            fi.IsRichText = false;
            fi.ParentId = masterCaseId;
            fi.Type = 'TextPost';
            fi.Body = 'Email moved from Case ' + currentCase.CaseNumber + 'and the case have been moved to Recycle Bin.';
            insert fi;
            
            for(EmailMessage em: emails){
                oldIdEmailMap.put(em.Id,em);
                em.Id = null;
                em.ParentId = masterCaseId;
            }
            insert emails;
            
            for(Attachment at: attachments){
                at.Id = null;
                at.ParentId = oldIdEmailMap.get(at.ParentId).Id;
                System.debug(at.ParentId);
            }
            insert attachments;
            
            for(ContentDocumentLink cdl: contentDocumentLinks){
                cdl.Id = null;
                cdl.LinkedEntityId = oldIdEmailMap.get(cdl.LinkedEntityId).Id;
                System.debug(cdl.LinkedEntityId);
            }
            insert contentDocumentLinks;

            // Update the Notification status to send a new email
            update new Case(Id = masterCaseId,
                Case_Notification_Status__c = 'Send to Owner');
            // Delete the duplicate case
            delete new Case(Id = currentCaseId);
            
        }catch(Exception e) {
            System.debug('e.getMessage');
            return e.getMessage();
        }
        System.debug('SUCCESS');
        return 'SUCCESS';
    }
    
    public class EQT_Case implements Comparable {
        @AuraEnabled public Boolean isSelected { get; private set; }
        @AuraEnabled public Integer order { get; private set; }
        @AuraEnabled public Case cs { get; private set; }
        EQT_Case (Boolean isSelected, Integer order, Case cs) 
        {
            this.isSelected = isSelected;
            this.order = order;
            this.cs = cs;
        }
        
        /**
        * @description  Compare Case based on the order is used for the sort().  
        */
        public Integer compareTo(Object compareTo) {
            EQT_Case compare = (EQT_Case)compareTo;
            Integer returnValue = 0;
            if (order < compare.order) {
                returnValue = -1;
            } else if (order > compare.order) {
                returnValue = 1;
            }
            return returnValue;
        }
    }    
    /**
    * @description  Compare Case based on the order is used for the sort().    
    * @param        List of Case
    * @return       List of EQT_Case
    */
    private static List<EQT_Case> EQT_CaseSObjToObj(List<Case> cases){
        List<EQT_Case> csList = new List<EQT_Case>();
        Integer i = 0;
        for(Case cs: cases){
            System.debug(cs.Subject);
            EQT_Case csObject = new EQT_Case(false, i, cs);
            csList.add(csObject);
            i++;
        }
        csList.sort();
        System.debug(csList);
        return csList;
    }
    /**
    * @description  Create a string of Email Ids     
    * @param        List of Emails
    * @return       Email Id string
    */    
    private static String emailIdString(List<EmailMessage> emails){
        List<String> emailIds = new List<String>();
        for(EmailMessage em: emails){
            emailIds.add(em.Id);
        }
        String emailIdString = String.join(emailIds,'\',\'');
        return emailIdString;
    }
}