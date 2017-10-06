/**
    About
    -----
    Description: Trigger Handler for the Sector Team Member SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2017

    Details / Methods
    -----------------
    Use Case 1. Populate Sector and Subsector fields

    Update History
    --------------
    Created June 2017 - F.A.

    Issues / TODOs
    --------------
*/

public with sharing class EQT_SectorTeamMemberHandler implements EQT_ITrigger {

    private Set<Id> allContactsIdsSet = new Set<Id>();
    private Set<Id> newTeamMemberIds;
    private Map<Id, Map<String, List<String>>> contactIdToSectorMap = new Map<Id, Map<String, List<String>>>(); // Map<ContactId, Map<SectorName, List<Subsector>>>

    // Constructor
    public EQT_SectorTeamMemberHandler() {}

    public void bulkBefore() {
        if(Trigger.isInsert) {
            for(sObject so : Trigger.new) {
                EQT_Sector_Team_Member__c stmObj = (EQT_Sector_Team_Member__c)so;

                allContactsIdsSet.add(stmObj.EQT_Contact__c);
            }

            if(!allContactsIdsSet.isEmpty()) {
                List<EQT_Sector_Rating__c> sectorRatingsList = [
                    SELECT Id, Sector__r.Name, Subsector__r.Name, Contact__c
                    FROM EQT_Sector_Rating__c
                    WHERE Contact__c IN :allContactsIdsSet
                    ORDER BY Contact__c, Sector__r.Name, Subsector__r.Name
                ];
                for(EQT_Sector_Rating__c sectorRating : sectorRatingsList){
                    String sectorName = sectorRating.Sector__r.Name.toLowerCase();
                    String subsectorName = sectorRating.Subsector__r.Name;
                    Id contactId = sectorRating.Contact__c;

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
            }
        }

        if(Trigger.isDelete){ // Retrieve the Ids of Expertise Records related to these Sector Team Members and send them for future deletion
            Set<Id> deletedTeamMemberIds = trigger.oldMap.keySet();
            List<EQT_SectorTeamMemberExpertise__c> teamMemberExpertiseRecordsToDelete = 
                        [SELECT Id FROM EQT_SectorTeamMemberExpertise__c WHERE SectorTeamMember__c IN :deletedTeamMemberIds];
            if(!teamMemberExpertiseRecordsToDelete.isEmpty()){
                Set<Id> teamMemberExpertiseIdsToDelete = new Set<Id>();
                for(EQT_SectorTeamMemberExpertise__c tme : teamMemberExpertiseRecordsToDelete)
                    teamMemberExpertiseIdsToDelete.add(tme.Id);
                deleteTeamMemberExpertise(teamMemberExpertiseIdsToDelete);
            }
        }
    }

    public void bulkAfter() {
        if(Trigger.isInsert) {
            Map<Id,sObject> newSObjMap = Trigger.newMap;
            newTeamMemberIds = newSObjMap.keySet();
        }
    }

    public void beforeInsert(SObject so) {
        EQT_Sector_Team_Member__c stmObj = (EQT_Sector_Team_Member__c)so;

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

        system.debug('beforeInsert -> stmObj: ' + stmObj);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {}

    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so) {}

    public void afterUpdate(SObject oldSo, SObject so) {}

    public void afterDelete(SObject so) {}

    public void andFinally() {
        if(newTeamMemberIds != null)
            createTeamMemberExpertise(newTeamMemberIds); // Call creation of the expertise records
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

    @future
    public static void deleteTeamMemberExpertise(Set<Id> expertiseToDelete) {
        // Only delete those for which the TeamMember record was successfully deleted
        List<EQT_SectorTeamMemberExpertise__c> teamMemberExpertiseRecordsToDelete = 
                        [SELECT Id FROM EQT_SectorTeamMemberExpertise__c WHERE Id IN :expertiseToDelete AND SectorTeamMember__c = NULL];
        delete teamMemberExpertiseRecordsToDelete;
    }

    private void createTeamMemberExpertise(Set<Id> teamMemberIds) {
        // Only delete those for which the TeamMember record was successfully deleted
        List<EQT_Sector_Team_Member__c> newTeamMembers = 
                        [SELECT Id, EQT_Contact__c, EQT_Sector_Team__r.Name FROM EQT_Sector_Team_Member__c WHERE Id IN :teamMemberIds];
        System.debug('Team members to Process:\n'+newTeamMembers);
        Set<Id> contactIds = new Set<Id>();
        for(EQT_Sector_Team_Member__c tm : newTeamMembers){
            contactIds.add(tm.EQT_Contact__c);
        }
        Map<Id,Map<String,List<Id>>> contactSectorExpertiseIdMap = new Map<Id,Map<String,List<Id>>>();

        List<EQT_Sector_Rating__c> sectorExpertise = [
                    SELECT Id, Contact__c, Sector__r.Name, Subsector__r.Sector__r.Name,Subsector_Segment__r.Subsector__r.Sector__r.Name
                    FROM EQT_Sector_Rating__c
                    WHERE Contact__c IN :contactIds
                    ORDER BY Contact__c, Sector__c, Subsector__c, Subsector_Segment__c
                ];
        System.debug('Retrieving Sector Expertise for Contacts:\n'+sectorExpertise);
        for(EQT_Sector_Rating__c exp : sectorExpertise){
            String sectorName = exp.Sector__r.Name.toLowerCase();
            Id contactId = exp.Contact__c;
            if(!contactSectorExpertiseIdMap.containsKey(contactId))
                contactSectorExpertiseIdMap.put(contactId,new Map<String,List<Id>>());
            if(!contactSectorExpertiseIdMap.get(contactId).containsKey(sectorName))
                contactSectorExpertiseIdMap.get(contactId).put(sectorName, new List<Id>());
            contactSectorExpertiseIdMap.get(contactId).get(sectorName).add(exp.Id);
        }
        System.debug(contactSectorExpertiseIdMap);
        List<EQT_SectorTeamMemberExpertise__c> expertiseToInsert = new List<EQT_SectorTeamMemberExpertise__c>();
        for(EQT_Sector_Team_Member__c stm : newTeamMembers){
            System.debug('SectorTeam: ' + stm.EQT_Sector_Team__r.Name);
            String sectorName = stm.EQT_Sector_Team__r.Name;
            Id contactId = stm.EQT_Contact__c;
            if(contactSectorExpertiseIdMap.containsKey(contactId)){
                System.debug('Contact match: ' + contactId);
                if(contactSectorExpertiseIdMap.get(contactId).containsKey(sectorName.toLowerCase())){
                    System.debug('Sector match: ' + sectorName.toLowerCase());
                    for(Id sectorExpertiseId : contactSectorExpertiseIdMap.get(contactId).get(sectorName.toLowerCase())){
                        System.debug('sectorExpertiseId: ' + sectorExpertiseId);
                        EQT_SectorTeamMemberExpertise__c newExpertise = new EQT_SectorTeamMemberExpertise__c(
                                    Name = sectorName,
                                    Sector_Expertise__c = sectorExpertiseId,
                                    SectorTeamMember__c = stm.Id
                            );
                        expertiseToInsert.add(newExpertise);
                    }
                }
            }
        }
        System.debug(expertiseToInsert);
        if(!expertiseToInsert.isEmpty())
            insert expertiseToInsert;
    }
}