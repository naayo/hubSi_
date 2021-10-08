/***
* @author Ariane Tanguy (GFI)
* @date 03/06/2020
* @description batch_createNewFacture test class
* @see batch_createNewFacture
*/

@isTest 
public class batch_createNewFactureTest {
    
    @testSetup 
    public static void testSetup(){    
        
        // Create a contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = date.newInstance(system.today().year(), system.today().month() - 1, system.today().day() + 1);
        insert c;
        
        // Create a stock
        Stock_Produit__c s = TestFactory.createStock();
        insert s;
        
        // Create an emprunt
        Emprunt__c e = TestFactory.createEmprunt(c, s);
        e.Date_sortie__c = system.today() - 2;
        e.Date_retour_prevu__c = system.today() + 2;
        insert e;
        
        e.Caution_recue__c = TRUE;
        e.Status__c = 'Sortie';
        update e;
    }
    
    static testMethod void launchBatchTest() {
        
        Facture__c f = [SELECT id, Nombre_jours_consommes__c, Date_fin_periode__c, Date_debut_periode__c, Contrat_actif__c
                        FROM Facture__c];
        system.assertEquals(2, f.Nombre_jours_consommes__c, 
                            'There should be 2 days spent on the old facture - This is wrong');
        system.assertEquals(date.newInstance(system.today().year(), system.today().month() - 1, system.today().day() + 1), 
                            f.Date_debut_periode__c, 
                            'Date_debut_periode__c');
        
        // Handle the end of the month scenario
        if(system.today() != f.Date_fin_periode__c){
            f.Date_fin_periode__c = system.today();
            update f;
        }
        
        system.assertEquals(system.today(), f.Date_fin_periode__c, 
                            'Date_fin_periode__c');
         
        // Night has come, time to create the new factures
        test.startTest();
        batch_createNewFacture newFactureBatch = new batch_createNewFacture();
        DataBase.executeBatch(newFactureBatch);        
        test.stopTest();
        
        // Check whether a new facture was created
        List<Facture__c> factureList = [SELECT id, Nombre_jours_consommes__c, Nombre_jours_reportes__c, 
                                        Facture_active__c, Nombre_jours_restants__c
                                        FROM Facture__c];
        system.assertEquals(2, factureList.size(), 
                            'There should be another facture created - This is wrong');
        
        Facture__c oldFacture = factureList[0];
        system.assertEquals(TRUE, oldFacture.Facture_active__c, 'Wrong facture mutterpinder');
        Facture__c newFacture = factureList[1];
        
        // Check the old facture
        system.assertEquals(0, oldFacture.Nombre_jours_consommes__c, 
                            'The number of used days in the old facture should be maximum the formule s - This is wrong');
        system.assertEquals(4, oldFacture.Nombre_jours_restants__c, 
                            'The number of remaining days in the old facture should be same as the formule - This is wrong');
        
        // Check the new facture
        system.assertEquals(0, newFacture.Nombre_jours_reportes__c, 
                            'The number of days added in the new facture should be same as the formule - This is wrong');
    }
}