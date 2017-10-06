public with sharing class EQT_Campaign_Page_Config_Controller {
	
    public Id backgroundImage {get; set;}
    
    public Map<Id,String> imageMap {get; private set;}

    public List<SelectOption> CampaignMemberStatusOptions {get; private set;}

    public List<String> selectedFields {get; set;}
    
    public Boolean editState {get; set;}
    
    public ApexPages.StandardController stdController { get; set; }
    
    private Campaign c;
    private List<Document> documents;
    
       
    public EQT_Campaign_Page_Config_Controller(ApexPages.StandardController controller){
        if(!Test.isRunningTest())
            controller.addFields(new List<String>{
                    'EQT_Invitation_Background_Image_Id__c','EQT_Invitation_Form_Fields__c'
            });
        this.stdController = controller;
        init(stdController);
    }
    
    private void init(ApexPages.StandardController controller){
        
        this.c = (Campaign)controller.getRecord();

        this.imageMap = new Map<Id,String>();
		
        this.documents = [ 
            SELECT Id, Name, Type from Document
                WHERE Folder.DeveloperName = 'EQT_Campaign_Email_Templates'
                AND IsPublic = true
                AND Type IN ('png','jpg','jpeg','gif')
        ];
        
        Id noImageId;
        for(Document d : documents){
            imageMap.put(d.Id, d.Name);
            if(d.Name == 'No image')
                noImageId = d.Id;
        }
        
        populateCampaignMemberStatusOptions();

        this.backgroundImage = (c.EQT_Invitation_Background_Image_Id__c != null)?c.EQT_Invitation_Background_Image_Id__c:noImageId;

        if(String.isNotBlank(c.EQT_Invitation_Form_Fields__c))
            this.selectedFields = c.EQT_Invitation_Form_Fields__c.split(';');
        else
            this.selectedFields = new List<String>();

        this.editState = false;

    }
    
    private void populateCampaignMemberStatusOptions(){
        List<SelectOption> options = new List<SelectOption>();
        
        Map<String,String> fieldLabelMap = getDisplayFieldsMap();
        System.debug(fieldLabelMap);
        for(String field : fieldLabelMap.keySet()){
            SelectOption option = new SelectOption(field, fieldLabelMap.get(field), true);
            options.add(option);
        }

        this.CampaignMemberStatusOptions = options;
    }

    private void toggleCampaignMemberStatusOptions(){
        for(SelectOption option : CampaignMemberStatusOptions)
            option.setDisabled(!editState);
    }

    private Map<String,String> getDisplayFieldsMap(){

        Map<String,String> fieldLabelMap = new Map<String,String>();
        
        Schema.DescribeSObjectResult d = CampaignMember.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
        System.debug(fieldsMap);
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fr = fieldsMap.get(fieldName).getDescribe();
            System.debug(fieldName + ' :::' + fieldName.toLowerCase().startsWith('eqt_x_'));
            if (fr.isAccessible() && fr.isCustom() && fr.isUpdateable() && fieldName.toLowerCase().startsWith('eqt_x_')) {
                System.debug(fieldName);
                fieldLabelMap.put(fieldName, fr.getLabel());
            }
        }

        return fieldLabelMap;
    }

    public List<SelectOption> getImages(){
        List<SelectOption> options = new List<SelectOption>();
		System.debug(documents);
        for(Document d : documents){
            SelectOption option = new SelectOption(d.Id, d.Name);
            /*if(d.Name == 'No image')
                options.add(0, option);
            else*/
	            options.add(option);
        }
        return options;
    }
    
    public PageReference toggleEditState(){
        editState = !editState;
        toggleCampaignMemberStatusOptions();
        return null;
    }
    
    public PageReference save(){

        toggleEditState();
        c.EQT_Invitation_Background_Image_Id__c = backgroundImage;
        c.EQT_Invitation_Form_Fields__c = String.join(selectedFields, ';');

		update c;
        
        return null;
        
    }

    public PageReference cancelChange(){
        /*
        PageReference pageRef = ApexPages.currentPage();
        pageRef.setRedirect(true);
        System.debug(pageRef.getUrl());
        */
        
        init(stdController);

       	return null;
    }      
        
}