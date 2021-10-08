/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Helper class for UserTrigger
*/

public class UserTriggerHelper {
    
    /***
	* @description Get all already used email / username
	* @param newUserList - list of user
	* @return Set<String>
	*/
    public static Set<String> getAlreadyUsedUsername(List<User> newUserList){
        
        // List of created username
        Set<String> newUsernameSet = new Set<String>();
        for(User u : newUserList){
            newUsernameSet.add(u.Username + '%');
        }
        
        // Check whether those usernames aren't already taken
        List<User> alreadyCreatedUser = [SELECT id, Username
                                         FROM User
                                         WHERE Username LIKE: newUsernameSet];
        
        Set<String> alreadyUsedUsername = new Set<String>();
        for(User u : alreadyCreatedUser){
            alreadyUsedUsername.add(u.username);
        }
        
        return alreadyUsedUsername;
    }
    
    /***
	* @description Get the related custom metadata
	* @param newUserList - list of user
	* @return Map<String, List<SFAMConfig__c>>
	*/
    public static Map<String, SFAMConfig__c> getRelatedConfigSFAM(List<User> newUserList){
        
        // List of created username
        Set<String> businessProfileSet = new Set<String>();
        for(User u : newUserList){
            businessProfileSet.add(u.BusinessProfile__c);
        }
        
        // Check whether those usernames aren't already taken
        Map<String, SFAMConfig__c> userPermissionMap = new Map<String, SFAMConfig__c>();
        if(businessProfileSet.size() > 0){
            List<SFAMConfig__c> relatedPermissionList = [SELECT id, 
                                                         UserBusinessProfile__c, 
                                                         UserProfileId__c, UserRoleId__c, UserPermissionSetId__c  
                                                         FROM SFAMConfig__c
                                                         WHERE UserBusinessProfile__c IN: businessProfileSet];
            
            // Map the custom permission to their business profile
            for(SFAMConfig__c c : relatedPermissionList){
                userPermissionMap.put(c.UserBusinessProfile__c, c);
            }
        }
        
        return userPermissionMap;
    }
}