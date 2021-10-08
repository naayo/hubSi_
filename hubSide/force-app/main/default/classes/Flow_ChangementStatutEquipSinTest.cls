/***
* @author Ariane Tanguy (GFI)
* @date 28/04/2021
* @description Flow_ChangementStatutEquipSin test class
* @class Flow_ChangementStatutEquipSin
*/

@isTest
public class Flow_ChangementStatutEquipSinTest {
    
    /***
    * @description Update EquipSin status
    * @see updateEquipSinStatus
    */
    @isTest
    public static void updateEquipSinStatusTest(){
        
        // Create a case
        Case s = TestFactory.createSinistre();
        s.Typologie_Sinistre__c = 'Broken';
        insert s;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = s.id;
        insert e;
        
        e = [SELECT id, RecordTypeId FROM Equipement_Sinistre__c WHERE id =: e.id];
        system.assert(e.RecordTypeId == UtilityClassHelper.getCreatedRecordType('Equipement_a_reparer'));
        
        // Get the current status
        
        // Mock the flow inputs
        List<Flow_ChangementStatutEquipSin.FlowInputs> fInputList = new List<Flow_ChangementStatutEquipSin.FlowInputs>();
        Flow_ChangementStatutEquipSin.FlowInputs fInput = new Flow_ChangementStatutEquipSin.FlowInputs();
        fInput.barcodeString = 'INS000001';
        fInput.selectedRT = e.RecordTypeId;
        fInput.getCurrentStatus = true;
        fInputList.add(fInput);
        
        // And play the flow
        List<Flow_ChangementStatutEquipSin.FlowOutputs> fOutputList = Flow_ChangementStatutEquipSin.updateEquipSinStatus(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        system.assertEquals(1, fOutputList[0].barcodeCount, 'There should be one barcode - This is wrong');
        system.assert(fOutputList[0].currentStatusString.contains('En Analyse'), 
                            'The current status should be En analyse - This is wrong');
        
        // Now update the status
        fInput.getCurrentStatus = false;
        fInput.newStatus = 'Irréparable';
        
        // Play the flow again
        fOutputList = Flow_ChangementStatutEquipSin.updateEquipSinStatus(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        system.assertEquals(1, fOutputList[0].barcodeCount, 'There should be one barcode - This is wrong');
        system.assertEquals(false, fOutputList[0].isErrorRT, 'The status shouldve have been changed successfully');
        
        e = [SELECT id, Statut_equipement__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        system.assertEquals(fInput.newStatus = 'Irréparable', e.Statut_equipement__c, 'The status shouldve have been changed to Irréparable');
        
        // Actually, go directly to the final status
        fInput.setFinalStatus = true;
        
        // Play the flow again
        fOutputList = Flow_ChangementStatutEquipSin.updateEquipSinStatus(fInputList);
        
        e = [SELECT id, Statut_equipement__c FROM Equipement_Sinistre__c WHERE id =: e.id];
        system.assertEquals(fInput.newStatus = 'Irréparable', e.Statut_equipement__c, 
                            'The status shouldve have been changed to Irréparable');
    }
}