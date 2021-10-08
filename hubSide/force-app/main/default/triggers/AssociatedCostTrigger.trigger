/***
* @author Ariane Tanguy (GFI)
* @date 08/06/2021
* @description AssociatedCost__c Trigger
*/

trigger AssociatedCostTrigger on AssociatedCost__c (after update, after delete) {
    
    // BEFORE TRIGGERS
    if(Trigger.isAfter){
        
        // BEFORE UPDATE TRIGGERS
        if(Trigger.isUpdate){
            
            // Update the case + equipSin cout global on delete
            AssociatedCostTriggerHandler.updateCoutReelOnUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER DELETE TRIGGERS
        if(Trigger.isDelete){
            
            // Update the case + equipSin cout global on delete
            AssociatedCostTriggerHandler.updateCoutReelOnDelete(Trigger.old);
        }
    }
}