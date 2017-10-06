/**
    About
    -----
    Description: Scheduler class for importing contacts from investran

    Created for: EQT
    Created date: June 2016
    
    Details / Methods
    -----------------
    

    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public class EQT_SchedulableInvestranContactImport implements Schedulable {
	public void execute(SchedulableContext ctx) {
		Database.executeBatch(new EQT_BatchInvestranContactListImport(), 2000);
	}
}