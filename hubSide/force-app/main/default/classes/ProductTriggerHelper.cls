/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Helper class for ProductTrigger
*/

public class ProductTriggerHelper {
    
    /***
	* @description Get all the gammes related to the newly created product
	* @param newProductList - list of products
	* @return List<Gamme__c>
	*/
    public static List<Gamme__c> getRelatedGamme(List<Product2> newProductList){
        
        // Get the max and min prices
        Decimal minPrice = 1000000;
        Decimal maxPrice = 0;
        for(Product2 p : newProductList){
            minPrice = minPrice > p.Prix_indicatif__c ? p.Prix_indicatif__c : minPrice;
            maxPrice = maxPrice < p.Prix_indicatif__c ? p.Prix_indicatif__c : maxPrice;
        }
        
        // Query the gamme produit
        List<Gamme__c> relatedGammeList = [SELECT id, Valeur_Minimale_Produit__c, Valeur_Maximale_Produit__c 
                                           FROM Gamme__c
                                           WHERE RecordType.DeveloperName = 'Gamme_produit'
                                           AND Valeur_Minimale_Produit__c <= : minPrice
                                           AND Valeur_Maximale_Produit__c >= : maxPrice];
        
        return relatedGammeList;
    }

}