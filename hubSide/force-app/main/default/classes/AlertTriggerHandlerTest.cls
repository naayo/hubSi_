/***
* @author Ariane Tanguy (GFI)
* @date 06/04/2021
* @description User test class
* @Object User
*/

@isTest
public class AlertTriggerHandlerTest {
    
    /***
    * @description Checks the user's profile before delete
    * @see isDeleteAuthorized
    */
    @isTest
    static void isDeleteAuthorizedTest(){
        
         // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
        
        // Create a user
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SFAM GS'].id;
        u.email = 'michael.jockson@123.com';
        insert u;
        
         // Create an alert
        Alert__c a = TestFactory.createAlert(c.id);
        insert a;
        
        // Try deleting the alert as a GS
        system.runAs(u){
            try{
                delete a;
                system.assert(false, 
                              'The alert shouldnt have been deleted - This is wrong');
            }
            catch(Exception e){
                system.assert(e.getMessage().contains('pas les droits suffisants pour supprimer'), 
                              'The error message isnt the expected one - This is wrong' + e);
            }
        }
        
        // Try again, as a super admin
        delete a;        
        system.assertEquals(0, [SELECT id FROM Alert__c].size(), 
                            'The alert shouldve been deleted - This is wrong');
    }
    
    /***
    * @description Check if Poussé par Salesforce is checked
    * @see isDeleteAuthorized
    */
    @isTest
    static void isPushedBySalesforceCheckedTest(){
        
         // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
                
         // Create an alert
        Alert__c a = TestFactory.createAlert(c.id);
        a.SalesDiscountMotif__c = 'Demande contournement Règlement Contrat';
       	a.BusinessRulesNumber__c = 'RGSIN19';
        insert a;
        system.assertEquals(false, 
                                c.Pouss_par_Salesforce__c);
        
        
    }
}