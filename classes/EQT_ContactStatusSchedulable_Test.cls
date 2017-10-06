@isTest
public class EQT_ContactStatusSchedulable_Test 
{
    @isTest
    public static void TestMethod1()
    {
        Test.startTest();
        system.schedule('ScheduleApexClassTest', '00 00 * * 1-12 ? *', new EQT_ContactStatusSchedulable());
        Test.stopTest();
    }
}