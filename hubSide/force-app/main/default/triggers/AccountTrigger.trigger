/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Account Trigger
*/

trigger AccountTrigger on Account (before update) {
    
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
                
        // BEFORE INSERT
        if(Trigger.isUpdate){
            
            // Check the record type
            AccountTriggerHandler.checkRecordTypeOnUpdate(Trigger.new, Trigger.oldMap);
            
            // Get the related user, and update them
            AccountTriggerHandler.updateRelatedUser(Trigger.new, Trigger.oldMap);
        }
    }
}