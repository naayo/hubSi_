/***
* @author Ariane Tanguy (GFI)
* @date 08/06/2021
* @description Test class for AssociatedCostTrigger
*/
@isTest
public class AssociatedCostTriggerHandlerTest {
    
    /***
    * @description Update the equipSin name on insert
    * @see handleBeforeInsert
    */
    @isTest
    public static void updateCoutReelOnUpdateTest(){
        
        // Create a sinistre
        Case s = TestFactory.createSinistre();
        insert s;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = s.id;
        insert e;
        
        // Create two associated cost
        AssociatedCost__c a1 = new AssociatedCost__c(Name = 'Chassis', UnitCost__c = 10, ManpowerCost__c = 10, DamagedEquipment__c = e.id);
        AssociatedCost__c a2 = new AssociatedCost__c(Name = 'Ecran', UnitCost__c = 100, ManpowerCost__c = 20, DamagedEquipment__c = e.id);
        insert new List<AssociatedCost__c>{a1, a2};
        
        // Update one of them
        a2.UnitCost__c = 20;
        update a2;
        
        // Check whether the case and equipSin got updated
        s = [SELECT id, Montant_sinistre__c FROM Case WHERE id =: s.id];
        e = [SELECT id, RealCost__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        
        Decimal expectedMontant = a1.UnitCost__c + a2.UnitCost__c + a2.ManpowerCost__c;
   
        system.assertEquals(expectedMontant, e.RealCost__c, 
                            'The equipSin realCost shouldve been updated - This is wrong');
        
        // Update again
        a2.UnitCost__c = 200;
        update a2;
        
        // Check whether the case and equipSin got updated
        s = [SELECT id, Montant_sinistre__c FROM Case WHERE id =: s.id];
        e = [SELECT id, RealCost__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        
        expectedMontant = a1.UnitCost__c + a2.UnitCost__c + a2.ManpowerCost__c;
    }
    
    /***
    * @description Update the equipSin name on insert
    * @see handleBeforeInsert
    */
    @isTest
    public static void updateCoutReelOnDeleteTest(){
        
        // Create a sinistre
        Case s = TestFactory.createSinistre();
        insert s;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = s.id;
        insert e;
        
        // Create three associated cost
        AssociatedCost__c a1 = new AssociatedCost__c(Name = 'Chassis', UnitCost__c = 10, ManpowerCost__c = 10, DamagedEquipment__c = e.id);
        AssociatedCost__c a2 = new AssociatedCost__c(Name = 'Ecran', UnitCost__c = 100, ManpowerCost__c = 20, DamagedEquipment__c = e.id);
        AssociatedCost__c a3 = new AssociatedCost__c(Name = 'Autre', UnitCost__c = 20, ManpowerCost__c = 10, DamagedEquipment__c = e.id);
        insert new List<AssociatedCost__c>{a1, a2, a3};
        
        // Delete one of them
        delete a3;
        
        // Check whether the case and equipSin got updated
        s = [SELECT id, Montant_sinistre__c FROM Case WHERE id =: s.id];
        e = [SELECT id, RealCost__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        
        Decimal expectedMontant = a1.UnitCost__c + a2.UnitCost__c + a2.ManpowerCost__c;

        system.assertEquals(expectedMontant, e.RealCost__c, 
                            'The equipSin realCost shouldve been updated - This is wrong');
        
        // Delete another one
        delete a2;
        
        // Check whether the case and equipSin got updated
        s = [SELECT id, Montant_sinistre__c FROM Case WHERE id =: s.id];
        e = [SELECT id, RealCost__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        
        expectedMontant = a1.UnitCost__c + a1.ManpowerCost__c;

        system.assertEquals(expectedMontant, e.RealCost__c, 
                            'The equipSin realCost shouldve been updated - This is wrong');
        
        // Delete the last one
        delete a1;
        
        // Check whether the case and equipSin got updated
        s = [SELECT id, Montant_sinistre__c FROM Case WHERE id =: s.id];
        e = [SELECT id, RealCost__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        
        expectedMontant = 0;

        system.assertEquals(expectedMontant, e.RealCost__c, 
                            'The equipSin realCost shouldve been updated - This is wrong');
    }
}