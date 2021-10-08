/***
* @author Ariane Tanguy (GFI)
* @date 23/09/2020
* @description Piece justificative Trigger
*/

trigger PieceJustificativeTrigger on Piece_justificative_Sinistre__c (before insert, before update, after update) {
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Update case on create
            Map<id, Case> relatedCaseIdMap = PieceJustificativeTriggerHelper.getRelatedCase(trigger.New);
            PieceJustificativeTriggerHandler.updateCaseOnCreate(trigger.New, relatedCaseIdMap);
            
            // Update contentDocumentId and contentVersionId
            Map<id, List<id>> documentIdContentIdMap = PieceJustificativeTriggerHelper.getRelatedDocument(trigger.new);
            PieceJustificativeTriggerHandler.updatePJOnCreate(trigger.new, documentIdContentIdMap);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Create a new PJ if the previous one is refused
            PieceJustificativeTriggerHandler.createNewPJ(trigger.New, trigger.oldMap);
            
            // Update contentDocumentId and contentVersionId
            Map<id, List<id>> documentIdContentIdMap = PieceJustificativeTriggerHelper.getRelatedDocument(trigger.new, trigger.oldMap);
            PieceJustificativeTriggerHandler.updatePJOnCreate(trigger.new, documentIdContentIdMap);

            // created alert when piece just status is not needed
            PieceJustificativeTriggerHandler.manageAlertNotNeeded(trigger.new);
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            Map<id, Case> relatedCaseIdMap = PieceJustificativeTriggerHelper.getRelatedCase(trigger.New);
            Map<id, List<Piece_justificative_Sinistre__c>> otherRelatedPJMap = PieceJustificativeTriggerHelper.getOtherRelatedPJ(trigger.new);
            PieceJustificativeTriggerHandler.updateCaseOnUpdate(trigger.New, trigger.oldMap, relatedCaseIdMap, otherRelatedPJMap);
            
            // Update case status and flag depending on PJ validity
            List<Piece_justificative_Sinistre__c> relatedPJList = PieceJustificativeTriggerHelper.getRelatedPJ(trigger.New, trigger.oldMap);
            PieceJustificativeTriggerHandler.updateSinistreOnUpdate(relatedCaseIdMap, relatedPJList);
        }
    }
}