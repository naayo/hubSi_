/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Handler class for UserTrigger
*/

public class UserTriggerHandler {
    
    /***
	* @description Check username before insert
	* @param newUserList - list of all new user
	* @param alreadyUsedUsernameSet - already used username set
	* @return NA
	*/
    public static void checkUsernameBeforeInsert(List<User> newUserList, Set<String> alreadyUsedUsernameSet){
        
        //replace Community Plus License by Community License >
        //id passLocProfileId = [SELECT Id FROM Profile WHERE Name = 'Passloc Customer community Plus Login User'].id;
        //id illipassProfileId = [SELECT Id FROM Profile WHERE Name = 'Illipass Customer community Plus Login User'].id;
        id passLocProfileId = [SELECT Id FROM Profile WHERE Name = 'Passloc Customer community Login User'].id;
        id illipassProfileId = [SELECT Id FROM Profile WHERE Name = 'Illipass Customer community Login User'].id;
        // <
        
        // For all new users
        for(User u : newUserList){
            
            // If the profile is the community one
            if(u.ProfileId == passLocProfileId ||
              u.PRofileId == illipassProfileId){
                
                // If the username is already used
                while(alreadyUsedUsernameSet.contains(u.username)){
                    u.username += 'dup';
                    u.CommunityNickname += 'dup';
                    u.Duplicate_flag__c = TRUE;
                }
            }
        }
    }
    
    /***
	* @description Assign profile + role + perm set before insert
	* @param newUserList - list of all new user
	* @param relatedPermissionMap - related SFAMConfig map
	* @return NA
	*/
    public static void updateUserPermission(List<User> newUserList, 
                                            Map<id, User> oldUserMap, 
                                            Map<String, SFAMConfig__c> relatedPermissionMap, 
                                            boolean isBefore){
                
        // For all new users
        Map<id, id> psaToInsert = new Map<id, id>();
        for(User u : newUserList){
            
            // If the user has a business profile
            if(u.BusinessProfile__c != NULL &&
               (oldUserMap == NULL || 
                u.BusinessProfile__c != oldUserMap.get(u.id).BusinessProfile__c) && 
               relatedPermissionMap.keySet().contains(u.BusinessProfile__c)){
                   
                   SFAMConfig__c p = relatedPermissionMap.get(u.BusinessProfile__c);
                   
                   if(isBefore){
                       // Assign profile and role
                       u.ProfileId = p.UserProfileId__c != NULL ? p.UserProfileId__c : u.ProfileId;
                       u.UserRoleId = p.UserRoleId__c != NULL ? p.UserRoleId__c : u.UserRoleId;
                   } else {
                       // Get permission sets
                       if(p.UserPermissionSetId__c != NULL){
                           List<String> permissionList = p.UserPermissionSetId__c.contains(';') ? 
                               p.UserPermissionSetId__c.split(';') : new List<String>{p.UserPermissionSetId__c};
                                   
                                   for(String s : permissionList){
                                       if(s != NULL){
                                           psaToInsert.put(s, u.id);
                                       }
                                   }
                       }
                   }
               }
        }
        
        if(psaToInsert.size() > 0){
            managePermissionSetAssignment(psaToInsert);
        }
    }
    
    /***
	* @description Update the user's permission
	* @param permissionMap - list of permission to insert
	* @return NA
	*/
    @future
    private static void managePermissionSetAssignment(Map<id, id> permissionMap){
        
        List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
        Set<id> movingUserIdSet = new Set<id>();
        for(id p : permissionMap.keySet()){
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = p, 
                                                                      AssigneeId = permissionMap.get(p));
            movingUserIdSet.add(permissionMap.get(p));
            psaToInsert.add(psa);
        }
        
        // First check whether the user wasn't involved in other permission set
        List<PermissionSetAssignment> psaToDelete = [SELECT id
                                                     FROM PermissionSetAssignment 
                                                     WHERE AssigneeId IN: movingUserIdSet
                                                     AND PermissionSet.ProfileId = NULL];
        if(psaToDelete.size() > 0){
            delete psaToDelete;
        }
        
        // Then insert the new permission set assignments
        if(psaToInsert.size() > 0){
            insert psaToInsert;
        }
    }
}