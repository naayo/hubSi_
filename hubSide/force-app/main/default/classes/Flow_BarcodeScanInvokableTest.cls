/***
* @author Ariane Tanguy (GFI)
* @date 11/02/2021
* @description Flow_BarcodeScanInvokable test class
* @class Flow_BarcodeScanInvokable
*/

@isTest
public class Flow_BarcodeScanInvokableTest {
    
    /***
    * @description Split flow string into workable barcode strings
    * @see splitBarcode
    */
    @isTest
    public static void splitBarcodeTest(){
        
        // Create a case
        Case s = TestFactory.createSinistre();
        insert s;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = s.id;
        insert e;
        
        // Mock the flow inputs
        Flow_BarcodeScanInvokable.FlowInputs fInput = new Flow_BarcodeScanInvokable.FlowInputs();        
        fInput.fieldToUpdate = 'Adresse_de_livraison__c';
        fInput.objectToQuery = 'Equipement_sinistre__c';
        fInput.fieldToQuery = 'Numero_sinistre__c';
        fInput.barcodeString = 'INS000001';
        fInput.valueToUpdate = '12 rue 132';
        
        List<Flow_BarcodeScanInvokable.FlowInputs> fInputList = new List<Flow_BarcodeScanInvokable.FlowInputs>();
        fInputList.add(fInput);
        
        List<Flow_BarcodeScanInvokable.FlowOutputs> fOutputList = Flow_BarcodeScanInvokable.splitBarcode(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        system.assertEquals(1, fOutputList[0].barcodeList.size(), 'There should be two barcodes - This is wrong');
        system.assertEquals('INS000001', fOutputList[0].barcodeList[0], 'The first barcode should be INS000001 - This is wrong');
        
        e = [SELECT Adresse_de_livraison__c FROM Equipement_sinistre__c WHERE id =: e.id];
        system.assertEquals(fInput.valueToUpdate, e.Adresse_de_livraison__c);
    }
}