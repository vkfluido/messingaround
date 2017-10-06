@isTest
public class AssignmentUpdateActionTest {
	
    private static Id projectAssignmentRecordTypeId 
        = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.EQT_Project_Assignment');
    private static Id boardMngAssignmentRecordTypeId 
	    = EQT_UTIL_Meta.getRecordTypeId('EQT_Assignment__c.Board_Management_Assignment');
    
    // Test that a new project assignment gets linked to an existing active Tier 1 agreement
    static testMethod void testProjectAssignmentForTier1Agreement() {
        Contact contact = createTestContact();
        EQT_IA_Contract__c tier1Agreement = createTestAgreement(contact, 'Tier 1', 'Active');
        EQT_Assignment__c projectAssignment = createTestAssignment(contact, true);
        EQT_Assignment__c boardAssignment = createTestAssignment(contact, false);
        
        List<EQT_Assignment__c> assignments = 
            AssignmentUpdateAction.assignActiveAgreement(new List<EQT_Assignment__c>{projectAssignment, boardAssignment});
        
        // Verify agreement on project assignment is the tier 1 agreement
        System.assertEquals(tier1agreement.Id, projectAssignment.Agreement__c, 'Agreement Ids are not matching');
        // Verify that the boardAssignment does not have an agreement
        System.assert(boardAssignment.Agreement__c == null, 'Expected agreement to be blank');
    }
    
    // Test that a new project assignment is not linked to an existing active project IE agreement
    static testMethod void testProjectAssignmentForProjectIEAgreement() {
        Contact contact = createTestContact();
        EQT_IA_Contract__c tier1Agreement = createTestAgreement(contact, 'Project IE', 'Active');
        EQT_Assignment__c projectAssignment = createTestAssignment(contact, true);
        EQT_Assignment__c boardAssignment = createTestAssignment(contact, false);
        
        List<EQT_Assignment__c> assignments 
            = AssignmentUpdateAction.assignActiveAgreement(new List<EQT_Assignment__c>{projectAssignment, boardAssignment});
        
        // Verify that the projectAssignment does not have an agreement
        System.assert(projectAssignment.Agreement__c == null, 'Expected agreement to be blank on project assignment');
        // Verify that the boardAssignment does not have an agreement
        System.assert(boardAssignment.Agreement__c == null, 'Expected agreement to be blank on board assignment');
    }
    
    // Test that a new project assignment is linked to the lastest active agreement
    static testMethod void testProjectAssignmentForTier1AgreementDateOrder() {
        Contact contact = createTestContact();
        EQT_IA_Contract__c tier1Old = createTestAgreement(contact, 'Tier 1', 'Active', DateTime.newInstance(2016,1,1));
        EQT_IA_Contract__c tier1New = createTestAgreement(contact, 'Tier 1', 'Active');
        EQT_Assignment__c projectAssignment = createTestAssignment(contact, true);
        
        List<EQT_Assignment__c> assignments 
            = AssignmentUpdateAction.assignActiveAgreement(new List<EQT_Assignment__c>{projectAssignment});
        
        // Verify that the projectAssignment is linked to the latest agreement
        System.assertEquals(tier1New.Id, projectAssignment.Agreement__c);
    }
    
    /**
     * Creates a test assignment - toggle between project and board with the boolean flag
     */
    private static EQT_Assignment__c createTestAssignment(Contact contact, boolean project) {
        Id rtId = project ? projectAssignmentRecordTypeId : boardMngAssignmentRecordTypeId ;
        String role = project ? 'Industrial Advisor' : 'Board Member' ;
        EQT_Assignment__c assignment = new EQT_Assignment__c( 
            Contact__c = contact.Id, RecordTypeId = rtId, Start_Date__c = Date.today(), EQT_Role__c = role
        );
        insert assignment;
        return assignment;
    }
    
    
    private static EQT_IA_Contract__c createTestAgreement(Contact contact, String type, String status) {
        return createTestAgreement(contact, type, status, DateTime.now());
    }
    
    /**
     * Creates an Agreement linked to Contact.
     */
    private static EQT_IA_Contract__c createTestAgreement(Contact contact, String type, String status, DateTime CreatedDate) {
        // Default to private individual type agreement
        Id CompanyRTId = EQT_UTIL_Meta.getRecordTypeId('EQT_IA_Contract__c.EQT_Private_Individual');
        EQT_IA_Contract__c agreement = new EQT_IA_Contract__c ( 
            EQT_Industrial_Advisor__c = contact.Id, 
            EQT_Type__c = type,
            EQT_Status__c = status,
			RecordTypeId = CompanyRTId,
			CreatedDate = CreatedDate            
        );
        insert agreement;
        return agreement;
    }
    
    /**
     * Creates a test contact of type "Person" assoicated with an Account (type "Other")
     */
    private static Contact createTestContact() { 
        Id otherCompanyRTId = EQT_UTIL_Meta.getRecordTypeId('Account.EQT_Other');

        Account a = EQT_TestFactory.createSampleAccount('Account.EQT_Other', 'Sample account1',false);
        a.EQT_EPM_Responsible__c = '9999';
        insert a;

        Contact c = new Contact();
        c.LastName = 'Generic Contact, will get default RT';
        c.EQT_EPM_PersonID__c = '1234';
        c.EQT_EPM_Record_Type_Name__c = 'EQT_Person';
        c.AccountId = a.Id;
        c.EQT_Social_Security_Number__c = '123456789';
        insert c;
        System.debug(LoggingLevel.INFO, '@@ c'+c);
        return c;

/*
        Account account = new Account(
            Name = 'MyTestAccount', RecordtypeId = otherCompanyRTId
        );
        insert account;
        
        Id personRTId = EQT_UTIL_Meta.getRecordTypeId('Contact.EQT_Person');
        Contact contact = new Contact( 
            firstName = 'Test', lastName = 'Test', RecordTypeId = personRTId, Account = account,
            EQT_Social_Security_Number__c = '1234567890'
        );
        insert contact;
        return contact;
*/
    }
}