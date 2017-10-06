@isTest
public class EQT_Proxy_EmailMessage_Handler_Test {
    
    @isTest
    public static void testCreateEmailMessage() {
        // Define
        String subject = 'Test subject';
        String toAddress = 'to@example.com';
        String ccAddress = 'cc@example.com';
        Datetime messageDate = Datetime.newInstance(2016, 11, 14);
        String htmlBody = 'Test html body';
        String dynamicsId = '123456789';
                
        // Prepare
        Case c = new Case(
            Subject = 'Test'
        );
        insert c;
        ContentVersion cv = new ContentVersion();
        cv.Dynamics_EmailMessageDynamicsId__c = dynamicsId;
        cv.Title = 'Content Version test';
        cv.ContentUrl = 'http://www.google.com';
        insert cv;
        List<ContentVersion> cvList = [select ContentDocumentId from ContentVersion where Id = :cv.Id];
        Id contentDocumentID = cvList[0].ContentDocumentId;
        List<Contact> conList = new List<Contact>();
        conList.add(new Contact(LastName = 'To 1', Email='to1@example.com'));
        conList.add(new Contact(LastName = 'To 2', Email='to2@example.com'));
        conList.add(new Contact(LastName = 'Cc 1', Email='cc1@example.com'));
        conList.add(new Contact(LastName = 'Cc 2', Email='cc2@example.com'));
        conList.add(new Contact(LastName = 'From', Email='from@example.com'));
        insert conList;
       
        EQT_Proxy_EmailMessage__c pem = new EQT_Proxy_EmailMessage__c();
        pem.Subject__c = subject;
        pem.ToAddress__c = toAddress;
        pem.CcAddress__c = ccAddress;
        pem.MessageDate__c = messageDate;
        pem.HtmlBody__c = htmlBody;
        pem.ParentId__c = c.Id;
        pem.DynamicsId__c = dynamicsId;
        pem.ToIds__c = conList[0].Id + ',' + conList[1].Id;
        pem.CcIds__c = conList[2].Id + ',' + conList[3].Id;
        pem.FromId__c = conList[4].Id;
        
        // Test
        Test.startTest();
        insert pem;
        Test.stopTest();
        
        // Assert
        List<EmailMessage> emList = [select Id, ParentId, Subject, FromAddress, ToAddress, CcAddress, MessageDate, HtmlBody, Status from EmailMessage];
        System.assert(emList.size() == 1);
        System.assert(emList[0].ParentId == c.Id);
        System.assert(emList[0].Subject == subject);
        System.assert(emList[0].ToAddress == toAddress);
        System.assert(emList[0].CcAddress == ccAddress);
        System.assert(emList[0].MessageDate == messageDate, emList[0].MessageDate + ' differs from ' + messageDate);
        System.assert(emList[0].HtmlBody == htmlBody);
        System.assert(emList[0].Subject != '5'); // It must not be in draft status
        
        List<ContentDocumentLink> cdlList = [select ContentDocumentId, LinkedEntityId from ContentDocumentLink where ContentDocumentId = :contentDocumentID and LinkedEntityId = :emList[0].Id];
        System.assert(cdlList.size() == 1);
        
        List<EmailMessageRelation> emrList = [select EmailMessageId,RelationId,RelationType from EmailMessageRelation];
        List<boolean> found = new List<boolean>();
        found.add(false);
        found.add(false);
        found.add(false);
        found.add(false);
        found.add(false);
        found.add(false);
        for (EmailMessageRelation emr : emrList) {
            System.assert(emr.EmailMessageId == emList[0].Id);
            if (emr.RelationId == conList[0].Id) {
                found[0] = true;
                System.assert(emr.RelationType == 'ToAddress');
            }
            if (emr.RelationId == conList[1].Id) {
                found[1] = true;
                System.assert(emr.RelationType == 'ToAddress');
            }
            if (emr.RelationId == conList[2].Id) {
                found[2] = true;
                System.assert(emr.RelationType == 'CcAddress');
            }
            if (emr.RelationId == conList[3].Id) {
                found[3] = true;
                System.assert(emr.RelationType == 'CcAddress');
            }
            if (emr.RelationId == conList[4].Id) {
                found[4] = true;
                System.assert(emr.RelationType == 'FromAddress');
            }
        }
        System.assert(found[0]);
        System.assert(found[1]);
        System.assert(found[2]);
        System.assert(found[3]);
        System.assert(found[4]);
        
    }

}