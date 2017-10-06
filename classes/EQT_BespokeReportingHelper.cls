/**
    About
    -----
    Description: To help the BespokeReporting batch job the trigger sets the next Next Deadline
                 when record is inserted or updated also the class for creating the new Case
    Created for: EQT
    Create date: November 2016
    
    Details / Methods
    -----------------
    Use case 1. Set Next Deadline on insert and update

    Update History
    --------------
    Created November 2016 - Fredrik Burlin

    Issues / TODOs
    --------------
*/
public class EQT_BespokeReportingHelper {
    
    // Set the new deadline for the Bespoke_Reporting__c object upon save
    public static Date nextDeadline(Bespoke_Reporting__c br){
        Integer offset = Integer.valueOf(br.Days_before_Deadline__c);
        Date createDate = br.Start_Date__c;
        Integer ocurrence = Integer.valueOf(br.Recurrence__c);
        while(createDate < Date.today().addDays(offset)){
            createDate = createDate.addMonths(ocurrence);
        }
        return createDate;
    }
    
    private static Id rfiBRRT = EQT_UTIL_Meta.getRecordTypeId('Case.RFI_Bespoke_Request');
    private static Id rfiQUEUE = EQT_UTIL_Meta.getQueueId('RFI Inbox');
    // The new case that is created
    public static Case newCase(Bespoke_Reporting__c br){
        Case newCase = new Case(
            RecordTypeId = rfiBRRT,
            OwnerId = rfiQUEUE,
            AccountId = br.Account__c,
            Subject = br.Name,
            Deadline__c = br.Next_Deadline__c,
            Origin = 'System',
            Status = 'New',
            Priority = 'Medium',
            Case_Notification_Status__c = 'Send to RFI',
            Category__c  = 'Bespoke (recurring) requests (approved & new)',
            Bespoke_Reporting__c = br.Id,
            Description = br.Description__c
        );
        return newCase;
    }
}