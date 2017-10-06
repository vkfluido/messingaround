/**
    About
    -----
    Description: Schedulable class for batch to check if agreement end data passed
    Created for: EQT
    Create date: April 2017

    Details / Methods
    -----------------

    Update History
    --------------
    Created April 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_AgreementAutoExpire_SCH implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new EQT_AgreementAutoExpire_BATCH());
    }
}