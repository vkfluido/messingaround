@isTest
private class EQT_InvestranContactListImportHandler_T {
	
	@isTest static void tiggerDeleteTest() {
		//set up org
		EQT_TestFactory.setUpOrg();

		//create sample data to check batch
		List<EQT_Investran_Contact_List_Import__c> batchList = new List<EQT_Investran_Contact_List_Import__c>();
		for(Integer i = 1; i <= 1000; i++) {
			batchList.add(new EQT_Investran_Contact_List_Import__c
				(
					Total_Commitment__c = i * 10,
					Invester_ID__c = String.valueOf(i),
					Investor_Reference__c = 'test' + i,
					Legal_Entity_ID__c = '22',
					Legal_Entity__c = 'test',
					Organization_ID__c = 'org1',
					Investor__c = 'something',
					Imported__c = false
				)
			);
		}

		insert batchList;
		system.assertEquals(1000, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = false].size());
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Commitment__c].size());

		//now marked all as imported
		List<EQT_Investran_Contact_List_Import__c> toUpdate = [SELECT Id, Imported__c FROM EQT_Investran_Contact_List_Import__c];
		for(EQT_Investran_Contact_List_Import__c item : toUpdate) {
			item.Imported__c = true;
		}

		update toUpdate;

		//verify there are no records in EQT_Investran_Contact_List_Import__c
		system.assertEquals(0, [SELECT Id FROM EQT_Investran_Contact_List_Import__c WHERE Imported__c = false].size());
	}
}