/*
    About
    -----
    Description: Campaign Landing page controller. Gathers the Campaign Member's response and preferences. 
                 Shows only applicable fields that were configured in the campaign.
    Created by: felix.guerrero@fluidogroup.com
    Create date: 27-10-2016
    
    Details / Methods
    -----------------
    - Page actions
        submit //update changes to campaign member

    - Generic public
        getCampaignMemberStatusOptions // load available Status Options to show as aRadioButton Group
        getShowExtraFields // controls rendering of the additional fields section
    
    - Private
        getDisplayedFields // Returns the list of fields that should be shown on the page and queried/updated from campaign member
        getCurrentCampaignMember // Queries the CampaignMember from the given CampaignId and ContactId
*/

global without sharing class EQT_Campaign_LandingPage_Controller {

    /* Standard Form Fields */
    public transient String FirstName {get; set;}
    public transient String LastName {get; set;}
    public transient String Company {get; set;}
    public transient String Email {get; set;}

    /* Attendance response options */
    public String bgURL {get; private set;}
    public String attendValue {get; set;}

    public CampaignMember cm {get; set;}
    public Boolean isNewCampaignMember {get; private set;}

    public String[] displayedFields {get; private set;}


    private final Campaign c;
    public Boolean isCampaignValid {get; private set;}

    public EQT_Campaign_LandingPage_Controller(ApexPages.StandardController controller){
        if(!Test.isRunningTest()){
            controller.addFields(new LIST<String> {
                'IsActive', 'Status', 'EQT_Invitation_Background_Image_Id__c', 'EQT_Invitation_Form_Fields__c'
            });
        }
        String campaignIdString = ApexPages.currentPage().getParameters().get('id');
        this.isNewCampaignMember = false;
        
        // Check if the campaign exists and is active
        Boolean valid = false;
        if(String.isNotBlank(campaignIdString)){
            try{
                this.c = (Campaign)controller.getRecord();    
            }catch(Exception e){
                System.debug(e.getMessage());
            }
            if(c != null){
                if((c.IsActive && c.Status == 'In Progress') || c.Status == 'Planning')
                    valid = true;
            }
        }
        
        this.isCampaignValid = valid;
        System.debug(c);
        if(valid){

            String ContactIdString = ApexPages.currentPage().getParameters().get('cid');
            
            EQT_Admin_Settings__c settings = EQT_Admin_Settings__c.getOrgDefaults();
            string siteURL = settings.Campaign_Site_URL__c;

            this.bgURL = siteURL + '/servlet/servlet.ImageServer?id=' + c.EQT_Invitation_Background_Image_Id__c + '&oid=' + UserInfo.getOrganizationId();
            
            String fieldsToQuery = (c.EQT_Invitation_Form_Fields__c!=null?c.EQT_Invitation_Form_Fields__c:'');
            System.debug('fieldsToQuery:' + fieldsToQuery);
            this.displayedFields = getDisplayedFields(fieldsToQuery);
            System.debug('displayedFields: '+ displayedFields);
            

            // Check if the campaign member exists
            Id contactId;
            try{
                contactId = Id.valueOf(ContactIdString);
            }catch(Exception e){
                //this.isCampaignValid = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invitation reference is invalid.'));
            }
            System.debug('contactId: ' + contactId);
            if(contactId != null){
                this.cm = getCurrentCampaignMember(displayedFields, c.Id, contactId);
                System.debug('Campaign member:\n'+cm);
                if(cm!=null){
                    this.firstname = cm.FirstName;
                    this.lastname = cm.LastName;
                    this.company = cm.CompanyOrAccount;
                    this.email = cm.Email;
                    if(cm.HasResponded)
                        this.attendValue = cm.Status;
                }else{
                    // The Contact Id provided did not match an existing Campaign Member, return an error.
                    this.isCampaignValid = false;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invitation reference is invalid.'));
                }
            }else{
                    this.isNewCampaignMember = true;
            }    
            
            if(isNewCampaignMember)
                this.cm = new CampaignMember(CampaignId = c.Id);
            
        }else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The requested campaign has ended or does not exist.'));
    }

    public List<SelectOption> getCampaignMemberStatusOptions(){
        List<SelectOption> options = new List<SelectOption>();
        if(c != null){
            List<CampaignMemberStatus> cms = [
                                                SELECT CampaignId, Label 
                                                FROM CampaignMemberStatus 
                                                WHERE HasResponded = true 
                                                AND CampaignId =: c.Id 
                                                ORDER BY SortOrder ASC     ];

            for(CampaignMemberStatus status : cms){
                SelectOption option = new SelectOption(status.Label, status.Label);
                options.add(option);
            }
        }
        return options;
    }

    public Boolean getShowExtraFields() {
        return (displayedFields != null && displayedFields.size() > 0);
    }

    private String[] getDisplayedFields(String formFields){

        String[] displayedFields = new List<String>();
        if(String.isNotBlank(formFields)) {
            Set<String> fieldsSet = new Set<String>();
            fieldsSet.addAll(formFields.split(';'));
            Schema.DescribeSObjectResult d = CampaignMember.sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
            System.debug(fieldsMap);
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fr = fieldsMap.get(fieldName).getDescribe();
                System.debug(fieldName + ' :::' + fieldsSet.contains(fieldName.toLowerCase()));
                if(fieldsSet.contains(fieldName.toLowerCase())){
                //if (fr.isAccessible() && fr.isCustom() && fr.isUpdateable() && fieldName.toLowerCase().startsWith('eqt_invitation')) {
                    displayedFields.add(fieldName);//fieldLabelMap.put(fieldName, fr.getLabel());
                }
            }
        }
        return displayedFields;
    }

    @TestVisible
    private CampaignMember getCurrentCampaignMember(String[] fields, Id campaignId, Id contactId){
        List<CampaignMember> campaignMembers;
        CampaignMember mem;
        String query = 'SELECT Id, FirstName, LastName, CompanyOrAccount, Email, Status, HasResponded ';
        for(String f : fields)
            query += (','+f);

        query +=' FROM CampaignMember ' +
                ' WHERE CampaignId =: campaignId  ' +
                ' AND   ContactId =: contactId  ' +
                ' LIMIT 1';
        System.debug(query);
        try {
            campaignMembers = (List<CampaignMember>) Database.query(query);
        }catch (Exception e){
            System.debug(e.getMessage());
        }
        if(campaignMembers != null && campaignMembers.size()>0){
            System.debug(campaignMembers);
            mem =campaignMembers[0];
        }
        return mem;
    }

    public PageReference submit(){
        
        ApexPages.getMessages().clear();
        
        System.debug(cm);
        if(c.Status == 'Planning'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Page is on preview-only mode.'));
            return null;
        }

        if(isNewCampaignMember)
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invitation reference not found.'));
        else{
            System.debug(attendValue);
            if(attendValue == null)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select an attendance option.'));
            else{
                cm.Status = attendValue;
                update cm;        
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Your response has been registered, thank you.'));
            }
        }

        return null;
    }
}