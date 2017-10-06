@RestResource(urlMapping='/InvestranImport/*')
global with sharing class EQT_Investran_WS  {
    @HttpGet
    global static resultClass scheduleBatch() {
    	RestRequest req = RestContext.request;

    	JSON resultObj;
    	resultClass result = new resultClass();
    	result.message = 'Failed to start';
    	result.status = 'FAIL';
		result.errorMessage = 'Unknown';
		result.command = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

		// Schedule the batch
		try
		{
			Id cleanDatabatchInstanceId = Database.executeBatch(new EQT_BatchInvestranRemoveCommitments());
			result.message = 'Batch scheduled successfully';
			result.asyncApexJobId = cleanDatabatchInstanceId;
			result.errorMessage = '';
			result.status = 'SUCCESS';
		} catch (exception e) {
			result.message = 'Batch failed to start';
			result.status = 'ERROR';
			result.errorMessage = ''+e;
		}

        return result;
    }

    global class resultClass {
    	public String status;
        public String errorMessage;
        public String message;
        public String asyncApexJobId;
        public String command;
    }


    /*
    Calling from CURL:
	curl https://test_or_login.salesforce.com/services/oauth2/token -d "grant_type=password" -d "client_id=consumer_key" -d "client_secret=consumer_secret" -d "username=user@name.com.dev" -d "password=the_password"
	curl -H "Authorization: Bearer access_token" "instance_url/services/apexrest/apexRestClass"
	The access_token may be the session ID also created in a soap login :)

	Example (to dev)
	----------------
	Login:
	curl https://test.salesforce.com/services/oauth2/token -d "grant_type=password" -d "client_id=3MVG92H4TjwUcLlIBrU.UbTRMHIb8wbYZNWi6ut352.3ZgvCO5X3Z285MQqxuIuY1lHMqsdf8w_pWWU2iR3VT" -d "client_secret=7684638042554218789" -d "username=integration@eqtpartners.com.dev" -d "password=eq7production16"
	
	Login Response: (JSON)
	{"access_token":"00D3E0000000U9P!AQMAQKSYUnqxC3MbMDvKv9N0v._s594zaOI3PLjudSTp46dQvyCBKR_21z81qczh7wrNPM0oHsEob7ZvJ8FXUQxCZt2r2XcL","instance_url":"https://eqtpartners--DEV.cs82.my.salesforce.com","id":"https://test.salesforce.com/id/00D3E0000000U9PUAU/00558000000zIyTAAU","token_type":"Bearer","issued_at":"1474017894280","signature":"OWGp8zHPw/kHmXv8rTJgwVMe/if2L6mJkX8HyKODYq0="}

	Service Call
	curl -H 'Authorization: Bearer 00D3E0000000U9P!AQMAQKSYUnqxC3MbMDvKv9N0v._s594zaOI3PLjudSTp46dQvyCBKR_21z81qczh7wrNPM0oHsEob7ZvJ8FXUQxCZt2r2XcL' "https://eqtpartners--DEV.cs82.my.salesforce.com/services/apexrest/InvestranImport/scheduleBatch"
   
   	Dev notes
   	---------
	Only one Get per class
	Get methods have no body (ie no parameters)

    RestRequest req = RestContext.request;
	RestResponse res = RestContext.response;

    @HttpPost
    global static {{ object_name }} cleanData() {

        {{ object_name }} obj;

        return obj;

    }

    @HttpPut
    global static {{ object_name }} updateObject() {

        {{ object_name }} obj;
	}*/
}