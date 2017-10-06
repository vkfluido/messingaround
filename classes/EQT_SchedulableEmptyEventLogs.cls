/**
    About
    -----
    Description: Schedulable class to empty event logs
    Created for: EQT POC
    Create date: April 2016
    
    Details / Methods
    -----------------
   
    Update History
    --------------
    Created April 2016 - R.B.
    
    Issues / TODOs
**/
public class EQT_SchedulableEmptyEventLogs implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new EQT_BatchDeleteEventLogs());
    }
}