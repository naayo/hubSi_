/***
* @author Ariane Tanguy (GFI)
* @date 25/08/2020
* @description Task Trigger
*/

trigger TaskTrigger on Task (before insert, before update, after insert, before delete) {
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Update the record type
            TaskTriggerHandler.updateRecordTypeOnCreation(Trigger.new);
            
            // Update task on insert
            Map<String, EmailTemplate> emailTemplateMap = TaskTriggerHelper.getRelatedTemplate(Trigger.new);
            TaskTriggerHandler.updateTaskOnInsert(Trigger.new, emailTemplateMap);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Update the related case
            Map<id, Case> caseIdMap = TaskTriggerHelper.getRelatedCase(Trigger.new);
            TaskTriggerHandler.updateRelatedCase(Trigger.new, Trigger.oldMap, caseIdMap);
        }
        
        // BEFORE DELETE
        if(Trigger.isDelete){
            
            // Check whether the user has the permission to delete that task
            TaskTriggerHandler.checkProfileBeforeDelete(Trigger.old);
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Check whether there is an email to be sent
            Map<String, EmailTemplate> emailTemplateMap = TaskTriggerHelper.getRelatedTemplate(Trigger.new);
            TaskTriggerHandler.handleCommunication(Trigger.new, emailTemplateMap);
        }
    }
}