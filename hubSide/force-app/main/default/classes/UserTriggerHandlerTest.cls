/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description User test class
* @Object User
*/

@isTest
public class UserTriggerHandlerTest {
    
    /***
    * @description Check the username before insert
    * @see checkUsernameBeforeInsert
    */
    @isTest
    public static void checkUsernameBeforeInsertTest(){
        
        //replace Community Plus License by Community License >
        //id passLocProfileId = [SELECT Id FROM Profile WHERE Name = 'Passloc Customer community Plus Login User'].id;
        id passLocProfileId = [SELECT Id FROM Profile WHERE Name = 'Passloc Customer community Login User'].id;
        // <
        
        // Create an account and a contact
        Account a = TestFactory.createClient();
        insert a;        
        Contact c = [SELECT id FROM Contact WHERE AccountId =: a.id];
        
        // Create a user
        User u = TestFactory.createUser();
        u.ProfileId = passLocProfileId;
        u.ContactId = c.id;
        u.username = 'michael.jockson@123.com';
        insert u;
        
        u = [SELECT id, username FROM User WHERE id =: u.id];
        system.assert(u.username == 'michael.jockson@123.com');
        
        // Create another account + contact + user
        Account a1 = TestFactory.createClient();
        insert a1;        
        Contact c1 = [SELECT id FROM Contact WHERE AccountId =: a1.id];
        
        User u1 = TestFactory.createUser();
        u1.ProfileId = passLocProfileId;
        u1.ContactId = c1.id;
        u1.username = 'michael.jockson@123.com';
        insert u1;
        
        u1 = [SELECT username FROM User WHERE id =: u1.id];
        system.assertEquals('michael.jockson@123.comdup', u1.username, 
                           'The username shouldve been changed - This is wrong');
        
        // Create another account + contact + user
        Account a2 = TestFactory.createClient();
        insert a2;        
        Contact c2 = [SELECT id FROM Contact WHERE AccountId =: a2.id];
        
        User u2 = TestFactory.createUser();
        u2.ProfileId = passLocProfileId;
        u2.ContactId = c2.id;
        u2.username = 'michael.jockson@123.com';
        insert u2;
        
        u2 = [SELECT username FROM User WHERE id =: u2.id];
        system.assertEquals('michael.jockson@123.comdupdup', u2.username, 
                           'The username shouldve been changed - This is wrong');
    }
    
    /***
    * @description Check the username before insert
    * @see checkUsernameBeforeInsert
    */
    @isTest
    public static void updateUserPermissionOnInsert(){
        
        // Create two SFAMConfig 
        SFAMConfig__c c = new SFAMConfig__c();
        c.UserBusinessProfile__c = 'DirectionQualiteSinistre';
        c.UserProfile__c = 'SFAM Stock';
        c.UserRole__c = 'Admin_Enseigne';
        c.UserPermissionSet__c = 'PS_GSIN_Manager';
        
        SFAMConfig__c s = new SFAMConfig__c();
        s.UserBusinessProfile__c = 'ManagerTCQualite';
        s.UserProfile__c = 'SFAM Stock';
        s.UserRole__c = 'Vendeur';
        s.UserPermissionSet__c = 'PS_GSIN_Manager';
        
        List<SFAMConfig__c> listConfig = new List<SFAMConfig__c>{c, s};
        insert listConfig;
        
        // Create a user
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SFAM Stock'].id;
        u.username = 'michael.jockson@123.com';
        u.BusinessProfile__c = 'DirectionQualiteSinistre';
        Test.startTest();
        insert u;
        Test.stopTest();
        
        u = [SELECT id, profileId, userRoleId FROM User WHERE id =: u.id];
        system.assertEquals([SELECT Id FROM Profile WHERE Name = 'SFAM Stock'].id, 
                            u.profileId, 
                           'The profile id shouldve been udpated - This is wrong');
        system.assertEquals([SELECT Id FROM UserRole WHERE DeveloperName = 'Admin_Enseigne'].id, 
                            u.userRoleId, 
                           'The role id shouldve been udpated - This is wrong');
        
        system.assertEquals([SELECT PermissionSetId 
                             FROM PermissionSetAssignment 
                             WHERE AssigneeId =: u.id
                             AND PermissionSet.Name = 'PS_GSIN_Manager'].PermissionSetId, 
                            [SELECT id FROM PermissionSet WHERE Name = 'PS_GSIN_Manager'].id, 
                            'The permission set id shouldve been udpated - This is wrong');
    }
}