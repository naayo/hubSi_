/***
* @author Ariane Tanguy (GFI)
* @date 31/03/2021
* @description Helper class for SFAMConfigTrigger
*/

public class SFAMConfigTriggerHelper {
    
    /***
	* @description Get the missing profiles
	* @param newConfigList - list of new config
	* @return Map<id, Profile>
	*/
    public static Map<String, Profile> getMissingProfile(List<SFAMConfig__c> newConfigList){
        
        // Get the profile names
        Set<String> profileNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            profileNameSet.add(c.UserProfile__c);
        }
        
        Map<String, Profile> relatedProfileMap = new Map<String, Profile>();
        if(profileNameSet.size() > 0){
            List<Profile> relatedProfileList = [SELECT id, Name FROM Profile WHERE Name IN: profileNameSet];
            for(Profile p : relatedProfileList){
                relatedProfileMap.put(p.Name, p);
            }
        }
        
        return relatedProfileMap;
    }
    
    /***
	* @description Get the missing profiles
	* @param newConfigList - list of new config
	* @param oldConfigMap - map of old config
	* @return Map<id, Profile>
	*/
    public static Map<String, Profile> getMissingProfile(List<SFAMConfig__c> newConfigList, Map<id, SFAMConfig__c> oldConfigMap){
        
        // Get the profile names
        Set<String> profileNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            if(c.UserProfile__c != oldConfigMap.get(c.id).UserProfile__c){
                profileNameSet.add(c.UserProfile__c);
            }
        }
        
        Map<String, Profile> relatedProfileMap = new Map<String, Profile>();
        if(profileNameSet.size() > 0){
            List<Profile> relatedProfileList = [SELECT id, Name FROM Profile WHERE Name IN: profileNameSet];
            for(Profile p : relatedProfileList){
                relatedProfileMap.put(p.Name, p);
            }
        }        
        
        return relatedProfileMap;
    }
    
    /***
	* @description Get the missing roles
	* @param newConfigList - list of new config
	* @return Map<id, UserRole>
	*/
    public static Map<String, UserRole> getMissingRole(List<SFAMConfig__c> newConfigList){
        
        // Get the role names
        Set<String> roleNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            roleNameSet.add(c.UserRole__c);
        }
        
        Map<String, UserRole> relatedRoleMap = new Map<String, UserRole>();
        if(roleNameSet.size() > 0){
            List<UserRole> relatedRoleList = [SELECT id, DeveloperName FROM UserRole WHERE DeveloperName IN: roleNameSet];
            for(UserRole p : relatedRoleList){
                relatedRoleMap.put(p.DeveloperName, p);
            }
        }
        
        return relatedRoleMap;
    }
    
    /***
	* @description Get the missing roles
	* @param newConfigList - list of new config
	* @param oldConfigMap - map of old config
	* @return Map<id, UserRole>
	*/
    public static Map<String, UserRole> getMissingRole(List<SFAMConfig__c> newConfigList, Map<id, SFAMConfig__c> oldConfigMap){
        
        // Get the role names
        Set<String> roleNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            if(c.UserRole__c != oldConfigMap.get(c.id).UserRole__c){
                roleNameSet.add(c.UserRole__c);
            }
        }
        
        Map<String, UserRole> relatedRoleMap = new Map<String, UserRole>();
        if(roleNameSet.size() > 0){
            List<UserRole> relatedRoleList = [SELECT id, DeveloperName FROM UserRole WHERE DeveloperName IN: roleNameSet];
        
            for(UserRole p : relatedRoleList){
                relatedRoleMap.put(p.DeveloperName, p);
            }
        }
        
        return relatedRoleMap;
    }
    
    /***
	* @description Get the missing permission sets
	* @param newConfigList - list of new config
	* @return Map<id, PermissionSet>
	*/
    public static Map<String, PermissionSet> getMissingPermissionSet(List<SFAMConfig__c> newConfigList){
        
        // Get the permission set names
        Set<String> permNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            if(c.UserPermissionSet__c != NULL){
                permNameSet.addAll(c.UserPermissionSet__c.split(';'));
            }
        }
        
        Map<String, PermissionSet> relatedPermMap = new Map<String, PermissionSet>();
        if(permNameSet.size() > 0){
            List<PermissionSet> relatedPermList = [SELECT id, Name FROM PermissionSet WHERE Name IN: permNameSet];
            for(PermissionSet p : relatedPermList){
                relatedPermMap.put(p.Name, p);
            }
        }
        
        return relatedPermMap;
    }
    
    /***
	* @description Get the missing permission sets
	* @param newConfigList - list of new config
	* @param oldConfigMap - map of old config
	* @return Map<id, PermissionSet>
	*/
    public static Map<String, PermissionSet> getMissingPermissionSet(List<SFAMConfig__c> newConfigList, Map<id, SFAMConfig__c> oldConfigMap){
        
        // Get the permission set names
        Set<String> permNameSet = new Set<String>();
        for(SFAMConfig__c c : newConfigList){
            if(c.UserPermissionSet__c != oldConfigMap.get(c.id).UserPermissionSet__c &&
               c.UserPermissionSet__c != NULL){
                   permNameSet.addAll(c.UserPermissionSet__c.split(';'));
               }
        }
        
        Map<String, PermissionSet> relatedPermMap = new Map<String, PermissionSet>();
        if(permNameSet.size() > 0){
            List<PermissionSet> relatedPermList = [SELECT id, Name FROM PermissionSet WHERE Name IN: permNameSet];
            for(PermissionSet p : relatedPermList){
                relatedPermMap.put(p.Name, p);
            }
        }
        
        return relatedPermMap;
    }
}