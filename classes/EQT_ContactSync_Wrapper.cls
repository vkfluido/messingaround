/**
    About
    -----
    Description: REST Service wrapper class
    Created for: EQT
    Create date: June 2017

    Details / Methods
    -----------------


    Update History
    --------------
    Created June 2017 - R.B.

    Issues / TODOs
    --------------
*/
global class EQT_ContactSync_Wrapper {

    global class RequestParams {
        public String lastcall_timestamp { get; set; }
        public String username { get; set; }
        public String index { get; set; }
    }

    global class ResponseObj {
        public List<Contact> contacts { get; set; }
        public UserInfo userInfo { get; set; }
        public String indexToStartWith { get; set; }
    }

    global class UserInfo {
        public String ssoUserId { get; set; }
        public String userName { get; set; }
        public Boolean isActive { get; set; }
        public String lastModifiedDate { get; set; }

        public UserInfo() {}

        public UserInfo(User givenUser) {
            if(givenUser != null) {
                this.ssoUserId = givenUser.EQT_SSO_User_Id__c;
                this.userName = givenUser.Username;
                this.isActive = givenUser.isActive;
                this.lastModifiedDate = givenUser.LastModifiedDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            }
        }

        public UserInfo(String ssoUserId, String username, Boolean isActive, Datetime lastModifiedDate) {
            this.ssoUserId = ssoUserId;
            this.userName = userName;
            this.isActive = isActive;
            this.lastModifiedDate = lastModifiedDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
    }

    global class UserResponseObj {
        public List<EQT_ContactSync_Wrapper.UserInfo> users { get; set; }
        public String indexToStartWith { get; set; }
    }
}