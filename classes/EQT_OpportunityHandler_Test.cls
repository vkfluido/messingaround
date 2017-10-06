@isTest
private class EQT_OpportunityHandler_Test {
    
    
    @isTest static void optySetRecordIDByNamefromEPM() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            
            String oppStageName = 'Showing interest';
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('sample opp', sampleFund.Id, oppStageName, false);
            opp.EQT_EPM_Record_Type_Name__c = 'EQT_Fundraising_Request';
            insert opp;

            opp = [SELECT Id,RecordTypeId,EQT_EPM_Record_Type_Name__c FROM Opportunity WHERE Id = :opp.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Opportunity.EQT_Fundraising_Request'), opp.RecordTypeId);    

            //Update sample account with other record type name and check the record type is set
            opp.EQT_EPM_Record_Type_Name__c = 'EQT_Fundraising_Request';
            update opp;

            opp = [SELECT Id,RecordTypeId,EQT_EPM_Record_Type_Name__c FROM Opportunity WHERE Id = :opp.Id];
            system.assertEquals(EQT_UTIL_Meta.getRecordTypeId('Opportunity.EQT_Fundraising_Request'), opp.RecordTypeId); 
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());     
        }
    }

    @isTest static void deleteRollupTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        String oppStageName = 'Closed Out';
        /*
        Set<String> closedWonStages = new Set<String>();
        Set<String> notClosedStages = new Set<String>();
        List<String> opportunity1stCloseValues = new List<String>();

        //get stages for later roll-up
        for(OpportunityStage os : [SELECT Id, MasterLabel, IsClosed, IsWon FROM OpportunityStage]) {
            if(os.IsClosed && os.IsWon) {
                closedWonStages.add(os.MasterLabel);
            }
            else if(!os.IsClosed) {
                notClosedStages.add(os.MasterLabel);
            }
        }

        String customSettingValue = EQT_UTIL_Settings.getOpportunityCloseValue();

        if(customSettingValue != null) {
            //if more then 1 values is set in custom setting
            if(customSettingValue.contains(';')) {
                opportunity1stCloseValues.addAll(customSettingValue.split(';'));
            }
            else {
                opportunity1stCloseValues.add(customSettingValue);
            }
        }
        */
        //get stages for each calculation
        String csPipelineVolumeWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation();
        List<String> stagesForPipelineWeighted = new List<String>();
        if(csPipelineVolumeWeighted.contains(';')) {
            stagesForPipelineWeighted.addAll(csPipelineVolumeWeighted.split(';'));
        }
        else {
            stagesForPipelineWeighted.add(csPipelineVolumeWeighted);
        }

        String csPipelineVolumeUnWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation();
        List<String> stagesForPipelineUnweighted = new List<String>();
        if(csPipelineVolumeUnWeighted.contains(';')) {
            stagesForPipelineUnweighted.addAll(csPipelineVolumeUnWeighted.split(';'));
        }
        else {
            stagesForPipelineUnweighted.add(csPipelineVolumeUnWeighted);
        }

        String csCommittedCapital = EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation();
        List<String> stagesForCommittedCapital = new List<String>();
        if(csCommittedCapital.contains(';')) {
            stagesForCommittedCapital.addAll(csCommittedCapital.split(';'));
        }
        else {
            stagesForCommittedCapital.add(csCommittedCapital);
        }
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());

            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', a.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp.Id].size());
            //update amount on opportunity
            opp.Amount = 100;
            opp.Probability = 2;
            opp.EQT_Bite_Size__c = 100;
            update opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND Amount = 100 AND EQT_Bite_Size__c = 100].size());

            //verify rollup summary value
            system.assertEquals(100, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);

            //now delete opportunity
            delete opp;
            system.assertEquals(0, [SELECT Id FROM Opportunity WHERE EQT_Fund__c = :sampleFund.Id].size());
            
            //verify rollup summary
            system.assertEquals(0, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);
        }
    }

    @isTest static void insertUpdateRollupTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        String oppStageName1 = 'Closed Out';
        String oppStageName2 = 'Showing interest';
        
        //get stages for each calculation
        String csPipelineVolumeWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation();
        List<String> stagesForPipelineWeighted = new List<String>();
        if(csPipelineVolumeWeighted.contains(';')) {
            stagesForPipelineWeighted.addAll(csPipelineVolumeWeighted.split(';'));
        }
        else {
            stagesForPipelineWeighted.add(csPipelineVolumeWeighted);
        }

        String csPipelineVolumeUnWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation();
        List<String> stagesForPipelineUnweighted = new List<String>();
        if(csPipelineVolumeUnWeighted.contains(';')) {
            stagesForPipelineUnweighted.addAll(csPipelineVolumeUnWeighted.split(';'));
        }
        else {
            stagesForPipelineUnweighted.add(csPipelineVolumeUnWeighted);
        }

        String csCommittedCapital = EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation();
        List<String> stagesForCommittedCapital = new List<String>();
        if(csCommittedCapital.contains(';')) {
            stagesForCommittedCapital.addAll(csCommittedCapital.split(';'));
        }
        else {
            stagesForCommittedCapital.add(csCommittedCapital);
        }
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());

            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', a.Id, oppStageName1, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp.Id].size());
            //update amount on opportunity
            opp.Amount = 100;
            opp.Probability = 2;
            opp.EQT_Bite_Size__c = 100;
            update opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND Amount = 100 AND EQT_Bite_Size__c = 100].size());

            //verify rollup summary value
            system.assertEquals(100, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);

            //now add new opportunity
            Opportunity opp1 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp1', a.Id, oppStageName2, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp1.Id].size());
            //update amount on opportunity
            opp1.Amount = 100;
            opp1.Probability = 2;
            opp1.EQT_Bite_Size__c = 100;
            update opp1;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp1.Id AND Amount = 100 AND EQT_Bite_Size__c = 100].size());
            
            //verify rollup summary
            system.assertEquals(100, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(2, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(100, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);
        }
    }

    @isTest static void massRollupTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        String oppStageName1 = 'Closed Out';
        String oppStageName2 = 'Showing interest';
        
        //get stages for each calculation
        String csPipelineVolumeWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation();
        List<String> stagesForPipelineWeighted = new List<String>();
        if(csPipelineVolumeWeighted.contains(';')) {
            stagesForPipelineWeighted.addAll(csPipelineVolumeWeighted.split(';'));
        }
        else {
            stagesForPipelineWeighted.add(csPipelineVolumeWeighted);
        }

        String csPipelineVolumeUnWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation();
        List<String> stagesForPipelineUnweighted = new List<String>();
        if(csPipelineVolumeUnWeighted.contains(';')) {
            stagesForPipelineUnweighted.addAll(csPipelineVolumeUnWeighted.split(';'));
        }
        else {
            stagesForPipelineUnweighted.add(csPipelineVolumeUnWeighted);
        }

        String csCommittedCapital = EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation();
        List<String> stagesForCommittedCapital = new List<String>();
        if(csCommittedCapital.contains(';')) {
            stagesForCommittedCapital.addAll(csCommittedCapital.split(';'));
        }
        else {
            stagesForCommittedCapital.add(csCommittedCapital);
        }

        //disable opportunity trigger
        EQT_TestFactory.disableOpportunityTrigger();
        Opportunity opp1;
        Opportunity opp2;
        Fund__c sampleFund;

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            
            //create sample fund
            sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());

            opp1 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('for test1', a.Id, oppStageName1, sampleFund.Id);
            opp2 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('for test2', a.Id, oppStageName2, sampleFund.Id); 

            //create opportunities
            List<Opportunity> toInsert = new List<Opportunity>();
            String rtId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());
            for(Integer i=1; i<=200; i++) {
                toInsert.add(new Opportunity
                    (
                        Name = 'sample opp' + i,
                        CloseDate = Date.today().addDays(14),
                        AccountId = a.Id,
                        StageName = oppStageName1,
                        RecordTypeId = rtId,
                        EQT_Fund__c = sampleFund.Id,
                        Probability = 2,
                        EQT_Bite_Size__c = 100
                    )
                );
            }

            for(Integer i=1; i<=200; i++) {
                toInsert.add(new Opportunity
                    (
                        Name = 'sample opp 1' + i,
                        CloseDate = Date.today().addDays(14),
                        AccountId = a.Id,
                        StageName = oppStageName2,
                        RecordTypeId = rtId,
                        EQT_Fund__c = sampleFund.Id,
                        Probability = 2,
                        EQT_Bite_Size__c = 100
                    )
                );
            }

            for(Integer i=1; i<=200; i++) {
                toInsert.add(new Opportunity
                    (
                        Name = 'sample opp 2' + i,
                        CloseDate = Date.today().addDays(14),
                        AccountId = a.Id,
                        StageName = oppStageName2,
                        RecordTypeId = rtId,
                        EQT_Fund__c = sampleFund.Id,
                        Probability = 2,
                        EQT_Bite_Size__c = 100,
                        Type = EQT_UTIL_Settings.getOpportunityCoInvestmentPreSignType()
                    )
                );
            }

            for(Integer i=1; i<=200; i++) {
                toInsert.add(new Opportunity
                    (
                        Name = 'sample opp 3' + i,
                        CloseDate = Date.today().addDays(14),
                        AccountId = a.Id,
                        StageName = oppStageName2,
                        RecordTypeId = rtId,
                        EQT_Fund__c = sampleFund.Id,
                        Probability = 2,
                        EQT_Bite_Size__c = 100,
                        Type = EQT_UTIL_Settings.getOpportunityCoInvestmentPostSignType()
                    )
                );
            }

            insert toInsert;
            system.assertEquals(802, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND EQT_Fund__c = :sampleFund.Id].size());
        }

        //enable opportunity trigger
        EQT_TestFactory.enableOpportunityTrigger();
        system.runAs(u) {
            //make update to opp1 and verify rollups
            opp1.Probability = 2;
            opp1.EQT_Bite_Size__c = 100;
            update opp1;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp1.Id AND Probability = 2 AND EQT_Bite_Size__c = 100].size());

            //verify rollup summary
            system.assertEquals(20100, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            //EQT_Bite_Size__c*Probability (in percentage)
            system.assertEquals(1200, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(60000, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);
            system.assertEquals(20000, [Select Id, EQT_Pre_sign_syndication__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pre_sign_syndication__c);
            system.assertEquals(20000, [Select Id, EQT_Post_sign_syndication__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Post_sign_syndication__c);
        }
    }

    @isTest static void newInvestorNoCommitmentsTTTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :a.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', a.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp.Id].size());
            //verify status on opportunity
            system.assertEquals('TT', [SELECT EQT_E_T_TT__c FROM Opportunity WHERE Id = :opp.Id].EQT_E_T_TT__c);
        }
    }

    
    @isTest static void newInvestorCommitmentNoSetTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify status on opportunity
            system.assertEquals(null, [SELECT EQT_E_T_TT__c FROM Opportunity WHERE Id = :opp.Id].EQT_E_T_TT__c);
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
        }
    }

    @isTest static void newInvestorCommitmentsTTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            sampleFund.EQT_Fund_Sub_Strategy__c = 'Equity';
            update sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create another fund with different strategy
            Fund__c sampleFund1 = EQT_TestFactory.createSampleFund('sample fund', 'Private Capital');
            sampleFund1.EQT_Fund_Sub_Strategy__c = 'Infrastructure';
            update sampleFund1;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund1.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund1.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify status on opportunity
            system.assertEquals('T', [SELECT EQT_E_T_TT__c FROM Opportunity WHERE Id = :opp.Id].EQT_E_T_TT__c);
        }
    }

    @isTest static void newInvestorCommitmentsETest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create another fund with different strategy
            Fund__c sampleFund1 = EQT_TestFactory.createSampleFund('sample fund1', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund1.Id].size());
            //create fund with previus one
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFundWithPreviousFund('sample fund2', 'Credit', '');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            system.assert([SELECT EQT_Previous_Fund__c FROM Fund__c WHERE Id = :sampleFund2.Id].EQT_Previous_Fund__c != null);
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //crete aother commitment with previous fund
            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund1.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify status on opportunity
            system.assertEquals('E', [SELECT EQT_E_T_TT__c FROM Opportunity WHERE Id = :opp.Id].EQT_E_T_TT__c);
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
        }
    }

    @isTest static void createGatekeeperAssociationRecordInsertTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create new gatekeeper account
            Account gatekeeperAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample gatekeeper account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :gatekeeperAccount.Id].size());
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.AccountId = investorAccount.Id;
            opp.EQT_Gatekeeper__c = gatekeeperAccount.Id;
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());
            //verify gatekeeper association record was added
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c
                                    WHERE EQT_Gatekeeper__c = :opp.EQT_Gatekeeper__c
                                    AND EQT_Investor__c = :opp.AccountId].size());
        }
    }

    @isTest static void createGatekeeperAssociationRecordUpdateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create new gatekeeper account
            Account gatekeeperAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample gatekeeper account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :gatekeeperAccount.Id].size());
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.AccountId = investorAccount.Id;
            opp.EQT_Gatekeeper__c = gatekeeperAccount.Id;
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());
            //verify gatekeeper association record was added
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c
                                    WHERE EQT_Gatekeeper__c = :opp.EQT_Gatekeeper__c
                                    AND EQT_Investor__c = :opp.AccountId].size());

            //create new gatekeeper account
            Account gatekeeperAccount2 = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample gatekeeper account2');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :gatekeeperAccount2.Id].size());
            //update opportunity gatekeeper field to new gatekeeper account
            opp.EQT_Gatekeeper__c = gatekeeperAccount2.Id;
            update opp;
            //verify associations records
            system.assertEquals(2, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c
                                    WHERE EQT_Gatekeeper__c = :gatekeeperAccount.Id
                                    AND EQT_Investor__c = :opp.AccountId].size());
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c
                                    WHERE EQT_Gatekeeper__c = :opp.EQT_Gatekeeper__c
                                    AND EQT_Investor__c = :opp.AccountId].size());
        }
    }

    @isTest static void createGatekeeperAssociationRecordTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create new gatekeeper account
            Account gatekeeperAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample gatekeeper account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :gatekeeperAccount.Id].size());
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            //create gatekeeper association record
            EQT_Investor_Gatekeeper_Associations__c toAdd = new EQT_Investor_Gatekeeper_Associations__c();
            toAdd.EQT_Gatekeeper__c = gatekeeperAccount.Id;
            toAdd.EQT_Investor__c = investorAccount.Id;
            insert toAdd;
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.AccountId = investorAccount.Id;
            opp.EQT_Gatekeeper__c = gatekeeperAccount.Id;
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id].size());
            //verify gatekeeper association record was not added
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :gatekeeperAccount.Id].size());
            system.assertEquals(1, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c
                                    WHERE EQT_Gatekeeper__c = :opp.EQT_Gatekeeper__c
                                    AND EQT_Investor__c = :opp.AccountId].size());
        }
    }

    @isTest static void accountCountryAssignmentInsertTest() {/*
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account', false);
            investorAccount.EQT_Country__c = 'Poland'; //Poland
            insert investorAccount;
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());

            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.AccountId = investorAccount.Id;
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;

        }*/
    }

    @isTest static void accountCountryAssignmentUpdateNoAccountTest() {/*
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account', false);
            investorAccount.EQT_Country__c = 'Poland'; //Poland
            insert investorAccount;
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());

            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;

            //make update
            opp.AccountId = investorAccount.Id;
            update opp;
        }*/
    }

    @isTest static void accountCountryAssignmentUpdateTest() {/*
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';
        String fundraisingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());

            //create new investor account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', 'sample investor account', false);
            investorAccount.EQT_Country__c = 'Poland'; //Poland
            insert investorAccount;
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());

            EQT_TestFactory.disableOpportunityTrigger();
            //create sample opportunity
            Opportunity opp = EQT_TestFactory.createSampleOpportunity('test opp', sampleFund.Id, oppStageName, false);
            opp.AccountId = investorAccount.Id;
            opp.RecordTypeId = fundraisingRecordTypeId;
            insert opp;

            EQT_TestFactory.enableOpportunityTrigger();
            //make update
            opp.Description = 'test';
            update opp;
        }*/
    }

    @isTest static void opportunityInvestedPreviousFundTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create another fund with different strategy
            Fund__c sampleFund1 = EQT_TestFactory.createSampleFund('sample fund1', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund1.Id].size());
            //create prev fund
            Fund__c prevFund = EQT_TestFactory.createSampleFund('prev fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :prevFund.Id].size());
            //create fund with previus one
            Fund__c sampleFund2 = EQT_TestFactory.createSampleFundWithPreviousFund('sample fund2', 'Credit', prevFund.Id);
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund2.Id].size());
            system.assertEquals(prevFund.Id, [SELECT EQT_Previous_Fund__c FROM Fund__c WHERE Id = :sampleFund2.Id].EQT_Previous_Fund__c );
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample commitment
            EQT_Commitment__c commitment = EQT_TestFactory.createSampleCommitment(sampleFund.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            //crete aother commitment with previous fund
            EQT_Commitment__c commitment2 = EQT_TestFactory.createSampleCommitment(sampleFund2.Id, investorAccount.Id);
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :sampleFund2.Id
                                    AND EQT_Investor__c = :investorAccount.Id].size());
            EQT_Commitment__c commitment3 = EQT_TestFactory.createSampleCommitment(prevFund.Id, investorAccount.Id);
            commitment3.EQT_Amount__c = 1000;
            update commitment3;
            system.assertEquals(1, [SELECT Id FROM EQT_Commitment__c
                                    WHERE EQT_Fund__c = :prevFund.Id
                                    AND EQT_Investor__c = :investorAccount.Id
                                    AND EQT_Amount__c = 1000].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund2.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify status on opportunity
            system.assertEquals('E', [SELECT EQT_E_T_TT__c FROM Opportunity WHERE Id = :opp.Id].EQT_E_T_TT__c);
            //verify there are no gatekeeper associations records
            system.assertEquals(0, [SELECT Id FROM EQT_Investor_Gatekeeper_Associations__c].size());
            //verify EQT_Invested_Previous_Fund__c field have 1000 value
            system.assertEquals(1000, [SELECT EQT_Invested_Previous_Fund__c FROM Opportunity WHERE Id = :opp.Id].EQT_Invested_Previous_Fund__c);
        }
    }

    @isTest static void opportunityFirstInteractionDateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        String oppStageName = 'Showing interest';

        system.runAs(u) {
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id].size());
            //create new account
            Account investorAccount = EQT_TestFactory.createSampleAccount('Account.EQT_Investor_Gatekeeper', 'sample account');
            system.assertEquals(1, [SELECT Id FROM Account WHERE Id = :investorAccount.Id].size());
            //create sample Fundraising Request Opportunity
            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', investorAccount.Id, oppStageName, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :investorAccount.Id AND Id = :opp.Id].size());
            //verify that first interaction date is empty
            system.assertEquals(null, [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
            //create sample task for this opportunity
            Task t = EQT_TestFactory.createSampleTask(opp.Id, Date.today(), true);
            system.assertEquals(1, [SELECT Id FROM Task WHERE WhatId = :opp.Id].size());
            //verify opportunity have EQT_First_Interaction_Date__c set
            system.assertEquals(Date.today(), [SELECT EQT_First_Interaction_Date__c FROM Opportunity WHERE Id = :opp.Id].EQT_First_Interaction_Date__c);
        }
    }

    @isTest static void converstionRateTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE UserName = 'testuser@example.eqt'].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();
        //get metadata object type fields
        EQT_Admin_Business_Mapping__mdt mapping = EQT_UTIL_Settings.getAccountContactMap('Contact Account Mapping');
        String oppStageName1 = 'Closed Out';
        String oppStageName2 = 'Showing interest';
        
        //get stages for each calculation
        String csPipelineVolumeWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeWeightedCalculation();
        List<String> stagesForPipelineWeighted = new List<String>();
        if(csPipelineVolumeWeighted.contains(';')) {
            stagesForPipelineWeighted.addAll(csPipelineVolumeWeighted.split(';'));
        }
        else {
            stagesForPipelineWeighted.add(csPipelineVolumeWeighted);
        }

        String csPipelineVolumeUnWeighted = EQT_UTIL_Settings.getStagesForPipelineVolumeUnweightedCalculation();
        List<String> stagesForPipelineUnweighted = new List<String>();
        if(csPipelineVolumeUnWeighted.contains(';')) {
            stagesForPipelineUnweighted.addAll(csPipelineVolumeUnWeighted.split(';'));
        }
        else {
            stagesForPipelineUnweighted.add(csPipelineVolumeUnWeighted);
        }

        String csCommittedCapital = EQT_UTIL_Settings.getStagesForCommittedCapitalCalculation();
        List<String> stagesForCommittedCapital = new List<String>();
        if(csCommittedCapital.contains(';')) {
            stagesForCommittedCapital.addAll(csCommittedCapital.split(';'));
        }
        else {
            stagesForCommittedCapital.add(csCommittedCapital);
        }
        
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);
            String query = 'SELECT Id, Name, ' + mapping.EQT_Account_Company_Email_field__c + ',' + mapping.EQT_Account_Company_Phone_field__c + ' FROM Account WHERE Name=:accountName';
            List<Account> insertedAccount = Database.query(query);
            system.assertEquals(1, insertedAccount.size());
            
            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund');
            sampleFund.CurrencyIsoCode = 'USD';
            update sampleFund;
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Id = :sampleFund.Id AND CurrencyIsoCode = 'USD'].size());

            Opportunity opp = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp', a.Id, oppStageName1, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp.Id].size());
            //update amount on opportunity
            opp.CurrencyIsoCode = 'EUR';
            opp.Amount = 100;
            opp.Probability = 2;
            opp.EQT_Bite_Size__c = 100;
            update opp;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp.Id AND Amount = 100 AND EQT_Bite_Size__c = 100].size());

            //verify rollup summary value
            Decimal conversionRate = [SELECT ConversionRate FROM CurrencyType WHERE IsActive = true AND IsoCode = :sampleFund.CurrencyIsoCode].ConversionRate;
            
            system.assertEquals(100*conversionRate, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(0, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);

            //now add new opportunity
            Opportunity opp1 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('sample opp1', a.Id, oppStageName2, sampleFund.Id);
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Id = :opp1.Id].size());
            //update amount on opportunity
            opp1.CurrencyIsoCode = 'EUR';
            opp1.Amount = 100;
            opp1.Probability = 2;
            opp1.EQT_Bite_Size__c = 100;
            update opp1;
            system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Id = :opp1.Id AND Amount = 100 AND EQT_Bite_Size__c = 100].size());
            
            //verify rollup summary
            system.assertEquals(100*conversionRate, [Select Id, EQT_Committed_volumes__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Committed_volumes__c);
            system.assertEquals(2*conversionRate, [Select Id, EQT_Pipeline_Volume_Weighted__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume_Weighted__c);
            system.assertEquals(100*conversionRate, [Select Id, EQT_Pipeline_Volume__c FROM Fund__c WHERE Id = :sampleFund.Id].EQT_Pipeline_Volume__c);
        }
    }

    @isTest static void investorPreferencesNotInterestedTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());
        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        String oppStageName1 = 'No Interest';

        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);

            EQT_Investor_Preference_PE__c investorPref = EQT_TestFactory.createSampleInvestorPreference(a.Id, 'Credit', 'Not Interested', false);

            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());

            Opportunity opp1 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('for test1', a.Id, oppStageName1, sampleFund.Id);

            Opportunity oppResult = [SELECT Id, StageName FROM Opportunity WHERE id = :opp1.Id];
            system.assertEquals('Decline', oppResult.StageName);
        }
    }

    @isTest static void opportunityActivityTest() {
        User u = EQT_TestFactory.createUser('testuser@example.eqt', 'EQT Investor Relations');
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u.Id].size());

        User u2 = EQT_TestFactory.createUser('testuser2@example.eqt', 'EQT Investor Relations');
        u2.lastname = 'test2';
        update u2;
        system.assertEquals(1, [SELECT Id FROM User WHERE Id = :u2.Id].size());

        //disable Account trigger
        EQT_TestFactory.disableAccountTrigger();

        String oppStageName1 = 'No Interest';

        Opportunity opp1;
        Event e;
        Task t;
        system.runAs(u) {
            //create sample account
            String accountName = 'test account';
            Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Investor', accountName);

            //create sample fund
            Fund__c sampleFund = EQT_TestFactory.createSampleFund('sample fund', 'Credit');
            system.assertEquals(1, [SELECT Id FROM Fund__c WHERE Name = 'sample fund'].size());

            opp1 = EQT_TestFactory.createSampleFundraisingRequestOpportunity('for test1', a.Id, oppStageName1, sampleFund.Id);

            //create sample event
            e = new Event();
            e.DurationInMinutes = 15;
            e.ActivityDateTime = Datetime.now();
            //e.EQT_EPM_PersonID__c = '567';
            e.Subject = 'test';
            e.WhatId = opp1.id;
            insert e;

            Event eRes = [SELECT Id, EQT_Opportunity_Owner__c FROM Event WHERE Id = :e.Id];
            system.assertEquals('test', eRes.EQT_Opportunity_Owner__c);

            // create sample task
            t = EQT_TestFactory.createSampleTask(opp1.Id, Date.today(), true);
            Task tRes = [SELECT Id, EQT_Opportunity_Owner__c FROM Task WHERE Id = :t.Id];
            system.assertEquals('test', tRes.EQT_Opportunity_Owner__c);
        }

        opp1.OwnerId = u2.Id;
        update opp1;

        Event eRes = [SELECT Id,EQT_Opportunity_Owner__c FROM Event WHERE Id = :e.Id];
        system.assertEquals('test2', eRes.EQT_Opportunity_Owner__c);

        Task tRes = [SELECT Id, EQT_Opportunity_Owner__c FROM Task WHERE Id = :t.Id];
        system.assertEquals('test2', tRes.EQT_Opportunity_Owner__c);
    }
}