/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Handler class for ProductTrigger
*/

public class ProductTriggerHandler {
    
    /***
	* @description Automatically set the gamme on the products (not the offre)
	* @param newProductList - list of product
	* @param relatedGammeMap - related gamme map
	* @return NA
	*/
    public static void updateGamme(List<Product2> newProductList, List<Gamme__c> relatedGammeMap){
    
        id productLocRTId = UtilityClassHelper.getCreatedRecordType('Produit_location');
        
        // Update the Gamme on each product
        for(Product2 p : newProductList){
            
            // If the product is location
            if(p.RecordTypeId == productLocRTId){
                
                p.Caution__c = p.Prix_indicatif__c / 2;
                
                for(Gamme__c g : relatedGammeMap){
                    if(g.Valeur_Minimale_Produit__c <= p.Prix_indicatif__c &&
                       p.Prix_indicatif__c <= g.Valeur_Maximale_Produit__c){
                           p.Gamme_produit__c = g.id;
                           break;
                       }
                }
            }
        }
    }
}