public with sharing class EQT_BusinessCard_Controller {
    private static final String EQT_CV = 'EQT_CV';

    private class AgreementWrapper implements Comparable {
        public String type;
        public String status;
        public Date endDate;

        public AgreementWrapper(String type, String status, Date endDate){
            this.type = type;
            this.status = status;
            this.endDate = endDate;
        }

        public Integer compareTo(Object compareTo) {
            AgreementWrapper aw = (AgreementWrapper)compareTo;

            Integer res = 0;
            if(this.status==null && aw.status==null){
                res = 0;
            } else if (this.status==null){
                res = 1;
            } else {

                if(this.endDate == aw.endDate){
                    res = 0;
                } else if (this.endDate > aw.endDate) {
                    res = 1;
                } else {
                    res = -1;
                }
            }

            return res;
        }

        public String getString(){
            return type + ', ' + status;
        }
    }

    @AuraEnabled
    public static String getBusinessCardData(Id recordId) {
        // create return object
        ReturnType t = new ReturnType();
        // get contact data
        List<Contact> contacts = [
            SELECT Id, Name, Title, MobilePhone, Phone, Email, EQT_Email_2__c , EQT_Email_3__c, 
            Firstname, Lastname, EQT_IA_Suggested_By__c, 
            OwnerId, Owner.Name,
            EQT_LinkedIn_Profile__c, 
            EQT_Industrial_Advisor_Short_Bio__c, 
            //toLabel(Engagement_Level__c),
            toLabel(EQT_IA_Status__c), 
            toLabel(EQT_Suitable_Positions__c), 
            EQT_Assessment_Rating_Number__c, EQT_Assessment_Rating_Total__c, EQT_Average_Assessment_Rating__c,
            Birthdate,EQT_Age__c,Fax,Gender__c,OtherPhone,
            Account.Name,AccountId,
            MailingAddress,MailingCity,MailingCountry,MailingPostalCode,MailingState,MailingStreet,
            OtherAddress,OtherCity,OtherCountry,OtherPostalCode,OtherState,OtherStreet,
            EQT_Alternative_Address__c, EQT_Address_Comments__c, EQT_Country_of_Residence__c,
            (SELECT Id, EQT_Type__c, EQT_Status__c, EQT_End_Date__c FROM EQT_IA_Contracts__r ORDER BY EQT_Status__c, EQT_End_Date__c DESC NULLS LAST)
            FROM Contact 
            WHERE id =: recordId limit 1];
        if (null == contacts || contacts.size() != 1) {
            throw new AuraHandledException('Unknown contact requested');
        }
        Contact contact = contacts.get(0);
        
        // get photo if any
        Attachment att = null;
        try {
            att = [SELECT Id, Name, LastModifiedDate, ContentType
        		FROM Attachment 
            	WHERE ParentId =: recordId
            	AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/bmp', 'image/jpg') 
            	ORDER BY LastModifiedDate DESC LIMIT 1];
        } catch (Exception e) {
            t.e = 'No picture for found to user - error from picture retrieval: ' + e.getMessage();
        }
        
        // get assignments
        final List<EQT_Assignment__c> assignments = [SELECT Id, Name, Company__c, Company__r.Name, 
				Project__c, Project__r.Name, 
				Project__r.Account.Id, Project__r.Account.Name, 
				Start_Date__c, EQT_End_Date__c, EQT_Role__c, 
				Project__r.EQT_Business_Line_Sub_Strategy__c, Project__r.Account.Industry, Operative__c  
				FROM EQT_Assignment__c where Contact__c =: recordId 
				order by Start_Date__c desc, EQT_End_Date__c desc];
        for (EQT_Assignment__c assign : assignments) {
            // deal or work history
            final boolean isDeal = (null != assign.Project__c);
            
            // build base map
            Map<String, Object> obj = null;
            
            if (isDeal) {
                // this is a Deal
                obj = new Map<String,Object>{'Id' => assign.Id, 'Name' => assign.Name, 
                    'StartDate' => isoDate(assign.Start_Date__c), 'EndDate' => isoDate(assign.EQT_End_Date__c), 
                    'Role' => assign.EQT_Role__c, 'Sector' => assign.Project__r.Account.Industry, 
                    'AccountId' => assign.Project__r.Account.Id, 'AccountName' => assign.Project__r.Account.Name,
                    'DealId' => assign.Project__c, 'DealName' => assign.Project__r.Name, 
                    'BusinessLine' => assign.Project__r.EQT_Business_Line_Sub_Strategy__c};
				t.Deals.add(obj);
            } else {
                // this is an EQT assignment
                obj = new Map<String,Object>{'Id' => assign.Id, 'Name' => assign.Name, 'StartDate' => isoDate(assign.Start_Date__c), 'EndDate' => isoDate(assign.EQT_End_Date__c), 'AccountId' => assign.Company__c, 'AccountName' => assign.Company__r.Name, 'Role' => assign.EQT_Role__c, 'EQT' => true, 'Type' => assign.Operative__c ? 'Operative' : 'Board'};
				t.Assignments.add(obj);
            }
            
            // build and set the date range
            final Date dateStart = assign.Start_Date__c;
            final Date dateEnd = assign.EQT_End_Date__c;
            obj.put('DateRange', buildDateRange(dateStart, dateEnd));
        }
        
        // get work history by getting affiliations
        final List<EQT_Affiliation__c> affiliations = [select Id, Name, Start_Date__c, End_Date__c, 
                                                 Account__r.Name, Account__c, Role__c, Operative__c 
                                                 from EQT_Affiliation__c where Contact__c =: recordId and 
                                                 Include_in_CV_highlights__c=true 
                                                 order by Start_Date__c desc, End_Date__c desc];
        for (EQT_Affiliation__c aff : affiliations) {
            // build and set the date range
            final Date dateStart = aff.Start_Date__c;
            final Date dateEnd = aff.End_Date__c;
            final String dateRange = buildDateRange(dateStart, dateEnd);
            
            // add to list
            t.Assignments.add(new Map<String, Object>{'Id' => aff.Id, 'Name' => aff.Name, 'StartDate' => isoDate(aff.Start_Date__c), 'EndDate' => isoDate(aff.End_Date__c), 'DateRange' => dateRange, 'AccountId' => aff.Account__c, 'AccountName' => aff.Account__r.Name, 'Role' => aff.Role__c, 'EQT' => false, 'Type' => aff.Operative__c ? 'Operative' : 'Board'});
        }

        // get fund contact roles SFAM-171
        final List<EQT_Fund_Contact_Role_Association__c> fundContactRolesList = [
            SELECT Id, toLabel(EQT_Role__c), EQT_Fund__c, EQT_Fund__r.Name, Start_Date__c, End_Date__c
            FROM EQT_Fund_Contact_Role_Association__c where EQT_Contact__c =: recordId AND EQT_Role__c = '14'
            order by Start_Date__c desc, End_Date__c desc
        ];

        for(EQT_Fund_Contact_Role_Association__c fundContactRoleItem : fundContactRolesList){
            system.debug('fundContactRoleItem: ' + fundContactRoleItem);
            system.debug('fundContactRoleItem.EQT_Fund__r.Name: ' + fundContactRoleItem.EQT_Fund__r.Name);

            // build and set the date range
            final Date dateStart = fundContactRoleItem.Start_Date__c;
            final Date dateEnd = fundContactRoleItem.End_Date__c;
            final String dateRange = buildDateRange(dateStart, dateEnd);

            // add to list
            t.Assignments.add(new Map<String, Object>{'Id' => fundContactRoleItem.EQT_Fund__c,'Name' => fundContactRoleItem.EQT_Fund__r.Name,'StartDate' => isoDate(fundContactRoleItem.Start_Date__c),'EndDate' => isoDate(fundContactRoleItem.End_Date__c),'DateRange' => dateRange,'AccountId' => null,'AccountName' => fundContactRoleItem.EQT_Fund__r.Name,'Role' => fundContactRoleItem.EQT_Role__c,'EQT' => false,'Type' => 'IAC'});
        }

        // get sectors / functional / geos
        final List<EQT_Sector_Rating__c> sectors = [select id, Sector__r.Name, Subsector__r.Name, Subsector_Segment__r.Name from EQT_Sector_Rating__c where contact__c =: recordId];
        final List<EQT_Functional_Rating__c> functions = [select id, Functional_Topic__r.Name, Functional_Subtopic__r.Name from EQT_Functional_Rating__c where contact__c =: recordId];
        final List<EQT_Geographical_Rating__c> geos = [select id,Geography__r.Name from EQT_Geographical_Rating__c where contact__c =: recordId];

        // set contact data
        List<String> suitablePositions = null;
        if (!String.isEmpty(contact.EQT_Suitable_Positions__c)) {
            suitablePositions = contact.EQT_Suitable_Positions__c.split(';');
        }
        //set agreements
        List<AgreementWrapper> agreementsWrappers = new List<AgreementWrapper>();
        if(!contact.EQT_IA_Contracts__r.isEmpty()) {
            for(EQT_IA_Contract__c a : contact.EQT_IA_Contracts__r) {
                agreementsWrappers.add(new AgreementWrapper(a.EQT_Type__c, a.EQT_Status__c, a.EQT_End_Date__c));
            }
            agreementsWrappers.sort();
        }

        List<String> agreements = new List<String>();
        if(!agreementsWrappers.isEmpty()){
            for(AgreementWrapper aw : agreementsWrappers){
                agreements.add(aw.getString());
            }
        }

        t.Contact.put('Agreements', agreements);
        t.Contact.put('Id', contact.Id);
        t.Contact.put('PhoneMobile', contact.MobilePhone);
        t.Contact.put('PhoneBusiness', contact.Phone);
        t.Contact.put('Fax', contact.Fax);
        t.Contact.put('Birthdate', contact.Birthdate);
        t.Contact.put('Age', contact.EQT_Age__c);
        t.Contact.put('Gender', contact.Gender__c);
        t.Contact.put('PhoneHome', contact.OtherPhone);
        t.Contact.put('Email', contact.Email);
        t.Contact.put('Email2', contact.EQT_Email_2__c);
        t.Contact.put('Email3', contact.EQT_Email_3__c);
        t.Contact.put('FirstName', contact.FirstName);
        t.Contact.put('LastName', contact.LastName);
        t.Contact.put('Title', contact.Title);
        t.Contact.put('CountryOfResidence', contact.EQT_Country_of_Residence__c);
        t.Contact.put('Status', contact.EQT_IA_Status__c);
        //t.Contact.put('EngagementLevel', contact.Engagement_Level__c);
        t.Contact.put('Bio', contact.EQT_Industrial_Advisor_Short_Bio__c);
        t.Contact.put('LinkedinProfile', contact.EQT_LinkedIn_Profile__c);
        t.Contact.put('SuitablePositions', suitablePositions);
        //t.Contact.put('QualityAssured', contact.EQT_Quality_Assured_Since_Transferred__c);
        t.Contact.put('Owner', new Map<String,String>{'Id' => contact.OwnerId, 'Name' => contact.Owner.Name});
        t.Contact.put('Account', new Map<String,String>{'Id' => contact.AccountId, 'Name' => contact.Account.Name});
        t.Contact.put('AddressMailing', new Map<String,String>{'PostalCode' => contact.MailingPostalCode, 'Street' => contact.MailingStreet, 'City' => contact.MailingCity, 'State' => contact.MailingState, 'Country' => contact.MailingCountry});
        t.Contact.put('AddressOther', new Map<String,String>{'PostalCode' => contact.OtherPostalCode, 'Street' => contact.OtherStreet, 'City' => contact.OtherCity, 'State' => contact.OtherState, 'Country' => contact.OtherCountry});
        t.Contact.put('AddressAlternative', contact.EQT_Alternative_Address__c);
        t.Contact.put('AddressComments', contact.EQT_Address_Comments__c);
        
        // get Investment Committee Member
        final List<EQT_Fund_Contact_Role_Association__c> fund_icms = [select Id, eqt_fund__c, eqt_contact__c, 
			eqt_fund__r.Name from EQT_Fund_Contact_Role_Association__c 
			where eqt_role__c = '10' and eqt_contact__c =: recordId];
        if (!fund_icms.isEmpty()) {
            t.FundICMs = new List<Object>();
            for (EQT_Fund_Contact_Role_Association__c icm : fund_icms) {
                t.FundICMs.add(new Map<String,Object>{'Id' => icm.Id, 
                    'FundName' => icm.EQT_Fund__r.Name, 'FundId' => icm.EQT_Fund__c});
            }
        }
        
        // get any assessment for deals
        final List<AggregateResult> dealAssessments = [select EQT_Deal__c, count(EQT_Assessment_Rating_Score__c) ccount, avg(EQT_Assessment_Rating_Score__c) cavg 
			from eqt_assessment__c 
			where eqt_deal__c != null and eqt_industrial_advisor__C=:recordId 
			group by EQT_Deal__c 
			order by eqt_deal__c];
        
        // set overall contact assessment
        t.Assessments.put('Contact', new Map<String, Object>{'Overall' => contact.EQT_Average_Assessment_Rating__c, 
            'Count' => contact.EQT_Assessment_Rating_Number__c});
        
        // add individual deal assessments
        for (AggregateResult r : dealAssessments) {
            t.Assessments.put(String.valueOf(r.get('EQT_Deal__c')), new Map<String,Object>{
                'Type' => 'Deal', 
                'Count' => r.get('ccount'), 
                'Overall' => r.get('cavg')});
        }
        
        // set sectors
        for (EQT_Sector_Rating__c sect : sectors) {
            final String main = sect.Sector__r.Name;
            final String sub = sect.Subsector__r.Name;
            final String segment = sect.Subsector_Segment__r.Name;
            String name = main;
            if (!String.isEmpty(sub)) name += ' > ' + sub;
            if (!String.isEmpty(segment)) name += ' > ' + segment;
            t.Sectors.Add(new Map<String,String>{'Id' => sect.Id, 
                'Name' => name, 
                'Main' => main, 
                'Sub' => sub,
                'Segment' => segment});
        }
                
        // set functions
        for (EQT_Functional_Rating__c func : functions) {
            final String main = func.Functional_Topic__r.Name;
            final String sub = func.Functional_Subtopic__r.Name;
            String name = main;
            if (!String.isEmpty(sub)) name += ' > ' + sub;
            t.Functions.Add(new Map<String,String>{'Id' => func.Id, 
                'Name' => name, 
                'Main' => main, 
                'Sub' => sub});
        }
                
        // set geos
        for (EQT_Geographical_Rating__c geo : geos) {
            final String main = geo.Geography__r.Name;
            t.Geos.Add(new Map<String,String>{'Id' => geo.Id, 'Name' => main, 'Main' => main});
        }
        
        // set photo
        t.Photo = att;
        
        // get CV's
        ContentDocument cv = getContentDocumentForCV(recordId);
        t.Contact.put('CVLink', cv);
        
        // return
        return JSON.serialize(t);
    }
    
    @AuraEnabled
    public static Id savePhoto(Id parentId, String fileName, String base64Data, String contentType) {
        // remove existing
        List<Attachment> current = getAttachmentsForParentId(parentId);
        if (current.size() > 0) delete current;

        // add new
        Attachment attachment = createAttachment(parentId, fileName, base64Data, contentType);
        
        // return new id
        return attachment.id;
    }
    
    @AuraEnabled
    public static void deletePhoto(Id photoId) {
        if(photoId==null){
            throw new AuraHandledException('The Profile Picture Id was not set.');
        }
        
        List<Attachment> attachmentsList = [SELECT ID From Attachment where Id=:photoId];
        if(attachmentsList.size()==1){
            delete attachmentsList;
        } else {
            throw new AuraHandledException('The Profile Picture was not found.');
        }
    }
    
    @AuraEnabled
    public static String saveCVChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId, Boolean isFinalChunk) {
        system.debug('@@saveCVChunk started');
        system.debug('@@saveCVChunk fileId: ' + fileId);

        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8'); // TODO check

        if (fileId=='' || fileId==null) {
            system.debug('@@saveCVChunk saveCV way ');
            Id attachId = saveAttachment(parentId, fileName, base64Data, contentType);
            fileId = String.valueOf(attachId);
        } else {
            system.debug('@@saveCVChunk appendToFile way');
            appendToAttachment(fileId, base64Data);
        }

        if(isFinalChunk){
            return moveAttachment(parentId, fileId, filename);
        }

        return fileId;
    }

    @AuraEnabled
    public static String checkCVId(Id contentDocumentId){
        system.debug('contentDocumentId: ' + contentDocumentId);

        if(contentDocumentId==null){
            return 'BAD';
        }

        List<ContentDocument> contentDocumentList = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        if(contentDocumentList.size()==1){
            return 'OK';
        }

        return 'BAD';
    }

    private static Id moveAttachment(Id parentId, String fileId, String filename){
        Attachment a = [
            SELECT Id, Body, Name, parentId
            FROM Attachment
            WHERE Id = :fileId
        ];
        system.debug('final attachment: ' + a);

        ContentDocument cv = getContentDocumentForCV(parentId);
        system.debug('@@moveAttachment cv: ' + cv);

        Id resultCDId = null;

        if (cv != null) {
            // found existing CV - update
            ContentVersion updatedCV = new ContentVersion(
                ContentDocumentId = cv.Id,
                Title = filename,
                PathOnClient = '/' + filename,
                VersionData = a.Body,
                EQT_Type__c = EQT_CV
            );
            insert updatedCV;

            resultCDId = cv.Id;
        } else {
            // none found - create actual CV
            ContentVersion newCV = new ContentVersion(
                Title = filename,
                PathOnClient = '/' + filename,
                VersionData = a.Body,
                EQT_Type__c = EQT_CV
            );
            insert newCV;

            // refetch the ContentVersion we just created as the Id to the actual ContentDocument is not set
            newCV = [select contentdocumentid from contentversion where id=:newCV.ID limit 1];
            if (null == newCV) {
                throw new AuraHandledException('Unable to refetch the ContentVersion we just inserted');
            }

            // link to contact
            ContentDocumentLink newCVLink = new ContentDocumentLink();
            newCVLink.ContentDocumentId = newCV.ContentDocumentId;
            newCVLink.LinkedEntityId = parentId;
            newCVLink.ShareType = 'I';
            insert newCVLink;

            resultCDId = newCV.ContentDocumentId;
        }

        delete a;

        return resultCDId;
    }

    public static Id saveAttachment(Id parentId, String fileName, String base64Data, String contentType) {
        system.debug('Entering saveAttachment');

        //Id dummyRecordId = EQT_UTIL_Settings.getDefaultAccountId();

        //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment a = new Attachment();
        a.parentId = parentId;//dummyRecordId;
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;
        insert a;

        system.debug('Attachment: ' + a);
        return a.Id;
    }

    private static void appendToAttachment(Id fileId, String base64Data) {
        system.debug('Entering appendToFile fileId: ' + fileId);

        //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment a = [
                SELECT Id, Body
                FROM Attachment
                WHERE Id = :fileId
        ];

        system.debug('appendToFile attachment: ' + a);

        String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);

        update a;
    }

    public static ContentDocument getContentDocumentForCV(String recordId) {
        // sanity
        if (String.isEmpty(recordId)) return null;

        // get CV's
        List<ContentDocumentLink> cv_links = [SELECT ContentDocumentId FROM ContentDocumentLink where LinkedEntityId =: recordId and IsDeleted=false];
        List<ContentDocument> cvs = null;
        if (cv_links.size() > 0) {
            List<Id> cv_link_ids = new List<Id>();
            for (ContentDocumentLink obj : cv_links) cv_link_ids.add(obj.ContentDocumentId);
            cvs = [SELECT id, title from ContentDocument where Id in :cv_link_ids and Id in (select contentdocumentid from contentversion where contentdocumentid in :cv_link_ids and EQT_Type__c=:EQT_CV)];
            if (cvs.size() > 0) return cvs[0];
        }
        return null;
    }
    
    public static List<Attachment> getAttachmentsForParentId(Id parentId) {
        List<Attachment> current = [SELECT ID From Attachment where ParentId=:parentId];
        return current;
    }
    
    public static Attachment createAttachment(Id parentId, String fileName, String base64Data, String contentType) {
		// create
        Attachment attachment = new Attachment();
        attachment.parentId = parentId;
        attachment.body = EncodingUtil.base64Decode(base64Data);
        attachment.name = fileName;
        attachment.contentType = contentType;
        insert attachment;
        
        // return
        return attachment;
    }
    
    /**
     * Utility method to create a ISO date as a String from a 
     * Date object.
     */
    public static String isoDate(Date d) {
        if (null == d) return null;
        integer day = d.day();
        integer month = d.month();
        integer year = d.year();
        return String.valueOf(year) + '-' + 
            (month < 10 ? ('0' + month) : String.valueOf(month)) + '-' +
            (day < 10 ? ('0' + day) : String.valueOf(day));
    }
    
    private static String buildDateRange(Date dateStart, Date dateEnd) {
        if (null == dateStart && null == dateEnd) {
            return '';
        } else if (null == dateEnd) {
            return dateStart.year() + ' - Current';
        } else if (null == dateStart) {
            return 'Unknown - ' + dateEnd.year();
        } else {
            return dateStart.year() + ' - ' + dateEnd.year();
        }
    }
    
    public class ReturnType {
        public Map<String,Object> Contact = new Map<String, Object>();
        public Map<String,Object> Assessments = new Map<String,Object>();
        public List<Object> Geos = new List<Object>();
        public List<Object> Functions = new List<Object>();
        public List<Object> Sectors = new List<Object>();
        public final List<Object> Deals = new List<Object>();
        public final List<Object> Assignments = new List<Object>();
        public List<Object> FundICMs = null;
        public Attachment Photo;
        public String e;
    }
}