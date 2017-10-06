/**
    About
    -----
    Description: Provides data for Add Investor to fundraise page
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    - Page actions
    	addInvestor //creates for selected fund records Opportunities with Record Type Fundrasing Request
    				// and for each of them OpportunityContactRoles entries for all key contacts
   
    Update History
    --------------
    Created May 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AddInvestorToFundraise_VFCx {

	private String accountId;
	private Account account;
	public List<FundWrapper> fundList {get; set;}
	public List<KeyContactWrapper> keyContactList {get; set;}
	private Set<String> notClosedStages;
	private String fundraisingFundRecordTypeId;
    private String coInvestmentFundRecordTypeId;
    private String fundrasingOpportunityRecordTypeId;
    private String coInvestmentOpportunityRecordTypeId;

	/* Wrapper class */
	public class FundWrapper {
		public Boolean selected {get;set;}
		public Fund__c fundRecord {get;set;}

		public FundWrapper(Fund__c fund) {
			this.selected = false;
			this.fundRecord = fund;
		}
	}

	/* Wrapper class */
	public class KeyContactWrapper {
		public String contactId {get;set;}
		public String contactName {get;set;}
		public String roles {get;set;}

		public KeyContactWrapper(AccountContactRelation relation) {
			this.contactId = relation.ContactId;
			this.contactName = relation.Contact.Name;
			this.roles = relation.Roles;
		}

		public KeyContactWrapper(Contact contact) {
			this.contactId = contact.Id;
			this.contactName = contact.Name;
		}
	}

	public EQT_AddInvestorToFundraise_VFCx(ApexPages.StandardController stdController) {
		accountId = stdController.getId();
		account = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :accountId];
		loadFundList();
		loadInvestorList();
	}

	//loads fund records
	private void loadFundList() {
		fundList = new List<FundWrapper>();
		//get record types ids
		fundraisingFundRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundPlanningFundraisingRecordTypeName());
		coInvestmentFundRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundCoInvestmentFundraiseRecordTypeName());
		fundrasingOpportunityRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());
		coInvestmentOpportunityRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName());

		String planningFundraisingStatusSetting = EQT_UTIL_Settings.getFundPlanningFundraisingStatuseName();
		List<String> planningFundraisingStatuses = String.isNotEmpty(planningFundraisingStatusSetting) ? planningFundraisingStatusSetting.split(';') : new List<String>();

		for(Fund__c fund : [SELECT Id, Name, EQT_Final_Close_Date__c, RecordTypeId
							FROM Fund__c
							WHERE RecordTypeId IN (:fundraisingFundRecordTypeId, :coInvestmentFundRecordTypeId)
							AND Status__c IN :planningFundraisingStatuses]) {

			fundList.add(new FundWrapper(fund));
		}
	}

	//load investor list based on account in context
	private void loadInvestorList() {
		keyContactList = new List<KeyContactWrapper>();
		for(AccountContactRelation investor : [SELECT Id, ContactId, Contact.Name, Roles,
													StartDate, EndDate
													FROM AccountContactRelation
													WHERE IsActive = true
													AND IsDirect = true
													AND AccountId = :accountId]) {
		
			keyContactList.add(new KeyContactWrapper(investor));
		}

		if(keyContactList.isEmpty()) {
			List<Contact> associatedContact = [SELECT Id, Name FROM Contact WHERE Name = :account.Name];
			if(!associatedContact.isEmpty()) {
				keyContactList.add(new KeyContactWrapper(associatedContact[0]));
			}
		}
	}

	public PageReference addInvestor() {
		
		PageReference pr = new PageReference('/' + accountId);
		pr.setRedirect(true);

		List<OpportunityContactRole> toCreate = new List<OpportunityContactRole>();
		List<Opportunity> oppToCreateList = new List<Opportunity>();
		Opportunity opportunitytoCreate;

		Set<String> selectedFunds = new Set<String>();

		for(FundWrapper fundW : fundList) {
			if(fundW.selected) {
				String newOppName = fundW.fundRecord.Name + ' - ' + account.Name;

				opportunitytoCreate = new Opportunity();
				opportunitytoCreate.Name = newOppName.length() > 120 ? newOppName.substring(0,120) : newOppName;
				opportunitytoCreate.AccountId = account.Id;
				opportunitytoCreate.CloseDate = fundW.fundRecord.EQT_Final_Close_Date__c;
				opportunitytoCreate.OwnerId = account.OwnerId;
				opportunitytoCreate.EQT_Fund__c = fundW.fundRecord.Id;
				opportunitytoCreate.EQT_Code_Invoked__c = true;
				if(fundW.fundRecord.RecordTypeId == fundraisingFundRecordTypeId) {
					opportunitytoCreate.StageName = EQT_UTIL_Settings.getOpportunityFundraisingRequestDefaultStage();
					opportunitytoCreate.RecordTypeId = fundrasingOpportunityRecordTypeId;
				}
				else if(fundW.fundRecord.RecordTypeId == coInvestmentFundRecordTypeId) {
					opportunitytoCreate.RecordTypeId = coInvestmentOpportunityRecordTypeId;
					opportunitytoCreate.StageName = EQT_UTIL_Settings.getOpportunityCoInvestmentDefaultStage();
					opportunitytoCreate.Type = EQT_UTIL_Settings.getOpportynityCoInvestmentDefaultType();
					opportunitytoCreate.EQT_Likelyhood_for_close__c = EQT_UTIL_Settings.getOpportunityCoInvestmentLikelyHoodForClose();
				}

				oppToCreateList.add(opportunitytoCreate);
				
				selectedFunds.add(fundW.fundRecord.Id);
			}
		}

		if(oppToCreateList.isEmpty()) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_NoRecordSelected));
			return null;
		}
		else {

			//check for already existing opportunities with selected fund and account
			List<Opportunity> alreadyExistingOpp = [SELECT Id FROM Opportunity
													WHERE AccountId = :account.Id
													AND EQT_Fund__c IN :selectedFunds
													AND RecordTypeId IN (:fundrasingOpportunityRecordTypeId, :coInvestmentOpportunityRecordTypeId)];

			if(!alreadyExistingOpp.isEmpty()) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_OppExistsForAccountAndFund));
				return null;
			}

			Savepoint sp = Database.setSavepoint();

			try {
				insert oppToCreateList;
				//now add key contacts
				for(Opportunity newOpp : oppToCreateList) {
					for(KeyContactWrapper contact : keyContactList) {
						toCreate.add(new OpportunityContactRole(ContactId = contact.contactId, isPrimary = false, OpportunityId = newOpp.Id));
					}
				}
				if(!toCreate.isEmpty()) {
					insert toCreate;
				}
			}
			catch(Exception e) {
				Database.rollback(sp);
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
				return null;
			}
		}

		return pr;
	}
}