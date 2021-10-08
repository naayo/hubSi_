/***
* @author Ariane Tanguy (GFI)
* @date 19/11/2020
* @description Document Trigger
*/

trigger DocumentTrigger on Document__c (before update, after update) {   
    
    DocumentTriggerHandler handler = new DocumentTriggerHandler();
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Get the related case and all its related documents
            Map<id, Case> relatedCaseMap = DocumentTriggerHelper.getRelatedCase(Trigger.new);
            List<Document__c> relatedDocumentList = DocumentTriggerHelper.getRelatedDocument(Trigger.new, relatedCaseMap.keySet());
            DocumentTriggerHandler.updateCaseOnUpdate(relatedDocumentList, relatedCaseMap);
        }
    }
    
    // AFTER TRIGGERS
     if(Trigger.isAfter){
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            DocumentTriggerHandler.deleteContentDocumentIfRemovedStatus(Trigger.new);
        }
    }
}