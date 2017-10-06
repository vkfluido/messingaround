/**
    About
    -----
    Description: Trigger Handler for the Sector Rating SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2017

    Details / Methods
    -----------------
    Use Case 1. Populate Sector and Subsector fields
    Use Case 2. Populate Sector Team Member Expertise: When a new "Sector Expertise" is added to a contact, check if this person is member
                of a Sector Team by matching the Sector Team Name. If so, add the corresponding Sector Team Member Expertise.

    Update History
    --------------
    Created June 2017 - F.A.
    Updated July 2017 - felix.guerrero@fluidogroup.com: Use Case 2
    Issues / TODOs
    --------------
*/

public with sharing class EQT_SectorRatingHandler implements EQT_ITrigger {
    private Set<Id> contactIdsForSectorTeamEvalSet = new Set<Id>();
    private Map<Id, Map<String, List<String>>> contactIdToSectorMap = new Map<Id, Map<String, List<String>>>(); // Map<ContactId, Map<SectorName, List<Subsector>>>
    
    private Boolean doInsertTeamMemberExpertise = false;
    private List<EQT_SectorTeamMemberExpertise__c> teamMemberExpertiseToInsert = new List<EQT_SectorTeamMemberExpertise__c>();
    
    // Constructor
    public EQT_SectorRatingHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(SObject so) {}

    public void beforeUpdate(SObject oldSo, SObject so) {
        // Prevent changing the Sector/Subsector/Segment of an existing Sector Expertise Record
        EQT_Sector_Rating__c sr = (EQT_Sector_Rating__c)so;
        EQT_Sector_Rating__c srOld = (EQT_Sector_Rating__c)oldSo;
        if (   sr.Sector__c != srOld.Sector__c 
            || sr.Subsector__c != srOld.Subsector__c
            || sr.Subsector_Segment__c != srOld.Subsector_Segment__c) {
            sr.addError('Directly changing Sector,Subsector or Segment is not permitted.');
        }
    }

    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {
        EQT_Sector_Rating__c sr = (EQT_Sector_Rating__c)so;

        contactIdsForSectorTeamEvalSet.add(sr.Contact__c);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        // This check is not necessary because the records cannot be re-parented from the parent Contact   
    }

    public void afterDelete(SObject so) {
        EQT_Sector_Rating__c sr = (EQT_Sector_Rating__c)so;

        contactIdsForSectorTeamEvalSet.add(sr.Contact__c);
    }

    public void andFinally() {
        doInsertTeamMemberExpertise = (Trigger.isAfter && Trigger.isInsert);

        if(!contactIdsForSectorTeamEvalSet.isEmpty())
            evaluateSectorTeamMembers();
    }

    private void evaluateSectorTeamMembers(){

        // Gets all Sector Team Members that correspond to contacts whose Sector Expertise was updated
        List<EQT_Sector_Team_Member__c> sectorTeamMembersList = [
            SELECT
                Id, EQT_Contact__c,EQT_Sector_Team__r.Name,
                Sector_Consumer_Goods__c, Sector_Energy_Environmental__c, Sector_Healthcare__c, Sector_Industrials__c, Sector_Services__c, Sector_TMT__c,
                Sub_sector_Consumer_Goods__c, Sub_sector_Energy_Environmental__c, Sub_sector_Healthcare__c, Sub_sector_Industrials__c, Sub_sector_Services__c, Sub_sector_TMT__c
            FROM EQT_Sector_Team_Member__c
            WHERE EQT_Contact__c IN :contactIdsForSectorTeamEvalSet
        ];

        // Assemble a Map of SectorTeam members that matched a contact
        // A contact can be member of several Sctor Teams
         // existingSectorTeamMembersIds => contactToTeamMemberMap.keySet
        Map<Id,List<EQT_Sector_Team_Member__c>> contactToTeamMemberMap = new Map<Id,List<EQT_Sector_Team_Member__c>>();
        for(EQT_Sector_Team_Member__c stm : sectorTeamMembersList){
            if(!contactToTeamMemberMap.containsKey(stm.EQT_Contact__c))
                contactToTeamMemberMap.put(stm.EQT_Contact__c,new List<EQT_Sector_Team_Member__c>());
            contactToTeamMemberMap.get(stm.EQT_Contact__c).add(stm);
        }


        // Continue only if any of the contacts is member of a sector team
        if(contactToTeamMemberMap.isEmpty()){
            return;
        }

        // Process Expertise only for the contacts that are also Sector Team Members
        List<EQT_Sector_Rating__c> sectorRatingsList = [
            SELECT Id, Sector__r.Name, Subsector__r.Name, Subsector_Segment__r.Name, Contact__c
            FROM EQT_Sector_Rating__c
            WHERE Contact__c IN :contactToTeamMemberMap.keySet()
            ORDER BY Contact__c, Sector__r.Name, Subsector__r.Name
        ];

        //Map<Id,String> expertiseSectorMap = new Map<Id,String>(); // Get the Sector Name for each expertise item
        for(EQT_Sector_Rating__c sectorRating : sectorRatingsList){

            String sectorName = sectorRating.Sector__r.Name.toLowerCase();
            String subsectorName = sectorRating.Subsector__r.Name;
            //String segmentName = sectorRating.Subsector_Segment__r.Name;
            Id contactId = sectorRating.Contact__c;
            
            if(doInsertTeamMemberExpertise){ //Execute Only if the trigger is After Insert
                EQT_SectorTeamMemberExpertise__c stme;
                // Loop through the TeamMembers for this contact
                for(EQT_Sector_Team_Member__c tm : contactToTeamMemberMap.get(contactId)){
                    if(tm.EQT_Sector_Team__r.Name.toLowerCase() == sectorName){
                        stme = new EQT_SectorTeamMemberExpertise__c(
                            Name = sectorName,
                            Sector_Expertise__c = sectorRating.Id,
                            SectorTeamMember__c = tm.Id
                        );
                    }
                }
                System.debug('New Sector Team Member Expertise\n' + stme);
                if(stme != null)
                    teamMemberExpertiseToInsert.add(stme);
            }

            if( !contactIdToSectorMap.containsKey(contactId) ){
                contactIdToSectorMap.put(contactId, new Map<String, List<String>>() );
            }

            if( !contactIdToSectorMap.get(contactId).containsKey(sectorName) ){
                contactIdToSectorMap.get(contactId).put(sectorName, new List<String>() );
            }

            if( String.isBlank(subsectorName) ){
                continue;
            }

            contactIdToSectorMap.get(contactId).get(sectorName).add(subsectorName);
        }

        system.debug('contactIdToSectorMap: ' + contactIdToSectorMap);

        for(EQT_Sector_Team_Member__c stmObj : sectorTeamMembersList) {
            stmObj.Sector_Consumer_Goods__c = getSectorForContact(stmObj.EQT_Contact__c, 'Consumer Goods');
            stmObj.Sector_Energy_Environmental__c = getSectorForContact(stmObj.EQT_Contact__c, 'Energy & Environmental');
            stmObj.Sector_Healthcare__c = getSectorForContact(stmObj.EQT_Contact__c, 'Healthcare');
            stmObj.Sector_Industrials__c = getSectorForContact(stmObj.EQT_Contact__c, 'Industrials');
            stmObj.Sector_Services__c = getSectorForContact(stmObj.EQT_Contact__c, 'Services');
            stmObj.Sector_TMT__c = getSectorForContact(stmObj.EQT_Contact__c, 'TMT');

            stmObj.Sub_sector_Consumer_Goods__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'Consumer Goods');
            stmObj.Sub_sector_Energy_Environmental__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'Energy & Environmental');
            stmObj.Sub_sector_Healthcare__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'Healthcare');
            stmObj.Sub_sector_Industrials__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'Industrials');
            stmObj.Sub_sector_Services__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'Services');
            stmObj.Sub_sector_TMT__c = getSubSectorForContact(stmObj.EQT_Contact__c, 'TMT');
        }

        if(!teamMemberExpertiseToInsert.isEmpty())
            insert teamMemberExpertiseToInsert;
        
        update sectorTeamMembersList;
    }

    private String getSectorForContact(Id contactId, String sectorName){

        if(
            contactIdToSectorMap.containsKey(contactId) &&
            contactIdToSectorMap.get(contactId).containsKey( sectorName.toLowerCase() )
        ){
            if(sectorName.length() > 255){
                return sectorName.left(252) + '...';
            }

            return sectorName;
        }

        return null;
    }

    private String getSubSectorForContact(Id contactId, String sectorName){
        if(
            contactIdToSectorMap.containsKey(contactId) &&
            contactIdToSectorMap.get(contactId).containsKey( sectorName.toLowerCase() )
        ) {
            List<String> subsectorsList = contactIdToSectorMap.get(contactId).get( sectorName.toLowerCase() );

            if(subsectorsList.isEmpty()){
                return null;
            }

            String subsectorConcat = String.join(subsectorsList, ' | ');
            if(subsectorConcat.length() > 255){
                return subsectorConcat.left(252) + '...';
            }
            return subsectorConcat;
        }

        return null;
    }
}