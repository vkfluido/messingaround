@IsTest
private class EQT_NetworkSearch_LCC_Test {

    @testSetup
    static void testSetup() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Portfolio_Company', accountName);

            Contact c1 = EQT_TestFactory.createSampleContact('f1', 'l1', a.Id, false);
            c1.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());
            c1.EQT_Suitable_Positions__c = 'CEO';
            c1.Engagement_Level__c = 'Tier 1';
            c1.EQT_Country_of_Residence__c = 'Sweden';

            Contact c2 = EQT_TestFactory.createSampleContact('f2', 'l2', a.Id, false);
            c2.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());
            c2.EQT_Suitable_Positions__c = 'Chairman';
            c2.Engagement_Level__c = 'Tier 1';
            c2.EQT_Country_of_Residence__c = 'Sweden';

            Contact c3 = EQT_TestFactory.createSampleContact('f3', 'l3', a.Id, false);
            c3.RecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Contact.' + EQT_UTIL_Settings.getIndustrialAdvisorRecordTypeName());
            c3.EQT_Suitable_Positions__c = 'CEO;Chairman';
            c3.Engagement_Level__c = 'Tier 1';
            c3.EQT_Country_of_Residence__c = 'Sweden';

            Contact c4 = EQT_TestFactory.createSampleContact('f4', 'l4', a.Id, false);
            c4.Engagement_Level__c = 'Tier 1';
            c3.EQT_Country_of_Residence__c = 'Sweden';

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

            Id boardManagementRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.' + EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName());
            List<EQT_Assignment__c> assignments = EQT_TestFactory.createTestAssignments(1, EQT_UTIL_Settings.getAssignmentBoardMngRecordTypeName(), new List<Opportunity> {opp}, new List<Account> {a}, new List<Contact> {c1,c2,c3,c4}, false);
            EQT_Assignment__c assignmentWithoutProject = EQT_TestFactory.createSampleAssignment(a.Id, c1.Id, boardManagementRTId, 'Chairman', false);
            assignments.add(assignmentWithoutProject);
            insert assignments;

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

            EQT_Sector_Team__c sectorTeam1 = EQT_TestFactory.createSampleSectorTeam('Healthcare', true);

            EQT_Sector_Team_Member__c sectorTeamMember1 = EQT_TestFactory.createSampleSectorTeamMember(c1.Id, sectorTeam1.Id, 'Deputy of Sector Team', true, false);
            EQT_Sector_Team_Member__c sectorTeamMember2 = EQT_TestFactory.createSampleSectorTeamMember(c3.Id, sectorTeam1.Id, 'Head of Sector Team', true, false);

            insert new List<EQT_Sector_Team_Member__c> {sectorTeamMember1,sectorTeamMember2};
        }
    }

    @isTest static void loadListTest() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            system.assert(EQT_NetworkSearch_LCC.getPositions().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getRoles().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getEngagementLevels().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getSectorCompetences().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getFunctionalCompetences().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getGeographicalCompetences().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getCountryOfResidenceCompetences().size() > 0);
            system.assert(EQT_NetworkSearch_LCC.getSectoTeamCompetences().size() > 0);
        }
    }

    @isTest static void searchWithoutParametersTest() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
            params.deals = new List<String>();
            params.accounts = new List<String>();
            params.sectorFilter = new List<String>();
            params.functionalFilter = new List<String>();
            params.geoFilter = new List<String>();
            params.suitablePositions = new List<String>();
            params.engagementLevel = new List<String>();
            params.existingRoles = new List<String>();
            params.sectorTeam = new List<String>();

            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, true, false, false, false, false);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.assert(results.isEmpty());

        }
    }

    @isTest static void searchWithParametersMapTest() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            Map<String, Object> params = new Map<String, Object> {
                    'deals' => new List<String>(),
                    'accounts' => new List<String>(),
                    'sectorFilter' => new List<String>(),
                    'functionalFilter' => new List<String>(),
                    'geoFilter' => new List<String>(),
                    'isBoardMember' => false,
                    'suitablePositions' => new List<String>(),
                    'engagementLevel' => new List<String>(),
                    'existingRoles' => new List<String>(),
                    'sectorTeam' => new List<String>()
            };

            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination(params, 1, true);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.assert(results.isEmpty());
        }
    }

    @isTest static void searchWithParametersTest() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'test account'];
            Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND LastName = 'l1' LIMIT 1];
            Opportunity deal = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
            List<EQT_Sector_Rating__c> srList = [SELECT Id, Sector__c, Subsector__c FROM EQT_Sector_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Functional_Rating__c> fuList = [SELECT Functional_Topic__c, Functional_Subtopic__c FROM EQT_Functional_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Geographical_Rating__c> grList = [SELECT Geography__c FROM EQT_Geographical_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Sector_Team__c> stList = [SELECT Id FROM EQT_Sector_Team__c LIMIT 1];

            String sectorFilter = srList[0].Sector__c + '#' + srList[0].Subsector__c;
            String functionalFilter = fuList[0].Functional_Topic__c + '#' + fuList[0].Functional_Subtopic__c;
            String geoFilter = grList[0].Geography__c;

            EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
            params.deals = new List<String> {deal.Id};
            params.accounts = new List<String> {acc.Id};
            params.sectorFilter = new List<String> {sectorFilter};
            params.functionalFilter = new List<String> {functionalFilter};
            params.geoFilter = new List<String> {geoFilter};
            params.isBoardMember = false;
            params.suitablePositions = new List<String> {'CEO'};
            params.engagementLevel = new List<String> {'Tier 1'};
            params.existingRoles = new List<String>();
            params.residence = new List<String> {'Sweden'};
            params.sectorTeam = new List<String> {stList[0].Id};

            system.debug('searchWithParametersTest params: ' + params);
            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, true, false, false, false, false);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.debug('searchWithParametersTest results: ' + results);

            system.assertEquals(0, results.size());
        }
    }

    @isTest static void searchWithParametersResult1Test() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'test account'];
            Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND LastName = 'l1' LIMIT 1];
            Opportunity deal = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
            List<EQT_Sector_Team__c> stList = [SELECT Id FROM EQT_Sector_Team__c LIMIT 1];

            EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
            params.deals = new List<String> {deal.Id};
            params.accounts = new List<String> {acc.Id};
            params.sectorFilter = new List<String>();
            params.functionalFilter = new List<String>();
            params.geoFilter = new List<String>();
            params.isBoardMember = false;
            params.suitablePositions = new List<String> {'CEO'};
            params.engagementLevel = new List<String> {'Tier 1'};
            params.existingRoles = new List<String>();
            params.residence = new List<String> {'Sweden'};
            params.sectorTeam = new List<String> {stList[0].Id};

            system.debug('searchWithParametersResult1Test params: ' + params);

            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, true, false, false, false, false);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.debug('searchWithParametersResult1Test pageResults: ' + pageResults);

            system.assertEquals(2, pageResults.contacts.size());

            system.assertEquals(0, results[0].assessments.size());
        }
    }

    @isTest static void searchWithParametersResult2Test() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'test account'];
            Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND LastName = 'l1' LIMIT 1];
            Opportunity deal = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];

            List<EQT_Sector_Rating__c> srList = [SELECT Id, Sector__c, Subsector__c FROM EQT_Sector_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Functional_Rating__c> fuList = [SELECT Functional_Topic__c, Functional_Subtopic__c FROM EQT_Functional_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Geographical_Rating__c> grList = [SELECT Geography__c FROM EQT_Geographical_Rating__c WHERE Contact__c = :c.Id LIMIT 1];

            String sectorFilter = srList[0].Sector__c + '#' + srList[0].Subsector__c;
            String functionalFilter = fuList[0].Functional_Topic__c + '#' + fuList[0].Functional_Subtopic__c;
            String geoFilter = grList[0].Geography__c;

            EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
            params.deals = new List<String> {deal.Id};
            params.accounts = new List<String> {acc.Id};
            params.sectorFilter = new List<String>();
            params.functionalFilter = new List<String>();
            params.geoFilter = new List<String> {geoFilter};
            params.isBoardMember = false;
            params.suitablePositions = new List<String> {'CEO'};
            params.engagementLevel = new List<String> {'Tier 1'};
            params.existingRoles = new List<String> {'Chairman'};
            params.residence = new List<String> {'Sweden'};

            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, true, false, false, false, false);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.assertEquals(0, pageResults.contacts.size());
        }
    }

    @isTest static void searchWithParametersResult3Test() {
        User runningUser = [SELECT Id FROM User WHERE Username = 'testuser@example.eqt'];

        system.runAs(runningUser) {
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'test account'];
            Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND LastName = 'l1' LIMIT 1];
            Opportunity deal = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
            List<EQT_Sector_Rating__c> srList = [SELECT Id, Sector__c, Subsector__c FROM EQT_Sector_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Functional_Rating__c> fuList = [SELECT Functional_Topic__c, Functional_Subtopic__c FROM EQT_Functional_Rating__c WHERE Contact__c = :c.Id LIMIT 1];
            List<EQT_Geographical_Rating__c> grList = [SELECT Geography__c FROM EQT_Geographical_Rating__c WHERE Contact__c = :c.Id LIMIT 1];

            String sectorFilter = srList[0].Sector__c + '#' + srList[0].Subsector__c;
            String functionalFilter = fuList[0].Functional_Topic__c + '#' + fuList[0].Functional_Subtopic__c;
            String geoFilter = grList[0].Geography__c;

            EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
            params.deals = new List<String>();
            params.accounts = new List<String> {acc.Id};
            params.sectorFilter = new List<String>();
            params.functionalFilter = new List<String>();
            params.geoFilter = new List<String>();
            params.isBoardMember = false;
            params.suitablePositions = new List<String>();
            params.engagementLevel = new List<String>();
            params.existingRoles = new List<String>();

            EQT_NetworkSearch_Wrapper.PageResult pageResults = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, true, false, false, false, false);
            List<EQT_NetworkSearch_Wrapper.SearchResults> results = pageResults.contacts;
            system.assertEquals(3, results.size());
        }
    }
    
    @isTest static void testGetSearchesForCurrentUser_NoneMine() {
        List<User> users = [SELECT Id FROM User where Id!=:UserInfo.getUserId()];
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=users[0].Id, Key__c='foo', Filters__c='dummy')
        };
        insert searches;
        
        List<EQT_IANetworkSearch_Save__c> retrieved = EQT_NetworkSearch_LCC.getSearchesForCurrentUser();
        System.assert(0 == retrieved.size());
    }
    @isTest static void testGetSearchesForCurrentUser_Mine() {
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='foo', Filters__c='dummy', SavedSearch__c=False), 
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='bar', Filters__c='dummy', SavedSearch__c=True)
        };
        insert searches;
        
        List<EQT_IANetworkSearch_Save__c> retrieved = EQT_NetworkSearch_LCC.getSearchesForCurrentUser();
        System.assert(1 == retrieved.size());
    }
    
    @isTest static void testGetFiltersFromKey_KeyNotFound() {
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='bar', Filters__c='dummy', SavedSearch__c=True)
        };
        insert searches;
        try {
            // should fail
	        EQT_NetworkSearch_LCC.getFiltersFromKey('foo');
            System.assert(False);
            
        } catch (AuraHandledException e) {
            
        }
    }
    
    @isTest static void testGetFiltersFromKey_NotMySavedSearch() {
        List<User> users = [SELECT Id FROM User where Id!=:UserInfo.getUserId()];
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=users[0].Id, Key__c='foo', Filters__c='dummy', SavedSearch__c=True)
        };
        insert searches;
        try {
            // should fail
	        EQT_NetworkSearch_LCC.getFiltersFromKey('foo');
            System.assert(False);
            
        } catch (AuraHandledException e) {
            
        }
    }
    
    @isTest static void testGetFiltersFromKey_Found() {
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='foo', Filters__c='dummy')
        };
        insert searches;
        System.assertEquals('dummy', EQT_NetworkSearch_LCC.getFiltersFromKey('foo'));
    }
    
    @isTest static void testShareSearch() {
        String key = EQT_NetworkSearch_LCC.shareSearch('foo_BAR_baz');
        System.assert(32 == key.length());
        
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Id, Filters__C FROM EQT_IANetworkSearch_Save__c WHERE OwnerId=:USerInfo.getUserId() AND Key__c=:key AND SavedSearch__c=False];
        System.assert(1 == searches.size());
        System.assertEquals('foo_BAR_baz', searches[0].Filters__c);
    }
    
    @isTest static void testDeleteSearch_NoneFound() {
        List<User> users = [SELECT Id FROM User where Id!=:UserInfo.getUserId()];
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=users[0].Id, Key__c='foo', Filters__c='dummy')
        };
		
		try {
            // should fail as not found
            EQT_NetworkSearch_LCC.deleteSearch('bar');
            System.assert(False);
            
		} catch (AuraHandledException e) {
			// success
        }
    }
    
    @isTest static void testDeleteSearch_NotMine() {
        List<User> users = [SELECT Id FROM User where Id!=:UserInfo.getUserId()];
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=users[0].Id, Key__c='foo', Filters__c='dummy')
        };
		
		try {
            // should fail as not mine
            EQT_NetworkSearch_LCC.deleteSearch('foo');
            System.assert(False);
            
		} catch (AuraHandledException e) {
			// success
        }
    }
    
    @isTest static void testDeleteSearch_EmptyKey() {
        try {
            // should fail as empty key
            EQT_NetworkSearch_LCC.deleteSearch('');
            System.assert(False);
            
		} catch (AuraHandledException e) {
			// success
        }
    }
    
	@isTest static void testDeleteSearch_Success() {
        List<EQT_IANetworkSearch_Save__c> searches = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='foo', Filters__c='dummy')
        };
        insert searches;
		System.assert(EQT_NetworkSearch_LCC.deleteSearch('foo'));
    }
    
    @isTest static void testUpsertSearch_NoFilters() {
        try {
            // should fail as empty fitlers
            EQT_NetworkSearch_LCC.upsertSearch(null, 'name', null);
            System.assert(False);
            
		} catch (AuraHandledException e) {
			// success
        }
    }
    
    @isTest static void testUpsertSearch_NoKey_Name() {
        final String key = EQT_NetworkSearch_LCC.upsertSearch(null, 'My search', 'foo_bar_baz');
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Id, Name, OwnerId, Filters__c, Key__c, SavedSearch__c FROM EQT_IANetworkSearch_Save__c];
        System.assert(1 == searches.size());
        System.assertEquals(key, searches[0].Key__c);
        System.assertEquals('foo_bar_baz', searches[0].Filters__c);
        System.assertEquals('My search', searches[0].Name);
        System.assertEquals(UserInfo.getUserId(), searches[0].OwnerId);
        System.assertEquals(True, searches[0].SavedSearch__c);
    }
    
    @isTest static void testUpsertSearch_NoKey_NoName() {
        final String key = EQT_NetworkSearch_LCC.upsertSearch(null, null, 'foo_bar_baz');
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Name, Key__c FROM EQT_IANetworkSearch_Save__c];
        System.assert(1 == searches.size());
        System.assertEquals(key, searches[0].Key__c);
        System.assert(searches[0].Name.startsWith('Saved search on '));
    }
    
    @isTest static void testUpsertSearch_Key_NewName() {
        List<EQT_IANetworkSearch_Save__c> inserts = new List<EQT_IANetworkSearch_Save__c>{
            new EQT_IANetworkSearch_Save__c(OwnerId=UserInfo.getUserId(), Key__c='foo', Filters__c='dummy')
        };
        insert inserts;
        
        final String newkey = EQT_NetworkSearch_LCC.upsertSearch('foo', 'My new name', 'foo_bar_baz');
        System.assertEquals('foo', newkey);
        List<EQT_IANetworkSearch_Save__c> searches = [SELECT Name, Key__c FROM EQT_IANetworkSearch_Save__c];
        System.assert(1 == searches.size());
        System.assertEquals(newkey, searches[0].Key__c);
        System.assertEquals('My new name', searches[0].Name);
    }
    
    @isTest static void testTrackContactOpen_NoId() {
        try {
            EQT_NetworkSearch_LCC.trackContactOpen(null, 'contactName');
            System.assert(false, 'Should fail due to missing contact id');
            
        } catch (AuraHandledException e) {
            // yeah
        }
    }
    
    @isTest static void testTrackContactOpen_NoName() {
        try {
            EQT_NetworkSearch_LCC.trackContactOpen('contactId', null);
            System.assert(false, 'Should fail due to missing contact name');
            
        } catch (AuraHandledException e) {
            // yeah
        }
    }
    
    @isTest static void testTrackContactOpen_DoTrack() {
        // create contact and account
        Account a = new Account();
        a.Name = 'Foo';
        insert a;
        Contact c = new Contact();
        c.AccountId = a.Id;
        c.FirstName = 'John';
        c.LastName = 'Doe';
        insert c;
        
        boolean rc = EQT_NetworkSearch_LCC.trackContactOpen(c.Id, 'John Doe');
        System.assert(rc, 'Return value should be true');
        List<EQT_IANetworkSearch_Track_ContactOpen__c> opens = [SELECT Id, Contact__c, Name, Profile_Name__c, Role_Name__c from EQT_IANetworkSearch_Track_ContactOpen__c];
        System.assertEquals(1, opens.size());
        EQT_IANetworkSearch_Track_ContactOpen__c open = opens[0];
        System.assertEquals(c.Id, open.Contact__c);
        System.assertEquals('John Doe', open.Name);
        System.assert(String.isNotEmpty(open.Role_Name__c));
        System.assert(String.isNotEmpty(open.Profile_Name__c));
    }
}