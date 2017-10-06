/**
    About
    -----
    Description: Provides data for Add Investors to fundraise page as Fund in context
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    - Page actions
    	add 	//creates for each Account record Opportunities with Record Type Fundrasing Request
    	search  //seach for accounts with specific criteria
    	checkAll //select/deselec all accounts om current page

    - Generic
    	hasNext //check if there are more records to show
        hasPrevious //check if previous set of data exists
        first //show first page
        last //show last page
        previous //show previous page
        next //show next page
        search //search accounts based on given criteria
        checkAll //select/deselect all accounts on currnet page
        add //creates new opportunities for selected Account and populates Opportunity contact roles
        	//for key accounts associated with selected Accounts
   
    Update History
    --------------
    Created May 2016 - R.B.
    Updated Jan 19, 2017 - felix.guerrero@fluidogroup.com: 
    				Message handling, added message for successes, added account name to error messages.
    				Does not stop if an investor already exists. Does not redirect to fund after adding investors.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AddInvestorsToFundraise_VFCx {
	public List<Schema.FieldSetMember> investorFields {get;set;}
	public List<Schema.FieldSetMember> investorPreferencesFields {get;set;}
	public Account accountToSearch {get;set;}
	public EQT_Investor_Preference_PE__c investorPreferenceToSearch {get;set;}
	public List<AccountWrapper> searchResults {get;set;}
	private Set<Id> accountIdsToSearch;
	private String DEBUGPREFIX = '*** EQT_AddInvestorsToFundraise_VFCx ***';
	public Integer pageSize {get;set;}
    public Integer totalSize {get;set;}
    public Boolean allSelected {get;set;}
    private Fund__c fund;
    //contains account ids which already exists for given fund in context and opportunity of type fundrising request
    private Set<Id> accountIds;
    private String fundrasingRecordTypeId;
    private String coInvestmentRecordTypeId;
    public List<SelectOption> checkboxStatuses {get;set;}
    //used only for checkbox fields to by default show -- None -- value to avoid narrowinf search result by default
    public Map<String, String> searchFieldMap {get;set;}
    //map for picklist values handling (global piclist not yest supported on VF page)
    //apiFiled -> possible picklist values
    public Map<String, List<SelectOption>> picklistMap {get;set;}
    //record type of newly created opportunity based on related fund record type
    private String fundraisingFundRecordTypeId;
    private String coInvestmentFundRecordTypeId;
    public Fund__c fundToSearchStrategySubstrategy {get;set;}
    //this var is only used for selecting/seareching fund record related to commitments
    //as IR profile can only read commitments records new commitment object cannot be created in code
    //because of Lightning issue (no DML operation on commitment object throws access error on lightning page)
    public Opportunity oppToSearchCommitment {get;set;}

	/* Wrapper class */
	public class AccountWrapper {
		public Boolean selected {get;set;}
		public Account account {get;set;}

		public AccountWrapper(Account account) {
			this.selected = false;
			this.account = account;
		}
	}

	public EQT_AddInvestorsToFundraise_VFCx(ApexPages.StandardController stdController) {
		fund = [SELECT Id, Name, EQT_Final_Close_Date__c, RecordTypeId
				FROM Fund__c
				WHERE Id = :stdController.getId()];
		fundToSearchStrategySubstrategy = new Fund__c();
		accountToSearch = new Account();
		investorFields = EQT_UTIL_Meta.getFieldSetFields('Account', 'Investor');
		investorPreferenceToSearch = new EQT_Investor_Preference_PE__c();
		investorPreferencesFields = EQT_UTIL_Meta.getFieldSetFields('EQT_Investor_Preference_PE__c', 'Investor_preferences');
		oppToSearchCommitment = new Opportunity();
		searchResults = new List<AccountWrapper>();
		pageSize = 50;

		//get opportunities record type ids based on record type name from custom settings
		fundrasingRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityFundraisingRequestRecordTypeName());
		coInvestmentRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Opportunity.' + EQT_UTIL_Settings.getOpportunityCoInvestmentRecordTypeName());

		//get funds record type ids based on record type name from custom settings
		fundraisingFundRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundPlanningFundraisingRecordTypeName());
		coInvestmentFundRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Fund__c.' + EQT_UTIL_Settings.getFundCoInvestmentFundraiseRecordTypeName());

		accountIds = new Set<Id>();

		for(Opportunity opp : [SELECT Id, AccountId FROM Opportunity
								WHERE EQT_Fund__c = :fund.Id
								AND RecordTypeId IN (:fundrasingRecordTypeId,:coInvestmentRecordTypeId)]) {
			accountIds.add(opp.AccountId);
		}
		setUpCheckBoxStatuses();
		buildSearchFieldMap();
		//build piklist map
		populatePicklistMap();
	}

	private void populatePicklistMap() {
		picklistMap = new Map<String, List<SelectOption>>();
		//start with account fields
		for(Schema.FieldSetMember f : investorFields) {
			if(f.getType() == Schema.DisplayType.PICKLIST) {
				picklistMap.put(f.getFieldPath(), getPicklistValues(new Account(), f.getFieldPath()));
			}
		}
		//now investror preferences
		for(Schema.FieldSetMember f : investorPreferencesFields) {
			if(f.getType() == Schema.DisplayType.PICKLIST) {
				picklistMap.put(f.getFieldPath(), getPicklistValues(new EQT_Investor_Preference_PE__c(), f.getFieldPath()));
			}
		}
	}

	private List<SelectOption> getPicklistValues(SObject objName, String fieldName) {
		List<SelectOption> result = new List<SelectOption>();
		result.add(new SelectOption('', Label.EQT_SelectList_None));

		Schema.sObjectType sObj = objName.getSObjectType();
		Schema.DescribeSObjectResult sObjDescribe = sObj.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = sObjDescribe.fields.getMap();

		List<Schema.PicklistEntry> ple = fieldMap.get(fieldName).getDescribe().getPickListValues();

		for(Schema.PicklistEntry f : ple) {
			result.add(new SelectOption(f.getValue(), f.getLabel()));
		}

		return result;
	}

	private void setUpCheckBoxStatuses() {
		checkboxStatuses = new List<SelectOption>();
		checkboxStatuses.add(new SelectOption(Label.EQT_SelectList_None, Label.EQT_SelectList_None));
		checkboxStatuses.add(new SelectOption('true', Label.EQT_SelectList_True));
		checkboxStatuses.add(new SelectOption('false', Label.EQT_SelectList_False));
	}

	private void buildSearchFieldMap() {
		searchFieldMap = new Map<String, String>();
		//loop through all objects and build field map for later use
		//account fields
		for(Schema.FieldSetMember f : investorFields) {
			searchFieldMap.put(f.getFieldPath(), '');
		}
		//investor preferences fields
		for(Schema.FieldSetMember f : investorPreferencesFields) {
			searchFieldMap.put(f.getFieldPath(), '');
		}
	}

	// instantiate the StandardSetController from a query locator
    // FETCH ACCOUNTS THAT MATCHES SEARCH CRITERIA
	public ApexPages.StandardSetController con {
		get {
			if(con == null) {
				accountIdsToSearch = new Set<Id>();
				//get account ids from investor preferences based on filled values
				Boolean initialInvPrefQuery = false;
				String invPrefQuery = '';
				for(Schema.FieldSetMember f : investorPreferencesFields) {
					if((f.getType() != Schema.DisplayType.BOOLEAN && investorPreferenceToSearch.get(f.getFieldPath()) != null)
						||  (f.getType() == Schema.DisplayType.BOOLEAN && searchFieldMap.containsKey(f.getFieldPath()) && searchFieldMap.get(f.getFieldPath()) != Label.EQT_SelectList_None)) {

						if(!initialInvPrefQuery) {
							invPrefQuery = 'SELECT Id, EQT_Account__c FROM EQT_Investor_Preference_PE__c';
							initialInvPrefQuery = true;
						}

						if(invPrefQuery.contains('WHERE')) {
				            if(f.getType() == Schema.DisplayType.PICKLIST || f.getType() == Schema.DisplayType.STRING) {
				            	invPrefQuery += ' AND ' + f.getFieldPath() + '=\'' + String.escapeSingleQuotes((String)investorPreferenceToSearch.get(f.getFieldPath())) + '\'';
				            }
				            else if(f.getType() == Schema.DisplayType.BOOLEAN) {
				                invPrefQuery += ' AND ' + f.getFieldPath() + '=' + Boolean.valueOf(searchFieldMap.get(f.getFieldPath())); //investorPreferenceToSearch.get(f.getFieldPath());
				            }
				        }
				        else {
				            if(f.getType() == Schema.DisplayType.PICKLIST || f.getType() == Schema.DisplayType.STRING) {
				            	invPrefQuery += ' WHERE ' + f.getFieldPath() + '=\'' + String.escapeSingleQuotes((String)investorPreferenceToSearch.get(f.getFieldPath())) + '\'';
				            }
				            else if(f.getType() == Schema.DisplayType.BOOLEAN) {
				                invPrefQuery += ' WHERE ' + f.getFieldPath() + '=' + Boolean.valueOf(searchFieldMap.get(f.getFieldPath())); //investorPreferenceToSearch.get(f.getFieldPath());
				            }
				        }
				    }
				}

				system.debug(DEBUGPREFIX + 'invPrefQuery=' + invPrefQuery);

				if(String.isNotEmpty(invPrefQuery)) {
					for(EQT_Investor_Preference_PE__c ip : Database.query(invPrefQuery)) {
						accountIdsToSearch.add(ip.EQT_Account__c);
					}
				}

				//get account ids from commitments based on filled values
				Boolean initialCommitmentQuery = false;
				String commitmentQuery = '';

				if(oppToSearchCommitment != null && String.isNotEmpty(oppToSearchCommitment.EQT_Fund__c)) {
					commitmentQuery = 'SELECT Id, EQT_Investor__c FROM EQT_Commitment__c';
					commitmentQuery += ' WHERE EQT_Fund__c=\'' + oppToSearchCommitment.EQT_Fund__c + '\'';
				}

				if(fundToSearchStrategySubstrategy != null && String.isNotEmpty(fundToSearchStrategySubstrategy.EQT_Fund_Strategy__c)) {
					if(String.isEmpty(commitmentQuery)) {
						commitmentQuery = 'SELECT Id, EQT_Investor__c FROM EQT_Commitment__c';
					}

					if(commitmentQuery.contains('WHERE')) {
						commitmentQuery += ' AND EQT_Fund_Strategy__c=\'' + fundToSearchStrategySubstrategy.EQT_Fund_Strategy__c + '\'';
					}
					else {
						commitmentQuery += ' WHERE EQT_Fund_Strategy__c=\'' + fundToSearchStrategySubstrategy.EQT_Fund_Strategy__c + '\'';
					}
				}

				if(fundToSearchStrategySubstrategy != null && String.isNotEmpty(fundToSearchStrategySubstrategy.EQT_Fund_Sub_Strategy__c)) {
					if(String.isEmpty(commitmentQuery)) {
						commitmentQuery = 'SELECT Id, EQT_Investor__c FROM EQT_Commitment__c';
					}

					if(commitmentQuery.contains('WHERE')) {
						commitmentQuery += ' AND EQT_Fund_Sub_Strategy__c=\'' + fundToSearchStrategySubstrategy.EQT_Fund_Sub_Strategy__c + '\'';
					}
					else {
						commitmentQuery += ' WHERE EQT_Fund_Sub_Strategy__c=\'' + fundToSearchStrategySubstrategy.EQT_Fund_Sub_Strategy__c + '\'';
					}
				}

				system.debug(DEBUGPREFIX + 'commitmentQuery=' + commitmentQuery);

				if(String.isNotEmpty(commitmentQuery)) {
					for(EQT_Commitment__c c : Database.query(commitmentQuery)) {
						accountIdsToSearch.add(c.EQT_Investor__c);
					}
				}

				//build account query
				String accountQuery = 'SELECT Id';
				for(Schema.FieldSetMember f : investorFields) {
					accountQuery += ', ' + f.getFieldPath();
				}
				accountQuery += ' FROM Account';
				//search for account now
				for(Schema.FieldSetMember f : investorFields) {
					if(accountToSearch.get(f.getFieldPath()) != null) {
						if(f.getType() == Schema.DisplayType.PICKLIST || f.getType() == Schema.DisplayType.STRING || f.getType() == Schema.DisplayType.Reference) {
							String fieldValue = (String)accountToSearch.get(f.getFieldPath());
							if(String.isNotEmpty(fieldValue)) {
								//DE15 - search by Account name should be working as Like
								if(f.getFieldPath() == 'Name') {
									if(accountQuery.contains('WHERE')) {
										accountQuery += ' AND ' + f.getFieldPath() + ' LIKE \'%' + String.escapeSingleQuotes((String)accountToSearch.get(f.getFieldPath())) + '%\'';
									}
									else {
										accountQuery += ' WHERE ' + f.getFieldPath() + ' LIKE \'%' + String.escapeSingleQuotes((String)accountToSearch.get(f.getFieldPath())) + '%\'';
									}
								}
								else {
									if(accountQuery.contains('WHERE')) {
										accountQuery += ' AND ' + f.getFieldPath() + '=\'' + String.escapeSingleQuotes((String)accountToSearch.get(f.getFieldPath())) + '\'';
									}
									else {
										accountQuery += ' WHERE ' + f.getFieldPath() + '=\'' + String.escapeSingleQuotes((String)accountToSearch.get(f.getFieldPath())) + '\'';
									}
								}
							}
						}
					}
				}

				if(!accountIdsToSearch.isEmpty()) {
					if(accountQuery.contains('WHERE')) {
						accountQuery += ' AND Id IN :accountIdsToSearch';
					}
					else {
						accountQuery += ' WHERE Id IN :accountIdsToSearch';
					}
				}
				accountQuery += ' ORDER BY Name'; 
				system.debug(DEBUGPREFIX + 'accountQuery=' + accountQuery);

				// sets the number of records in each page set
                con = new ApexPages.StandardSetController(Database.getQueryLocator(accountQuery));
                con.setPageSize(pageSize);
                totalSize = con.getResultSize();
			}
			return con;
		}
		set;
	}

	public PageReference search() {
		ApexPages.getMessages().clear();
		con = null;
		loadResults();

		return null;
	}

	private void loadResults() {
		searchResults = new List<AccountWrapper>();
		allSelected = false;

		for(Account a : (List<Account>)con.getRecords()) {
			searchResults.add(new AccountWrapper(a));
		}
	}

	public PageReference checkAll() {
		for(AccountWrapper aw : searchResults) {
			aw.selected = allSelected;
		}

		return null;
	}

	// indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }

    // returns the first page of records
    public void first() {
        con.first();
        loadResults();
    }

    // returns the last page of records
    public void last() {
        con.last();
        loadResults();
    }

    // returns the previous page of records
    public void previous() {
        con.previous();
        loadResults();
    }

    // returns the next page of records
    public void next() {
        con.next();
        loadResults();
    }

    public PageReference add() {
    	PageReference pr = new PageReference('/' + fund.Id);
    	pr.setRedirect(true);
		ApexPages.getMessages().clear();

    	List<Opportunity> oppToCreateList = new List<Opportunity>();

    	//account -> set of key contacts
    	Map<Id, Set<Id>> accountKeyContactMap = new Map<Id, Set<Id>>();
    	Set<Id> selectedAccounts = new Set<Id>();
    	List<OpportunityContactRole> toCreate = new List<OpportunityContactRole>();
    	Opportunity opportunitytoCreate;

        for(AccountWrapper aw : searchResults) {
    		if(aw.selected) {
    			//if there is already opportunity for selected account and fund in contect of type fundraising request or coinvestment
    			if(accountIds.contains(aw.account.Id)) {
    				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, aw.account.Name + ' - ' + Label.EQT_ErrorMessage_OppExistsForAccountAndFund));
					//return null;
    			}
    			else {
    				String newOppName = fund.Name + ' - ' + aw.account.Name;

    				selectedAccounts.add(aw.account.Id);

    				opportunitytoCreate = new Opportunity();
    				opportunitytoCreate.Name = newOppName.length() > 120 ? newOppName.substring(0,120) : newOppName;
    				opportunitytoCreate.AccountId = aw.account.Id;
    				opportunitytoCreate.CloseDate = fund.EQT_Final_Close_Date__c;
    				opportunitytoCreate.OwnerId = aw.account.OwnerId;
    				opportunitytoCreate.EQT_Fund__c = fund.Id;
    				opportunitytoCreate.EQT_Code_Invoked__c = true;
    				if(fund.RecordTypeId == fundraisingFundRecordTypeId) {
    					opportunitytoCreate.StageName = EQT_UTIL_Settings.getOpportunityFundraisingRequestDefaultStage();
    					opportunitytoCreate.RecordTypeId = fundrasingRecordTypeId;
    				}
    				else if(fund.RecordTypeId == coInvestmentFundRecordTypeId) {
    					opportunitytoCreate.RecordTypeId = coInvestmentRecordTypeId;
    					opportunitytoCreate.StageName = EQT_UTIL_Settings.getOpportunityCoInvestmentDefaultStage();
    					opportunitytoCreate.Type = EQT_UTIL_Settings.getOpportynityCoInvestmentDefaultType();
    					opportunitytoCreate.EQT_Likelyhood_for_close__c = EQT_UTIL_Settings.getOpportunityCoInvestmentLikelyHoodForClose();
    				}

    				oppToCreateList.add(opportunitytoCreate);
    			}
    		}
    	}

    	//build AccountKey contact map
    	if(!selectedAccounts.isEmpty()) {
    		for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId
    											FROM AccountContactRelation
												WHERE IsActive = true
												AND IsDirect = true
												AND AccountId IN :selectedAccounts]) {
    			if(accountKeyContactMap.containsKey(acr.AccountId)) {
    				accountKeyContactMap.get(acr.AccountId).add(acr.ContactId);
    			}
    			else {
    				Set<Id> contactIds = new Set<Id>();
    				contactIds.add(acr.ContactId);
    				accountKeyContactMap.put(acr.AccountId, contactIds);
    			}
    		}
    	}

    	if(oppToCreateList.isEmpty()) {
    		ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_NoRecordSelected));
			return null;
    	}
    	else {
    		Savepoint sp = Database.setSavepoint();

    		try {
    			insert oppToCreateList;
    			//now add key contacts
				for(Opportunity newOpp : oppToCreateList) {
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, newOpp.Name + ' added.'));
					if(accountKeyContactMap.containsKey(newOpp.AccountId)) {
						for(Id contactId : accountKeyContactMap.get(newOpp.AccountId)) {
							toCreate.add(new OpportunityContactRole(ContactId = contactId, isPrimary = false, OpportunityId = newOpp.Id));
						}
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

    	return null; //pr;
    }

    @RemoteAction
    public static List<User> getOwner(String ownerName) {
		if(String.isNotEmpty(ownerName)) {
			String query = 'SELECT Id, Name FROM User ' +
							'WHERE Name LIKE \'%' + String.escapeSingleQuotes(ownerName) + '%\' ' +
							'LIMIT 5';

			return Database.query(query);
		}
		else {
			return new List<User>();
		}
	}

	@RemoteAction
	public static List<Fund__c> getFunds(String fundName) {
		if(String.isNotEmpty(fundName)) {
			String query = 'SELECT Id, Name FROM Fund__c ' +
							'WHERE Name LIKE \'%' + String.escapeSingleQuotes(fundName) + '%\' ' +
							'LIMIT 5';

			return Database.query(query);
		}
		else {
			return new List<Fund__c>();
		}
	}
}