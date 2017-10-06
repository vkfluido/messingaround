/**
    About
    -----
    Description: Provides data for Add Investor to Campaing page
    Created for: EQT
    Create date: July 2016
    
    Details / Methods
    -----------------
    - 
   
    Update History
    --------------
    Created July 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AddInvestorToCampaign_VFCx {
	
	private String accountId;
	private Account account;
	public List<CampaignWrapper> campaignList {get; set;}
	public Integer pageSize {get;set;}
    public Integer totalSize {get;set;}
    private String campaignRecordTypeId;

	/* Wrapper class */
	public class CampaignWrapper {
		public Boolean selected {get;set;}
		public Campaign campaignRecord {get;set;}

		public CampaignWrapper(Campaign campaign) {
			this.selected = false;
			this.campaignRecord = campaign;
		}
	}

	public EQT_AddInvestorToCampaign_VFCx(ApexPages.StandardController stdController) {
		accountId = stdController.getId();
		account = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :accountId];
		pageSize = 10;
		campaignRecordTypeId = EQT_UTIL_Meta.getRecordTypeId('Campaign.' + EQT_UTIL_Settings.getCampaignInvestorEventRecordTypeName());
	}

	public List<CampaignWrapper> getCampaigns() {
		campaignList = new List<CampaignWrapper>();

		for(Campaign c : (List<Campaign>)con.getRecords()) {
			campaignList.add(new CampaignWrapper(c));
		}

		return campaignList;
	}

	public PageReference addInvestor() {
		PageReference pr = new PageReference('/' + accountId);
		pr.setRedirect(true);

		List<EQT_Campaign_Account_Member__c> campaignAccountMembers = new List<EQT_Campaign_Account_Member__c>();
		Set<String> selectedCampaigns = new Set<String>();

		for(CampaignWrapper campaignW : campaignList) {
			if(campaignW.selected) {
				campaignAccountMembers.add(new EQT_Campaign_Account_Member__c
					(
						EQT_Account__c = accountId,
						EQT_Campaign__c = campaignW.campaignRecord.Id
					)
				);

				selectedCampaigns.add(campaignW.campaignRecord.Id);
			}
		}

		if(campaignAccountMembers.isEmpty()) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_NoRecordSelected));
			return null;
		}
		else {
			//check for already existing campaign account members
			List<EQT_Campaign_Account_Member__c> existingCampaignAccountMembers = [SELECT Id FROM EQT_Campaign_Account_Member__c
																					WHERE EQT_Account__c = :accountId
																					AND EQT_Campaign__c IN :selectedCampaigns];

			if(!existingCampaignAccountMembers.isEmpty()) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.EQT_ErrorMessage_InvestorAlreadyAddedToCampaign));
				return null;
			}

			Savepoint sp = Database.setSavepoint();

			try {
				insert campaignAccountMembers;
			}
			catch(Exception e) {
				Database.rollback(sp);
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
				return null;
			}
		}

		return pr;
	}

	// instantiate the StandardSetController from a query locator
    // FETCH ACCOUNTS THAT MATCHES SEARCH CRITERIA
	public ApexPages.StandardSetController con {
		get {
			if(con == null) {
				String query = 'SELECT Id, Name, StartDate, EQT_Fund__c, Status FROM Campaign ' +
								'WHERE RecordTypeId = :campaignRecordTypeId ' +
								'AND IsActive = true ' +
								'AND Status IN (\'In Progress\', \'Planning\') ';

				// sets the number of records in each page set
                con = new ApexPages.StandardSetController(Database.getQueryLocator(query));
                con.setPageSize(pageSize);
                totalSize = con.getResultSize();
			}
			return con;
		}
		set;
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
    }

    // returns the last page of records
    public void last() {
        con.last();
    }

    // returns the previous page of records
    public void previous() {
        con.previous();
    }

    // returns the next page of records
    public void next() {
        con.next();
    }
}