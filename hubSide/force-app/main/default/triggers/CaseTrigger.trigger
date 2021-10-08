/***
* @author Ariane Tanguy (GFI)
* @date 28/07/2020
* @description Case Trigger
* DATE          DEV         DESCRIPTION
* 24/02/2021    KRE         add setReclamationNumber
*/

trigger CaseTrigger on Case (before insert, after insert, before update, after update, before delete, after delete) {
    
    system.debug('-- Trigger.new ' + Trigger.new);
    system.debug('-- Trigger.old ' + Trigger.old);
        
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Set tech_numsin__c
            Map<String, Decimal> maxNumMap = CaseTriggerHelper.getMaxNumber(Trigger.new);
            CaseTriggerHandler.setTechNumber(Trigger.new, maxNumMap);
            
            // Update the account if needed
            Map<id, Asset> relatedAssetMap = CaseTriggerHelper.getRelatedAccount(Trigger.new);
            CaseTriggerHandler.updateAccountOnAssetUpdate(Trigger.new, relatedAssetMap);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Check the case attente status
            Map<id, List<Document__c>> caseIdDocumentMap = CaseTriggerHelper.getRelatedDocument(Trigger.new);
            Id idDispatch = CaseTriggerHelper.getQueueIdDispatchSin();
            CaseTriggerHandler.updateSinistreOnUpdate(Trigger.new, Trigger.oldMap, caseIdDocumentMap,idDispatch);
            
            // Update alert status related to sinistre
            CaseTriggerHandler.updateAlertOnUpdate(Trigger.new, Trigger.oldMap);
            
            // Update calcul indemn status related to sinistre
            CaseTriggerHandler.updateCalculIndemnisationOnUpdate(Trigger.new, Trigger.oldMap);
            
            // Set tech_numsin__c
            Map<String, Decimal> maxNumMap = CaseTriggerHelper.getMaxNumber(Trigger.new);
            CaseTriggerHandler.setTechNumber(Trigger.new, Trigger.oldMap, maxNumMap);
            
            // Update the account if needed
            Map<id, Asset> relatedAssetMap = CaseTriggerHelper.getRelatedAccount(Trigger.new);
            CaseTriggerHandler.updateAccountOnAssetUpdate(Trigger.new, Trigger.oldMap, relatedAssetMap);
            
            // Update the related sinistre on reclamation update
            CaseTriggerHandler.updateSinistreOnReclaUpdate(Trigger.new, Trigger.oldMap);

            // Force value after approval approved or rejected 
            CaseTriggerHandler.forceValueApprovalProcess(Trigger.new, Trigger.oldMap);
        }
        
        // BEFORE DELETE
        if(Trigger.isDelete){
            CaseTriggerHandler.isDeleteAuthorized(Trigger.old);
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER INSERT
        if(Trigger.isInsert){
            
            // Create the appropriate number of document
            Map<String, List<Types_piece_justificative__c>> typologyPieceJustificativeMap = 
                CaseTriggerHelper.getRelatedPieceJustificative(Trigger.new);
            CaseTriggerHandler.createNecessaryDocs(Trigger.new, typologyPieceJustificativeMap);
                        
            CaseTriggerHandler.updateAssetKPI(Trigger.new,Trigger.oldMap);
        }
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            
            // Update the EquipSin name on sinistre / sav validation
            Map<id, List<Equipement_sinistre__c>> relatedEquipSinMap = CaseTriggerHelper.getRelatedEquipSin(Trigger.new);
            CaseTriggerHandler.updateEquipSinOnCaseValidation(Trigger.new, Trigger.oldMap, relatedEquipSinMap);
            
            CaseTriggerHandler.updateAssetKPI(Trigger.new,Trigger.oldMap);
            
            // Create alert related to sinistre
            CaseTriggerHandler.createAlertOnUpdate(Trigger.new, Trigger.oldMap);
        }
        
        // AFTER DELETE
        if(Trigger.isDelete){
            CaseTriggerHandler.updateAssetKPI(Trigger.old,Trigger.oldMap);
        }
        
        system.debug('-- Trigger.new ' + Trigger.new);
    }
}