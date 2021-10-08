/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description FactureTrigger test class
* @Object Facture__c
*/

@isTest
public class FactureTriggerHandlerTest {
    
    /***
    * @description Update the date for the contract starting in the past
    * @see updateRelatedFacture
    */
    @isTest
    public static void updateRelatedFactureTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year() - 4, 
                                                   system.today().month() - 4, 
                                                   system.today().day() - 2);
        insert c;
        
        // Query the facture
        Facture__c f = [SELECT id, Date_debut_periode__c FROM Facture__c WHERE Contrat__c =: c.id];
                
        system.assertEquals(system.today(), f.Date_debut_periode__c, 
                            'The facture start date is not the one expected - This is wrong');
        
        // Create another contract
        Asset c1 = TestFactory.createContract();
        c1.Date_debut_contrat__c = system.today() - 2;
        insert c1;
        
        // Query the facture
        Facture__c f1 = [SELECT id, Date_debut_periode__c FROM Facture__c WHERE Contrat__c =: c1.id];
                
        system.assertEquals(c1.Date_debut_contrat__c, f1.Date_debut_periode__c, 
                            'The facture start date is not the one expected - This is wrong');
    }
    
    
}