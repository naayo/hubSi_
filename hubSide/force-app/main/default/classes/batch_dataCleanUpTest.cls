/***
* @author Ariane Tanguy (GFI)
* @date 07/05/2021
* @description batch_dataCleanUp test class
* @see batch_dataCleanUp
*/

@isTest 
public class batch_dataCleanUpTest {
    
    @testSetup 
    public static void testSetup(){    
        
        // Create a contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = date.newInstance(system.today().year(), system.today().month() - 1, system.today().day() + 1);
        insert c;
        
        // Create a sinistre
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case s = new Case();
        s.vlocity_ins__Verified__c = TRUE;
        s.AssetId = c.id;
        s.RecordTypeId = caseSinistreId;
        insert s;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = s.id;
        insert e;
    }
    
    static testMethod void launchBatchTest() {
        
        List<Case> allSinistre = [SELECT id FROM Case];
        system.assertEquals(1, allSinistre.size(), 
                            'There should be only one sinistre - This is wrong');
        
        List<Equipement_Sinistre__c> allEquipSin = [SELECT id FROM Equipement_Sinistre__c];
        system.assertEquals(1, allEquipSin.size(), 
                            'There should be only one equipement - This is wrong');
        
        // Night has come, time to create the new factures
        test.startTest();
        batch_dataCleanUp newdataCleanUpBatch = new batch_dataCleanUp();
        DataBase.executeBatch(newdataCleanUpBatch);        
        test.stopTest();
        
        // Check whether everything was deleted
        allSinistre = [SELECT id FROM Case];
        system.assertEquals(0, allSinistre.size(), 
                            'There should be no more sinistre - This is wrong');
        
        allEquipSin = [SELECT id FROM Equipement_Sinistre__c];
        system.assertEquals(0, allEquipSin.size(), 
                            'There should be no more equipement - This is wrong');
    }
}