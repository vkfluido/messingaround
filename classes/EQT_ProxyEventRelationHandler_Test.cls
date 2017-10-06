@isTest
private class EQT_ProxyEventRelationHandler_Test {
	
	@isTest static void insertRelationTest() {
		//set up org
		EQT_TestFactory.setUpOrg();

		//create sample event proxy data
		List<EQT_Proxy_EventRelation__c> proxyEventList = new List<EQT_Proxy_EventRelation__c>();
		proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '1', EQT_EPM_PersonID__c = '5'));
		proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '2', EQT_EPM_PersonID__c = '7'));
		proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '3', EQT_EPM_PersonID__c = '9'));

		//create sample contact to match epm person Id
		Contact c1 = EQT_TestFactory.createSampleContact('test', 'contact1', null, false);
                c1.EQT_EPM_PersonID__c = '5';
                
                Contact c2 = EQT_TestFactory.createSampleContact('test', 'contact2', null, false);
                c2.EQT_EPM_PersonID__c = '7';

                Contact c3 = EQT_TestFactory.createSampleContact('test', 'contact3', null, false);
                c3.EQT_EPM_PersonID__c = '9';
                
                insert new List<Contact> {c1, c2, c3};

                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c1.Id AND EQT_EPM_PersonID__c = '5'].size());
                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c2.Id AND EQT_EPM_PersonID__c = '7'].size());
                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c3.Id AND EQT_EPM_PersonID__c = '9'].size());

                Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
                system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

                String defaultStage = 'Showing interest';

                Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, defaultStage, true);
                system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

                //create sample event
                List<Event> eventToCreate = new List<Event>();
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '5', EQT_EPM_External_ID__c = '1', WhatId = opp.Id));
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '7', EQT_EPM_External_ID__c = '2', WhatId = opp.Id));
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '9', EQT_EPM_External_ID__c = '3', WhatId = opp.Id));
                insert eventToCreate;
                system.assertEquals(3, [SELECT Id FROM Event].size());

                //delete event relation for contact c1 and c3
                delete [SELECT Id FROM EventRelation];
                system.assertEquals(0, [SELECT Id FROM EventRelation].size());

                //insert proxy data
                insert proxyEventList;

                system.assertEquals(3, [SELECT Id FROM EventRelation].size());
                system.assertEquals(0, [SELECT Id FROM EQT_Proxy_EventRelation__c].size());
	}

        @isTest static void duplicateTest() {
                //set up org
                EQT_TestFactory.setUpOrg();

                //create sample event proxy data
                List<EQT_Proxy_EventRelation__c> proxyEventList = new List<EQT_Proxy_EventRelation__c>();
                proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '1', EQT_EPM_PersonID__c = '5'));
                proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '2', EQT_EPM_PersonID__c = '7'));
                proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '3', EQT_EPM_PersonID__c = '9'));
                proxyEventList.add(new EQT_Proxy_EventRelation__c(EQT_EPM_EventExternalID__c = '1', EQT_EPM_PersonID__c = '5'));

                //create sample contact to match epm person Id
                Contact c1 = EQT_TestFactory.createSampleContact('test', 'contact1', null, false);
                c1.EQT_EPM_PersonID__c = '5';
                
                Contact c2 = EQT_TestFactory.createSampleContact('test', 'contact2', null, false);
                c2.EQT_EPM_PersonID__c = '7';

                Contact c3 = EQT_TestFactory.createSampleContact('test', 'contact3', null, false);
                c3.EQT_EPM_PersonID__c = '9';
                
                insert new List<Contact> {c1, c2, c3};

                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c1.Id AND EQT_EPM_PersonID__c = '5'].size());
                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c2.Id AND EQT_EPM_PersonID__c = '7'].size());
                system.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :c3.Id AND EQT_EPM_PersonID__c = '9'].size());

                Fund__c fund = EQT_TestFactory.createSampleFund('sample fund');
                system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :fund.Id].size());

                String defaultStage = 'Showing interest';

                Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opportunity', fund.Id, defaultStage, true);
                system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());

                //create sample event
                List<Event> eventToCreate = new List<Event>();
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '5', EQT_EPM_External_ID__c = '1', WhatId = opp.Id));
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '7', EQT_EPM_External_ID__c = '2', WhatId = opp.Id));
                eventToCreate.add(new Event (DurationInMinutes = 15, ActivityDateTime = Datetime.now(), EQT_EPM_PersonID__c = '9', EQT_EPM_External_ID__c = '3', WhatId = opp.Id));
                insert eventToCreate;
                system.assertEquals(3, [SELECT Id FROM Event].size());

                //delete event relation for contact c1 and c3
                delete [SELECT Id FROM EventRelation];
                system.assertEquals(0, [SELECT Id FROM EventRelation].size());

                //insert proxy data
                insert proxyEventList;

                system.assertEquals(3, [SELECT Id FROM EventRelation].size());
                system.assertEquals(0, [SELECT Id FROM EQT_Proxy_EventRelation__c].size());
        }       
}