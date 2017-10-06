@IsTest
private class EQT_SectorTeamMemberHandler_Test {

    @isTest
    static void testSectorTeamMemberTrigger() {
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

            List<EQT_SubSector__c> subsectors = EQT_TestFactory.createTestSubSectors(2, sectors, false);
            subsectors[0].Name = 'AAA';
            subsectors[1].Name = 'XXX';
            insert subsectors;

            EQT_Sector_Rating__c sectorRating1 = EQT_TestFactory.createSampleSectorRating('test', sectors[0].Id, subsectors[0].Id, c.id, true);
            EQT_Sector_Rating__c sectorRating2 = EQT_TestFactory.createSampleSectorRating('test', sectors[0].Id, subsectors[1].Id, c.id, true);

            EQT_Sector_Team__c st = EQT_TestFactory.createSampleSectorTeam('Healthcare', true); // Sector Team Should have the Same Name as the Sector Expertise


            EQT_Sector_Team_Member__c stm = EQT_TestFactory.createSampleSectorTeamMember(c.id, st.id, 'Head of Sector Team', true, true);

            EQT_Sector_Team_Member__c stmRes = [SELECT Id,Name,Sector_Healthcare__c,Sub_sector_Healthcare__c FROM EQT_Sector_Team_Member__c WHERE Id = :stm.Id];
            system.debug('stmRes: ' + stmRes);
            system.assertEquals('Healthcare' , stmRes.Sector_Healthcare__c);
            system.assertEquals('AAA | XXX' , stmRes.Sub_sector_Healthcare__c);

            delete stm;
        }
    }
}