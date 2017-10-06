public class EQT_NetworkSearch_ExportController {
    // declarations
    private EQT_NetworkSearch_Wrapper.PageResult result = null;
    private EQT_NetworkSearch_Wrapper.SearchParams params = null;
    
    public EQT_NetworkSearch_ExportController() {
        // get params from key
        this.params = this.generateParamsFromKey(ApexPages.currentPage().getParameters().get('key'));
        
        // search and result
        if(params != null)
        	this.result = EQT_NetworkSearch_LCC.searchWithPagination2(params, 1, True, false, false, false, false);
    }
    
    public EQT_NetworkSearch_Wrapper.PageResult getResults() {
        return this.result;
    }
    
    public PageReference logExport() {
        EQT_NetworkSearch_LCC.logSearch(this.params, this.result);
        return null;
    }
    
    /**
     * Visualforce pages cannot output a XML declarations so we return it from the 
     * controller as a string which works.
     */
    public String getXmlDeclaration() {
        return '<?xml version="1.0" ?>';
    }
    
    /**
     * To output URLs in the resulting spreadsheet linking back to the appropriate 
     * environment we retrive the instance URL from the controller.
     */
    public String getInstanceURL() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public EQT_NetworkSearch_Wrapper.SearchParams generateParamsFromKey(String key) {
        // get key from URL
        if (String.isEmpty(key)) {
            System.debug(LoggingLevel.ERROR, 'Unable to find export key in URL - aborting');
            return null;
        }
        
        EQT_NetworkSearch_Wrapper.SearchParams params = new EQT_NetworkSearch_Wrapper.SearchParams();
        params.type = 4; // log as export
        params.accounts = new List<String>();
        params.deals = new List<String>();
        params.functionalFilter = new List<String>();
        params.geoFilter = new List<String>();
        params.sectorFilter = new List<String>();
        params.engagementLevel = new List<String>();
        params.suitablePositions = new List<String>();
        params.existingRoles = new List<String>();
        
        // get filters
        final List<EQT_IANetworkSearch_Save__c> saves = [SELECT OwnerId, SavedSearch__c, Filters__c FROM EQT_IANetworkSearch_Save__c WHERE Key__c =: key];
        if (saves.size() != 1) {
            System.debug(LoggingLevel.ERROR, 'Unable to find saved search for key <' + key + '> - aborting');
            return null;
        }
        final EQT_IANetworkSearch_Save__c search = saves[0];
        if (search.SavedSearch__c && !search.OwnerId.equals(UserInfo.getUserId())) {
            // this is a saved search but the current user is not the owner - abort
            System.debug(LoggingLevel.ERROR, 'Found search but the current user is not the owner - aborting');
            return null;
        }
        
        // get filters, decode from Base64 and parse
        final String json_str = EncodingUtil.base64Decode(search.Filters__c).toString();
        final JSONParser parser = JSON.createParser(json_str);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                // found array - loop till we find object start
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        String id;
                        String type;
                        while (parser.nextToken() != null) {
                            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getCurrentName().equalsIgnoreCase('id')) {
                                // get next value which must be the ID
                                parser.nextValue();
                                id = parser.getText();
                            } else if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getCurrentName().equalsIgnoreCase('type')) {
                                // get next value which must be the type
                                parser.nextValue();
                                type = parser.getText();
                            }
                            if (String.isNotEmpty(id) && String.isNotEmpty(type)) break;
                        }
                        
                        // look at type and add to appropriate query param
                        if (type.equalsIgnoreCase('sector')) {
                            params.sectorFilter.add(id);
                        } else if (type.equalsIgnoreCase('functional')) {
                            params.functionalFilter.add(id);
                        } else if (type.equalsIgnoreCase('geo')) {
                            params.geoFilter.add(id);
                        } else if (type.equalsIgnoreCase('account')) {
                            params.accounts.add(id);
                        } else if (type.equalsIgnoreCase('deal')) {
                            params.deals.add(id);
                        } else if (type.equalsIgnoreCase('engagementLevel')) {
                            params.engagementLevel.add(id);
                        } else if (type.equalsIgnoreCase('suitablePosition')) {
                            params.suitablePositions.add(id);
                        } else if (type.equalsIgnoreCase('existingRole')) {
                            params.existingRoles.add(id);
                        }
                    }
                }
            }
        }
        return params;
    }
 
}