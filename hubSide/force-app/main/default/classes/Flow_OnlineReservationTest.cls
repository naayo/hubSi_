/***
* @author Ariane Tanguy (GFI)
* @date 06/07/2020
* @description Flow_OnlineReservation test class
* @Class Flow_OnlineReservation
*/

@isTest
public class Flow_OnlineReservationTest {
    
    @testSetup
    public static void init(){
        
        //OPTIM>
        date currentdate = system.today();
        //<OPTIM
        
        // Create a distributeur
        Account d = TestFactory.createDistributeur();
        d.Enseigne__c = 'SFAM';
        insert d;
        
        // Create a client
        Account c = TestFactory.createClient();
        insert c;
        
        // Create a product
        Product2 p = TestFactory.createProduct();
        p.Famille_produit__c = 'Téléphone';
        insert p;
        
        // Create three stocks from this product
        List<Stock_Produit__c> createdStockList = new List<Stock_Produit__c>();
        for(Integer i = 0; i<3; i++){
            Stock_produit__c s = TestFactory.createStock(p.Id);
            //OPTIM>
            s.Code_distributeur_stock__c = d.id;
            //<OPTIM
            createdStockList.add(s);
        }
        insert createdStockList;
        
        test.startTest();
        
        //OPTIM>
        //for(Stock_Produit__c s : createdStockList){
        //    s.Code_distributeur_stock__c = d.id;
        //}
        //update createdStockList;
        //<OPTIM
        
        // Create a reservation
        List<Reservation__c> reservationList = new List<Reservation__c>();
        Reservation__c r = TestFactory.createReservation(c.id, createdStockList[0].id);
        //OPTIM>
        //r.Date_retrait__c = system.today();
        r.Date_retrait__c = currentdate;
        //<OPTIM
        r.Duree_emprunt__c = 1;
        reservationList.add(r);
        
        // And a pre reservation
        Reservation__c pr = TestFactory.createReservation(c.id, createdStockList[1].id);
        //OPTIM>
        pr.Date_retrait__c = system.today();
        pr.Date_retrait__c = currentdate;
        //<OPTIM
        pr.Duree_emprunt__c = 1;
        pr.Status__c = 'Pré-réservé';
        reservationList.add(pr);
        
        insert reservationList;
        
        // Create an emprunt
        Asset a = TestFactory.createContract(c.id);
        a.Id_distributeur__c = d.Id;
        insert a;
        
        //Test.stopTest();
        
        Emprunt__c e = TestFactory.createEmprunt(a, createdStockList[2]);
		//OPTIM>
        //e.Date_sortie__c = system.today();
        //e.Date_retour_prevu__c = system.today() + 2;
        e.Date_sortie__c = currentdate;
        e.Date_retour_prevu__c = currentdate;
        //<OPTIM
        insert e;
        
        Test.stopTest();
    }
    
    /***
	* @description From the flow, get all available stock
	* @LightningComponent Flow_SelectionStock
	*/
    @isTest
    public static void Flow_selectionStockTest(){
        
        test.startTest();
        
        Id selectedProductId = [SELECT id FROM Product2 LIMIT 1].id;
        Date choosenDate = system.today();
        Integer dureeLocation = 1;
        
        // Make the logic work
        List<id> availableStockIdList = Flow_OnlineReservation.RetrieveStock(selectedProductId, choosenDate, dureeLocation, 'SFAM', true, true);
        List<id> distributeurIdList = Flow_OnlineReservation.RetrieveStock(selectedProductId, choosenDate, dureeLocation, 'SFAM', true, false);
        
        // Check the result
        system.assertEquals(1, availableStockIdList.size(), 
                           'The returned list should have one stocks - This is wrong');
        
        // Get the distributeur for the user to choose from
        List<Object> objList = Flow_OnlineReservation.getAllDistributeur(selectedProductId, choosenDate, dureeLocation, 'SFAM', true);
        
        // Check the result
        system.assertEquals(1, objList.size(), 
                           'The returned list should have one distributeur - This is wrong');

        // The user chose the first distributeur, let's get one stock now
        Id choosenId = Flow_OnlineReservation.returnOneStockFromList(availableStockIdList, distributeurIdList[0]);
        
        // Check the result
        system.assertEquals(availableStockIdList[0], choosenId, 
                           'The returned list should have one distributeur - This is wrong');
        
        Test.stopTest();
    }
    
    /***
	* @description From the flow, get all available stock
	* @LightningComponent Flow_SelectionStockMagasin
	*/
    @isTest
    public static void Flow_selectionStockMagasinTest(){
        
        test.startTest();
        
        id distribId = [SELECT id FROM Account 
                        WHERE RecordTypeId =: UtilityClassHelper.getCreatedRecordType('Distributeur')][0].id;
        Id selectedProductId = [SELECT id FROM Product2 LIMIT 1].id;
        Date choosenDate = system.today();
        Integer dureeLocation = 1;
        
        // Make the logic work
        id chosenId = Flow_OnlineReservation.returnOneStock(selectedProductId, choosenDate, dureeLocation, distribId, false);
        
        // Check the result
        system.assert(chosenId != null, 'The returned id shouldnt be null - This is wrong');

        // Query the pre reservation
        Reservation__c r = [SELECT id, Status__c
                            FROM Reservation__c
                            WHERE Status__c = 'Pré-réservé'];
        r.Status__c = 'Réservé';
        update r;
        
        // Make the logic work again
        chosenId = Flow_OnlineReservation.returnOneStock(selectedProductId, choosenDate, dureeLocation, distribId, false);
        
        // Check the result
        system.assert(chosenId == null, 'The returned id should be null - This is wrong');
        
        Test.stopTest();
    }
    
}