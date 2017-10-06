public with sharing class EQT_Proxy_AccountContactRelation_SVC {
	
	@future
	public static void emptyProxyTable(List<String> proxyIds) {
		//delete all data from proxy table
    	if(!proxyIds.isEmpty()) {
    		delete [SELECT Id FROM EQT_Proxy_AccountContactRelation__c WHERE Id IN :proxyIds];
    	}
	}
}