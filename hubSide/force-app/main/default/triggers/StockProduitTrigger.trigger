/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Stock magasin Trigger
*/

trigger StockProduitTrigger on Stock_produit__c (before insert, before update) {
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        id createdStockRecordType = UtilityClassHelper.getCreatedRecordType('Stock_produit');
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Update the record type
            StockProduitTriggerHandler.updateRecordTypeOnCreation(Trigger.new, createdStockRecordType);
            
            // Handle the before insert field update
            User u = StockProduitTriggerHelper.getRelatedUserInfo();
            Map<id, Product2> relatedProductMap = StockProduitTriggerHelper.getRelatedProduct(Trigger.New);
            StockProduitTriggerHandler.handleBeforeInsert(Trigger.New, u, relatedProductMap);
            
            // Update the product availability
            Map<id, List<Stock_Produit__c>> relatedStockMap = StockProduitTriggerHelper.getRelatedStocks(relatedProductMap, Trigger.New);
            Map<id, Account> distributeurMap = StockProduitTriggerHelper.getDistributeur(relatedStockMap);
            StockProduitTriggerHandler.updateRelatedProductAvailability(relatedProductMap.values(), relatedStockMap, distributeurMap);
            
            // Update proprietaire stock
            StockProduitTriggerHandler.handleBeforeInsert(Trigger.New, distributeurMap);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Update the record type
            id bookedStockRecordType = UtilityClassHelper.getCreatedRecordType('Stock_non_empruntable');
            StockProduitTriggerHandler.updateRecordTypeOnUpdate(Trigger.new, Trigger.oldMap, createdStockRecordType, bookedStockRecordType);
            
            // Check whether the availability has changed
            Map<id, Product2> relatedProductMap = StockProduitTriggerHelper.getRelatedProduct(Trigger.New, Trigger.oldMap);
            Map<id, List<Stock_Produit__c>> relatedStockMap = StockProduitTriggerHelper.getRelatedStocks(relatedProductMap, Trigger.New);
            Map<id, Account> distributeurMap = StockProduitTriggerHelper.getDistributeur(relatedStockMap);
            StockProduitTriggerHandler.updateRelatedProductAvailability(relatedProductMap.values(), relatedStockMap, distributeurMap);
        }
    }
}