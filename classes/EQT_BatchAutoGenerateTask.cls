/**
    About
    -----
    Description: Batch to autogenerate task for opportunity owner if meeting activity description is missing
    Created for: EQT
    Create date: January 2017

    Details / Method
    -----------------
    -

    Update History
    --------------
    Created January 2017 - F.A.

    Issues / TODOs
    --------------
*/

public with sharing class EQT_BatchAutoGenerateTask implements Database.Batchable<SObject> {
    private static Integer DAYS_AGO {
        get {
            return -7;
        }
        set;
    }

    private static String TASK_SUBJECT {
        get {
            return 'Missing meeting activity';
        }
        set;
    }

    private static String TASK_DESCRIPTION {
        get {
            return 'Please fill description on meeting/call activity';
        }
        set;
    }

    public Iterable<sObject> start(Database.BatchableContext BC) {
        Date dateNDaysAgo = system.today().addDays(DAYS_AGO);
        Datetime datetimeNDaysAgoStart = Datetime.newInstanceGmt(dateNDaysAgo.year(), dateNDaysAgo.month(), dateNDaysAgo.day(), 0, 0, 0 );
        Datetime datetimeNDaysAgoEnd = datetimeNDaysAgoStart.addDays(1);

        system.debug('datetimeNDaysAgoStart: ' + datetimeNDaysAgoStart);
        system.debug('datetimeNDaysAgoEnd: ' + datetimeNDaysAgoEnd);

        List<Event> resultEventsList = [
            SELECT Id, WhatId, Description
            FROM Event
            WHERE
                What.type = 'Opportunity' AND
                Type IN ('Meeting', 'Call') AND
                StartDateTime >= :datetimeNDaysAgoStart AND
                StartDateTime < :datetimeNDaysAgoEnd
        ];

        system.debug('resultEventsList: ' + resultEventsList);

        return resultEventsList;
    }

    public void execute(Database.BatchableContext BC, List<Event> scope) {
        List<Event> eventsForProcessing = new List<Event>();
        Set<Id> opportunityIds = new Set<Id>();

        // check which events has empty description
        for(Event eventItem : scope){
            if(String.isBlank(eventItem.Description)){
                eventsForProcessing.add(eventItem);
                opportunityIds.add(eventItem.WhatId);
            }
        }

        // search for opportunities details
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
        system.debug('opportunitiesMap: ' + opportunitiesMap);

        List<Task> tasksForCreateList = new List<Task>();
        for(Event eventItem : eventsForProcessing){
            if(opportunitiesMap.containsKey(eventItem.WhatId)){
                Task newTask = new Task(
                    OwnerId = opportunitiesMap.get(eventItem.WhatId).OwnerId,
                    Subject = TASK_SUBJECT,
                    Description = TASK_DESCRIPTION,
                    ActivityDate = System.today(),
                    WhatId = opportunitiesMap.get(eventItem.WhatId).Id,
                    Type = 'Other'
                );
                tasksForCreateList.add(newTask);
            }
        }

        system.debug('tasksForCreateList: ' + tasksForCreateList);
        if(!tasksForCreateList.isEmpty()){
            insert tasksForCreateList;
        }
    }

    public void finish(Database.BatchableContext BC) {

    }
}