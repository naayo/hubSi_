/***
* @author Ariane Tanguy (GFI)
* @date 01/06/2021
* @description Reception Colis Trigger
*/

trigger ReceptionColisTrigger on Reception_colis__c (before insert) {
    
    // BEFORE TRIGGERS
    if (Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Set batchNumber
            Map<String, Decimal> maxBatchNumber = ReceptionColisTriggerHelper.getMaxBatchNumber();
            ReceptionColisTriggerHandler.setBatchNumber(Trigger.new, maxBatchNumber);
        }
    }
}