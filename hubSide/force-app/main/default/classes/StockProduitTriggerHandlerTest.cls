/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description StockMagasin test class
* @Object Stock_Produit__c
*/

@isTest
public class StockProduitTriggerHandlerTest {
    
    /***
    * @description Update the record type on stock creation
    * @see updateRecordTypeOnCreation
    */
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        insert s;
        
        // Query product and check whether the record type has been correctly updated
        s = [SELECT id, Name, RecordType.DeveloperName FROM Stock_Produit__c WHERE id =: s.id];
        
        system.assertEquals(s.RecordType.DeveloperName, 'Stock_produit', 
                            'The record type should have been updated on the stock - This is wrong');
    }
    
    /***
    * @description Update the record type on stock update
    * @see updateRecordTypeOnUpdate
	*/
    @isTest
    public static void updateRecordTypeOnUpdateTest(){
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        insert s;
        
        s.Statut__c = 'Sortie client';
        update s;
        
        // Query product and check whether the record type has been correctly updated
        s = [SELECT id, Name, RecordType.DeveloperName FROM Stock_Produit__c WHERE id =: s.id];
        
        system.assertEquals(s.RecordType.DeveloperName, 'Stock_non_empruntable', 
                            'The record type should have been updated on the stock - This is wrong');
        
        s.Statut__c = 'En stock';
        update s;
        
        // Query product and check whether the record type has been correctly updated
        s = [SELECT id, Name, RecordType.DeveloperName FROM Stock_Produit__c WHERE id =: s.id];
        
        system.assertEquals(s.RecordType.DeveloperName, 'Stock_produit', 
                            'The record type should have been updated again on the stock - This is wrong');
    }
    
    /***
    * @description Update the product availability
    * @see updateRelatedProductAvailability
    */
    @isTest
    public static void updateRelatedProductAvailabilityTest(){
        
        // Create a distributeur
        Account a = TestFactory.createDistributeur();
        a.Name = 'Magasin';
        a.Compte_test__c = FALSE;
        insert a;
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        s.Code_distributeur_stock__c = a.id;
        insert s;
        
        Product2 p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible.', p.Disponibilite_stock__c, 
                            'The product availability shouldve been initiated - This is wrong');
        
        // Create a reservation
        Reservation__c r = TestFactory.createReservation(s);
        r.Date_retrait__c = system.today() + 3;
        r.Duree_emprunt__c = 1;
        insert r;
        
        p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible jusqu\'au ' + 
                            UtilityClassHelper.formatDate(r.Date_retrait__c), p.Disponibilite_stock__c, 
                            'The product availability shouldve been updated - This is wrong');
        
        Test.startTest();
        
        // Create an asset
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c, s);
        e.Date_sortie__c = system.today();
        e.Date_retour_prevu__c = system.today() + 2;
        insert e;
        
        // Take it out
        e.Heure_sortie__c = system.now().time();
        e.Heure_retour_prevue__c = system.now().time();
        e.Etat_sortie__c = 'Neuf';
        e.Montant_caution_sortie__c = 100;
        e.Caution_recue__c = true;
        update e;
        
        // Check the related product
        p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible à partir du ' + 
                            UtilityClassHelper.formatDate(e.Date_retour_prevu__c) + 
                            ' et jusqu\'au ' + 
                            UtilityClassHelper.formatDate(r.Date_retrait__c), p.Disponibilite_stock__c, 
                            'The product availability shouldve been updated - This is wrong');
        
        // Cancel the reservation
        r.Status__c = 'Annulé';
        r.Motif_annulation__c = 'Test casualty';
        update r;
        
        // Check the related product
        p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible à partir du ' + 
                            UtilityClassHelper.formatDate(e.Date_retour_prevu__c), p.Disponibilite_stock__c, 
                            'The product availability shouldve been again updated - This is wrong');
        
        Test.stopTest();
    }
    
    /***
    * @description Update the product availability
    * @see updateRelatedProductAvailability
    */
    @isTest
    public static void updateRelatedProductAvailabilityTest_fakeDistributeur(){
        
        // Create a distributeur
        Account a = TestFactory.createDistributeur();
        a.Name = 'Magasin';
        a.Compte_test__c = FALSE;
        insert a;
        
        // Create another distributeur
        Account a1 = TestFactory.createDistributeur();
        a1.Name = 'FakeMagasin';
        a1.Compte_test__c = TRUE;
        insert a1;
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        s.Code_distributeur_stock__c = a.id;
        insert s;
        
        Product2 p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible.', p.Disponibilite_stock__c, 
                            'The product availability shouldve been initiated - This is wrong');
        
        // Create another stock
        Stock_Produit__c s1 = TestFactory.createStock(s.Produit__c);
        s1.Code_distributeur_stock__c = a1.id;
        insert s1;
        
        p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible.', p.Disponibilite_stock__c, 
                            'The product availability shouldve stayed the same - This is wrong');
        
        // Create again another stock
        Stock_Produit__c s2 = TestFactory.createStock(s.Produit__c);
        s2.Code_distributeur_stock__c = a.id;
        insert s2;
        
        p = [SELECT id, Disponibilite_stock__c FROM Product2 WHERE id =: s.Produit__c];
        system.assertEquals('Magasin : Votre produit est disponible.', p.Disponibilite_stock__c, 
                            'The product availability shouldve stayed the same - This is wrong');
    }
}