/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Emprunt Trigger
*/

trigger EmpruntTrigger on Emprunt__c (before insert, before update, after insert, after update, before delete) {
    
    // Objects to update
    List<SObject> sObjectsToUpdate = new List<SObject>();
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT TRIGGERS
        if(Trigger.isInsert){

            system.debug('--- BEFORE EMPRUNT INSERT');
                        
            // Update the emprunt on create
            List<Facture__c> relatedFactureList = empruntTriggerHelper.getAllRelatedFacture(Trigger.new);
            id createdEmpruntRecordType = UtilityClassHelper.getCreatedRecordType('Emprunt');
            Map<List<String>, Decimal> tableDecompteMap = EmpruntTriggerHelper.getRelatedTableDecompte(Trigger.new);
            List<Asset> relatedAssetList = EmpruntTriggerHelper.getRelatedAsset(Trigger.New);
            List<Stock_Produit__c> relatedStockList = EmpruntTriggerHelper.getRelatedStock(Trigger.New);
            empruntTriggerHandler.updateEmpruntOnCreate(Trigger.new, 
                                                        relatedFactureList, 
                                                        createdEmpruntRecordType, 
                                                        tableDecompteMap, 
                                                        relatedAssetList, 
                                                        relatedStockList);
            
            // Check whether the planning is ok
            List<Reservation__c> plannedReservationList = empruntTriggerHelper.getPlannedReservation(Trigger.new);
            EmpruntTriggerHandler.checkStockPlanning(Trigger.new, plannedReservationList);
        }
        
        // BEFORE UPDATE TRIGGERS
        if(Trigger.isUpdate){
        
            system.debug('--- BEFORE EMPRUNT UPDATE');
            
            // Check whether the planning is ok
            List<Reservation__c> plannedReservationList = empruntTriggerHelper.getPlannedReservation(Trigger.oldMap, Trigger.new);
            EmpruntTriggerHandler.checkStockPlanning(Trigger.new, plannedReservationList);
            
            // Go to the next status if all the fields are completed, 
            // and send the long awaited automated email
            EmpruntTriggerHandler.automateEmpruntStatus(Trigger.new);
        }
        
        // BEFORE DELETE TRIGGERS
        if(Trigger.isDelete){
            
            system.debug('--- BEFORE EMPRUNT DELETE');
            
            // Get the related factures
            List<Facture__c> relatedFactureList = empruntTriggerHelper.getAllRelatedFacture(Trigger.old);
            
            // Update the facture
            sObjectsToUpdate.addAll(empruntTriggerHandler.cleanFactureOnDelete(Trigger.old, relatedFactureList));
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER INSERT TRIGGERS
        if(Trigger.isInsert){
            
            system.debug('--- AFTER EMPRUNT INSERT');
            
            // Update the facture on creation
            List<Facture__c> relatedFactureList = empruntTriggerHelper.getAllRelatedFacture(Trigger.new);
            List<Asset> relatedAssetList = EmpruntTriggerHelper.getRelatedAsset(Trigger.New);
            sObjectsToUpdate.addAll(empruntTriggerHandler.updateFactureOnCreation(Trigger.new, relatedFactureList, relatedAssetList));
            
        }
        
        // AFTER INSERT TRIGGERS
        if(Trigger.isUpdate){
            
            system.debug('--- AFTER EMPRUNT UPDATE');
            
            // Update the facture on update
            List<Facture__c> relatedFactureList = empruntTriggerHelper.getRelatedFactureOnEmpruntChange(Trigger.oldMap, Trigger.new);
            List<Asset> relatedAssetList = EmpruntTriggerHelper.getRelatedAsset(Trigger.New);
            sObjectsToUpdate.addAll(empruntTriggerHandler.updateFacture(Trigger.new, Trigger.oldMap, relatedFactureList, relatedAssetList));
            
        }
    }
    
    // FINALLY
    if(sObjectsToUpdate.size() > 0){
        update sObjectsToUpdate;
    }
}