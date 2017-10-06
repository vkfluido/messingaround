public with sharing class EQT_Competence_SVC {
	public enum CompetenceType {SECTOR, FUNCTIONAL, GEO, SECTOR_TEAM} // network search by sector team SECTOR_TEAM
	
    @AuraEnabled
    public static List<Competence> loadSectorCompetences() {
        List<EQT_Sector__c> sectors = [SELECT Id, Name, (SELECT Id, Name FROM Subsectors__r) FROM EQT_Sector__c];
        List<EQT_Subsector_Segment__c> segments = [SELECT Id,Name,Subsector__c FROM EQT_Subsector_Segment__c ORDER BY Subsector__c];
        Map<Id,List<EQT_Subsector_Segment__c>> segmentMap = new Map<Id,List<EQT_Subsector_Segment__c>>();
        if (segments.size() > 0) {
            Id subsectorId = null;
            List<EQT_Subsector_Segment__c> subsectorSegments = null;
            for (EQT_Subsector_Segment__c segment : segments) {
                final Id idCurrent = segment.Subsector__c;
                if (!idCurrent.equals(subsectorId)) {
                    subsectorId = segment.Subsector__c;
                    subsectorSegments = new List<EQT_Subsector_Segment__c>();
                    segmentMap.put(subsectorId, subsectorSegments);
                }
                subsectorSegments.Add(segment);
            }
        }
        
        // build results
        final CompetenceType type = CompetenceType.SECTOR;
        final List<Competence> results = new List<Competence>();
        for (EQT_Sector__c sector : sectors) {
            // build sector competence
            Competence compSector = new Competence(type, sector.Id, sector.Name);
            results.Add(compSector);
            
            // loop subsectors
            for (EQT_Subsector__c subsector : sector.Subsectors__r) {
                // create subsector competence
                final Competence compSubsector = new Competence(type, compSector, subsector.Id, subsector.Name);
                compSector.Add(compSubsector);
                
                // loop any segments there might be
                List<EQT_Subsector_Segment__c> subsectorSegments = segmentMap.get(subsector.Id);
                if (null != subsectorSegments) {
                    for (EQT_Subsector_Segment__c segment : subsectorSegments) {
                        // create segment competence
                        final Competence compSegment = new Competence(type, compSubsector, segment.Id, segment.Name);
                        compSubsector.Add(compSegment);
                    }
                }
            }
        }
        
        // return
        return  results;
    }

    @AuraEnabled
    public static List<Competence> loadFunctionalCompetences() {
		List<Competence> results = new List<Competence>();
		final CompetenceType type = CompetenceType.FUNCTIONAL;
        
        for (EQT_Functional_Topic__c ft : [SELECT Id, Name, (SELECT Id, Name FROM Functional_Subtopics__r) FROM EQT_Functional_Topic__c]) {
            Competence item = new Competence(type, ft.Id, ft.Name);
            for (EQT_Functional_Subtopic__c st : ft.Functional_Subtopics__r) {
                item.Add(new Competence(type, item, st.Id, st.Name));
            }

            results.add(item);
        }

        return results;
    }

    @AuraEnabled
    public static List<Competence> loadSectorTeamCompetences() {
        List<Competence> results = new List<Competence>();
        final CompetenceType type = CompetenceType.SECTOR_TEAM;

        List<EQT_Sector_Team__c> sectorTeamList = [SELECT Id, Name FROM EQT_Sector_Team__c ORDER BY Name];
        for(EQT_Sector_Team__c sectorTeam : sectorTeamList ){
            Competence item = new Competence(type, sectorTeam.Id, sectorTeam.Name);

            results.add(item);
        }

        return results;
    }

    @AuraEnabled
    public static List<Competence> loadGeographicalCompetences() {
        final List<Competence> results = new List<Competence>();
		final CompetenceType type = CompetenceType.GEO;
        final List<EQT_Geography__c> geos = [SELECT Region__c, toLabel(Region__c) regionName, Country__c, toLabel(Country__c) countryName FROM EQT_Geography__c ORDER BY Region__c ASC, Country__c ASC];
        Competence region = null;
        for (EQT_Geography__c geo : geos) {
            final String regionId = geo.Region__c;    
            final String regionLabel = (String)geo.get('regionName');
            final String ctryId = geo.Country__c;
            final String ctryLabel = (String)geo.get('countryName');
            if (String.isEmpty(ctryId)) {
                // no country found (must be a (new) region)
                region = new Competence(type, regionId, regionLabel);
                results.Add(region);
                continue;
            }
            if (null == region || !region.id.equals(regionId)) {
                // we have no region yet but there is a country OR region is different so create region first 
                region = new Competence(type, regionId, regionLabel);
                results.Add(region);
            }
            
            // create country
            Competence ctry = new Competence(type, region, ctryId, ctryLabel);
            region.Add(ctry);
        }
        
        // return
        return results;
    }

    /**
     * Competence object for sector, functional and geography expertise.
     */
    public class Competence {
        @auraEnabled public String type;
        @auraEnabled public String id;
        @auraEnabled public String name;
        @auraEnabled public String parentId;
        @auraEnabled public String parentName;
        @auraEnabled public List<Competence> competences;

        public Competence() {}
        public Competence(CompetenceType type, String id, String name) {
            this.setType(type);
            this.id = id;
            this.name = name;
        }
        public Competence(CompetenceType type, Competence parent, String id, String name) {
            if (null == parent) {
                this(type, id, name);
            } else {
                this.setType(type);
                this.id = parent.Id + '#' + id;
                this.name = name;
                this.parentId = parent.id;
                this.parentName = parent.Name;
            }
        }
        public Competence setType(CompetenceType type) {
            this.type = String.valueOf(type).toLowerCase();
            return this;
        }
        public Competence Add(Competence child) {
            if (null == child) return this;
            if (null == this.competences) this.competences = new List<Competence>();
            this.competences.add(child);
            return this;
        }
    }
}