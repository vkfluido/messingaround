@IsTest
private class EQT_SectorRatingHandler_Test {

    @isTest
    static void testSectorRatingTrigger() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Business Line Credit Profile');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            system.assert(a.Id != null);

            Contact c = EQT_TestFactory.createSampleContact('Test', 'Test', a.Id);
            system.assert(c.Id != null);

            List<EQT_Sector__c> sectors = EQT_TestFactory.createTestSectors(1, false);
            sectors[0].Name = 'Healthcare';
            insert sectors;

            List<EQT_SubSector__c> subsectors = EQT_TestFactory.createTestSubSectors(3, sectors, false);
            subsectors[0].Name = 'AAA';
            subsectors[1].Name = 'XXX';
            subsectors[2].Name = 'ZZZ';
            insert subsectors;

            EQT_Sector_Team__c st = EQT_TestFactory.createSampleSectorTeam('Healthcare', true);
            EQT_Sector_Team__c st2 = EQT_TestFactory.createSampleSectorTeam('TMT', true);

            EQT_Sector_Team_Member__c stm = EQT_TestFactory.createSampleSectorTeamMember(c.id, st.id, 'Head of Sector Team', true, true);
            EQT_Sector_Team_Member__c stm2 = EQT_TestFactory.createSampleSectorTeamMember(c.id, st2.id, 'Team Member', true, true);

            EQT_Sector_Team_Member__c stmRes = [SELECT Id,Name,Sector_Healthcare__c,Sub_sector_Healthcare__c FROM EQT_Sector_Team_Member__c WHERE Id = :stm.Id];
            system.debug('stmRes: ' + stmRes);
            system.assertEquals(null , stmRes.Sector_Healthcare__c);
            system.assertEquals(null , stmRes.Sub_sector_Healthcare__c);

            EQT_Sector_Rating__c sectorRating1 = EQT_TestFactory.createSampleSectorRating('test', sectors[0].Id, subsectors[0].Id, c.id, false);
            EQT_Sector_Rating__c sectorRating2 = EQT_TestFactory.createSampleSectorRating('test', sectors[0].Id, subsectors[1].Id, c.id, false);
            insert new List<EQT_Sector_Rating__c>{sectorRating1, sectorRating2};
            stmRes = [SELECT Id,Name,Sector_Healthcare__c,Sub_sector_Healthcare__c FROM EQT_Sector_Team_Member__c WHERE Id = :stm.Id];
            system.debug('stmRes 2: ' + stmRes);
            system.assertEquals('Healthcare', stmRes.Sector_Healthcare__c);
            system.assertEquals('AAA | XXX' , stmRes.Sub_sector_Healthcare__c);

            // checks update operation
            List<EQT_Sector__c> sectors2 = EQT_TestFactory.createTestSectors(1, false);
            sectors2[0].Name = 'TMT';
            insert sectors2;

            sectorRating1.Sector__c = sectors2[0].Id;
            try{
                update sectorRating1;    
            }catch(DmlException e){
                // The update operation on Sector,Subsector or Segment is not permitted, generates DML EXception
                System.debug(e.getMessage());
            }
            // To remove 'AAA', user must remove the rating 
            delete sectorRating1;

            // Create another Sector Rating for sector TMT and Subsector ZZZ
            EQT_Sector_Rating__c sectorRating3 = EQT_TestFactory.createSampleSectorRating('test', sectors2[0].Id, subsectors[2].Id, c.id, true);


            stmRes = [SELECT Id,Name,Sector_Healthcare__c,Sub_sector_Healthcare__c,Sector_TMT__c,Sub_sector_TMT__c FROM EQT_Sector_Team_Member__c WHERE Id = :stm.Id];
            system.debug('stmRes 3: ' + stmRes);
            system.assertEquals('Healthcare', stmRes.Sector_Healthcare__c);
            system.assertEquals('XXX' , stmRes.Sub_sector_Healthcare__c);
            system.assertEquals('TMT', stmRes.Sector_TMT__c);
            system.assertEquals('ZZZ' , stmRes.Sub_sector_TMT__c);

            // After Adding and removing sector ratings, the Team meber should have 2 expertise items: 1 for Healthcare/XXX and 1 for TMT/ZZZ because Healthcare/AAA was deleted
            List<EQT_SectorTeamMemberExpertise__c> stmexpertise = [SELECT Id, Sector_Expertise__c, Sector__c, Subsector__c, Segment__c FROM EQT_SectorTeamMemberExpertise__c WHERE SectorTeamMember__c = :stm.Id];
            System.debug('Sector Team Member Expertise: ' + stmexpertise);
            System.assertEquals(2, stmexpertise.size());

        }
    }
}