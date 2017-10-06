/**
    About
    -----
    Description: Helps migration of EmailMessage records from Dynamics
    Created for: EQT
    Create date: November 2016
    
    Details / Methods
    -----------------
    This class is used to support migration of email messages from Dynamics
    to Salesforce. By inserting records into this object, corresponding
    EmailMessage records will be created and also related to ContentVersion
    records via ContentDocumentLink automatically.

    Apart from being used in the migration process, this class has no
    other functionality for the Salesforce users.

   
    Update History
    --------------
    Created November 2016 - andreas.piirimets@fluidogroup.com

    Issues / TODOs
    --------------
*/
public class EQT_Proxy_EmailMessage_Handler {
	
    /**
     * This shall be called from a before insert trigger with Trigger.new as parameter.
     * 
     */
    public static void createEmailMessage(List<EQT_Proxy_EmailMessage__c> pemList) {
        
        // Create a list of all DynamicsId:s
        List<String> dynamicsIdList = new List<String>();
        for (EQT_Proxy_EmailMessage__c pem : pemList) {
            dynamicsIdList.add(pem.DynamicsId__c);
        }
        
        // Get all ContentVersion records with matching DynamicsId:s
        List<ContentVersion> allCvList = [select Id, ContentDocumentId, Dynamics_EmailMessageDynamicsId__c from ContentVersion where Dynamics_EmailMessageDynamicsId__c in :dynamicsIdList];
        
        // Map all ContentVersion records on Dynamics Id
        Map<String, List<ContentVersion>> cvMap = new Map<String, List<ContentVersion>>();
        for (ContentVersion cv : allCvList) {
            List<ContentVersion> cvList = cvMap.get(cv.Dynamics_EmailMessageDynamicsId__c);
            if (cvList == null) {
                cvList = new List<ContentVersion>();
            }
            cvList.add(cv);
            cvMap.put(cv.Dynamics_EmailMessageDynamicsId__c, cvList);
        }
        
		// Go through all EmailMessage records that shall be created        
        for (EQT_Proxy_EmailMessage__c pem : pemList) {
            
            // Insert new EmailMessage with status = draft
            EmailMessage em = new EmailMessage(
                ParentId = pem.ParentId__c,
                Subject = pem.Subject__c,
                FromAddress = pem.FromAddress__c,
                ToAddress = pem.ToAddress__c,
                CcAddress = pem.CcAddress__c,
                MessageDate = pem.MessageDate__c,
                Status = '5',
                HtmlBody = pem.HtmlBody__c
            );
            insert em;
            
            // Relate all attachments to that EmailMessage
            List<ContentVersion> cvList = cvMap.get(pem.DynamicsId__c);
            if (cvList != null) {
	            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
                for (ContentVersion cv : cvList) {
                    ContentDocumentLink cdl = new ContentDocumentLink(
                        ContentDocumentId = cv.ContentDocumentId,
                        LinkedEntityId = em.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    );
                    cdlToInsert.add(cdl);
                }
            	insert cdlToInsert;
            }
            
            // Relate all FromIds, ToIds and CcIds to that EmailMessage
            List<EmailMessageRelation> emrList = new List<EmailMessageRelation>();
            List<String> idStrList;
            if (pem.ToIds__c != null) {
	            idStrList = pem.ToIds__c.split(',');
	            for (String idStr : idStrList) {
		            EmailMessageRelation emr = new EmailMessageRelation(
	                    EmailMessageId = em.Id,
	                    RelationId = (Id)idStr,
	                    RelationType = 'ToAddress'
	                );
	                emrList.add(emr);
	            }
            }
            if (pem.CcIds__c != null) {
	            idStrList = pem.CcIds__c.split(',');
	            for (String idStr : idStrList) {
		            EmailMessageRelation emr = new EmailMessageRelation(
	                    EmailMessageId = em.Id,
	                    RelationId = (Id)idStr,
	                    RelationType = 'CcAddress'
	                );
	                emrList.add(emr);
	            }
        	}
            if (pem.FromId__c != null) {
                EmailMessageRelation emr = new EmailMessageRelation(
                    EmailMessageId = em.Id,
                    RelationId = (Id)pem.FromId__c,
                    RelationType = 'FromAddress'
                );
                emrList.add(emr);
        	}

            insert emrList;
            
            // Update EmailMessage record to status = sent
            em.Status = '3';
            update em;
        }
    }
}