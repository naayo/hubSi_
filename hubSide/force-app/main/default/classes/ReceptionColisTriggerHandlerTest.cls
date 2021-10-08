/***
* @author Ariane Tanguy (GFI)
* @date 01/06/2021
* @description ReceptionColisTrigger test class
* @Object Reception_colis__c
*/

@isTest
public class ReceptionColisTriggerHandlerTest {
    
    /***
	* @description Set batchNumber field
	* @see setBatchNumber
	*/
    @isTest
    public static void setBatchNumberTest(){
        
        // Create a RC
        Reception_colis__c r = new Reception_colis__c();
        r.Name = 'test123';
       	r.Date_reception__c = system.today();
       	r.Nom_transporteur__c = 'ChronopostSav';
        insert r;
        
        r = [SELECT tech_batchNumber__c
            FROM Reception_colis__c
            WHERE id =: r.id];
        
        system.assertEquals(1, r.tech_batchNumber__c, 
                           'The tech number shouldve stayed 1 - This is wrong');
        
        // Create a RC
        Reception_colis__c r1 = new Reception_colis__c();
        r1.Name = 'test124';
       	r.Date_reception__c = system.today();
       	r1.Nom_transporteur__c = 'ChronopostSav';
        insert r1;
        
        r1 = [SELECT tech_batchNumber__c
              FROM Reception_colis__c
              WHERE id =: r1.id];
        
        system.assertEquals(2, r1.tech_batchNumber__c, 
                           'The tech number should be equal to 2 - This is wrong');
    }
}