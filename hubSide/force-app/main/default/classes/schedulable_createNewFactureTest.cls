/***
* @author Ariane Tanguy (GFI)
* @date 07/07/2020
* @description schedulable_createNewFacture test class
* @see schedulable_createNewFacture
*/

@isTest 
public class schedulable_createNewFactureTest {
    
    static testMethod void executeTest() {
        
        Test.startTest();
        
        String sch = '0 0 23 * * ?';
        String jobId = System.schedule('test check', sch, new schedulable_createNewFacture());
        
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