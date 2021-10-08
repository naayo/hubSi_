/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Policy Coverage Trigger
*/

trigger PolicyCoverageTrigger on vlocity_ins__AssetCoverage__c (before insert, after insert, before update) { 
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
        
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            id fomuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
            
            // Check whether there is already an active formule on the contract
            List<vlocity_ins__AssetCoverage__c> allPreviousPolicyList = PolicyCoverageTriggerHelper.getPreviousPolicies(Trigger.New);
            Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap = PolicyCoverageTriggerHelper.mapPreviousFormules(allPreviousPolicyList);
            Map<id, List<vlocity_ins__AssetCoverage__c>> assetIdOptionMap = PolicyCoverageTriggerHelper.mapPreviousOptions(allPreviousPolicyList);
            PolicyCoverageTriggerHandler.checkPreviousFormuleOnCreation(Trigger.New, assetIdFormuleMap, assetIdOptionMap);
            
            // Update the formule's record type and name on creation
            Map<id, Product2> relatedProductFormuleMap = PolicyCoverageTriggerHelper.getRelatedProductFormule(Trigger.New, allPreviousPolicyList);
            PolicyCoverageTriggerHandler.updateFormuleOnCreation(Trigger.New, relatedProductFormuleMap, fomuleLocationId);
            
            // Combine the different forumule + option to update the policies at the asset level
            Map<id, Asset> relatedAssetMap = PolicyCoverageTriggerHelper.getRelatedAsset(Trigger.New);
            PolicyCoverageTriggerHandler.updateRelatedAsset(Trigger.New, relatedAssetMap, assetIdFormuleMap, assetIdOptionMap, relatedProductFormuleMap);
            
            // Update the related formules if the previous one was closed
            PolicyCoverageTriggerHandler.handleFormuleResiliation(Trigger.New, assetIdFormuleMap, relatedProductFormuleMap, fomuleLocationId);
            
            // Finally update the related facture
            Map<id, Facture__c> assetIdFactureMap = PolicyCoverageTriggerHelper.getRelatedFacture(Trigger.New, fomuleLocationId);
            PolicyCoverageTriggerHandler.updateRelatedFacture(Trigger.New, assetIdFactureMap, relatedProductFormuleMap);
        }
        
        // BEFORE INSERT
        if(Trigger.isUpdate){
            
            PolicyCoverageTriggerHandler.updateFormuleOnUpdate(Trigger.New, Trigger.oldMap);
            
            // Check whether a policy was cancelled - if so, update the asset policies
            List<vlocity_ins__AssetCoverage__c> allPreviousPolicyList = PolicyCoverageTriggerHelper.getPreviousPolicies(Trigger.New, Trigger.oldMap);
            Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap = PolicyCoverageTriggerHelper.mapPreviousFormules(allPreviousPolicyList);
            Map<id, List<vlocity_ins__AssetCoverage__c>> assetIdOptionMap = PolicyCoverageTriggerHelper.mapPreviousOptions(allPreviousPolicyList);
            Map<id, Product2> relatedProductFormuleMap = PolicyCoverageTriggerHelper.getRelatedProductFormule(Trigger.New, allPreviousPolicyList);
            Map<id, Asset> relatedAssetMap = PolicyCoverageTriggerHelper.getRelatedAsset(Trigger.New, Trigger.oldMap);
            PolicyCoverageTriggerHandler.updateRelatedAsset(Trigger.New, relatedAssetMap, assetIdFormuleMap, assetIdOptionMap, relatedProductFormuleMap);
            
        }
    }
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER INSERT
        if(Trigger.isInsert){
            
            // Combine the different forumule + option to update the policies at the asset level
            Map<id, Asset> relatedAssetMap = PolicyCoverageTriggerHelper.getRelatedAsset(Trigger.New);
            PolicyCoverageTriggerHandler.updateRelatedAsset(Trigger.New, relatedAssetMap);
            
        }
    }
}