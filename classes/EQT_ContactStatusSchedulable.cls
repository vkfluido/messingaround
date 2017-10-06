public with sharing class EQT_ContactStatusSchedulable implements Schedulable{
	public void execute(SchedulableContext SC) {
        EQT_ContactStatusUpdate b = new EQT_ContactStatusUpdate();
        database.executeBatch(b, 100);
    }
}