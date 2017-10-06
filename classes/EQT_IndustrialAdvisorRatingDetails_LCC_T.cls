@IsTest
private class EQT_IndustrialAdvisorRatingDetails_LCC_T {
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

    @isTest static void getValuesTest() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];
        Contact c = [SELECT Id FROM Contact WHERE FirstName = 'f1' AND LastName = 'l1'];

        system.runAs(runningUser) {
            system.assert(EQT_IndustrialAdvisorRatingDetails_LCC.getGeographicalRatings(c.Id).size() > 0);
            system.assert(EQT_IndustrialAdvisorRatingDetails_LCC.getFunctionalRatings(c.Id).size() > 0);
            system.assert(EQT_IndustrialAdvisorRatingDetails_LCC.getSectorialRatings(c.Id).size() > 0);
        }
    }
}