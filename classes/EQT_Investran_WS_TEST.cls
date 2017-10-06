@isTest
private class EQT_Investran_WS_TEST {
	
	@isTest static void constructAndRequestInvestranWebService() {
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/InvestranImport/scheduleBatch';  
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		EQT_Investran_WS.resultClass r = EQT_Investran_WS.scheduleBatch();
		System.assert(r.asyncApexJobId!=null);
	}
}