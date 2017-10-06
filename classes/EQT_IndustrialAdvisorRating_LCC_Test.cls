@IsTest
private class EQT_IndustrialAdvisorRating_LCC_Test {
    @testSetup
    static void testSetup() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Portfolio_Company', accountName);

            Contact c1 = EQT_TestFactory.createSampleContact('f1', 'l1', a.Id, false);
            Contact c2 = EQT_TestFactory.createSampleContact('f2', 'l2', a.Id, false);
            Contact c3 = EQT_TestFactory.createSampleContact('f3', 'l3', a.Id, false);
            Contact c4 = EQT_TestFactory.createSampleContact('f4', 'l4', a.Id, false);

            insert new List<Contact> {c1,c2,c3,c4};

            Opportunity opp = new Opportunity(
                    Name = 'deal',
                    AccountId = a.Id,
                    RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.EQT_Deal'),
                    StageName = 'Qualification',
                    CloseDate = Date.today().addMonths(2),
                    EQT_Sector__c = 'Services'
            );
            insert opp;

            List<EQT_Assignment__c> assignments = EQT_TestFactory.createTestAssignments(1, 'Board_Management_Assignment', new List<Opportunity> {opp}, new List<Account> {a}, new List<Contact> {c1,c2,c3,c4}, true);

            List<EQT_Sector__c> sectors = EQT_TestFactory.createTestSectors(2, true);
            List<EQT_SubSector__c> subSectors = EQT_TestFactory.createTestSubSectors(4, sectors, true);
            List<EQT_SubSector_Segment__c> segments = EQT_TestFactory.createTestSegments(8, subSectors, true);

            List<EQT_Functional_Topic__c> topics = EQT_TestFactory.createTestTopics(2, true);
            List<EQT_Functional_SubTopic__c> subTopics = EQT_TestFactory.createTestSubTopics(4, topics, true);

            List<EQT_Geography__c> geographies = EQT_TestFactory.createTestGeographies(4, true);

            EQT_Sector_Rating__c secRatings = EQT_TestFactory.createSampleSectorRating('sr1', sectors[0].Id, subSectors[0].Id, c1.Id, true);
            EQT_Functional_Rating__c topRatings = EQT_TestFactory.createSampleFunctionalRating('fr1', topics[0].Id, subTopics[0].Id, c1.Id, true);
            EQT_Geographical_Rating__c geoRatings = EQT_TestFactory.createSampleGeographicalRating('gr1', geographies[0].Id, c1.Id, true);

            EQT_Affiliation__c affiliation = EQT_TestFactory.createSampleAffiliation(a.Id, c1.Id, 'CEO', Date.today().addMonths(-1), Date.today().addMonths(1), true);
        }
    }
    
    @isTest static void testGetSectorCompetences() {
        EQT_IndustrialAdvisorRating_LCC.getSectorCompetences();
    }
    
    @isTest static void testGetFunctionalCompetences() {
        EQT_IndustrialAdvisorRating_LCC.getFunctionalCompetences();
    }
    
    @isTest static void testGetGeoCompetences() {
        EQT_IndustrialAdvisorRating_LCC.getGeographicalCompetences();
    }
    
    @isTest static void testGetSectorRatings() {
        User u = [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt' LIMIT 1];
        Id i = u.Id;
        EQT_IndustrialAdvisorRating_LCC.getSectorRatings(i);
    }
    
    @isTest static void testGetFunctionalRatings() {
        User u = [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt' LIMIT 1];
        Id i = u.Id;
        EQT_IndustrialAdvisorRating_LCC.getFunctionalRatings(i);
    }
    
    @isTest static void testGetGeographicalRatings() {
        User u = [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt' LIMIT 1];
        Id i = u.Id;
        EQT_IndustrialAdvisorRating_LCC.getGeographicalRatings(i);
    }
    
    @isTest static void testSaveCompetences() {
        // get the id of a random contact
        final List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
        final Id cid = contacts[0].Id;
        
        // get sectors, functional topics and geographies
        final List<String> sectors = new List<String>();
        final List<String> functionals = new List<String>();
        final List<String> geos = new List<String>();
        for (EQT_Sector__c r : [SELECT Id FROM EQT_Sector__c]) {
            sectors.Add(r.Id);
        }
        for (EQT_Functional_Topic__c r : [SELECT Id FROM EQT_Functional_Topic__c]) {
            functionals.Add(r.Id);
        }
        for (EQT_Geography__c g : [SELECT Id, Region__c FROM EQT_Geography__c]) {
            geos.Add(g.Region__c);
        }
        
        // save all the ratings
        final boolean rc = EQT_IndustrialAdvisorRating_LCC.saveCompetences(cid, sectors, functionals, geos);
        System.assert(rc);
        
        // retrieve all ratings for this contact (using the controller) and assert count
        final List<String> sectorRatings = EQT_IndustrialAdvisorRating_LCC.getSectorRatings(cid);
        final List<String> functionalRatings = EQT_IndustrialAdvisorRating_LCC.getFunctionalRatings(cid);
        final List<String> geoRatings = EQT_IndustrialAdvisorRating_LCC.getGeographicalRatings(cid);
        System.assertEquals(sectors.size() + functionals.size() + geos.size(), sectorRatings.size() + functionalRatings.size() + geoRatings.size());
    }
    

}