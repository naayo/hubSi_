/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description EmpruntTrigger test class
* @Object Emprunt__c
*/

@isTest
public class EmpruntTriggerHandlerTest {
    
    /***
	* @description Update the related facture when an emprunt is created
	* @see setFactureOnEmprunt
	*/
    @isTest
    public static void setFactureOnEmpruntTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        e.Client__c = c.AccountId;
        insert e;
        
        // Query the related facture and 
        // check whether the Emprunt has been correctly updated
        Facture__c f = [SELECT id, Nombre_jours_restants__c
                        FROM Facture__c WHERE Contrat__c =: c.id];
        e = [SELECT id, Facture__c
             FROM Emprunt__c WHERE Contrat__c =: c.id];
        
        system.assertEquals(e.Facture__c, f.id,
                            'The facture field should have been updated on the emprunt - This is wrong');
    }
    
    /***
	* @description Update the remaining number of days when an emprunt is created and updated
	* @see setRemainingDays
	*/
    @isTest
    public static void setRemainingDaysTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        e.Client__c = c.AccountId;
        insert e;
        
        // Query the related facture and 
        // check whether the Emprunt has been correctly updated
        Facture__c f = [SELECT id, Nombre_jours_restants__c
                        FROM Facture__c WHERE Contrat__c =: c.id];
        e = [SELECT id, Nombre_de_jours_consommation__c
             FROM Emprunt__c WHERE Contrat__c =: c.id];
        
        system.assertEquals(e.Nombre_de_jours_consommation__c, f.Nombre_jours_restants__c,
                            'The remaining number of days should have been updated on the emprunt - This is wrong');
    }
    
    /***
	* @description Update the record type
	* @see updateRecordTypeOnCreation
	*/
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        insert e;
        
        // Query emprunt and check whether the record type has been correctly updated
        e = [SELECT id, RecordType.DeveloperName FROM Emprunt__c WHERE id =: e.id];
        
        system.assertEquals('Emprunt', e.RecordType.DeveloperName, 
                            'The record type should have been updated on the emprunt - This is wrong');
    }
    
    /***
	* @description Update the coefficient de decompte
	* @see updateCoefdeDecompte
	*/
    @isTest
    public static void updateCoefdeDecompteTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        insert e;
        
        // Query emprunt and check whether the coef has been correctly updated
        e = [SELECT id, Coefficient_decompte__c FROM Emprunt__c WHERE id =: e.id];
        
        // Query the related table de decompte
        Table_decompte__c t = [SELECT Coefficient_decompte__c FROM Table_decompte__c];
        
        system.assertEquals(t.Coefficient_decompte__c, e.Coefficient_decompte__c, 
                            'The coef should have been updated on the emprunt - This is wrong');
    }
    
    /***
	* @description Sum the emprunt fields and update them on the facture 
	* @see updateFacture
	*/
    @isTest
    public static void updateFactureTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = system.today() - 10;
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        e.Date_retour_prevu__c = system.today();
        e.Montant_geste_commercial__c = 10;
        e.Motif_geste_commercial__c = 'Retard';
        insert e;
        
        // Mock an old emprunt
        e.Date_sortie__c = system.today() - 2;
        e.Heure_sortie__c = system.now().time();
        e.Heure_retour_prevue__c = system.now().time();
        e.Caution_recue__c = true;
        update e;
        
        test.startTest();
        
        e.Heure_retour__c = system.now().time();
        e.Etat_retour__c = e.Etat_sortie__c;
        e.Point_de_vente_retour__c = e.Point_de_vente_sortie__c;
        e.Caution_restituee__c = e.Caution_recue__c;
        e.Status__c = 'Retourné';
        update e;
        
        // Query the emprunt to check the number of days imputed
        e = [SELECT Duree_location__c, Nombre_jours_imputes__c, 
             Nombre_de_jours_consommation__c, Jours_consommes__c FROM Emprunt__c WHERE id =: e.id];
        
        system.assertEquals(4, e.Nombre_de_jours_consommation__c, 
                            'There should be 4 days - This is wrong');
        system.assertEquals(2, e.Jours_consommes__c, 
                            'There should be 2 consummed days - This is wrong');
        system.assertEquals(2, e.Nombre_jours_imputes__c, 
                            'There should be 2 imputed days - This is wrong');
        
        // Query the facture and check whether the number of days spent has been updated
        List<Facture__c> factureList = [SELECT Montant_facture__c, Nombre_jours_consommes__c
                                        FROM Facture__c
                                        WHERE Contrat__c =: c.id];
        
        system.assertEquals(2, factureList[0].Nombre_jours_consommes__c, 
                            'The number of days spent hasnt been updated - This is wrong');
        system.assertEquals(-10, factureList[0].Montant_facture__c, 
                            'The total invoiced hasnt been updated - This is wrong');
        
        // Create another emprunt
        Emprunt__c newEmprunt = TestFactory.createEmprunt(c);
        newEmprunt.Date_retour_prevu__c = system.today();
        newEmprunt.Montant_geste_commercial__c = 100;
        newEmprunt.Motif_geste_commercial__c = 'Retard';
        insert newEmprunt;
        
        // Mock an old emprunt
        newEmprunt.Date_sortie__c = system.today() - 1;
        update newEmprunt;
        
        // Query the facture and check whether the number of days spent has been updated
        factureList = [SELECT Montant_facture__c, Nombre_jours_consommes__c
                       FROM Facture__c
                       WHERE Contrat__c =: c.id];
        
        // Query the emprunt to check the number of days imputed
        newEmprunt = [SELECT Nombre_jours_imputes__c
                      FROM Emprunt__c WHERE id =: newEmprunt.id];
        
        system.assertEquals(e.Nombre_jours_imputes__c + newEmprunt.Nombre_jours_imputes__c, factureList[0].Nombre_jours_consommes__c, 
                            'The number of days spent hasnt been updated after another emprunt created - This is wrong');
        system.assertEquals(-110, factureList[0].Montant_facture__c, 
                            'The Montant Facture hasnt been updated after another emprunt created - This is wrong');
        
        // Update the emprunt
        newEmprunt.Date_sortie__c = system.today() - 2;
        newEmprunt.Montant_geste_commercial__c = 10;
        update newEmprunt;
        
        // Query the facture and check whether the number of days spent has been updated
        factureList = [SELECT Montant_facture__c, Nombre_jours_consommes__c, Nombre_jours_depassement__c
                       FROM Facture__c
                       WHERE Contrat__c =: c.id];
        
        // Query the emprunt to check the number of days imputed
        newEmprunt = [SELECT Nombre_jours_imputes__c
                      FROM Emprunt__c WHERE id =: newEmprunt.id];
        
        system.assertEquals(e.Nombre_jours_imputes__c + newEmprunt.Nombre_jours_imputes__c, factureList[0].Nombre_jours_consommes__c, 
                            'The number of days spent hasnt been updated after emprunt update - This is wrong');
        system.assertEquals(-20, factureList[0].Montant_facture__c, 
                            'The Montant facturé hasnt been updated after emprunt update - This is wrong');
        
        test.stopTest();
    }
    
    /***
	* @description Substract the fields from deleted emprunt on the facture
	* @see cleanFactureOnDelete
	*/
    @isTest
    public static void cleanFactureOnDeleteTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        e.Date_sortie__c = system.today();
        e.Date_retour_prevu__c = system.today() + 2;
        e.Montant_geste_commercial__c = 10;
        e.Motif_geste_commercial__c = 'Retard';
        insert e;
        
        // On second thoughts - delete it
        delete e;
        
        // Query the facture and check whether the number of days spent has been updated
        List<Facture__c> factureList = [SELECT Montant_facture__c, Nombre_jours_consommes__c
                                       FROM Facture__c
                                       WHERE Contrat__c =: c.id];
        
        system.assertEquals(0, factureList[0].Nombre_jours_consommes__c, 
                            'The number of days spent hasnt been updated after deletion - This is wrong');
        system.assertEquals(0, factureList[0].Montant_facture__c, 
                            'The Montant geste co hasnt been updated after deletion - This is wrong');
    }
    
    /***
	* @description When creating an emprunt, check whether there isn't already a reservation.
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
        
        test.startTest();
        
        // Create a new reservation
        Reservation__c r = TestFactory.createReservation(c.AccountId, s.id);
        r.Date_retrait__c = system.today();
        r.Duree_emprunt__c = 1;
        insert r;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c, s);
        e.Date_sortie__c = system.today() + 1;
        e.Date_retour_prevu__c = system.today() + 2;
        
        // Try to insert it
        try{
            insert e;
            system.assert(false, 'This emprunt shouldnt have been successfully inserted - This is wrong');
        } catch(Exception ex){
            system.assertEquals(TRUE, ex.getMessage().contains('pas disponible sur la'), ex.getMessage());
        }
        
        // Change the reservation
        r.Date_retrait__c = system.today() + 4;
        r.Duree_emprunt__c = 1;
        update r;
        
        // And insert the emprunt again
        insert e;
        
        test.stopTest();
    }
    
    /***
	* @description Check whether the emprutn status is well automated
	* @see automateEmpruntStatus
	*/
    @isTest
    public static void automateEmpruntStatusTest(){
        
        // Create a contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Create a distributeur
        Account d = TestFactory.createDistributeur();
        insert d;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c);
        e.Date_sortie__c = system.today() + 1;
        e.Date_retour_prevu__c = system.today() + 2;
        e.Point_de_vente_retour__c = d.id;
        e.Point_de_vente_sortie__c = d.id;
        insert e;
        
        Test.startTest();
        
        // Take it out
        e.Heure_sortie__c = system.now().time();
        e.Heure_retour_prevue__c = system.now().time();
        e.Etat_sortie__c = 'Neuf';
        e.Montant_caution_sortie__c = 100;
        e.Caution_recue__c = true;
        update e;
        
        // Check whether the status got updated
        e = [SELECT Status__c FROM Emprunt__c WHERE id =: e.id];
        system.assertEquals('Sortie', e.Status__c, 
                           'The emprunt status hasnt been updated - This is wrong');
        
        // Bring it back 
        e.Date_retour__c = system.today() + 2;
        e.Heure_retour__c = system.now().time();
        e.Etat_retour__c = 'Bon état';
        e.Montant_caution_retour__c = 100;
        e.Caution_restituee__c = TRUE;
        update e;
        
        // Check whether the status got updated
        e = [SELECT Status__c FROM Emprunt__c WHERE id =: e.id];
        system.assertEquals('Retourné', e.Status__c, 
                           'The emprunt status hasnt been updated - This is wrong');
        
        // Wait, actually there was a scratch, let's play it again
        e.Caution_restituee__c = FALSE;
        e.Status__c = 'Sortie';
        update e;
        
        // Update teh emprunt again
        e.Caution_restituee__c = TRUE;
        e.Etat_retour__c = 'Rayé';
        e.Montant_a_deduire__c = 10;
        e.Default__c = 'Rayé';
        update e;
        
        Test.stopTest();
        
        // Check whether the status got updated
        e = [SELECT Status__c FROM Emprunt__c WHERE id =: e.id];
        system.assertEquals('Retour avec défaut', e.Status__c, 
                           'The emprunt status hasnt been correctly updated - This is wrong');
    }
    
}