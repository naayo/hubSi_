/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Account test class
* @Object Account
*/

@isTest
public class AccountTriggerHandlerTest {
    
    /***
    * @description Check record type on account update
    * @see checkRecordTypeOnUpdate
    */
    @isTest
    public static void checkRecordTypeOnUpdateTest(){
        
        // Mock API account creation
        Account a = TestFactory.createClient();
        a.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Client_SFAM');
        insert a;
        
        // Create a location asset
        Asset c = TestFactory.createContract(a.id);
        insert c;
        
        // Check the account record type got updated correctly
        a = [SELECT id, Record_Type_Name__c FROM Account WHERE id =: a.id];
        system.assertEquals('Client_location', a.Record_Type_Name__c, 
                           'The account RT shouldve been updated to Location - This is wrong');
        
        // Mock now an API account update
        a.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Client_SFAM');
        a.BillingCity = 'AnotherFakeCity';
        update a;
        
        // Check the account record type again
        a = [SELECT id, Record_Type_Name__c FROM Account WHERE id =: a.id];
        system.assertEquals('Client_location', a.Record_Type_Name__c, 
                           'The account RT shouldve been updated to Location - This is wrong');
    }
    
    /***
    * @description Update related user on account update
    * @see updateRelatedUser
    */
    @isTest
    public static void updateRelatedUserTest(){
        
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
        insert u;
        
        u = [SELECT id, username FROM User WHERE id =: u.id];
        system.assertEquals('michael.jockson@123.com', u.username, 
                           'The username isnt the expected one - This is wrong');
        
        // Update the connexion email
        test.startTest();
        a.Email_connexion__c = 'michael.jockson@123.fr';
        update a;
        test.stopTest();
        
        u = [SELECT id, username FROM User WHERE id =: u.id];
        system.assertEquals('michael.jockson@123.fr', u.username, 
                           'The username hasnt changed - This is wrong');
    }
}