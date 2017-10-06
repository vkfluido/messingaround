/**
    About
    -----
    Description: Schedulable class to generate task for missing meeting activity
    Created for: EQT
    Create date: January 2017

    Details / Method
    -----------------

    Update History
    --------------
    Created January 2017 - F.A.

    Issues / TODOs
    --------------
**/
public with sharing class EQT_SchedulableAutoGenerateTask implements Schedulable {

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new EQT_BatchAutoGenerateTask());
    }
}