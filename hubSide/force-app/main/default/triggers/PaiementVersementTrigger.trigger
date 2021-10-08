/***
* @author Nicolas Brancato (GFI)
* @date 07/01/2020
* @description Paiement Versement Trigger
*/

trigger PaiementVersementTrigger on Paiement_Versement__c (after insert) {
    
    PaiementVersementTriggerHandler handler = new PaiementVersementTriggerHandler();
    
    // AFTER TRIGGERS
    if (Trigger.isAfter){
        
        // AFTER INSERT
        if(Trigger.isInsert){
            
            // Update the related mouvement financiers
            Map<id, List<Mouvements_financiers__c>> relatedMFMap = PaiementVersementTriggerHelper.getRelatedMF(Trigger.new);
            handler.updateRelatedMF(Trigger.new, relatedMFMap);
            
            // Handle after insert
            handler.handleAfterInsert(Trigger.new);
        }
    }
}