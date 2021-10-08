/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Reservation Trigger
*/

trigger ReservationTrigger on Reservation__c (before insert, before update, after insert) {
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        List<Emprunt__c> currentEmpruntList = ReservationTriggerHelper.getCurrentEmprunt(Trigger.new);
        List<Reservation__c> plannedReservationList = ReservationTriggerHelper.getPlannedReservation(Trigger.new);
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            system.debug('--- BEFORE RESERVATION INSERT');
            
            // Update the record type
            ReservationTriggerHandler.updateRecordTypeOnCreation(Trigger.new);
            
            // Check whether the status is correct
            Map<id, String> cannotMap = ReservationTriggerHelper.getRelatedDecompte(Trigger.new);
            ReservationTriggerHandler.updatePreReservation(Trigger.new, cannotMap);
            
            // Check whether the planning is ok
            ReservationTriggerHandler.checkStockPlanning(Trigger.new, currentEmpruntList, plannedReservationList);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            system.debug('--- BEFORE RESERVATION UPDATE');
            
            // Check whether the planning is ok
            ReservationTriggerHandler.checkStockPlanning(Trigger.new, currentEmpruntList, plannedReservationList);
            
            // Update the record type if the reservation is converted into an emprunt
            ReservationTriggerHandler.updateRecordTypeOnUpdate(Trigger.new, Trigger.oldMap);
            
            // Update the related stock
            List<Stock_Produit__c> relatedStockList = ReservationTriggerHelper.getRelatedStock(Trigger.new, Trigger.oldMap);
            ReservationTriggerHandler.updateRelatedStock(Trigger.new, relatedStockList);
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER INSERT
        if(Trigger.isInsert){
            
            system.debug('--- AFTER RESERVATION INSERT');
            
            // Update the related stock
            List<Stock_Produit__c> relatedStockList = ReservationTriggerHelper.getRelatedStock(Trigger.new);
            ReservationTriggerHandler.updateRelatedStock(Trigger.new, relatedStockList);
        }
    }
}