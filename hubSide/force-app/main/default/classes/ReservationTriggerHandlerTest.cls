/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description ReservationTrigger test class
* @Object Reservation__c
*/

@isTest
public class ReservationTriggerHandlerTest {
    
    /***
	* @description When creating a reservation, check the record type
	* @see updateRecordTypeOnCreation
	*/
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a new Contract
        Reservation__c r = TestFactory.createReservation();
        insert r;
        
        // Query the reservation and check whether the record type has been correctly updated
        r = [SELECT id, RecordType.DeveloperName FROM Reservation__c WHERE id =: r.id];
        
        system.assertEquals('Reservation', r.RecordType.DeveloperName, 
                            'The record type should have been updated on the reservation - This is wrong');
    }
    
    /***
	* @description When converting a reservation, check the record type
	* @see updateRecordTypeOnUpdate
	*/
    @isTest
    public static void updateRecordTypeOnUpdateTest(){
        
        // Create a new Contract
        Reservation__c r = TestFactory.createReservation();
        insert r;
        
        // Convert the reservation
        r.Status__c = 'Réservation_convertie';
        update r;
        
        // Query the reservation and check whether the record type has been correctly updated
        r = [SELECT id, RecordType.DeveloperName FROM Reservation__c WHERE id =: r.id];
        
        system.assertEquals('Reservation_convertie', r.RecordType.DeveloperName, 
                            'The record type should have been updated on the converted reservation - This is wrong');
    }

    /***
	* @description When creating a reservation, check whether there isn't already a reservation or an emprunt
	* @see checkStockPlanning
	*/
    @isTest
    public static void checkStockPlanningTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        insert s;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c, s);
        e.Client__c = c.AccountId;
        e.Date_sortie__c = system.today();
        e.Date_retour_prevu__c = system.today() + 1;
        e.Heure_sortie__c = system.now().time();
        e.Heure_retour_prevue__c = system.now().time();
        insert e;
        
        e.Status__c = 'Sortie';
        e.Caution_recue__c = TRUE;
        update e;
        
        test.startTest();
        
        // Create a new reservation
        Reservation__c r = TestFactory.createReservation(s);
        r.Date_retrait__c = system.today() + 5;
        r.Duree_emprunt__c = 1;
        insert r;
        
        // Create another reservation
        Reservation__c newRes = TestFactory.createReservation(s);
        newRes.Date_retrait__c = system.today() + 3;
        newRes.Duree_emprunt__c = 2;
        
        // Try to insert it
        try{
            insert newRes;
            system.assert(false, 'This reservation shouldnt have been successfully inserted - This is wrong');
        } catch(Exception ex){
            system.assertEquals(TRUE, ex.getMessage().contains('pas disponible sur la'), ex.getMessage());
        }
        
        // Change the reservation
        newRes.Duree_emprunt__c = 1;
        insert newRes;
        
        List<Reservation__c> reservationList = [SELECT id FROM Reservation__c WHERE Produit_reserve__c =: s.id];
        system.assertEquals(2, reservationList.size(), 
                            'This reservation should have been successfully inserted - This is wrong');
        
        test.stopTest();
    }
    
    /***
	* @description When creating a pre reservation, check whether it should'nt be a reservation
	* @see updatePreReservation
	*/
    @isTest
    public static void updatePreReservationTest(){
        
        // Create a new reservation
        Reservation__c r = TestFactory.createReservation();
        r.Status__c = 'Pré-réservé';
        r.Date_retrait__c = system.today() + 5;
        r.Duree_emprunt__c = 1;
        insert r;
        
        r = [SELECT Client__c, Status__c, Motif_pre_reservation__c FROM Reservation__c WHERE id =: r.id];
        system.assertEquals('Pré-réservé', r.Status__c, 
                           'The status should have been pre reserved - This is wrong');
        system.assertEquals('Prospect à qualifier', r.Motif_pre_reservation__c, 
                           'The motif should have been Prospect à qualifier - This is wrong');
        
        // Create a contract on that account
        Asset a = TestFactory.createContract(r.Client__c);
        insert a;
        
        test.startTest();
        
        // Create another reservation
        Reservation__c newRes = TestFactory.createReservation(r.Client__c);
        newRes.Status__c = 'Pré-réservé';
        newRes.Date_retrait__c = system.today() + 31;
        newRes.Duree_emprunt__c = 1;
        insert newRes;
        
        newRes = [SELECT Status__c, Produit_reserve__c FROM Reservation__c WHERE id =: newRes.id];
        system.assertEquals('Réservé', newRes.Status__c, 
                           'The status should have been reserved - This is wrong');
        
        // Create yet another reservation
        Reservation__c anotherRes = TestFactory.createReservation(r.Client__c, newRes.Produit_reserve__c);
        anotherRes.Status__c = 'Pré-réservé';
        anotherRes.Date_retrait__c = system.today() + 31;
        anotherRes.Duree_emprunt__c = 1;
        insert anotherRes;
        
        anotherRes = [SELECT Status__c, Motif_pre_reservation__c FROM Reservation__c WHERE id =: anotherRes.id];
        system.assertEquals('Pré-réservé', anotherRes.Status__c, 
                           'The status should have been pre reserved again - This is wrong');
        system.assertEquals('Hors stock', anotherRes.Motif_pre_reservation__c, 
                           'The motif should have been Hors stock - This is wrong');
        
        test.stopTest();
    }
    
    /***
	* @description When creating a reservation, update the stock if needed
	* @see updateRelatedStock
	*/
    @isTest
    public static void updateRelatedStockTest(){
        
        test.startTest();
        
        // Create a stock
        Stock_produit__c s = TestFactory.createStock();
        insert s;
        
        system.assertEquals(NULL, s.Prochaine_reservation__c, 
                           'That stock shouldnt have a next reservation already - This is wrong');
        
        // Create a new reservation
        Reservation__c r = TestFactory.createReservation(s);
        r.Date_retrait__c = system.today() + 5;
        r.Duree_emprunt__c = 1;
        insert r;
        
        // Check the stock
        s = [SELECT Prochaine_reservation__c, Date_retrait_souhaitee__c FROM Stock_produit__c WHERE id =: s.id];
        system.assertEquals(r.Date_retrait__c, s.Date_retrait_souhaitee__c, 
                           'The stock next reservation date shouldve been updated - This is wrong');
        system.assertEquals(r.id, s.Prochaine_reservation__c, 
                           'The stock next reservation shouldve been updated - This is wrong');
        
        // Update the reservation
        r.Date_retrait__c = system.today() + 10;
        update r;
        
        test.stopTest();
        
        // Check the stock
        s = [SELECT Prochaine_reservation__c, Date_retrait_souhaitee__c FROM Stock_produit__c WHERE id =: s.id];
        system.assertEquals(r.Date_retrait__c, s.Date_retrait_souhaitee__c, 
                           'The stock next reservation date shouldve been updated again - This is wrong');
        
        // Create another reservation
        Reservation__c r1 = TestFactory.createReservation(s);
        r1.Date_retrait__c = system.today() + 4;
        r1.Duree_emprunt__c = 1;
        insert r1;
        
        // Check the stock
        s = [SELECT Prochaine_reservation__c, Date_retrait_souhaitee__c FROM Stock_produit__c WHERE id =: s.id];
        system.assertEquals(r1.Date_retrait__c, s.Date_retrait_souhaitee__c, 
                           'The stock next reservation date shouldve been updated with the new reservation - This is wrong');
        system.assertEquals(r1.id, s.Prochaine_reservation__c, 
                           'The stock next reservation shouldve been updated  with the new reservation - This is wrong');
    }
}