@isTest
public class EQT_BusinessCard_Controller_Test {

    @isTest
    public static void testGetBusinessCardData_WithAssignments() {
        // create contact
        Contact c = createContact('John', 'Doe');
        
        // create accounts
        
        // create projects
         
        // create assignments wo/ project
        EQT_IA_Contract__c agreement1 = EQT_TestFactory.createSampleAgreement(c.id, 'Tier 1', null, false);
        EQT_IA_Contract__c agreement2 = EQT_TestFactory.createSampleAgreement(c.id, 'Tier 1', null, false);
        EQT_IA_Contract__c agreement3 = EQT_TestFactory.createSampleAgreement(c.id, 'Tier 1', 'Active', false);
        EQT_IA_Contract__c agreement4 = EQT_TestFactory.createSampleAgreement(c.id, 'Tier 1', 'Active', false);

        insert new List<EQT_IA_Contract__c>{agreement1, agreement2, agreement3, agreement4};

        // create assignments w/ project
        
        
        
        Test.startTest();
		
		final String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        final JSONParser parser = Json.createParser(s);
        
        
        Test.stopTest();
    }
    
    
    @isTest
    public static void testGetBusinessCardData_WithAffiliations() {
        // create contact
        Contact c = createContact('John', 'Doe');
        
        // create accounts
        
        // create affiliations
        
        
        // create geo ratings for contact
        
        Test.startTest();
		
		final String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        final JSONParser parser = Json.createParser(s);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBusinessCardData_WithGeos() {
        // create contact
        Contact c = createContact('John', 'Doe');
        
        // create region
        
        
        // create countries
        
        // create geo
        
        
        // create geo ratings for contact
        
        Test.startTest();
		
		final String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        final JSONParser parser = Json.createParser(s);
        
        
        Test.stopTest();
    }

    
    @isTest
    public static void testGetBusinessCardData_WithFunctionalTopics() {
        // create contact
        Contact c = createContact('John', 'Doe');
        
        // create functional topics
        EQT_Functional_Topic__c topic1 = new EQT_Functional_Topic__c(Name='Topic1');
        EQT_Functional_Topic__c topic2 = new EQT_Functional_Topic__c(Name='Topic2');
        insert topic1; insert topic2;
        
        // create subtopics
        EQT_Functional_Subtopic__c subtopic1_1 = new EQT_Functional_Subtopic__c(Name='Subtopic1_1', Functional_Topic__c=topic1.id);
        EQT_Functional_Subtopic__c subtopic1_2 = new EQT_Functional_Subtopic__c(Name='Subtopic1_2', Functional_Topic__c=topic1.id);
        insert subtopic1_1; insert subtopic1_2;
        
        // create functional topic ratings for contact
        EQT_Functional_Rating__c rating1 = new EQT_Functional_Rating__c(
            Contact__c=c.Id, 
            Functional_Topic__c=topic1.Id);
        EQT_Functional_Rating__c rating1_1 = new EQT_Functional_Rating__c(
            Contact__c=c.Id, 
            Functional_Topic__c=topic1.Id, 
            Functional_Subtopic__c=subtopic1_1.id);
        EQT_Functional_Rating__c rating1_2 = new EQT_Functional_Rating__c(
            Contact__c=c.Id, 
            Functional_Topic__c=topic1.Id, 
            Functional_Subtopic__c=subtopic1_2.id);
        insert rating1; insert rating1_1; insert rating1_2;
        
        Test.startTest();
		
		final String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        final JSONParser parser = Json.createParser(s);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBusinessCardData_WithSectors() {
        // create contact
        Contact c = createContact('John', 'Doe');
        
        // create sectors
        EQT_Sector__c sector1 = new EQT_Sector__c(Name='Sector1');
        EQT_Sector__c sector2 = new EQT_Sector__c(Name='Sector2');
        insert sector1; insert sector2;
        
        // create subsectors
        EQT_Subsector__c subsector1_1 = new EQT_Subsector__c(Name='Subsector1_1', Sector__c=sector1.Id);
        EQT_Subsector__c subsector1_2 = new EQT_Subsector__c(Name='Subsector1_2', Sector__c=sector1.Id);
        insert subsector1_1; insert subsector1_2;
        
        // crearte subsector segment
        EQT_Subsector_Segment__c segment1_2_1 = new EQT_Subsector_Segment__c(Name='Segment1_2_1', Subsector__c=subsector1_2.Id);
        insert segment1_2_1;
        
        // create sector ratings for contact
        EQT_Sector_Rating__c rating1_1 = new EQT_Sector_Rating__c(
            Contact__c=c.Id, 
            Sector__c=sector1.Id, 
            Subsector__c=subsector1_1.Id);
        EQT_Sector_Rating__c rating1_2_1 = new EQT_Sector_Rating__c(
            Contact__c=c.Id, 
            Sector__c=sector1.Id, 
            Subsector__c=subsector1_2.Id,
        	Subsector_Segment__c=segment1_2_1.Id);
        EQT_Sector_Rating__c rating2 = new EQT_Sector_Rating__c(
            Contact__c=c.Id, 
            Sector__c=sector2.Id);
        insert rating1_2_1; insert rating1_1; insert rating2;
        
        Test.startTest();
		
		final String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        final JSONParser parser = Json.createParser(s);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBusinessCardData_WithAttachment() {
        Contact c = createContact('John', 'Doe');
        Id attachId = EQT_BusinessCard_Controller.savePhoto(c.Id, 'photo.png', pictureBase64, 'image/png');
        
        Test.startTest();
        String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        JSONParser parser = Json.createParser(s);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JsonToken.FIELD_NAME && parser.getText().equals('Attachment')) {
                JSONToken token = parser.nextValue();
                System.assert(null != token);
                Attachment a = (Attachment)parser.readValueAs(Attachment.class);
                System.assertEquals(attachId, a.Id);
            }
        }        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBusinessCardData_NoAttachment() {
        Contact c = createContact('John', 'Doe');
        
        Test.startTest();
        String s = EQT_BusinessCard_Controller.getBusinessCardData(c.Id);
        JSONParser parser = Json.createParser(s);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JsonToken.FIELD_NAME && parser.getText().equals('Attachment')) {
                System.assert(null == parser.nextValue());
            }
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBusinessCardData_UnknownContact() {
        try {
            String s = EQT_BusinessCard_Controller.getBusinessCardData(Id.valueOf('0035800000ArdXAAAZ'));
            s = null;
            s.equals('foo'); // use NPE to signal test fail :(
        } catch (AuraHandledException e) {
            
        }
    }
    
    @isTest
    public static void testSaveCV() {
        EQT_TestFactory.setUpOrg();

        EQT_TestFactory.disableAccountTrigger();

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');
        EQT_TestFactory.setDefaultAccountId(a.Id);

        Contact c = createContact('John', 'Doe');
        
        Test.startTest();
        String attachmentId = EQT_BusinessCard_Controller.saveCVChunk(c.Id, 'cv.pdf', base64v1, 'application/pdf', '', true);
        System.assert(attachmentId != null);
        ContentDocument doc = EQT_BusinessCard_Controller.getContentDocumentForCV(c.Id);
        System.assertEquals('cv.pdf', doc.Title);
        Test.stopTest();
    }

    @isTest
    public static void testSaveCVMultipart() {
        EQT_TestFactory.setUpOrg();

        EQT_TestFactory.disableAccountTrigger();

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');
        EQT_TestFactory.setDefaultAccountId(a.Id);

        Contact c = createContact('John', 'Doe');

        Test.startTest();

        String attachmentId = EQT_BusinessCard_Controller.saveCVChunk(c.Id, 'cv.pdf', base64v1, 'application/pdf', '', false);
        System.assert(attachmentId != null);

        String attachmentId2 = EQT_BusinessCard_Controller.saveCVChunk(c.Id, 'cv.pdf', base64v1, 'application/pdf', attachmentId, true);
        System.assertNotEquals(attachmentId, attachmentId2 );

        ContentDocument doc = EQT_BusinessCard_Controller.getContentDocumentForCV(c.Id);
        System.assertEquals('cv.pdf', doc.Title);
        system.assertEquals(attachmentId2, doc.Id);
        Test.stopTest();
    }

    @isTest
    public static void testCheckCVIdOK() {
        EQT_TestFactory.setUpOrg();

        EQT_TestFactory.disableAccountTrigger();

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'Sample account');
        EQT_TestFactory.setDefaultAccountId(a.Id);

        Contact c = createContact('John', 'Doe');
        
        String attachmentId = EQT_BusinessCard_Controller.saveCVChunk(c.Id, 'cv.pdf', base64v1, 'application/pdf', '', true);
        System.assert(attachmentId != null);
        ContentDocument doc = EQT_BusinessCard_Controller.getContentDocumentForCV(c.Id);
        System.assertEquals('cv.pdf', doc.Title);
        
        Test.startTest();
        
        String res = EQT_BusinessCard_Controller.checkCVId(doc.Id);
        System.assertEquals('OK', res);

        Test.stopTest();
    }

    @isTest
    public static void testCheckCVIdEmpty() {
        Test.startTest();
        
        String res = EQT_BusinessCard_Controller.checkCVId(null);
        System.assertEquals('BAD', res);

        Test.stopTest();
    }

    @isTest
    public static void testSavePhoto() {
        Contact c = createContact('John', 'Doe');
        final Attachment attach = EQT_BusinessCard_Controller.createAttachment(c.Id, 'filename1.png', pictureBase64, 'image/png');
        
        Test.startTest();
        List<Attachment> attachments = EQT_BusinessCard_Controller.getAttachmentsForParentId(c.Id);
        System.assertEquals(1, attachments.size());
        Id photoId = EQT_BusinessCard_Controller.savePhoto(c.ID, 'photo.png', pictureBase64, 'image/png');
        System.assert(null != photoId);
        System.assert(!attach.Id.equals(photoId));
        Test.stopTest();
    }
    
    @isTest
    public static void testDeletePhoto() {
        Contact c = createContact('John', 'Doe');
        Id photoId = EQT_BusinessCard_Controller.savePhoto(c.ID, 'photo.png', pictureBase64, 'image/png');

        Test.startTest();
        EQT_BusinessCard_Controller.deletePhoto(photoId);
        List<Attachment> attachments = EQT_BusinessCard_Controller.getAttachmentsForParentId(c.Id);
        System.assertEquals(0, attachments.size());
        Test.stopTest();
    }

    @isTest
    public static void testGetAttachments_None() {
        Contact c = createContact('John', 'Doe');
        
        Test.startTest();
        List<Attachment> a = EQT_BusinessCard_Controller.getAttachmentsForParentId(c.Id);
        System.assertEquals(0, a.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testGetAttachments_Some() {
        Contact c = createContact('John', 'Doe');
        EQT_BusinessCard_Controller.createAttachment(c.Id, 'filename1.png', pictureBase64, 'image/png');
        
        Test.startTest();
        List<Attachment> a = EQT_BusinessCard_Controller.getAttachmentsForParentId(c.Id);
        System.assertEquals(1, a.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testGetContactDocumentForCV_NoCV() {
        Contact c = createContact('John', 'Doe');
        Test.startTest();
       	
        ContentDocument doc = EQT_BusinessCard_Controller.getContentDocumentForCV(c.Id);
        System.assert(null == doc);
        
        Test.stopTest();
    }

    @isTest
    public static void testIsoDate() {
        Date d = Date.newInstance(2017, 12, 31);
        String s = EQT_BusinessCard_Controller.isoDate(d);
        System.assertEquals('2017-12-31', s);
        
		d = Date.newInstance(2017, 1, 1);
		s = EQT_BusinessCard_Controller.isoDate(d);
        System.assertEquals('2017-01-01', s);
        
        s = EQT_BusinessCard_Controller.isoDate(null);
        System.assert(null == s);
    }
    
    private static Contact createContact(String fn, String ln) {
        Contact c = new Contact(FirstName=fn, LastName=ln);
        insert c;
        return c;
    }
 	
    private final static String pictureBase64 = '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';
    private final static String base64v1 = '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'+
'xAsECwOlJY8wgmKVwskQ2sWKZFNcwZaFRDi5TrbzMTZhj4f4vzGJb+/fqTHI2SD5mw2bNbLNDxUAgYux'+
'qkTf/Piz8lyxpmKOj617WOeP+Gmj5U39tN6GFK6hM6+eG826GxWo1IRvebpu1yEawsfxHshvN+3T+mvS'+
'paFK6R2m1m3GLyq4BFZgK3rl7/ab0cAlkEgdhxNSkjIoCPNqkyFV0IEPuoNkehhTsW5XNTtieqoNR1kv'+
'//t04h5f/MB2y1HSKT8xlJyTXPmr8qTrthLxevkAYbgGMgKYZxhiGClBeZBHey1VN3FklzTo76D3i9OZ'+
'mjbxv1TbcKDS//HvN40ozUHGscFtXwJR0dwnwRWS5lUUee4I6YoF5m1PjXm7IfB0urCe+Mdz/DDP+HMe'+
'4/+v7rht6+Op3SmpvoAPFgIUtOADTamInqYqIZkbIcAW9WmwEQK0El9NabfDEJMXhPlKonOEqtZZBWah'+
'qLAXDxKOsCyrAIZlHMSAqUt/u+FVgF8YLuFTc7Ae+ZpTxws/f/78at/T8nz8aqZKy8sfw/P8UxMefPkZ'+
'jKZp0StqhI6XTVPmNFN0C2NFHy0KA2O4A+k0RNAL1EVW8BTRoJWRHPEP2r0+aI6XkON/XRmnyBuRb79x'+
'+Yf/B6cOzDAKZW5kc3RyZWFtCmVuZG9iago1IDAgb2JqCjU4MTAKZW5kb2JqCjIgMCBvYmoKPDwgL1R5'+
'cGUgL1BhZ2UgL1BhcmVudCAzIDAgUiAvUmVzb3VyY2VzIDYgMCBSIC9Db250ZW50cyA0IDAgUiAvTWVk'+
'aWFCb3ggWzAgMCA1OTUuMjggODQxLjg5XQo+PgplbmRvYmoKNiAwIG9iago8PCAvUHJvY1NldCBbIC9Q'+
'REYgL1RleHQgXSAvQ29sb3JTcGFjZSA8PCAvQ3MxIDcgMCBSID4+IC9Gb250IDw8IC9UVDQgMTEgMCBS'+
'Ci9UVDIgOSAwIFIgPj4gPj4KZW5kb2JqCjEyIDAgb2JqCjw8IC9MZW5ndGggMTMgMCBSIC9OIDMgL0Fs'+
'dGVybmF0ZSAvRGV2aWNlUkdCIC9GaWx0ZXIgL0ZsYXRlRGVjb2RlID4+CnN0cmVhbQp4AZ2Wd1RT2RaH'+
'z703vdASIiAl9Bp6CSDSO0gVBFGJSYBQAoaEJnZEBUYUESlWZFTAAUeHImNFFAuDgmLXCfIQUMbBUURF'+
'5d2MawnvrTXz3pr9x1nf2ee319ln733XugBQ/IIEwnRYAYA0oVgU7uvBXBITy8T3AhgQAQ5YAcDhZmYE'+
'R/hEAtT8vT2ZmahIxrP27i6AZLvbLL9QJnPW/3+RIjdDJAYACkXVNjx+JhflApRTs8UZMv8EyvSVKTKG'+
'MTIWoQmirCLjxK9s9qfmK7vJmJcm5KEaWc4ZvDSejLtQ3pol4aOMBKFcmCXgZ6N8B2W9VEmaAOX3KNPT'+
'+JxMADAUmV/M5yahbIkyRRQZ7onyAgAIlMQ5vHIOi/k5aJ4AeKZn5IoEiUliphHXmGnl6Mhm+vGzU/li'+
'MSuUw03hiHhMz/S0DI4wF4Cvb5ZFASVZbZloke2tHO3tWdbmaPm/2d8eflP9Pch6+1XxJuzPnkGMnlnf'+
'bOysL70WAPYkWpsds76VVQC0bQZA5eGsT+8gAPIFALTenPMehmxeksTiDCcLi+zsbHMBn2suK+g3+5+C'+
'b8q/hjn3mcvu+1Y7phc/gSNJFTNlReWmp6ZLRMzMDA6Xz2T99xD/48A5ac3Jwyycn8AX8YXoVVHolAmE'+
'iWi7hTyBWJAuZAqEf9Xhfxg2JwcZfp1rFGh1XwB9hTlQuEkHyG89AEMjAyRuP3oCfetbEDEKyL68aK2R'+
'r3OPMnr+5/ofC1yKbuFMQSJT5vYMj2RyJaIsGaPfhGzBAhKQB3SgCjSBLjACLGANHIAzcAPeIACEgEgQ'+
'A5YDLkgCaUAEskE+2AAKQTHYAXaDanAA1IF60AROgjZwBlwEV8ANcAsMgEdACobBSzAB3oFpCILwEBWi'+
'QaqQFqQPmULWEBtaCHlDQVA4FAPFQ4mQEJJA+dAmqBgqg6qhQ1A99CN0GroIXYP6oAfQIDQG/QF9hBGY'+
'AtNhDdgAtoDZsDscCEfCy+BEeBWcBxfA2+FKuBY+DrfCF+Eb8AAshV/CkwhAyAgD0UZYCBvxREKQWCQB'+
'ESFrkSKkAqlFmpAOpBu5jUiRceQDBoehYZgYFsYZ44dZjOFiVmHWYkow1ZhjmFZMF+Y2ZhAzgfmCpWLV'+
'saZYJ6w/dgk2EZuNLcRWYI9gW7CXsQPYYew7HA7HwBniHHB+uBhcMm41rgS3D9eMu4Drww3hJvF4vCre'+
'FO+CD8Fz8GJ8Ib4Kfxx/Ht+PH8a/J5AJWgRrgg8hliAkbCRUEBoI5wj9hBHCNFGBqE90IoYQecRcYimx'+
'jthBvEkcJk6TFEmGJBdSJCmZtIFUSWoiXSY9Jr0hk8k6ZEdyGFlAXk+uJJ8gXyUPkj9QlCgmFE9KHEVC'+
'2U45SrlAeUB5Q6VSDahu1FiqmLqdWk+9RH1KfS9HkzOX85fjya2Tq5FrleuXeyVPlNeXd5dfLp8nXyF/'+
'Sv6m/LgCUcFAwVOBo7BWoUbhtMI9hUlFmqKVYohimmKJYoPiNcVRJbySgZK3Ek+pQOmw0iWlIRpC06V5'+
'0ri0TbQ62mXaMB1HN6T705PpxfQf6L30CWUlZVvlKOUc5Rrls8pSBsIwYPgzUhmljJOMu4yP8zTmuc/j'+
'z9s2r2le/7wplfkqbip8lSKVZpUBlY+qTFVv1RTVnaptqk/UMGomamFq2Wr71S6rjc+nz3eez51fNP/k'+
'/IfqsLqJerj6avXD6j3qkxqaGr4aGRpVGpc0xjUZmm6ayZrlmuc0x7RoWgu1BFrlWue1XjCVme7MVGYl'+
's4s5oa2u7act0T6k3as9rWOos1hno06zzhNdki5bN0G3XLdTd0JPSy9YL1+vUe+hPlGfrZ+kv0e/W3/K'+
'wNAg2mCLQZvBqKGKob9hnmGj4WMjqpGr0SqjWqM7xjhjtnGK8T7jWyawiZ1JkkmNyU1T2NTeVGC6z7TP'+
'DGvmaCY0qzW7x6Kw3FlZrEbWoDnDPMh8o3mb+SsLPYtYi50W3RZfLO0sUy3rLB9ZKVkFWG206rD6w9rE'+
'mmtdY33HhmrjY7POpt3mta2pLd92v+19O5pdsN0Wu067z/YO9iL7JvsxBz2HeIe9DvfYdHYou4R91RHr'+
'6OG4zvGM4wcneyex00mn351ZzinODc6jCwwX8BfULRhy0XHhuBxykS5kLoxfeHCh1FXbleNa6/rMTdeN'+
'53bEbcTd2D3Z/bj7Kw9LD5FHi8eUp5PnGs8LXoiXr1eRV6+3kvdi72rvpz46Pok+jT4Tvna+q30v+GH9'+
'Av12+t3z1/Dn+tf7TwQ4BKwJ6AqkBEYEVgc+CzIJEgV1BMPBAcG7gh8v0l8kXNQWAkL8Q3aFPAk1DF0V'+
'+nMYLiw0rCbsebhVeH54dwQtYkVEQ8S7SI/I0shHi40WSxZ3RslHxUXVR01Fe0WXRUuXWCxZs+RGjFqM'+
'IKY9Fh8bFXskdnKp99LdS4fj7OIK4+4uM1yWs+zacrXlqcvPrpBfwVlxKh4bHx3fEP+JE8Kp5Uyu9F+5'+
'd+UE15O7h/uS58Yr543xXfhl/JEEl4SyhNFEl8RdiWNJrkkVSeMCT0G14HWyX/KB5KmUkJSjKTOp0anN'+
'aYS0+LTTQiVhirArXTM9J70vwzSjMEO6ymnV7lUTokDRkUwoc1lmu5iO/kz1SIwkmyWDWQuzarLeZ0dl'+
'n8pRzBHm9OSa5G7LHcnzyft+NWY1d3Vnvnb+hvzBNe5rDq2F1q5c27lOd13BuuH1vuuPbSBtSNnwy0bL'+
'jWUb326K3tRRoFGwvmBos+/mxkK5QlHhvS3OWw5sxWwVbO3dZrOtatuXIl7R9WLL4oriTyXckuvfWX1X'+
'+d3M9oTtvaX2pft34HYId9zd6brzWJliWV7Z0K7gXa3lzPKi8re7V+y+VmFbcWAPaY9kj7QyqLK9Sq9q'+
'R9Wn6qTqgRqPmua96nu37Z3ax9vXv99tf9MBjQPFBz4eFBy8f8j3UGutQW3FYdzhrMPP66Lqur9nf19/'+
'RO1I8ZHPR4VHpcfCj3XVO9TXN6g3lDbCjZLGseNxx2/94PVDexOr6VAzo7n4BDghOfHix/gf754MPNl5'+
'in2q6Sf9n/a20FqKWqHW3NaJtqQ2aXtMe9/pgNOdHc4dLT+b/3z0jPaZmrPKZ0vPkc4VnJs5n3d+8kLG'+
'hfGLiReHOld0Prq05NKdrrCu3suBl69e8blyqdu9+/xVl6tnrjldO32dfb3thv2N1h67npZf7H5p6bXv'+
'bb3pcLP9luOtjr4Ffef6Xfsv3va6feWO/50bA4sG+u4uvnv/Xtw96X3e/dEHqQ9eP8x6OP1o/WPs46In'+
'Ck8qnqo/rf3V+Ndmqb307KDXYM+ziGePhrhDL/+V+a9PwwXPqc8rRrRG6ketR8+M+YzderH0xfDLjJfT'+
'44W/Kf6295XRq59+d/u9Z2LJxPBr0euZP0reqL45+tb2bedk6OTTd2nvpqeK3qu+P/aB/aH7Y/THkens'+
'T/hPlZ+NP3d8CfzyeCZtZubf94Tz+wplbmRzdHJlYW0KZW5kb2JqCjEzIDAgb2JqCjI2MTIKZW5kb2Jq'+
'CjcgMCBvYmoKWyAvSUNDQmFzZWQgMTIgMCBSIF0KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2Vz'+
'IC9NZWRpYUJveCBbMCAwIDU5NS4yOCA4NDEuODldIC9Db3VudCAxIC9LaWRzIFsgMiAwIFIgXSA+Pgpl'+
'bmRvYmoKMTQgMCBvYmoKPDwgL1R5cGUgL0NhdGFsb2cgL1BhZ2VzIDMgMCBSID4+CmVuZG9iagoxMSAw'+
'IG9iago8PCAvVHlwZSAvRm9udCAvU3VidHlwZSAvVHJ1ZVR5cGUgL0Jhc2VGb250IC9QRUZKWFArQ2Fs'+
'aWJyaSAvRm9udERlc2NyaXB0b3IKMTUgMCBSIC9Ub1VuaWNvZGUgMTYgMCBSIC9GaXJzdENoYXIgMzMg'+
'L0xhc3RDaGFyIDcxIC9XaWR0aHMgWyA0MjAgNTI3IDM0OQo0OTggNzk5IDIyNiAyMjkgNTI1IDM5MSA1'+
'MjUgNTI1IDIyOSAzMzUgNDc5IDI1MCA0MjMgNTI1IDQ3MSAyNTIgODU1IDUyNSA2MTUKNjQ2IDUxNyA1'+
'MjUgMzA1IDQ1MiA1NjcgNTI1IDI1MiA0NTkgMjM5IDQzMyA1NzkgNDg4IDY2MiA2NzMgNjQyIDQ1OSBd'+
'ID4+CmVuZG9iagoxNiAwIG9iago8PCAvTGVuZ3RoIDE3IDAgUiAvRmlsdGVyIC9GbGF0ZURlY29kZSA+'+
'PgpzdHJlYW0KeAFdk0Fu2zAQRfc6BZfpIjAtSnYMCAKCBAG8SFvU7QFkkTIE1JIgywvfvu+P0xTo4i0e'+
'h0PPp6nVy/51P/SLW32fx/aQFtf1Q5zTZbzObXLHdOqHbJ272LfLh9lae26mbEXz4XZZ0nk/dKOrqsy5'+
'1Q9aLst8cw/PcTymL1r7Nsc098PJPfx6OdjK4TpNv9M5DYvzWV27mDqOe2+mr805uZW1Pu4j9X65PdL1'+
'b8fP25QcE9Gxvo/UjjFdpqZNczOcUlZ5X1dvb3WWhvhfKezuHcfuY2u+rivhfdHWWZXnKHi/6aQBBe+3'+
'ubRAgWopLVFAo3SDgvd+J92iQNX0CQWO8qruUECDtEEBtZOPKNBbqNqigNqQEQU2WzWhQHWtzR0K3tOS'+
'VYG7EFT1Q4GsAk1Ssgp0KyWroNeqZA2Wt1DAQFbBZt1GIKvg6jRGIKtArZeswfKWyhvIKphZQwayCo7a'+
'SMkqqJqSNVje0pSswfJunrSZrIIf0sUGsgrvSwUsyCo4uZGSVXCyeguyCno1RkFWgerayWGg+vdZMzjZ'+
'NpO1sLylbSZrcc/LkDy1v29Kr05fx+drbq/zzEO2T8jeuN5uP6TPr2waJx1g/AFDbOs2CmVuZHN0cmVh'+
'bQplbmRvYmoKMTcgMCBvYmoKNDYyCmVuZG9iagoxNSAwIG9iago8PCAvVHlwZSAvRm9udERlc2NyaXB0'+
'b3IgL0ZvbnROYW1lIC9QRUZKWFArQ2FsaWJyaSAvRmxhZ3MgNCAvRm9udEJCb3ggWy01MDMgLTMwNyAx'+
'MjQwIDEwMjZdCi9JdGFsaWNBbmdsZSAwIC9Bc2NlbnQgOTUyIC9EZXNjZW50IC0yNjkgL0NhcEhlaWdo'+
'dCA2NDQgL1N0ZW1WIDAgL1hIZWlnaHQKNDc2IC9BdmdXaWR0aCA1MjEgL01heFdpZHRoIDEzMjggL0Zv'+
'bnRGaWxlMiAxOCAwIFIgPj4KZW5kb2JqCjE4IDAgb2JqCjw8IC9MZW5ndGggMTkgMCBSIC9MZW5ndGgx'+
'IDYzMjQgL0ZpbHRlciAvRmxhdGVEZWNvZGUgPj4Kc3RyZWFtCngBnVh5dFzVeb/v3TdvmRnNzJs3b1bN'+
'vmuXZiRZ20iy9t2yZEleZO3esGRbkrGNjTG2cQqGOsSqQSyJSYtZYhtwoEAhJW05h+UUSklMWprj8EcJ'+
'UKBpSVKKbY363Vlk2SYnOX3nvLnv3vfmfr/7Lb/vu3d2evcE4tEhhBEamxzZiRIX9b/QbNq8fd+mZJ9+'+
'HiH50paJkfFkH12FtmQLDCT7VBRa35bJ2b2p/gC0p7fvGEu9p4ehv3pyZG9qfvRL6LumRiYnoIXLPAc/'+
'LsS+UYtC79eiX0Zr0fQjyWfS+p6qRQ+WJvukvXpX8hvSku9nj197R74n/ycXBXeIciEd+gfEIRrafHSM'+
'vICLgbfkPUufMITfHB/SVv4eWfjEq1c+P/CP5OGf73u76crlhePCF3wJdAWYIXnB/7jvL3yIkPL0lcuX'+
'TwtfJGZKvUw0IUYD4v8JxDyGvMwX6Cz+FO5z6CzNQDuIzrK/QGcVWXC3ozHGA+0oGoP3TQoPepq5B3nw'+
'RbSBiaJ5PIrWQTuMr6BBehfy49dRMRmnPkB3Uf+xeBHaeXYczZMxZkXiW/I8TL8N/3Wjbvo8ckN/Dj8K'+
'c+5BYWoRZdEK9ACgTK4fITViEbGXGwVBS3bkQgZkg7dm5IAxL5KQFXlAdwGkR5nICF/xSAR/EZAKOZGM'+
'fEiLTDBHBrIgP+iIQUqYU4MUKYXMoln0Y/TvlJ8apo5Q52iG3kCfon+Gg/gYfh0vMn3MOeZ3igbFCcVH'+
'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'+
'lVz8OaoLGsyoDNr4RkCWFb9EzaCP4AQ4cSLHcUn+KJXSxEHNsBqTeLciQ7JIoklJMXepzD6rxWdSnXBG'+
'83It73JK4CpIt5R0yObSsazORXT/wOLX1BTMqyLzLqsipvJjlXnknmzKz2uAG853yfd6uMnFwkkyWtXQ'+
'2DqwKrtuZPvW0emt/wdoG5hQCmVuZHN0cmVhbQplbmRvYmoKMTkgMCBvYmoKNDMwMQplbmRvYmoKOSAw'+
'IG9iago8PCAvVHlwZSAvRm9udCAvU3VidHlwZSAvVHJ1ZVR5cGUgL0Jhc2VGb250IC9CUFFGS0UrQ2Fs'+
'aWJyaS1MaWdodCAvRm9udERlc2NyaXB0b3IKMjAgMCBSIC9Ub1VuaWNvZGUgMjEgMCBSIC9GaXJzdENo'+
'YXIgMzMgL0xhc3RDaGFyIDQxIC9XaWR0aHMgWyA0NTMgNDcxIDc5MQo1MjAgMjIxIDQ5NCAyMjYgNTM1'+
'IDU1NCBdID4+CmVuZG9iagoyMSAwIG9iago8PCAvTGVuZ3RoIDIyIDAgUiAvRmlsdGVyIC9GbGF0ZURl'+
'Y29kZSA+PgpzdHJlYW0KeAFdkc1qwzAQhO96Ch3TQ/DaiZ0GjKGkBHzoD3X7AI60DoJaFrJy8Nt3pKQp'+
'9DCHb1djjcbZoX1urQkye/eT6jjIwVjteZ4uXrE88dlYkRdSGxVulGZq7J3IYO6WOfDY2mGSdS2kzD5g'+
'mYNf5OpJTyd+iLM3r9kbe5arr0OXJt3FuW8e2QZJommk5gGfe+ndaz+yzJJ13WrsTVjWcP2d+FwcSySC'+
'I79GUpPm2fWKfW/PLGqipj4eG8FW/1vtr4bTcDtZ5E0dRVRuGlEXBRAiqvKIGyAE1BG3QIhoRxFLIISt'+
'ilgBIWAZcQeEiGgf8REIEW3TRXsghHurlPM3UYwcq71XoS7eo4XUfyooPtxYvv8iN7n40KQfvDiI/wpl'+
'bmRzdHJlYW0KZW5kb2JqCjIyIDAgb2JqCjI4MwplbmRvYmoKMjAgMCBvYmoKPDwgL1R5cGUgL0ZvbnRE'+
'ZXNjcmlwdG9yIC9Gb250TmFtZSAvQlBRRktFK0NhbGlicmktTGlnaHQgL0ZsYWdzIDQgL0ZvbnRCQm94'+
'ClstNTExIC0yNjkgMTIwOSA5NTJdIC9JdGFsaWNBbmdsZSAwIC9Bc2NlbnQgOTUyIC9EZXNjZW50IC0y'+
'NjkgL0NhcEhlaWdodCA2NDMKL1N0ZW1WIDAgL1hIZWlnaHQgNDczIC9BdmdXaWR0aCA1MjAgL01heFdp'+
'ZHRoIDEzMjggL0ZvbnRGaWxlMiAyMyAwIFIgPj4KZW5kb2JqCjIzIDAgb2JqCjw8IC9MZW5ndGggMjQg'+
'MCBSIC9MZW5ndGgxIDE5NTYgL0ZpbHRlciAvRmxhdGVEZWNvZGUgPj4Kc3RyZWFtCngBZVRdUBNXFL67'+
'd/du2CQbN8luwMhPIIQEBJVsgkAI4ScQTERsIKIIGBAEJfyJFcUq2tqK1o7VhzrWWsdph2m10/ri2E59'+
'qU5r23G0fXR86FNnfKrTHx/kr/dmgz/tnbl79tx77rnfOec7d2J8Xx/QgGkAAehNxEdBclDTWBTuGjrQ'+
'n9LvAMDeHOiL71R1MI+ldwAvpPYVLO0DiYnJlN6OpXNopHd5/xrW5UR8MuUfPMJ6znA80afac4eIPUA/'+
'1ADnrzXgkVIDxi+q/0TaP6sB58tUncj546oNkcR+4tSLPWJPzpNB4cmDmzi+B3jSYAVYA1IRYZ1K7tOe'+
'27fXn9vUbfD9A6ya5LEfH32UxPnL6Z9ic48XHqZd5S7hjTTsQR3YL3dp4SF2fnnu8fzutKtJT6nNpOAZ'+
'AZRQ9wFgQmAP/BhEmBHghHfAAPwbDFB3wCxqBbOME8xiaxUHADqAwCqs2/BNELAYYRrg8BqF72VSzkfB'+
'KPiWslJt1DXqKZ1BH6dJJhlQAgC8xwr4HAfKwUbsVLSJyWkWaI4zo7zcEtpToHjd7lI/7VEcebkCnVxT'+
'vGV+6C7NoiG2VFf8dFK/Nx+H0fmn9FF7TbvCyhIv8CyzUjKvq3GK7T0F1WtzOMixkNVwzrI6W7C/Lvc3'+
'JFhEY7oBIUO6UbQIiBWe/ckKc+uZY3OHoezrCuRRn2s4mmGZuxbJWhKwt2wXJRGmGXQ6k4YzGfWO2m0L'+
'h5Y9pCTJ0J6lvxgda8WxgXyzoEajJHEiKYWbRCSZszB2FT+joxnOFIgfjhz8/lS45f2fpyoS25usHEND'+
'jucEd3Qy2nE+UbV+98XezQdiZQakYeFXWqOgMxUVZrV98uTCpbkvO+Xc1VadwaQTJIPGVepqeu/BO0fv'+
'zoTwL6uXMa7I0h8wwmaDJgxSxcF4VFxJHB6lBKX0/+JEMOIfvdDhH45VyjzDaZHg3jwWrurf4FLahsaG'+
'2hRvz8xrrtZwpYnFiFEa0hbXd/kq2ysylVhiLBFTqK7Yie5SS47Nkm0RZYHNc+XZ/B0VvliNx+OPjm4M'+
'74+uXpGRbUoTTIIew8+0Z+aUbXD5YrUeT1V0hGTVufSMaWTNwI6zKkBcfKaAcqjZs1BuivBClhFHH4c6'+
'k1XUmVfoeEQvBhElrLKYLHoOUmcp6m0aGVZKFquWQrJGiyAFGaRBzH2DiYcQ8dzcaWYvxyPI8EYDZvIA'+
'zpgNfgfcIEBqiXAtHQ6Ph0jMUJI7N84aZuJzNjKEjRKn1ld2l3rLoE0vGcV0fdW5TY1jzYX+8cs9Z9K9'+
'Mb9vR2gNj6+EKCMQ3bG2c3pT7v5PQ0OhvN5tjVNBM69lWS3fVxvKD/ZUhUc25DdXbPVl4bwwWlEnZWTk'+
'ZhqLW6eav15Z2lDc3NkUSaGdwWiLAH7hKNxGtpcYhpn3AjXBWOB1EJQcnHEYFz6wRQ5urd7ZRBAhiEvI'+
'K60jgcErw+WVwx9295/pLJqCJ9+q39XogDRnt7aeiCuyVUZ6s4HTa3k+I8NcPXVjcu+NI3X1e8+3as9c'+
'cbeO+EjVZpeeUVnsOJCSvaD2rJginURlIb2F9B7Lkl606JEZX88w+MPWk9Rg8qOUF/Y6jqzlFS8k8YgT'+
'l58CMVmJVxZUekiS10vKYlHfDom9jq/F1wmsZV3YXX10I1EJivSkGnkBShJFWcc2vxss31q/1rAmGm7I'+
'bdvXmP0cJV0cGAy7eroX9i/j/v8KnFmOZHpLs3VdvUtpLDL5+k+Qis0unoO3cFyFoIpUTGVRwUsRLQeg'+
'IudSXONEGVPLT8Nb7t6zXc6Gurr855hx9xhwqQsjkZbinpNbCt5IL+8O2YOh5qLwTDjY68+kfp/45lij'+
'aPc6FouXkTFPCOlJA7xZVF1oDh/7Yl/k9HCtuaTJu/h6R7wuMUOedAoY8SQDATMAtS2bG8LBorr40GDP'+
'+GBxZHDXwAQA/wLPHWPmCmVuZHN0cmVhbQplbmRvYmoKMjQgMCBvYmoKMTQ2NgplbmRvYmoKMjUgMCBv'+
'YmoKKP7/XDAwMFNcMDAwYVwwMDBtXDAwMHBcMDAwbFwwMDBlXDAwMCBcMDAwQ1wwMDBWXDAwMCBcMDAw'+
'5lwwMDD4XDAwMOVcMDAwxlwwMDDYXDAwMMVcMDAwLlwwMDBwXDAwMGRcMDAwZikKZW5kb2JqCjI2IDAg'+
'b2JqCihNYWMgT1MgWCAxMC4xMi4zIFF1YXJ0eiBQREZDb250ZXh0KQplbmRvYmoKMjcgMCBvYmoKKCkK'+
'ZW5kb2JqCjI4IDAgb2JqCigpCmVuZG9iagoyOSAwIG9iagooV29yZCkKZW5kb2JqCjMwIDAgb2JqCihE'+
'OjIwMTcwMzIzMTAwNzMyWjAwJzAwJykKZW5kb2JqCjMxIDAgb2JqCigpCmVuZG9iagozMiAwIG9iagpb'+
'IF0KZW5kb2JqCjEgMCBvYmoKPDwgL1RpdGxlIDI1IDAgUiAvQXV0aG9yIDI3IDAgUiAvU3ViamVjdCAy'+
'OCAwIFIgL1Byb2R1Y2VyIDI2IDAgUiAvQ3JlYXRvcgoyOSAwIFIgL0NyZWF0aW9uRGF0ZSAzMCAwIFIg'+
'L01vZERhdGUgMzAgMCBSIC9LZXl3b3JkcyAzMSAwIFIgL0FBUEw6S2V5d29yZHMKMzIgMCBSID4+CmVu'+
'ZG9iagp4cmVmCjAgMzMKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDE3MjkwIDAwMDAwIG4gCjAwMDAw'+
'MDU5MjYgMDAwMDAgbiAKMDAwMDAwODkxNyAwMDAwMCBuIAowMDAwMDAwMDIyIDAwMDAwIG4gCjAwMDAw'+
'MDU5MDYgMDAwMDAgbiAKMDAwMDAwNjAzNiAwMDAwMCBuIAowMDAwMDA4ODgxIDAwMDAwIG4gCjAwMDAw'+
'MDAwMDAgMDAwMDAgbiAKMDAwMDAxNDU3NyAwMDAwMCBuIAowMDAwMDAwMDAwIDAwMDAwIG4gCjAwMDAw'+
'MDkwNTYgMDAwMDAgbiAKMDAwMDAwNjE0NSAwMDAwMCBuIAowMDAwMDA4ODYwIDAwMDAwIG4gCjAwMDAw'+
'MDkwMDYgMDAwMDAgbiAKMDAwMDAwOTkyOSAwMDAwMCBuIAowMDAwMDA5MzcxIDAwMDAwIG4gCjAwMDAw'+
'MDk5MDkgMDAwMDAgbiAKMDAwMDAxMDE2NSAwMDAwMCBuIAowMDAwMDE0NTU2IDAwMDAwIG4gCjAwMDAw'+
'MTUxNTYgMDAwMDAgbiAKMDAwMDAxNDc3NyAwMDAwMCBuIAowMDAwMDE1MTM2IDAwMDAwIG4gCjAwMDAw'+
'MTUzOTcgMDAwMDAgbiAKMDAwMDAxNjk1MyAwMDAwMCBuIAowMDAwMDE2OTc0IDAwMDAwIG4gCjAwMDAw'+
'MTcwOTUgMDAwMDAgbiAKMDAwMDAxNzE0OCAwMDAwMCBuIAowMDAwMDE3MTY3IDAwMDAwIG4gCjAwMDAw'+
'MTcxODYgMDAwMDAgbiAKMDAwMDAxNzIwOSAwMDAwMCBuIAowMDAwMDE3MjUxIDAwMDAwIG4gCjAwMDAw'+
'MTcyNzAgMDAwMDAgbiAKdHJhaWxlcgo8PCAvU2l6ZSAzMyAvUm9vdCAxNCAwIFIgL0luZm8gMSAwIFIg'+
'L0lEIFsgPGVhMjI5ZmNmNmY5MmVjMjcxZTk0NTM0NDRiMjg2NGE3Pgo8ZWEyMjlmY2Y2ZjkyZWMyNzFl'+
'OTQ1MzQ0NGIyODY0YTc+IF0gPj4Kc3RhcnR4cmVmCjE3NDY1CiUlRU9GCg==';
    private static final String base64v2 = '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'+
'IR3/b+I8/ykiqnt5DByFn3NeOCffWzZ8D19aYurnlr2nU46gxSHit6w0A8gXdhE8j0ktjLq7s16tkGhH'+
'SFRX1L0JuwILkjEioLAnOhMSjDCniRquW3EqVskvWCQMJDFL2gyrurQmmRMilJyAhHSM5J8udXAyIfFk'+
'OQRrERu2fiTmg2d0j+6nG0FNh2XZem5vYXC+rTfy574ymxDG9CBPWjkEzPah+IPF63KNVurdDlfbc56J'+
'dv91mk/rr0TXzXEhLAWlF6lyGXdtlEj+q7k6gtS/4+udrBVIWNzNiTcQlXiOidfyvVjhDnzQEyhTCDno'+
'reUV6hutykn/v+bLccsoyO50FCyhwKk5glgRXekrzDTuUkJ+w5lfALMG7R3GRjnoyCQ+5BJXcomD/jb3'+
'fnIj08LmZN+LX/y9irurj/7P+eYcGMSPgefpX3d9+IzbBmx8KPpRa3WKX4MkHBH0BEnW/Sj4hlalXTsB'+
'Gj1tPfBLw8tqxFs/zuBuOuxtLVNaHQZQuAUfKCbl6GmL8YQhzeXpgK0BkjNEgFbkmyiLx6F8RM4jqS1g'+
'tm9aSryFpEI/HyTcZSRZczCTjMsXfM5Tf252LUwX8bmlsG75FlP2W/MbrxOVWlZ/+y64qWQINxeD7rhC'+
'q0Nvk2G60BUUoDgLHyKMDX2cQauYwxOWa4qgF6iLXsEqrEHlJTryP9zu+eWyvSJs/+3I8l+e3IZ8PN39'+
'8f8AkBe42QplbmRzdHJlYW0KZW5kb2JqCjUgMCBvYmoKNTg2OQplbmRvYmoKMiAwIG9iago8PCAvVHlw'+
'ZSAvUGFnZSAvUGFyZW50IDMgMCBSIC9SZXNvdXJjZXMgNiAwIFIgL0NvbnRlbnRzIDQgMCBSIC9NZWRp'+
'YUJveCBbMCAwIDU5NS4yOCA4NDEuODldCj4+CmVuZG9iago2IDAgb2JqCjw8IC9Qcm9jU2V0IFsgL1BE'+
'RiAvVGV4dCBdIC9Db2xvclNwYWNlIDw8IC9DczEgNyAwIFIgPj4gL0ZvbnQgPDwgL1RUNCAxMSAwIFIK'+
'L1RUMiA5IDAgUiA+PiA+PgplbmRvYmoKMTIgMCBvYmoKPDwgL0xlbmd0aCAxMyAwIFIgL04gMyAvQWx0'+
'ZXJuYXRlIC9EZXZpY2VSR0IgL0ZpbHRlciAvRmxhdGVEZWNvZGUgPj4Kc3RyZWFtCngBnZZ3VFPZFofP'+
'vTe90BIiICX0GnoJINI7SBUEUYlJgFAChoQmdkQFRhQRKVZkVMABR4ciY0UUC4OCYtcJ8hBQxsFRREXl'+
'3YxrCe+tNfPemv3HWd/Z57fX2Wfvfde6AFD8ggTCdFgBgDShWBTu68FcEhPLxPcCGBABDlgBwOFmZgRH'+
'+EQC1Py9PZmZqEjGs/buLoBku9ssv1Amc9b/f5EiN0MkBgAKRdU2PH4mF+UClFOzxRky/wTK9JUpMoYx'+
'MhahCaKsIuPEr2z2p+Yru8mYlybkoRpZzhm8NJ6Mu1DemiXho4wEoVyYJeBno3wHZb1USZoA5fco09P4'+
'nEwAMBSZX8znJqFsiTJFFBnuifICAAiUxDm8cg6L+TlongB4pmfkigSJSWKmEdeYaeXoyGb68bNT+WIx'+
'K5TDTeGIeEzP9LQMjjAXgK9vlkUBJVltmWiR7a0c7e1Z1uZo+b/Z3x5+U/09yHr7VfEm7M+eQYyeWd9s'+
'7KwvvRYA9iRamx2zvpVVALRtBkDl4axP7yAA8gUAtN6c8x6GbF6SxOIMJwuL7OxscwGfay4r6Df7n4Jv'+
'yr+GOfeZy+77VjumFz+BI0kVM2VF5aanpktEzMwMDpfPZP33EP/jwDlpzcnDLJyfwBfxhehVUeiUCYSJ'+
'aLuFPIFYkC5kCoR/1eF/GDYnBxl+nWsUaHVfAH2FOVC4SQfIbz0AQyMDJG4/egJ961sQMQrIvrxorZGv'+
'c48yev7n+h8LXIpu4UxBIlPm9gyPZHIloiwZo9+EbMECEpAHdKAKNIEuMAIsYA0cgDNwA94gAISASBAD'+
'lgMuSAJpQASyQT7YAApBMdgBdoNqcADUgXrQBE6CNnAGXARXwA1wCwyAR0AKhsFLMAHegWkIgvAQFaJB'+
'qpAWpA+ZQtYQG1oIeUNBUDgUA8VDiZAQkkD50CaoGCqDqqFDUD30I3Qaughdg/qgB9AgNAb9AX2EEZgC'+
'02EN2AC2gNmwOxwIR8LL4ER4FZwHF8Db4Uq4Fj4Ot8IX4RvwACyFX8KTCEDICAPRRlgIG/FEQpBYJAER'+
'IWuRIqQCqUWakA6kG7mNSJFx5AMGh6FhmBgWxhnjh1mM4WJWYdZiSjDVmGOYVkwX5jZmEDOB+YKlYtWx'+
'plgnrD92CTYRm40txFZgj2BbsJexA9hh7DscDsfAGeIccH64GFwybjWuBLcP14y7gOvDDeEm8Xi8Kt4U'+
'74IPwXPwYnwhvgp/HH8e348fxr8nkAlaBGuCDyGWICRsJFQQGgjnCP2EEcI0UYGoT3QihhB5xFxiKbGO'+
'2EG8SRwmTpMUSYYkF1IkKZm0gVRJaiJdJj0mvSGTyTpkR3IYWUBeT64knyBfJQ+SP1CUKCYUT0ocRULZ'+
'TjlKuUB5QHlDpVINqG7UWKqYup1aT71EfUp9L0eTM5fzl+PJrZOrkWuV65d7JU+U15d3l18unydfIX9K'+
'/qb8uAJRwUDBU4GjsFahRuG0wj2FSUWaopViiGKaYolig+I1xVElvJKBkrcST6lA6bDSJaUhGkLTpXnS'+
'uLRNtDraZdowHUc3pPvTk+nF9B/ovfQJZSVlW+Uo5RzlGuWzylIGwjBg+DNSGaWMk4y7jI/zNOa5z+PP'+
'2zavaV7/vCmV+SpuKnyVIpVmlQGVj6pMVW/VFNWdqm2qT9QwaiZqYWrZavvVLquNz6fPd57PnV80/+T8'+
'h+qwuol6uPpq9cPqPeqTGpoavhoZGlUalzTGNRmabprJmuWa5zTHtGhaC7UEWuVa57VeMJWZ7sxUZiWz'+
'izmhra7tpy3RPqTdqz2tY6izWGejTrPOE12SLls3Qbdct1N3Qk9LL1gvX69R76E+UZ+tn6S/R79bf8rA'+
'0CDaYItBm8GooYqhv2GeYaPhYyOqkavRKqNaozvGOGO2cYrxPuNbJrCJnUmSSY3JTVPY1N5UYLrPtM8M'+
'a+ZoJjSrNbvHorDcWVmsRtagOcM8yHyjeZv5Kws9i1iLnRbdFl8s7SxTLessH1kpWQVYbbTqsPrD2sSa'+
'a11jfceGauNjs86m3ea1rakt33a/7X07ml2w3Ra7TrvP9g72Ivsm+zEHPYd4h70O99h0dii7hH3VEevo'+
'4bjO8YzjByd7J7HTSaffnVnOKc4NzqMLDBfwF9QtGHLRceG4HHKRLmQujF94cKHUVduV41rr+sxN143n'+
'dsRtxN3YPdn9uPsrD0sPkUeLx5Snk+cazwteiJevV5FXr7eS92Lvau+nPjo+iT6NPhO+dr6rfS/4Yf0C'+
'/Xb63fPX8Of61/tPBDgErAnoCqQERgRWBz4LMgkSBXUEw8EBwbuCHy/SXyRc1BYCQvxDdoU8CTUMXRX6'+
'cxguLDSsJux5uFV4fnh3BC1iRURDxLtIj8jSyEeLjRZLFndGyUfFRdVHTUV7RZdFS5dYLFmz5EaMWowg'+
'pj0WHxsVeyR2cqn30t1Lh+Ps4grj7i4zXJaz7NpyteWpy8+ukF/BWXEqHhsfHd8Q/4kTwqnlTK70X7l3'+
'5QTXk7uH+5LnxivnjfFd+GX8kQSXhLKE0USXxF2JY0muSRVJ4wJPQbXgdbJf8oHkqZSQlKMpM6nRqc1p'+
'hLT4tNNCJWGKsCtdMz0nvS/DNKMwQ7rKadXuVROiQNGRTChzWWa7mI7+TPVIjCSbJYNZC7Nqst5nR2Wf'+
'ylHMEeb05JrkbssdyfPJ+341ZjV3dWe+dv6G/ME17msOrYXWrlzbuU53XcG64fW+649tIG1I2fDLRsuN'+
'ZRvfbore1FGgUbC+YGiz7+bGQrlCUeG9Lc5bDmzFbBVs7d1ms61q25ciXtH1YsviiuJPJdyS699ZfVf5'+
'3cz2hO29pfal+3fgdgh33N3puvNYmWJZXtnQruBdreXM8qLyt7tX7L5WYVtxYA9pj2SPtDKosr1Kr2pH'+
'1afqpOqBGo+a5r3qe7ftndrH29e/321/0wGNA8UHPh4UHLx/yPdQa61BbcVh3OGsw8/rouq6v2d/X39E'+
'7Ujxkc9HhUelx8KPddU71Nc3qDeUNsKNksax43HHb/3g9UN7E6vpUDOjufgEOCE58eLH+B/vngw82XmK'+
'farpJ/2f9rbQWopaodbc1om2pDZpe0x73+mA050dzh0tP5v/fPSM9pmas8pnS8+RzhWcmzmfd37yQsaF'+
'8YuJF4c6V3Q+urTk0p2usK7ey4GXr17xuXKp2737/FWXq2euOV07fZ19ve2G/Y3WHruell/sfmnpte9t'+
'velws/2W462OvgV95/pd+y/e9rp95Y7/nRsDiwb67i6+e/9e3D3pfd790QepD14/zHo4/Wj9Y+zjoicK'+
'Tyqeqj+t/dX412apvfTsoNdgz7OIZ4+GuEMv/5X5r0/DBc+pzytGtEbqR61Hz4z5jN16sfTF8MuMl9Pj'+
'hb8p/rb3ldGrn353+71nYsnE8GvR65k/St6ovjn61vZt52To5NN3ae+mp4req74/9oH9oftj9MeR6exP'+
'+E+Vn40/d3wJ/PJ4Jm1m5t/3hPP7CmVuZHN0cmVhbQplbmRvYmoKMTMgMCBvYmoKMjYxMgplbmRvYmoK'+
'NyAwIG9iagpbIC9JQ0NCYXNlZCAxMiAwIFIgXQplbmRvYmoKMyAwIG9iago8PCAvVHlwZSAvUGFnZXMg'+
'L01lZGlhQm94IFswIDAgNTk1LjI4IDg0MS44OV0gL0NvdW50IDEgL0tpZHMgWyAyIDAgUiBdID4+CmVu'+
'ZG9iagoxNCAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMyAwIFIgPj4KZW5kb2JqCjExIDAg'+
'b2JqCjw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UcnVlVHlwZSAvQmFzZUZvbnQgL0FTSFJTRStDYWxp'+
'YnJpIC9Gb250RGVzY3JpcHRvcgoxNSAwIFIgL1RvVW5pY29kZSAxNiAwIFIgL0ZpcnN0Q2hhciAzMyAv'+
'TGFzdENoYXIgNzEgL1dpZHRocyBbIDQyMCA1MjcgMzQ5CjQ5OCA3OTkgMjI2IDIyOSA1MjUgMzkxIDUy'+
'NSA1MjUgMjI5IDMzNSA0NzkgMjUwIDQyMyA1MjUgNDcxIDI1MiA4NTUgNTI1IDYxNQo2NDYgNTE3IDUy'+
'NSAzMDUgNDUyIDU2NyA1MjUgMjUyIDQ1OSAyMzkgNDMzIDU3OSA0ODggNjYyIDY3MyA2NDIgNDU5IF0g'+
'Pj4KZW5kb2JqCjE2IDAgb2JqCjw8IC9MZW5ndGggMTcgMCBSIC9GaWx0ZXIgL0ZsYXRlRGVjb2RlID4+'+
'CnN0cmVhbQp4AV2TQW7bMBBF9zoFl+kiMC1KdgwIAoIEAbxIW9TtAWSRMgTUkiDLC9++74/TFOjiLR6H'+
'Q8+nqdXL/nU/9ItbfZ/H9pAW1/VDnNNlvM5tcsd06odsnbvYt8uH2Vp7bqZsRfPhdlnSeT90o6uqzLnV'+
'D1ouy3xzD89xPKYvWvs2xzT3w8k9/Ho52MrhOk2/0zkNi/NZXbuYOo57b6avzTm5lbU+7iP1frk90vVv'+
'x8/blBwT0bG+j9SOMV2mpk1zM5xSVnlfV29vdZaG+F8p7O4dx+5ja76uK+F90dZZlecoeL/ppAEF77e5'+
'tECBaiktUUCjdIOC934n3aJA1fQJBY7yqu5QQIO0QQG1k48o0Fuo2qKA2pARBTZbNaFAda3NHQre05JV'+
'gbsQVPVDgawCTVKyCnQrJaug16pkDZa3UMBAVsFm3UYgq+DqNEYgq0Ctl6zB8pbKG8gqmFlDBrIKjtpI'+
'ySqompI1WN7SlKzB8m6etJmsgh/SxQayCu9LBSzIKji5kZJVcLJ6C7IKejVGQVaB6trJYaD691kzONk2'+
'k7WwvKVtJmtxz8uQPLW/b0qvTl/H52tur/PMQ7ZPyN643m4/pM+vbBonHWD8AUNs6zYKZW5kc3RyZWFt'+
'CmVuZG9iagoxNyAwIG9iago0NjIKZW5kb2JqCjE1IDAgb2JqCjw8IC9UeXBlIC9Gb250RGVzY3JpcHRv'+
'ciAvRm9udE5hbWUgL0FTSFJTRStDYWxpYnJpIC9GbGFncyA0IC9Gb250QkJveCBbLTUwMyAtMzA3IDEy'+
'NDAgMTAyNl0KL0l0YWxpY0FuZ2xlIDAgL0FzY2VudCA5NTIgL0Rlc2NlbnQgLTI2OSAvQ2FwSGVpZ2h0'+
'IDY0NCAvU3RlbVYgMCAvWEhlaWdodAo0NzYgL0F2Z1dpZHRoIDUyMSAvTWF4V2lkdGggMTMyOCAvRm9u'+
'dEZpbGUyIDE4IDAgUiA+PgplbmRvYmoKMTggMCBvYmoKPDwgL0xlbmd0aCAxOSAwIFIgL0xlbmd0aDEg'+
'NjMyNCAvRmlsdGVyIC9GbGF0ZURlY29kZSA+PgpzdHJlYW0KeAGdWHl0XNV5v+/dN2+ZGc3MmzdvVs2+'+
'a5dmJFnbSLL23bJkSV5k7d6wZFuSsY2NMbZxCoY6xKpBLIlJi1liG3CgQCElbTmH5RRKSUxamuPwRwlQ'+
'oGlJUoptjfrdWWTZJic5fee8ue/e9+Z+v/stv++7d3Z69wTi0SGEERqbHNmJEhf1v9Bs2rx936Zkn34e'+
'IfnSlomR8WQfXYW2ZAsMJPtUFFrflsnZvan+ALSnt+8YS72nh6G/enJkb2p+9Evou6ZGJieghcs8Bz8u'+
'xL5Ri0Lv16JfRmvR9CPJZ9L6nqpFD5Ym+6S9elfyG9KS72ePX3tHvif/JxcFd4hyIR36B8QhGtp8dIy8'+
'gIuBt+Q9S58whN8cH9JW/h5Z+MSrVz4/8I/k4Z/ve7vpyuWF48IXfAl0BZghecH/uO8vfIiQ8vSVy5dP'+
'C18kZkq9TDQhRgPi/wnEPIa8zBfoLP4U7nPoLM1AO4jOsr9AZxVZcLejMcYD7Sgag/dNCg96mrkHefBF'+
'tIGJonk8itZBO4yvoEF6F/Lj11ExGac+QHdR/7F4Edp5dhzNkzFmReJb8jxMvw3/daNu+jxyQ38OPwpz'+
'7kFhahFl0Qr0AKBMrh8hNWIRsZcbBUFLduRCBmSDt2bkgDEvkpAVeUB3AaRHmcgIX/FIBH8RkAo5kYx8'+
'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'+
'F4xK9sDZnkgJlDn+NU9JQZfda1Ay77zHKEWnze7X00L8mxyNpFZAYclRE/GHocEKtaShXqSe0EgZDGaV'+
'XPw5qgsazKgM2vhGQJYVv0TNoI/gBDhxIsdxSf4oldLEQc2wGpN4tyJDskiiSUkxd6nMPqvFZ1KdcEbz'+
'ci3vckrgKki3lHTI5tKxrM5FdP/A4tfUFMyrIvMuqyKm8mOVeeSebMrPa4AbznfJ93q4ycXCSTKq7Wle'+
'3dOQXTeyfevo9Nb/A2famEkKZW5kc3RyZWFtCmVuZG9iagoxOSAwIG9iago0MzAxCmVuZG9iago5IDAg'+
'b2JqCjw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UcnVlVHlwZSAvQmFzZUZvbnQgL0hPSEZaTitDYWxp'+
'YnJpLUxpZ2h0IC9Gb250RGVzY3JpcHRvcgoyMCAwIFIgL1RvVW5pY29kZSAyMSAwIFIgL0ZpcnN0Q2hh'+
'ciAzMyAvTGFzdENoYXIgNDIgL1dpZHRocyBbIDQ1MyA0NzEgNzkxCjUyMCAyMjEgNDk0IDIyNiA1MzUg'+
'NTU0IDUwNyBdID4+CmVuZG9iagoyMSAwIG9iago8PCAvTGVuZ3RoIDIyIDAgUiAvRmlsdGVyIC9GbGF0'+
'ZURlY29kZSA+PgpzdHJlYW0KeAFdkctuwyAQRfd8Bct0EXnsxE4jWZaqVJG86EN1+wEOjCOkGiNMFv77'+
'XkiaSl2cxWG4MAzZoX1urQkye/eT6jjIwVjteZ4uXrE88dlYkRdSGxVultbU2DuRIdwtc+CxtcMk61pI'+
'mX0gMge/yNWTnk78ENfevGZv7Fmuvg5dWukuzn3zyDZIEk0jNQ847qV3r/3IMkvRdatRN2FZI/W343Nx'+
'LNEREvm1JTVpnl2v2Pf2zKImaurjsRFs9b9STtfEabhtLfKmjhCVm0bURQEFRFUedQMFUB11CwVEO4pa'+
'QgGqKmoFBdAy6g4KiGgf9REKiLbpoj0U4N4qVnsoINoUqe/fBuMT4qjvo1EX7zGV9B9pYHEQxvL9y9zk'+
'4sMTP8G8jIoKZW5kc3RyZWFtCmVuZG9iagoyMiAwIG9iagoyOTAKZW5kb2JqCjIwIDAgb2JqCjw8IC9U'+
'eXBlIC9Gb250RGVzY3JpcHRvciAvRm9udE5hbWUgL0hPSEZaTitDYWxpYnJpLUxpZ2h0IC9GbGFncyA0'+
'IC9Gb250QkJveApbLTUxMSAtMjY5IDEyMDkgOTUyXSAvSXRhbGljQW5nbGUgMCAvQXNjZW50IDk1MiAv'+
'RGVzY2VudCAtMjY5IC9DYXBIZWlnaHQgNjQzCi9TdGVtViAwIC9YSGVpZ2h0IDQ3MyAvQXZnV2lkdGgg'+
'NTIwIC9NYXhXaWR0aCAxMzI4IC9Gb250RmlsZTIgMjMgMCBSID4+CmVuZG9iagoyMyAwIG9iago8PCAv'+
'TGVuZ3RoIDI0IDAgUiAvTGVuZ3RoMSAyMTMyIC9GaWx0ZXIgL0ZsYXRlRGVjb2RlID4+CnN0cmVhbQp4'+
'AWVVaWwTRxSe3dmdtdfrddb22gluEhwb5w4hviA4zmniYBNCk5gjQHASQgJxAiGUIy3lLARKxfGjiFKK'+
'EBVqaVX4g9qq/Cmopa0QtD8RP/qrElKloh5UIgn0jdfh6lizb9/M7Jvvvfe957HRbeuRDu1BGKHeVHIz'+
'Sg/mAIiyDUM7+zP6LYRI38D6ZJ+moymQgQFYyOz7QLoHUmM7MvoKkGVDI70z+1dAz04ld2Tso/ugzx5O'+
'ptZr53VlIIsQ+b4eFf1Sj+776tHoWe2dSvcn9eh0UNOpnDqonaGSnh87+nyPnqff08HANKAvwb+7MFmU'+
'heaijEegM+l91n/jxvxTS7tNoX+QQ5f+7If7H6Zx/nzsx8Tkg+l7+svCOdjQgwVtgF3h3PQ9hMTzkw+m'+
'Nuovpy1lNtPCwMmogrmDEBdFm/BHKM6NoCJ8Ew3gv9EAcxNdIh3oElcEU4bYU6QUK0ISIigPpBOJkBEe'+
'UOqRAGsM3M3BGh2b4fcN42A6mc+YR2wOe5C9j6tgtwIhfJuX4TsBLUBLwKjiVNLTKrOCYCWuggrWX+gL'+
'eL1VYdbv87gKZDa95gsEw9hblcdiOKmthNm0fnsqidunHrF73fUrfLxNFWWR52ap1nn1RcqKnsLaytkC'+
'FnjM64SiYKMz0t9Y8CuR7Yo520SIKdus2GXCy4//5OXJ+dy+yd3YFlpb52I+1Qksx3O37Kqjos7dtlpR'+
'Faw3SZJFJ1jMRk/Dquk3ZyxkJI3Qpqd/cRLvAN/QHKuseeNL4yRqBjf1SLXmAXYNPyexnGCpS+6O7/ru'+
'aKztxE/j1anVLQ6BY7EgCrK3fUd71+lUzfyNZ3uX7UwETUTH4ysGsyxZSkvyOi8+PHNu8os1toIyh2Sy'+
'SLJq0hVXFbe8d/fQ3lsTUXjljTbAFX/6B47z+agFQGo4OL+GK43D76sgGf1VnATHw5vPdIWHEwttIicY'+
'iOxdtiVW07+42Nc5tGWo0xfomXi9uCO20MIDYqInhvKmtaGFK6pzfYnUllTCx6xNHO6uss922vPtik3m'+
'XcUuZ7irOpSo9/vD7ZuXxLa3l2Xl5Fv0skU2Avxcd+7s4OLiUKLB769pH6FRLXr6mGvmrcgNUZUxJJ8r'+
'ZDxa9OyMl6G8sNmIwB7EksWhSNYsSSTskwhh5NfsFrtRwMxJhnmHJaZZqt1hYIhNZyCYwRzREe6OySJi'+
'TERh8hi3VRAJ5kSzCZg8ABFz4m+RF9XRXBLIpcfj91MJDKWx80LUgInP2MhRNqqCll+btyoQxE6jalay'+
'jTWnljZvaS0Jj57vOZ4dSIRD66JzRbgSk5y69nWVa/YsLdj+cXQo6upd1TwesYoGnjeI6xuicyI9NbGR'+
'xXNaq1eG8iAunEGR1Jycglxzecd461ezqhaVt65piWfQTgDaUgRdjoEycr7AMGDec9QUY2HAQ1EKeMJj'+
'nn7fGd+1sravhSIiGFIo+jpG6gYvDC9YOPxBd//xNaXj+MiBpg3NHswKbkfH4aTP5rARo9UkGA2imJNj'+
'rR2/tmPrtbcbm7ae7jAcv+DtGAnRrF16+pjJ40eRmq4FrWaVDOlUJo8Y7bT2eJ7Wot1IrHA9x8GDb6Kh'+
'AfKTjBX+KnjW9pIVGngiKDOtQEln4qUFjR6qGgjQtNi13qHyV+FauE7m7fNi3tq9S6hKUWSn1fhzUKqi'+
'2CS+9d3IgpVNlaa57bFFBZ3bmvOfoWTL6wZjxT3d09tncP9/BU/MeLJneatjXlOxr7nUEuo/TDN26ckp'+
'fB38KkE1NGMaiwpf8GjGAQ25kOGaoNiAWmEWX/f2nlxbtKixcc4zzFA9Jkh1STzeVt5zZHnhW9kLuqPu'+
'SLS1NDYRi/SGc5nfxr7e16y4A54n5TPIuIeU9LQA9pfWllhj+z7fFj823GCtaAk8eaMr2ZiaoFnYA337'+
'KPSPcCYLzkwRBKH4XikDki4DcEgQnLRdH+X1sn46os+SCEtEHaPv3Ra25IdWVtf2xaokCgP6nz3Y0R/s'+
'OrSqTI3sT/3Otumgh8+XoBsQo81ktGZl6ZnsgYsHhiorl9cXukpdQD+jlGWUrAWunMDqnY3h8RNXtv4r'+
'yFb472GQGSYdBIEeXRpdtKq1tDE5NNgzOlgeH9wwMIbQfzF/gFIKZW5kc3RyZWFtCmVuZG9iagoyNCAw'+
'IG9iagoxNTk5CmVuZG9iagoyNSAwIG9iagoo/v9cMDAwU1wwMDBhXDAwMG1cMDAwcFwwMDBsXDAwMGVc'+
'MDAwIFwwMDBDXDAwMFZcMDAwIFwwMDDmXDAwMPhcMDAwYVwwMDNcMDEyXDAwMMZcMDAw2FwwMDBBXDAw'+
'M1wwMTJcMDAwIFwwMDB2XDAwMDIpCmVuZG9iagoyNiAwIG9iagooTWFjIE9TIFggMTAuMTIuMyBRdWFy'+
'dHogUERGQ29udGV4dCkKZW5kb2JqCjI3IDAgb2JqCigpCmVuZG9iagoyOCAwIG9iagooKQplbmRvYmoK'+
'MjkgMCBvYmoKKFdvcmQpCmVuZG9iagozMCAwIG9iagooRDoyMDE3MDMyMzExMzgxNVowMCcwMCcpCmVu'+
'ZG9iagozMSAwIG9iagooKQplbmRvYmoKMzIgMCBvYmoKWyBdCmVuZG9iagoxIDAgb2JqCjw8IC9UaXRs'+
'ZSAyNSAwIFIgL0F1dGhvciAyNyAwIFIgL1N1YmplY3QgMjggMCBSIC9Qcm9kdWNlciAyNiAwIFIgL0Ny'+
'ZWF0b3IKMjkgMCBSIC9DcmVhdGlvbkRhdGUgMzAgMCBSIC9Nb2REYXRlIDMwIDAgUiAvS2V5d29yZHMg'+
'MzEgMCBSIC9BQVBMOktleXdvcmRzCjMyIDAgUiA+PgplbmRvYmoKeHJlZgowIDMzCjAwMDAwMDAwMDAg'+
'NjU1MzUgZiAKMDAwMDAxNzUwNCAwMDAwMCBuIAowMDAwMDA1OTg1IDAwMDAwIG4gCjAwMDAwMDg5NzYg'+
'MDAwMDAgbiAKMDAwMDAwMDAyMiAwMDAwMCBuIAowMDAwMDA1OTY1IDAwMDAwIG4gCjAwMDAwMDYwOTUg'+
'MDAwMDAgbiAKMDAwMDAwODk0MCAwMDAwMCBuIAowMDAwMDAwMDAwIDAwMDAwIG4gCjAwMDAwMTQ2MzYg'+
'MDAwMDAgbiAKMDAwMDAwMDAwMCAwMDAwMCBuIAowMDAwMDA5MTE1IDAwMDAwIG4gCjAwMDAwMDYyMDQg'+
'MDAwMDAgbiAKMDAwMDAwODkxOSAwMDAwMCBuIAowMDAwMDA5MDY1IDAwMDAwIG4gCjAwMDAwMDk5ODgg'+
'MDAwMDAgbiAKMDAwMDAwOTQzMCAwMDAwMCBuIAowMDAwMDA5OTY4IDAwMDAwIG4gCjAwMDAwMTAyMjQg'+
'MDAwMDAgbiAKMDAwMDAxNDYxNSAwMDAwMCBuIAowMDAwMDE1MjI2IDAwMDAwIG4gCjAwMDAwMTQ4NDAg'+
'MDAwMDAgbiAKMDAwMDAxNTIwNiAwMDAwMCBuIAowMDAwMDE1NDY3IDAwMDAwIG4gCjAwMDAwMTcxNTYg'+
'MDAwMDAgbiAKMDAwMDAxNzE3NyAwMDAwMCBuIAowMDAwMDE3MzA5IDAwMDAwIG4gCjAwMDAwMTczNjIg'+
'MDAwMDAgbiAKMDAwMDAxNzM4MSAwMDAwMCBuIAowMDAwMDE3NDAwIDAwMDAwIG4gCjAwMDAwMTc0MjMg'+
'MDAwMDAgbiAKMDAwMDAxNzQ2NSAwMDAwMCBuIAowMDAwMDE3NDg0IDAwMDAwIG4gCnRyYWlsZXIKPDwg'+
'L1NpemUgMzMgL1Jvb3QgMTQgMCBSIC9JbmZvIDEgMCBSIC9JRCBbIDwxMDFlN2ZhYjE0NTU0NmEzMGEx'+
'ZjFmOWQ1YTEzYTc1Mz4KPDEwMWU3ZmFiMTQ1NTQ2YTMwYTFmMWY5ZDVhMTNhNzUzPiBdID4+CnN0YXJ0'+
'eHJlZgoxNzY3OQolJUVPRgo=';
}