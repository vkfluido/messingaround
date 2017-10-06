@isTest
private class EQT_CommitmentHandler_Test {
    @isTest static void triggerFactoryTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            commitment.EQT_Amount__c = 100;
            update commitment;
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id
                                    AND EQT_Amount__c = 100].size());

            delete commitment;
            system.assertEquals(0, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id
                                    AND EQT_Amount__c = 100].size());
        }
    }
	
	/* TA768 remove fields on Account
    @isTest static void newCommitmentEquityNoTriggerTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable commitment trigger
        EQT_TestFactory.disableCommitmentTrigger();

        system.runAs(u) {
        	//create investor account
        	Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
        	//create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Equity__c should be set to true for investor account
            investorAccount.EQT_Equity__c = true;
            update investorAccount;
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
        }
	}
	
	@isTest static void newCommitmentCreditNoTriggerTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable commitment trigger
        EQT_TestFactory.disableCommitmentTrigger();

        system.runAs(u) {
        	//create investor account
        	Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
        	//create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '6');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Credit__c  should be set to true for investor account
            investorAccount.EQT_Credit__c  = true;
            update investorAccount;
            system.assertEquals(true, [SELECT EQT_Credit__c  FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c );
        }
	}

	@isTest static void newCommitmentInfrastructureNoTriggerTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable commitment trigger
        EQT_TestFactory.disableCommitmentTrigger();

        system.runAs(u) {
        	//create investor account
        	Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
        	//create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '7');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Infrastructure__c  should be set to true for investor account
            investorAccount.EQT_Infrastructure__c  = true;
            update investorAccount;
            system.assertEquals(true, [SELECT EQT_Infrastructure__c  FROM Account WHERE Id = :investorAccount.Id].EQT_Infrastructure__c );
        }
	}

	@isTest static void newCommitmentMidMarketNoTriggerTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable commitment trigger
        EQT_TestFactory.disableCommitmentTrigger();

        system.runAs(u) {
        	//create investor account
        	Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
        	//create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '10');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Mid_Market__c  should be set to true for investor account
            investorAccount.EQT_Mid_Market__c  = true;
            update investorAccount;
            system.assertEquals(true, [SELECT EQT_Mid_Market__c  FROM Account WHERE Id = :investorAccount.Id].EQT_Mid_Market__c );
        }
	}

	@isTest static void newCommitmentSeniorDebtNoTriggerTest() {
		User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //disable commitment trigger
        EQT_TestFactory.disableCommitmentTrigger();

        system.runAs(u) {
        	//create investor account
        	Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
        	system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
        	//create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '11');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Credit__c should be set to true for investor account
            investorAccount.EQT_Credit__c = true;
            update investorAccount;
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
        }
	}

    @isTest static void newCommitmentEquityTriggerTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //enable commitment trigger
        EQT_TestFactory.enableCommitmentTrigger();

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund' AND EQT_Fund_Strategy__c = '3'].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Equity__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
        }
    }

    @isTest static void newCommitmentAllTypeTriggerTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //enable commitment trigger
        EQT_TestFactory.enableCommitmentTrigger();

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund1 = EQT_TestFactory.createSampleFund('sample fund1', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund1.Id].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFund('sample fund2', '6');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund3 = EQT_TestFactory.createSampleFund('sample fund3', '7');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund3.Id].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund4 = EQT_TestFactory.createSampleFund('sample fund4', '10');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund4.Id].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund5 = EQT_TestFactory.createSampleFund('sample fund5', '11');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund5.Id].size());
            //create sample commitments for each strategy and save investor
            EQT_Commitment__c commitment1 = EQT_TestFactory.createSampleCommitment(sampleFund1.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund1.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            EQT_Commitment__c commitment3 = EQT_TestFactory.createSampleCommitment(sampleFund3.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund3.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            EQT_Commitment__c commitment4 = EQT_TestFactory.createSampleCommitment(sampleFund4.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund4.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            EQT_Commitment__c commitment5 = EQT_TestFactory.createSampleCommitment(sampleFund5.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund5.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            //verify investor
            investorAccount = [SELECT Id, EQT_Equity__c, EQT_Credit__c,
                                EQT_Infrastructure__c, EQT_Mid_Market__c
                                FROM Account
                                WHERE Id = :investorAccount.Id];

            system.assertEquals(true, investorAccount.EQT_Equity__c);
            system.assertEquals(true, investorAccount.EQT_Credit__c);
            system.assertEquals(true, investorAccount.EQT_Infrastructure__c);
            system.assertEquals(true, investorAccount.EQT_Mid_Market__c);
        }
    }

    @isTest static void newCommitmentListTriggerTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //enable commitment trigger
        EQT_TestFactory.enableCommitmentTrigger();

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create another fund with strategy = credit
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFund('sample fund2', '6');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            //EQT_Equity__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            //create another commitment for the same investor
            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Credit__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
        }
    }

    @isTest static void updateCommitmentListTriggerTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //enable commitment trigger
        EQT_TestFactory.enableCommitmentTrigger();

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create second investor account
            Account investorAccount2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account2');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account2' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create another fund with strategy = credit
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFund('sample fund2', '6');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            //EQT_Equity__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            //create another commitment for the same investor
            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Credit__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            //update commitment2
            commitment2.EQT_Investor__c = investorAccount2.Id;
            update commitment2;
            //verify flags
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            system.assertEquals(false, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
            system.assertEquals(false, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount2.Id].EQT_Equity__c);
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount2.Id].EQT_Credit__c);
        }
    }

    @isTest static void deleteCommitmentListTriggerTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //enable commitment trigger
        EQT_TestFactory.enableCommitmentTrigger();

        system.runAs(u) {
            //create investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Name = :'investor account' AND RecordType.Name = 'Investor Gatekeeper'].size());
            //create sample fund with strategy = Equity
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());
            //create another fund with strategy = credit
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFund('sample fund2', '6');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            //crete sample fund with strategy = Equity
            Fund__c sampleFund3 = EQT_TestFactory.createSampleFund('sample fund3', '3');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund3.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());

            //EQT_Equity__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            //create another commitment for the same investor
            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //EQT_Credit__c should be set to true for investor account
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
            //create sample commitment
            EQT_Commitment__c commitment3 = EQT_TestFactory.createSampleCommitment(sampleFund3.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund3.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);

            //delete one commitme with strategy = Equity
            delete commitment;
            //verify investor have still EQT_Equity__c field selected as there is another commitment with such strategy
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
            system.assertEquals(true, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
            //no delete this remaining commitment with strategu = Equity
            delete commitment3;
            system.assertEquals(true, [SELECT EQT_Credit__c FROM Account WHERE Id = :investorAccount.Id].EQT_Credit__c);
            system.assertEquals(false, [SELECT EQT_Equity__c FROM Account WHERE Id = :investorAccount.Id].EQT_Equity__c);
        }
    }
    */
}