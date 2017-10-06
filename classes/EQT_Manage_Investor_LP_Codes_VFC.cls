/**
    About
    -----
    Description: User mapping for LP Codes to Investors
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    - Page actions
        sortAction //sort results based on clicked column
        cancel //go to home page

    - Generic
        loadInvestorLPCodes //load investor LP Codes
        filter //filter LP codes list
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
    Updated July 2016 - R.B. - fix save

    Issues / TODOs
    --------------
*/
public with sharing class EQT_Manage_Investor_LP_Codes_VFC {
    /* Wrapper class */
    public class InvestorLPCodeWrapper {
        public Boolean isMapped {get;set;}
        public EQT_Investor_LP_Code__c investorLPCodeRecord {get;set;}
        private final EQT_Investor_LP_Code__c investorLPCodeRecord_original;

        public InvestorLPCodeWrapper(EQT_Investor_LP_Code__c record) {
            this.investorLPCodeRecord = record;
            this.isMapped = record.EQT_Investor__c != null;
            this.investorLPCodeRecord_original = record.clone(true, true);
        }
    }

    public List<InvestorLPCodeWrapper> investorLPCodeList {get;set;}
    public Boolean showNotMapped {get;set;}
    public Integer pageSize {get;set;}
    public Integer totalSize {get;set;}
    public String orderByField {get;set;}
    public String orderByType {get;set;}
    public String investorLPCode {get;set;}
    public String vehicleName {get;set;}

    public EQT_Manage_Investor_LP_Codes_VFC() {
        showNotMapped = true;
        orderByField = 'EQT_Vehicle_Name__c';
        orderByType = 'DESC';
        pageSize = 50;
        loadInvestorLPCodes();
    }

    private void loadInvestorLPCodes() {
        investorLPCodeList = new List<InvestorLPCodeWrapper>();
        for(EQT_Investor_LP_Code__c invLPCode : (List<EQT_Investor_LP_Code__c>)con.getRecords()) {
            investorLPCodeList.add(new InvestorLPCodeWrapper(invLPCode));
        }
    }    

    // instantiate the StandardSetController from a query locator
    // FETCH INVESTOR LP CODES
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                String query = 'SELECT Id, Name, EQT_Investor__c, EQT_Vehicle_Name__c ' + 
                                'FROM EQT_Investor_LP_Code__c ';

                if(showNotMapped) {
                    query += 'WHERE EQT_Investor__c = null ';
                }
                else {
                    query += 'WHERE EQT_Investor__c != null ';
                }

                if(String.isNotEmpty(investorLPCode)) {
                    query += 'AND Name LIKE \'%' + String.escapeSingleQuotes(investorLPCode) + '%\' ';
                }

                if(String.isNotEmpty(vehicleName)) {
                    query += 'AND EQT_Vehicle_Name__c LIKE \'%' + String.escapeSingleQuotes(vehicleName) + '%\' ';
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
        loadInvestorLPCodes();
    }

    // returns the last page of records
    public void last() {
        con.last();
        loadInvestorLPCodes();
    }

    // returns the previous page of records
    public void previous() {
        con.previous();
        loadInvestorLPCodes();
    }

    // returns the next page of records
    public void next() {
        con.next();
        loadInvestorLPCodes();
    }

    // used to refresh results after selecting ordering
    public void sortAction() {
        system.debug('Order by:' + orderByField);
        system.debug('Order :' + orderByType);
        con = null;
        loadInvestorLPCodes();
    }

    public PageReference cancel() {
        PageReference pr = new PageReference('/');
        pr.setRedirect(true);

        return pr;
    }

    public PageReference save() {
        try {
            List<EQT_Investor_LP_Code__c> toUpdate = new List<EQT_Investor_LP_Code__c>();

            for(InvestorLPCodeWrapper ilpcw : investorLPCodeList) {
                if(ilpcw.investorLPCodeRecord_original.EQT_Investor__c != ilpcw.investorLPCodeRecord.EQT_Investor__c) {
                    toUpdate.add(ilpcw.investorLPCodeRecord);
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
        loadInvestorLPCodes();
        return null;
    }
}