@isTest
global class EQT_MockSlackCallout implements HttpCalloutMock {
	
	protected String body;
	protected Integer statusCode;

	public EQT_MockSlackCallout(String body, Integer statusCode) {
		this.body = body;
		this.statusCode = statusCode;
	}

	global HTTPResponse respond(HTTPRequest req) {
		//verify endpoint and method
		system.assert(req.getEndpoint().contains(EQT_UTIL_Settings.getSlackEndpointURL()));
    	system.assertEquals('GET', req.getMethod());

    	// Create a fake response
    	HttpResponse res = new HttpResponse();
    	res.setHeader('Content-Type', 'application/json');
    	res.setBody(this.body);
    	res.setStatusCode(this.statusCode);

    	return res;
	}
}