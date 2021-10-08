/***
* @author Ariane Tanguy (GFI)
* @date 31/03/2021
* @description Handler class for SFAMConfigTrigger
*/

public class SFAMConfigTriggerHandler {
    
    /***
	* @description Update permission ids on insert
	* @param newConfigList - list of new config
	* @param relatedProfileMap - map of related profile
	* @param relatedRoleMap - map of related role
	* @param relatedPermSetMap - map of related permission set
	* @return NA
	*/
    public static void updatePermissionIdOnInsert(List<SFAMConfig__c> newConfigList, 
                                                  Map<String, Profile> relatedProfileMap, 
                                                  Map<String, UserRole> relatedRoleMap, 
                                                  Map<String, PermissionSet> relatedPermSetMap){
        
        // Loop through the config
        for(SFAMConfig__c c : newConfigList){
            
            // Update the profile
            if(c.UserProfile__c != NULL
               && relatedProfileMap.keySet().contains(c.UserProfile__c)){
                   c.UserProfileId__c = relatedProfileMap.get(c.UserProfile__c).id;
               }
            
            // Update the role
            if(c.UserRole__c != NULL
               && relatedRoleMap.keySet().contains(c.UserRole__c)){
                   c.UserRoleId__c = relatedRoleMap.get(c.UserRole__c).id;
               }
            
            // Update the permission set
            if(c.UserPermissionSet__c != NULL){
                
                // If there is more than one permission set
                List<String> permissionList = c.UserPermissionSet__c.contains(';') ? 
                       c.UserPermissionSet__c.split(';') : new List<String>{c.UserPermissionSet__c};
                
                c.UserPermissionSetId__c = '';
                for(String s : permissionList){
                    if(relatedPermSetMap.keySet().contains(s)){
                        c.UserPermissionSetId__c += relatedPermSetMap.get(s).id + ';';
                    }
                }
                c.UserPermissionSetId__c = c.UserPermissionSetId__c.Substring(0, c.UserPermissionSetId__c.length() - 1);
            }
        }
    }
    
    /***
	* @description Update permission ids on insert
	* @param newConfigList - list of new config
	* @param oldConfigMap - map of old config
	* @param relatedProfileMap - map of related profile
	* @param relatedRoleMap - map of related role
	* @param relatedPermSetMap - map of related permission set
	* @return NA
	*/
    public static void updatePermissionIdOnUpdate(List<SFAMConfig__c> newConfigList, 
                                                  Map<id, SFAMConfig__c> oldConfigMap, 
                                                  Map<String, Profile> relatedProfileMap, 
                                                  Map<String, UserRole> relatedRoleMap, 
                                                  Map<String, PermissionSet> relatedPermSetMap){
        
        // Loop through the config
        for(SFAMConfig__c c : newConfigList){
            
            // Update the profile
            if(c.UserProfile__c != NULL
               && c.UserProfile__c != oldConfigMap.get(c.id).UserProfile__c
               && relatedProfileMap.keySet().contains(c.UserProfile__c)){
                   c.UserProfileId__c = relatedProfileMap.get(c.UserProfile__c).id;
               }
            
            // Update the role
            if(c.UserRole__c != NULL
               && c.UserRole__c != oldConfigMap.get(c.id).UserRole__c
               && relatedRoleMap.keySet().contains(c.UserRole__c)){
                   c.UserRoleId__c = relatedRoleMap.get(c.UserRole__c).id;
               }
            
            // Update the permission set
            if(c.UserPermissionSet__c != NULL
               && c.UserPermissionSet__c != oldConfigMap.get(c.id).UserPermissionSet__c){
                   
                   // If there is more than one permission set
                   List<String> permissionList = c.UserPermissionSet__c.contains(';') ? 
                       c.UserPermissionSet__c.split(';') : new List<String>{c.UserPermissionSet__c};
                
                   c.UserPermissionSetId__c = '';
                   for(String s : permissionList){
                       if(relatedPermSetMap.keySet().contains(s)){
                           c.UserPermissionSetId__c += relatedPermSetMap.get(s).id + ';';
                       }
                   }
                   c.UserPermissionSetId__c = c.UserPermissionSetId__c.Substring(0, c.UserPermissionSetId__c.length() - 1);
               }
        }
    }
}