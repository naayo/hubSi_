/***
* @author Nicolas Brancato (GFI)
* @date 19/02/2020
* @description Equipement Sinistre Trigger
*/

trigger EquipementSinistreTrigger on Equipement_sinistre__c (before insert, before update, after update) {
    
    EquipementSinistreTriggerHandler handler = new EquipementSinistreTriggerHandler();
    EquipementSinistreTriggerHelper helper = new EquipementSinistreTriggerHelper();
    
    // BEFORE TRIGGERS
    if (Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            Map<Id, Equipement_sinistre__c> relatedEquipSinMap = helper.getRelatedEquipSin(Trigger.new);
            Map<id, Case> relatedCaseMap =  helper.getRelatedCase(Trigger.New);
            handler.handleBeforeInsert(Trigger.new, relatedCaseMap, relatedEquipSinMap);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Update Valeur reparation on realCost change + change status on client choice
            Map<id, vlocity_ins__AssetInsuredItem__c> relatedInsuredItemMap = helper.getRelatedInsuredItem(Trigger.new);
            Map<id, Case> relatedCaseMap =  helper.getRelatedCase(Trigger.New);
            handler.handleBeforeUpdate(Trigger.new, Trigger.oldMap, relatedCaseMap, relatedInsuredItemMap);
            
            // Update related InsuredItem + CalcIndemn on equipSin update
            Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap = helper.getRelatedCalcIndemnRepa(Trigger.new);
            Map<id, Product2> relatedCatalogueProduitMap = helper.getRelatedCatalogueProduit(Trigger.new);
            handler.handleEquipSinReparation(Trigger.new, Trigger.oldMap, relatedInsuredItemMap, relatedCalcIndemnMap, relatedCatalogueProduitMap, relatedCaseMap);
        }
    }
    
    // AFTER TRIGGERS
    if (Trigger.isAfter){
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap = helper.getRelatedCalcIndemn(Trigger.new);
            handler.handleAfterUpdate(Trigger.new, Trigger.oldMap, relatedCalcIndemnMap);
        }
    }
}