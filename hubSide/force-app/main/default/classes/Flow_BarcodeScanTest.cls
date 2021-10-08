/***
* @author Ariane Tanguy (GFI)
* @date 03/11/2020
* @description Flow_BarcodeScan test class
* @Class Flow_BarcodeScanTest
*/

@isTest
public class Flow_BarcodeScanTest {
    
    /***
	* @description From a barcode scan, create colis
	* @LightningComponent Flow_BarcodeScan
	*/
    @isTest
    public static void createColisTest(){
        
        // Play the flow
        Integer numberDuplicates = Flow_BarcodeScan.processBarcode(NULL, 1, system.today(), 'LaPosteSav', '', NULL, '');
        
        // Check the result
        List<Colis__c> colisList = [SELECT id FROM Colis__c];
        system.assertEquals(colisList.size(), 1, 
                           'The number of colis created is not the expected one - This is wrong');
    }
    
    /***
	* @description From a barcode, update a status
	* @LightningComponent Flow_BarcodeScan
	*/
    @isTest
    public static void updateStatusTest(){
        
        // Create a client
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a sinistre
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.Typologie_Sinistre__c = 'Broken';
        c.RecordTypeId = caseSinistreId;
        insert c;
        
        c = [SELECT Numero_sinistre__c FROM Case WHERE id =: c.id];
        
        // Create an equipement sinistré
        Equipement_sinistre__c e = new Equipement_sinistre__c();
        e.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Equipement_a_reparer');
        e.Sinistre__c = c.id;
        insert e;    
                
        // Play the flow
        Integer numberDuplicates = Flow_BarcodeScan.processBarcode(c.Numero_sinistre__c, 0, NULL, NULL, 'En Attente Réception', '', '');
        
        e = [SELECT id, Statut_equipement__c FROM Equipement_sinistre__c WHERE id =: e.id];
        system.assertEquals(e.Statut_equipement__c, 'En Attente Réception', 
                           'The equipement status hasnt changed - This is wrong');
    }
    
    /***
	* @description From a barcode, update the owner
	* @LightningComponent Flow_BarcodeScan
	*/
    @isTest
    public static void updateOwnerTest(){
        
        // Create a colis
        id receivedColisRT = UtilityClassHelper.getCreatedRecordType('Colis_reception');
        Colis__c c = new Colis__c();
        c.Name = 'XREXWWE4584';
        c.Date_reception__c = system.today();
        c.Nom_transporteur__c = 'ChronopostSav';
        c.RecordTypeId = receivedColisRT;
        insert c;
        
        // Create a fake user
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id
                       FROM Profile
                       WHERE Name =: 'SFAM Expertise'].id;
        insert u;        
        
        // Play the flow
        Integer numberDuplicates = Flow_BarcodeScan.processBarcode('XREXWWE4584', NULL, NULL, NULL, NULL, NULL, u.id);
        
        c = [SELECT id, ownerId, owner.Name FROM Colis__c WHERE id =: c.id];
        system.assertEquals(c.OwnerId, u.id, 
                           'The colis owner hasnt changed - This is wrong ' + c.owner.Name);
    }
    
}