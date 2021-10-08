/***
* @author Ariane Tanguy (GFI)
* @date 06/04/2021
* @description User Trigger
*/

trigger AlertTrigger on Alert__c (after update, before delete) {
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        system.debug('--Approved IsUpdate Before');
        // BEFORE DELETE
        if(Trigger.isDelete){
            
            // Check if delete is authorized
            Map<id, Case> relatedCaseMap = AlertTriggerHelper.getRelatedCase(Trigger.old);
            AlertTriggerHandler.isDeleteAuthorized(Trigger.old, relatedCaseMap);
        }
    }
    
      if(Trigger.isAfter){
        // BEFORE DELETE
        if(Trigger.isUpdate){
            system.debug('--Approved IsUpdate');
            // Check case fields update
            Map<id, Case> relatedCaseMap = AlertTriggerHelper.getRelatedCase(Trigger.new);
            AlertTriggerHandler.updateCaseFields(Trigger.new, relatedCaseMap);
        }
    }
}