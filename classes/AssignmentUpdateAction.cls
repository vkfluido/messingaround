/**
 * Utility class to update Assignments after creation.
 * Methods in this class should be called from a Lightning Process.
 * 
 * Created By: rmohr@salesforce.com
 * Date Created: 2017-01-11
 */
public class AssignmentUpdateAction {
    
    private static final String PROJECT_IE_TYPE = 'Project IE';
    private static final String AGREEMENT_ACTIVE = 'Active';
    private static final String AGREEMENT_IN_PROGRESS = 'In Progress';
    
    private static Id projectAssignmentRecordTypeId 
        = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.EQT_Project_Assignment');
    private static Id boardMngAssignmentRecordTypeId 
	    = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.Board_Management_Assignment');
    
    // @InvocableMethod(label='Assign Active Agreement' description='Assigns an active Agreement to the Assignment')
  	
    public static List<EQT_Assignment__c> assignActiveAgreement(List<EQT_Assignment__c> assignments) {
        // Collect all contact ids for a bulk select
        Set<ID> contacts = new Set<ID>();
        for (EQT_Assignment__c assignment : assignments) {
            contacts.add(assignment.Contact__c);
        }
        System.debug(LoggingLevel.DEBUG, '@@ contacts = ' + contacts);
        Map<ID, EQT_IA_Contract__c> agreements = getActiveAgreementsMap(contacts);
        for (EQT_Assignment__c assignment : assignments) {
            EQT_IA_Contract__c agreement = null;
            System.debug(LoggingLevel.DEBUG, '@@ Comparing record type: ' + assignment.RecordTypeId 
                         + ' to agreement record type: ' + projectAssignmentRecordTypeId + '/' + boardMngAssignmentRecordTypeId);
            // Only set agreements for assignments of project type with no specified agreement
            if (assignment.Agreement__c == null && assignment.RecordTypeId == projectAssignmentRecordTypeId) {
                // If IA has an open-ended contract use that                
				agreement = agreements.get(assignment.Contact__c); 
                if (agreement != null) {
                    System.debug(LoggingLevel.DEBUG, '@@ Matched agreement ' + agreement + ' to assignment ' + assignment);
                    // Set agreement on Assignment
                    assignment.Agreement__c = agreement.Id;
                    System.debug(LoggingLevel.DEBUG, '@@ ' + agreement + ' linked to ' + assignment);
                }                
            }            
        }
        return assignments;
  	}
    
    /**
     * Returns open-ended active agreements by IA.
	 */
    private static Map<Id, EQT_IA_Contract__c> getActiveAgreementsMap(Set<Id> contacts) {
        List<EQT_IA_Contract__c> agreements = [SELECT Id, EQT_Industrial_Advisor__c, CreatedDate 
                                        FROM EQT_IA_Contract__c 
                                        WHERE EQT_Industrial_Advisor__c IN :contacts
                                        AND (EQT_Status__c = :AGREEMENT_ACTIVE OR EQT_Status__c = :AGREEMENT_IN_PROGRESS)
                                        AND EQT_Type__c <> :PROJECT_IE_TYPE
                                       	ORDER BY CreatedDate DESC];
        System.debug(LoggingLevel.DEBUG, '@@ ' + agreements.size() + ' open-ended agreements found');
        return buildAgreementsMap(agreements);
    }
    
    private static Map<Id, EQT_IA_Contract__c> buildAgreementsMap(List<EQT_IA_Contract__c> agreements) {
        Map<ID, EQT_IA_Contract__c> agreementsMap = new Map<ID, EQT_IA_Contract__c>();
        // Map agreements to contact - ensure only one agreement per contact and use the latest
        for (EQT_IA_Contract__c agreement : agreements) {
        	EQT_IA_Contract__c old = agreementsMap.get(agreement.EQT_Industrial_Advisor__c);
            if (old == null){
                // Nothing in the map - store the value
                agreementsMap.put(agreement.EQT_Industrial_Advisor__c, agreement);
                System.debug(LoggingLevel.DEBUG, '@@ Mapped ' + agreement + ' to ' + agreement.EQT_Industrial_Advisor__c);
            }
            else if (old.CreatedDate < agreement.CreatedDate) {
                // Replace with latest record
                agreementsMap.put(agreement.EQT_Industrial_Advisor__c, agreement);
                System.debug(LoggingLevel.DEBUG, '@@ Replaced old value with ' + agreement + ' for ' + agreement.EQT_Industrial_Advisor__c);
            }
        }
        System.debug(LoggingLevel.DEBUG, '@@ Map for agreements created ' + agreementsMap);
        return agreementsMap;
    }
}