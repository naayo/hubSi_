/***
* @author Nicolas Brancato (GFI)
* @date 11/02/2020
* @description Calcul Indemnisation Trigger
*/

trigger CalculIndemnisationTrigger on Mouvements_financiers__c (before update, before delete, after insert, after update, after delete) {
    
    CalculIndemnisationTriggerHandler handler = new CalculIndemnisationTriggerHandler();
    
    // BEFORE TRIGGERS
    if (Trigger.isBefore){
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            handler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        
        // BEFORE DELETE
        if(Trigger.isDelete){
            handler.handleBeforeDelete(Trigger.old);
        }
    }
    
    // AFTER TRIGGERS
    if (Trigger.isAfter){
        
        // AFTER INSERT
        if(Trigger.isInsert){
            handler.handleAfterInsert(Trigger.new);
        }
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            handler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        
        // AFTER DELETE
        if(Trigger.isDelete){
            handler.handleAfterDelete(Trigger.old);
        }
    }
}