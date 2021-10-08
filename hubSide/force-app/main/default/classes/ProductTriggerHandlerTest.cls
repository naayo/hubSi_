/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description ProductTrigger test class
* @Object Product2
*/

@isTest
public class ProductTriggerHandlerTest {
    
    /***
	* @description Update the record type
	* @see updateRecordTypeOnCreation
	*/
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a Product
        Product2 p = TestFactory.createProduct();
        insert p;
        
        // Query emprunt and check whether the record type has been correctly updated
        p = [SELECT id, RecordType.DeveloperName FROM Product2 WHERE id =: p.id];
        
        system.assertEquals('Produit_location', p.RecordType.DeveloperName, 
                            'The record type should have been updated on the product - This is wrong');
    }
    
    /***
	* @description Update the gamme
	* @see updateGamme
	*/
    @isTest
    public static void updateGammeTest(){
        
        // Create a Gamme
        Gamme__c g = TestFactory.createGammeProduit();
        g.Valeur_Minimale_Produit__c = 10;
        g.Valeur_Maximale_Produit__c = 100;
        insert g;
        
        // Create a Product
        Product2 p = TestFactory.createProduct();
        p.Prix_indicatif__c = 59;
        insert p;
        
        // Check that the gamme has been updated on the product
        p = [SELECT Gamme_produit__c FROM Product2 WHERE id =: p.id];
        system.assertEquals(g.id, p.Gamme_produit__c, 
                           'The gamme field should have been updated on the product - This is wrong');
        
    }
}