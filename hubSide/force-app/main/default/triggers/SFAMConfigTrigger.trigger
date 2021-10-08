/***
* @author Ariane Tanguy (GFI)
* @date 31/03/2021
* @description SFAMConfig Trigger
*/

trigger SFAMConfigTrigger on SFAMConfig__c (before insert, before update) {
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
                
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Assign profile / role / permission set ids
            Map<String, Profile> relatedProfileMap = SFAMConfigTriggerHelper.getMissingProfile(Trigger.new);
            Map<String, UserRole> relatedRoleMap = SFAMConfigTriggerHelper.getMissingRole(Trigger.new);
            Map<String, PermissionSet> relatedPermSetMap = SFAMConfigTriggerHelper.getMissingPermissionSet(Trigger.new);
            SFAMConfigTriggerHandler.updatePermissionIdOnInsert(Trigger.new, relatedProfileMap, relatedRoleMap, relatedPermSetMap);
        }
                
        // BEFORE UPDATE
        if(Trigger.isUpdate){
            
            // Assign profile / role / permission set ids
            Map<String, Profile> relatedProfileMap = SFAMConfigTriggerHelper.getMissingProfile(Trigger.new, Trigger.oldMap);
            Map<String, UserRole> relatedRoleMap = SFAMConfigTriggerHelper.getMissingRole(Trigger.new, Trigger.oldMap);
            Map<String, PermissionSet> relatedPermSetMap = SFAMConfigTriggerHelper.getMissingPermissionSet(Trigger.new, Trigger.oldMap);
            SFAMConfigTriggerHandler.updatePermissionIdOnUpdate(Trigger.new, Trigger.oldMap, relatedProfileMap, relatedRoleMap, relatedPermSetMap);
        }
    }
}