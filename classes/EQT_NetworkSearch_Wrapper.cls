/**
    About
    -----
    Description: Wrapper class for Network search functionality
    Created for: EQT
    Create date: March 2017

    Details / Methods
    -----------------

    Update History
    --------------
    Created March 2017 - R.B.

    Issues / TODOs
    --------------
*/
public class EQT_NetworkSearch_Wrapper {

    public class SearchParams {
        @auraEnabled public List<String> deals {get;set;}
        @auraEnabled public List<String> accounts {get;set;}
        @auraEnabled public List<String> sectorFilter {get;set;} //in format sectorId#subsectorId#subsegmentId
        @auraEnabled public List<String> functionalFilter {get;set;} //in format topicId#subTopicId
        @auraEnabled public List<String> geoFilter {get;set;}
        @auraEnabled public Boolean isBoardMember {get;set;}
        @auraEnabled public List<String> suitablePositions {get;set;}
        @auraEnabled public List<String> engagementLevel {get;set;}
        @auraEnabled public List<String> existingRoles {get;set;}
        @auraEnabled public List<String> residence {get;set;} // network search by country of residence
        @auraEnabled public List<String> sectorTeam {get;set;} // network search by sector team
        @auraEnabled public Integer type {get;set;}
    }

    public class Experience implements Comparable {
        @auraEnabled public String role {get;set;}
        @auraEnabled public String company {get;set;}
        @auraEnabled public Date startDate;
        @auraEnabled public Date endDate;

        public Experience(String role, String company, Date starDate, Date endDate) {
            this.role = role;
            this.company = company;
            this.startDate = starDate;
            this.endDate = endDate;
        }

        public Integer compareTo(Object compareTo) {
            Experience exp = (Experience) compareTo;

            Time t = Time.newInstance(0,0,0,0);

            Datetime ds1 = this.startDate == null ? null : Datetime.newInstance(this.startDate, t);
            Datetime ds2 = exp.startDate == null ? null : Datetime.newInstance(exp.startDate, t);
            Datetime de1 = this.endDate == null ? null : Datetime.newInstance(this.endDate, t);
            Datetime de2 = exp.endDate == null ? null : Datetime.newInstance(exp.endDate, t);


            Long diff = (ds1 == null ? 0 : ds1.getTime()) - (ds2 == null ? 0 : ds2.getTime());
            if(diff != 0) {
                return diff > 0 ? -1 : 1;
            }

            diff = (de1 == null ? 0 : de1.getTime()) - (de2 == null ? 0 : de2.getTime());
            if(diff != 0) {
                return diff > 0 ? -1 : 1;
            }
            else {
                return 0;
            }
        }
    }

    public class SectorExpertise {
        @auraEnabled public String sectorExpertise {get;set;}
        @auraEnabled public Boolean recommended {get;set;}

        public SectorExpertise(String sectorExpertise, Boolean recommended) {
            this.sectorExpertise = sectorExpertise;
            this.recommended = recommended;
        }
    }

    public class ContactDetails {
        @auraEnabled public String id {get;set;}
        @auraEnabled public String name {get;set;}
        @auraEnabled public String title {get;set;}
        @auraEnabled public String email {get;set;}
        @auraEnabled public String phone {get;set;}
        @auraEnabled public String countryOfResidence {get;set;}
        @auraEnabled public String ownerId {get;set;}
        @auraEnabled public String ownerName {get;set;}
        @auraEnabled public String engagementLevel {get;set;}
        @auraEnabled public String status {get;set;}
        @auraEnabled public String linkedinProfile {get;set;}
        @auraEnabled public List<String> suitablePositions {get;set;}
        @auraEnabled public Decimal ratingCount {get;set;}
        @auraEnabled public Decimal ratingTotal {get;set;}
        @auraEnabled public Decimal ratingAverage {get;set;}
    }

    public class SearchResults {
        @auraEnabled public ContactDetails cDetail {get;set;}
        @auraEnabled public String photoId {get;set;}
        @auraEnabled public List<Object> assessments {get;set;}
        @auraEnabled public List<Object> assignments {get;set;}
        @auraEnabled public List<SectorExpertise> sectorExpertise {get;set;}
        @auraEnabled public List<String> functionalExpertise {get;set;}
        @auraEnabled public List<String> geographicalExpertise {get;set;}
        @auraEnabled public List<Experience> experience {get;set;}
    }

    public class PageResult {
        @auraEnabled public Integer pageSize {get;set;}
        @auraEnabled public Integer page {get;set;}
        @auraEnabled public Integer total {get;set;}
        @auraEnabled public Long duration {get;set;}
        @auraEnabled public List<EQT_NetworkSearch_Wrapper.SearchResults> contacts {get;set;}
    }
}