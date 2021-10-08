/***
* @author Ariane Tanguy (GFI)
* @date 12/05/2020
* @description Asset Trigger
*/

trigger AssetTrigger on Asset (before insert, before update, after update) {

    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        id contratSiniRecordType = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // LOCATION + ASSURANCE Update the account record type if needed
            Map<id, Account> relatedAccountMap = AssetTriggerHelper.getRelatedAccount(Trigger.new);
            Map<id, String> accountAssetMap = AssetTriggerHelper.getPreviousAsset(Trigger.new);
            AssetTriggerHandler.updateAccountRecordType(Trigger.new, relatedAccountMap, accountAssetMap);
            
            // LOCATION Handle the account activation
            id contratLocRecordType = UtilityClassHelper.getCreatedRecordType('Contrat_location');
            AssetTriggerHandler.handleAccountActivation(Trigger.new, contratLocRecordType);

            // SINISTRE Handle Update TECH_CalculatorIndicLastChange__c
            AssetTriggerHandler.handleCalculatorIndicLastChange(Trigger.new, null, contratSiniRecordType);
        }
        
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // LOCATION Handle the resiliation if it's the case
            Map<id, Facture__c> relatedFactureMap = AssetTriggerHelper.getRelatedFacture(Trigger.new);
            Map<id, vlocity_ins__AssetCoverage__c> relatedPolicyCoverageMap = AssetTriggerHelper.getRelatedFormule(Trigger.new);
            AssetTriggerHandler.handleResiliation(Trigger.new, Trigger.oldMap, relatedFactureMap, relatedPolicyCoverageMap);

            // SINISTRE Handle Update TECH_CalculatorIndicLastChange__c
            AssetTriggerHandler.handleCalculatorIndicLastChange(Trigger.new, Trigger.oldMap, contratSiniRecordType);
        }
    }
    
    // AFTER TRIGGER
    if(Trigger.isAfter){
        
        // AFTER UPDATE
        if(Trigger.isUpdate){
            
            // ASSURANCE Handle the etat paiement update
            Map<id, List<Case>> relatedCaseMap = AssetTriggerHelper.getRelatedCase(Trigger.new);
            AssetTriggerHandler.handleValidPayment(Trigger.new, Trigger.oldMap, relatedCaseMap);
        }        
    }
}