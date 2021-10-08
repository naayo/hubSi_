/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Facture Trigger
*/

trigger FactureTrigger on Facture__c (before insert) {

    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Update the record type
            FactureTriggerHandler.updateFactureOnCreation(Trigger.New);
        }
    }
    
}