@isTest
public class EQT_ContactStatusUpdate_Test {
	@isTest
	public static void TestMethod1() {
		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		EQT_IA_Contract__c a = EQT_TestFactory.createSampleAgreement(c.Id,'Permanent IE','Active',true);
		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}
	@isTest
	public static void TestMethod2() {
		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Terminated by IA';
        agreement.EQT_Agreement_Termination_Reason__c = 'Moved to Competitor';
        agreement.EQT_Start_Date__c = Date.today().addMonths(-1);
        agreement.EQT_End_Date__c = Date.today().addMonths(1);
        insert agreement;
		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}
	@isTest
	public static void TestMethod3() {

		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Active';
        agreement.EQT_Start_Date__c = Date.today().addMonths(-1);
        agreement.EQT_End_Date__c = Date.today().addMonths(1);
        insert agreement;

		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}

	@isTest
	public static void TestMethod4() {

		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Active';
        agreement.EQT_Start_Date__c = Date.today().addYears(-2);
        agreement.EQT_End_Date__c = Date.today().addMonths(1);
        insert agreement;

		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}

	@isTest
	public static void TestMethod5() {

		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Active';
        agreement.EQT_Start_Date__c = Date.today().addMonths(1);
        agreement.EQT_End_Date__c = Date.today().addMonths(1);
        insert agreement;

		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}

	@isTest
	public static void TestMethod6() {

		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Active';
        agreement.EQT_Start_Date__c = Date.today().addMonths(-2);
        agreement.EQT_End_Date__c = Date.today().addMonths(-1);
        insert agreement;

		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}

	@isTest
	public static void TestMethod7() {

		Contact c = EQT_TestFactory.createSampleContact('TestContact', 'EQT_Industrialadvisor','','Contact.EQT_Industrial_Advisor');
		
		EQT_IA_Contract__c agreement = new EQT_IA_Contract__c();
		agreement.EQT_Industrial_Advisor__c = c.Id;
        agreement.EQT_Type__c = 'Permanent IE';
        agreement.EQT_Status__c = 'Active';
        agreement.EQT_Start_Date__c = Date.today().addYears(-2);
        agreement.EQT_End_Date__c = Date.today().addMonths(-1);
        insert agreement;

		test.startTest();
		EQT_ContactStatusUpdate abc = new EQT_ContactStatusUpdate();
		List<Contact> contList = [SELECT Id,ContactStatus__c FROM Contact where Name = 'TestContact EQT_Industrialadvisor'];
        abc.start(null);
        abc.execute(null,contList);
        abc.finish(null);
        test.stopTest();
	}
}