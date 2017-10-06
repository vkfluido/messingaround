/**
    About
    -----
    Description: User management of Fund to partnership mapping
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    - Page actions
    	sortAction //sort results based on clicked column
    	cancel //go to home page

    - Generic
    	getFundPartnerships //load Fund Partnerships records
    	filter //filter fund partnerships list
    	hasNext //check if there are more records to show
        hasPrevious //check if previous set of data exists
        first //show first page
        last //show last page
        previous //show previous page
        next //show next page
   
    Update History
    --------------
    Created June 2016 - R.B.
    Updated June 2016 - R.B. - added filtering

    Issues / TODOs
    --------------
*/
public with sharing class EQT_Manage_Fund_Partnership_VFC {
	/* Wrapper class */
	public class FundPartnershipWrapper {
		public Boolean isMapped {get;set;}
		public EQT_Fund_Partnership__c fundPartnershipRecord {get;set;}
		private final EQT_Fund_Partnership__c fundPartnershipRecord_original;

		public FundPartnershipWrapper(EQT_Fund_Partnership__c record) {
			this.fundPartnershipRecord = record;
			this.isMapped = record.EQT_Fund__c != null;
			this.fundPartnershipRecord_original = record.clone(true, true);
		}
	}

	public List<FundPartnershipWrapper> fundPartnershipList {get;set;}
	public Boolean showNotMapped {get;set;}
	public Integer pageSize {get;set;}
    public Integer totalSize {get;set;}
    public String orderByField {get;set;}
    public String orderByType {get;set;}
    public String partnershipName {get;set;}
    public String legalEntityId {get;set;}

	public EQT_Manage_Fund_Partnership_VFC() {
		showNotMapped = true;
		orderByField = 'Partnership_Name__c';
        orderByType = 'DESC';
		pageSize = 50;
		loadFundPartnerships();
	}

	private void loadFundPartnerships() {
		fundPartnershipList = new List<FundPartnershipWrapper>();
		for(EQT_Fund_Partnership__c fp : (List<EQT_Fund_Partnership__c>)con.getRecords()) {
			fundPartnershipList.add(new FundPartnershipWrapper(fp));
		}
	}

	// instantiate the StandardSetController from a query locator
    // FETCH FUND PARTNERSHIPS
	public ApexPages.StandardSetController con {
		get {
			if(con == null) {
				String query = 'SELECT Id, Partnership_Name__c, EQT_Fund__c, EQT_Investran_Partnership_Legal_EntityID__c ' + 
								'FROM EQT_Fund_Partnership__c ';

				if(showNotMapped) {
					query += 'WHERE EQT_Fund__c = null ';
				}
				else {
					query += 'WHERE EQT_Fund__c != null ';
				}

				if(String.isNotEmpty(partnershipName)) {
                    query += 'AND Partnership_Name__c LIKE \'%' + String.escapeSingleQuotes(partnershipName) + '%\' ';
                }

                if(String.isNotEmpty(legalEntityId)) {
                    query += 'AND EQT_Investran_Partnership_Legal_EntityID__c LIKE \'%' + String.escapeSingleQuotes(legalEntityId) + '%\' ';
                }

				query += 'ORDER BY ' + orderByField + ' ' + orderByType;

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
        loadFundPartnerships();
    }

    // returns the last page of records
    public void last() {
        con.last();
        loadFundPartnerships();
    }

    // returns the previous page of records
    public void previous() {
        con.previous();
        loadFundPartnerships();
    }

    // returns the next page of records
    public void next() {
        con.next();
        loadFundPartnerships();
    }

    // used to refresh results after selecting ordering
    public void sortAction() {
        system.debug('Order by:' + orderByField);
        system.debug('Order :' + orderByType);
        con = null;
        loadFundPartnerships();
    }

	public PageReference cancel() {
		PageReference pr = new PageReference('/');
		pr.setRedirect(true);

		return pr;
	}

	public PageReference save() {
		try {
			List<EQT_Fund_Partnership__c> toUpdate = new List<EQT_Fund_Partnership__c>();

			for(FundPartnershipWrapper fpw : fundPartnershipList) {
				if(fpw.fundPartnershipRecord_original.EQT_Fund__c != fpw.fundPartnershipRecord.EQT_Fund__c) {
					toUpdate.add(fpw.fundPartnershipRecord);
				}
			}

			if(!toUpdate.isEmpty()) {
				update toUpdate;
				//load unmapped records
                showNotMapped = true;
                filter();
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.EQT_InfoMessage_MappingSuccessfullySaved));
			}
			else {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.EQT_InfoMessage_NoChangesDetected));
			}			
		}
		catch(Exception e) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
		}

		return null;
	}

	public PageReference filter() {
        con = null;
        loadFundPartnerships();
        return null;
    }
}