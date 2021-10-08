/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Product Trigger
*/

trigger ProductTrigger on Product2 (before insert) {
        
	// BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT TRIGGERS
        if(Trigger.isInsert){
            
            // Update the gamme
            List<Gamme__c> relatedGammeList = ProductTriggerHelper.getRelatedGamme(Trigger.New);
            ProductTriggerHandler.updateGamme(Trigger.New, relatedGammeList);
        }
    }
}