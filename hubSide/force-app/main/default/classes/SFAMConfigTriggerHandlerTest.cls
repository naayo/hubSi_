/***
* @author Ariane Tanguy (GFI)
* @date 01/04/2021
* @description SFAMConfigTrigger test class
* @Object SFAMConfig__c
*/

@isTest
public class SFAMConfigTriggerHandlerTest {
    
    /***
    * @description Update permission ids on insert and update
    * @see updatePermissionIdOnInsert + updatePermissionIdOnUpdate
    */
    @isTest
    public static void updatePermissionIdTest(){
        
        // Create a new SFAMConfig record
        SFAMConfig__c c = new SFAMConfig__c();
        c.UserBusinessProfile__c = 'DirectionQualiteSinistre';
        c.UserProfile__c = 'SFAM Stock';
        c.UserRole__c = 'Admin_Enseigne';
        c.UserPermissionSet__c = 'PS_GSIN_Manager';
        insert c;
        
        c = [SELECT UserProfileId__c, UserRoleId__c, UserPermissionSetId__c
            FROM SFAMConfig__c
            WHERE id =: c.id];
        
        system.assertEquals([SELECT Id FROM Profile WHERE Name = 'SFAM Stock'].id, 
                            c.UserProfileId__c, 
                           'The profile id shouldve been udpated - This is wrong');
        system.assertEquals([SELECT Id FROM UserRole WHERE Name = 'Admin Enseigne'].id, 
                            c.UserRoleId__c, 
                           'The role id shouldve been udpated - This is wrong');
        system.assertEquals([SELECT Id FROM PermissionSet WHERE Name = 'PS_GSIN_Manager'].id, 
                            c.UserPermissionSetId__c, 
                           'The permission set id shouldve been udpated - This is wrong');
        
        // On second thought, update it
        c.UserProfile__c = 'SFAM Reparation';
        c.UserRole__c = 'Vendeur';
        c.UserPermissionSet__c = 'PS_GSIN_Manager;PS_ADM_Manager';
        update c;
        
        c = [SELECT UserProfileId__c FROM SFAMConfig__c WHERE id =: c.id];        
        system.assertEquals([SELECT Id FROM Profile WHERE Name = 'SFAM Reparation'].id, 
                            c.UserProfileId__c, 
                           'The profile id shouldve been udpated - This is wrong');
    }
}