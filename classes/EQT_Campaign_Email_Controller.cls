public class EQT_Campaign_Email_Controller {
    @AuraEnabled
    public static Campaign getCampaign(String campaignId){
        System.debug(campaignId);
        Campaign c;
        List<Campaign> campaign = [ SELECT Id, Name from Campaign WHERE Id =: campaignId LIMIT 1];
        if(campaign.size() == 1)
            c = campaign[0];
        return c;
    }

	@AuraEnabled
    public static String getJSONEmailTemplates(){
        String returnJsonString;
        List<String> templateJSONStrings = new List<String>();
        List<EmailTemplate> templates = [select Id, Name, Subject, Body from EmailTemplate where Folder.DeveloperName = 'IR_Templates'];
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartArray();
        if(templates.size() > 0){
            for(EmailTemplate t : templates){
                generator.writeStartObject();
                generator.writeStringField('id', t.Id);
                generator.writeStringField('name', t.Name);
                generator.writeStringField('subject', t.Subject);
                generator.writeStringField('body', (String.isNotEmpty(t.Body)?t.Body.substring(0,(t.Body.length()>180?180:t.Body.length()))+'...':'- Template text body is empty -'));
                generator.writeEndObject();
            }
        }
        generator.writeEndArray();
        returnJsonString = generator.getAsString();
        System.debug('returnJsonString:\n'+returnJsonString);
        return returnJsonString;
    }
    @AuraEnabled
    public static String getJSONMemberStatus(String campaignId){
        String returnJsonString;
        List<CampaignMemberStatus> status = [select Id, IsDefault, Label from CampaignMemberStatus
                                              Where CampaignId =: campaignId and HasResponded = false
                                              ORDER BY SortOrder];
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartArray();
        if(status.size() > 0){
            for(CampaignMemberStatus s : status){
                generator.writeStartObject();
                generator.writeStringField('id', s.Id);
                generator.writeStringField('name', s.Label);
                generator.writeEndObject();
            }
        }
        generator.writeEndArray();
        returnJsonString = generator.getAsString();
        System.debug('returnJsonString:\n'+returnJsonString);
        return returnJsonString;
    }
    @AuraEnabled
    public static Integer getCampaignMemberCount(String campaignId, String status){
        Integer count = [ SELECT Count() from CampaignMember WHERE CampaignId =: campaignId and Status =: status ];
        return count;
    }

    @AuraEnabled
    public static String sendMassEmails(String campaignId, String templateId, String oldStatus, String newStatus){
        
        Id oweaId;

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'ir@eqtpartners.com'];
        System.debug(owea);
        if(owea.size() > 0)
            oweaId = owea.get(0).Id;
        else
            return 'The email address ir@eqtpartners.com is not set up as an Organization-wide address';

        EmailTemplate[] templates = [select Id, Name from EmailTemplate where Id =: templateId];
        System.debug(templates);
        if(templates.size() > 0)
            templateId = templates[0].id;
        else
            return 'Could not find the specified e-mail template.';

        List<CampaignMember> cmList = [select Id, ContactId from CampaignMember where CampaignId =: campaignId and Status =: oldStatus LIMIT 900];
        List<Id> cmIds = new List<Id>();
        System.debug(cmList);
        if(cmList.size() > 0){
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for(CampaignMember cm : cmList){
                cmIds.add(cm.Id);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(oweaId);
                mail.setTemplateId(templateId);
                mail.setTargetObjectId(cm.ContactId);
                mail.saveAsActivity = true;
                System.debug(mail);
                emails.add(mail);
            }
            Messaging.SendEmailResult [] r;
            if ( !Test.isRunningTest() ){
                try {
                    r = Messaging.sendEmail(emails);
                } catch (Exception e) {
                    System.debug(e.getMessage());
                    return 'There was an error while sending the Emails: ' + e.getMessage();
                }
            } else {
                r = new List<Messaging.SendEmailResult>();
            }

            System.debug(r);
            if(String.isNotBlank(newStatus)){
                Boolean updateSucceeded = updateCampaignMemberStatus(cmIds,newStatus);
                if(updateSucceeded)
                    return 'Campaign e-mail sent to '+r.size()+' campaign members. Their status was updated to "'+newStatus+'".';
                else
                    return 'Campaign e-mail sent to '+r.size()+' campaign members, but there was an error updating campaign member status. Please contact the system administrator. Failing records: '+String.join(cmIds, ', ');
            }else
                 return 'Campaign e-mail sent to '+r.size()+' campaign members.';

        }else{
            return 'There are no Campaign Members with the "'+oldStatus+'" status.';
        }
    }

    private static Boolean updateCampaignMemberStatus(List<Id> campaignMemberIds, String newStatus){
        Boolean success = true;
        List<CampaignMember> cmsToUpdate = new List<CampaignMember>();
        if(String.isNotBlank(newStatus)){
            for(Id cmId : campaignMemberIds){
                CampaignMember cm = new CampaignMember(Id = cmId, Status = newStatus);
                cmsToUpdate.add(cm);
            }
            if(cmsToUpdate.size() > 0)
                try{
                    update cmsToUpdate;
                }catch(DmlException e){
                    System.debug(e.getMessage());
                    success = false;
                }
        }else
            success = false;
        return success;
    }
}