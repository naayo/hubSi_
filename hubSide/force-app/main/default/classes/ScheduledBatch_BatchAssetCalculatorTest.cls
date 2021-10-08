/***
* @author Pierre-Mickael Barral (Inetum)
* @date 21/01/2021
* @description ScheduledBatch_BatchAssetCalculatorTest test class
* @see ScheduledBatch_BatchAssetCalculatorTest
*/

@isTest 
public class ScheduledBatch_BatchAssetCalculatorTest {
    
    static testMethod void executeTest() {
        
        Test.startTest();
        
        String sch = '0 0 23 * * ?';
        String jobId = System.schedule('test check', sch, new ScheduledBatch_BatchAssetCalculator());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Check the job has run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        Datetime dt = DateTime.newInstance(system.today().year(), 
                                           system.today().month(), 
                                           system.today().day(), 
                                           23, 
                                           0, 
                                           0);
	      System.assertEquals(dt, ct.NextFireTime);
        
        Test.stopTest();
    }        
}