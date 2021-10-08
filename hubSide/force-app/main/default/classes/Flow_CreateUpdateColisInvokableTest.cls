/***
* @author Ariane Tanguy (GFI)
* @date 03/06/2021
* @description Flow_CreateUpdateColisInvokable test class
* @class Flow_CreateUpdateColisInvokableTest
*/

@isTest
public class Flow_CreateUpdateColisInvokableTest {
    
    /***
    * @description Create a colis
    * @see createColis
    */
    @isTest
    public static void createColisTest(){
        
        // CHRONOPOST
        // Mock the flow inputs
        Flow_CreateUpdateColisInvokable.FlowInputs fInput = new Flow_CreateUpdateColisInvokable.FlowInputs();        
        fInput.barcodeString = 'CHR15671867';
        fInput.receptionDate = system.today();
        fInput.senderName = 'ChronopostSav';
        fInput.createColis = TRUE;
        
        List<Flow_CreateUpdateColisInvokable.FlowInputs> fInputList = new List<Flow_CreateUpdateColisInvokable.FlowInputs>();
        fInputList.add(fInput);
        
        List<Flow_CreateUpdateColisInvokable.FlowOutputs> fOutputList = Flow_CreateUpdateColisInvokable.processBarcode(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        system.assertEquals(1, fOutputList[0].barcodeCount, 'There should be one input - This is wrong');
        system.assertEquals(1, fOutputList[0].barcodeProcessed, 'There should be one input - This is wrong');
        
        Colis__c c = [SELECT Name FROM Colis__c];
        system.assertEquals('CHR15671867', c.Name, 'The colis name shouldve been updated - This is wrong');
        
        // LA POSTE
        // Mock the flow inputs
        fInput = new Flow_CreateUpdateColisInvokable.FlowInputs();
        fInput.barcodeString = 'PO220621003';
        fInput.receptionDate = system.today();
        fInput.senderName = 'LaPosteSav';
        fInput.createColis = TRUE;
        
        fInputList = new List<Flow_CreateUpdateColisInvokable.FlowInputs>();
        fInputList.add(fInput);
                
        fOutputList = Flow_CreateUpdateColisInvokable.processBarcode(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        
        List<Colis__c> colisList = [SELECT Name FROM Colis__c];
        system.assertEquals(2, colisList.size(), 'There should be two colis now - This is wrong');
        
        // Colis en VRAC
        // Mock the flow inputs
        fInput = new Flow_CreateUpdateColisInvokable.FlowInputs();
        fInput.colisQuantity = 1;
        fInput.receptionDate = system.today();
        fInput.senderName = 'BulkParcelsSav';
        fInput.createColis = TRUE;
        
        fInputList = new List<Flow_CreateUpdateColisInvokable.FlowInputs>();
        fInputList.add(fInput);
        
        fOutputList = Flow_CreateUpdateColisInvokable.processBarcode(fInputList);
        system.assertEquals(1, fOutputList.size(), 'There should be only one output - This is wrong');
        
        List<Colis__c> colisList2 = [SELECT Name FROM Colis__c];
        system.assertEquals(3, colisList2.size(), 'There should be two colis now - This is wrong');
    }
}