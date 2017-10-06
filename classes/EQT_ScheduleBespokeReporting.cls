/**
About
-----
Description: Schedule class to schedule batch to create the Bespoke Reporting Cases
Created for: EQT
Create date: November 2016

Details / Methods
-----------------
- 

Update History
--------------
Created November 2016 - Fredrik Burlin

Issues / TODOs
--------------
*/
public without sharing class EQT_ScheduleBespokeReporting implements Schedulable, Database.Batchable<SObject>, Database.Stateful {

    public EQT_ScheduleBespokeReporting() {}
        
    public static String query = 
        'SELECT Id, Name, Account__c, Account__r.OwnerId, Last_Case_Created__c, Next_Deadline__c, Next_Case_Creation_Date__c, Days_before_Deadline__c, Description__c, Recurrence__c, Start_Date__c ' +
        'FROM Bespoke_Reporting__c ' +
        'WHERE Next_Case_Creation_Date__c <= TODAY ';
    
    public void execute(SchedulableContext ctx)  {
        EQT_ScheduleBespokeReporting s = new EQT_ScheduleBespokeReporting();
        Id batchprocessid = Database.executeBatch(s, 20);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Bespoke_Reporting__c> bespokeReportingList = (List<Bespoke_Reporting__c>)scope;
        List<Bespoke_Reporting__c> bespokeReportingUpdateList = new List<Bespoke_Reporting__c>();
        List<Case> casesInsertList = new List<Case>();
        for(Bespoke_Reporting__c br:bespokeReportingList){
            if(br.Next_Case_Creation_Date__c != br.Last_Case_Created__c){
                casesInsertList.add(EQT_BespokeReportingHelper.newCase(br));
                br.Last_Case_Created__c = Date.today();
            }
            bespokeReportingUpdateList.add(br);
        }
        insert casesInsertList;
        update bespokeReportingUpdateList;
    }
    
    public void finish(Database.BatchableContext BC) {}
}