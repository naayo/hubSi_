/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description User Trigger
*/

trigger UserTrigger on User (before insert, after insert, before update, after update) {
    
    // BEFORE AFTER INSERT UPDATE
    Map<String, SFAMConfig__c> relatedPermissionMap = UserTriggerHelper.getRelatedConfigSFAM(Trigger.new);
            UserTriggerHandler.updateUserPermission(Trigger.new, Trigger.oldMap, relatedPermissionMap, Trigger.isBefore);
    
    // BEFORE TRIGGERS
    if(Trigger.isBefore){
                
        // BEFORE INSERT
        if(Trigger.isInsert){
            
            // Get the already used usernames and make sure there is no duplicates in the newly created users
            Set<String> alreadyUsedUsernameSet = UserTriggerHelper.getAlreadyUsedUsername(Trigger.new);
            UserTriggerHandler.checkUsernameBeforeInsert(Trigger.new, alreadyUsedUsernameSet);
        }
    }
}