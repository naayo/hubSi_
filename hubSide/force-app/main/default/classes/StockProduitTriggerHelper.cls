/***
* @author Ariane Tanguy (GFI)
* @date 14/08/2020
* @description Helper class for StockProduitTrigger
*/

public class StockProduitTriggerHelper {
    
    /***
	* @description Get current user info
	* @param newStockList - list of stock
	* @return Map<id, User>
	*/
    public static User getRelatedUserInfo(){
        
        // Get the related user info        
        return [SELECT id, Distributeur_de_reference__c
                FROM User
                WHERE id =: system.UserInfo.getUserId()];
    }
    
    /***
	* @description On create - Get all the product related to the new stock
	* @param newStockList - list of stock
	* @return Map<id, Product2>
	*/
    public static Map<id, Product2> getRelatedProduct(List<Stock_Produit__c> newStockList){
        
        // Get the related product ids
        Set<id> productIdSet = new Set<Id>();
        for(Stock_Produit__c s : newStockList){
            productIdSet.add(s.Produit__c);
        }
        
        Map<id, Product2> relatedProductMap = new Map<id, Product2>([SELECT id, 
                                                                     Name, 
                                                                     Disponibilite_stock__c, 
                                                                     Produit_avec_numero_de_serie__c
                                                                     FROM Product2
                                                                     WHERE id IN: productIdSet]);
        return relatedProductMap;
    }
    
    /***
	* @description On update - Get all the product related to the new stock
	* @param newStockList - list of stock
	* @return Map<id, Product2>
	*/
    public static Map<id, Product2> getRelatedProduct(List<Stock_Produit__c> newStockList, Map<id, Stock_Produit__c> oldStockMap){
        
        // Get the related product ids
        Set<id> productIdSet = new Set<Id>();
        for(Stock_Produit__c s : newStockList){
            
            if(s.Statut__c != oldStockMap.get(s.id).Statut__c ||
               s.Date_retrait_souhaitee__c != oldStockMap.get(s.id).Date_retrait_souhaitee__c ||
               s.Date_retour__c != oldStockMap.get(s.id).Date_retour__c){
                   productIdSet.add(s.Produit__c);
               }
        }
        
        if(productIdSet.size() == 0){
            return new Map<id, Product2>();
        }
        
        Map<id, Product2> relatedProductMap = new Map<id, Product2>([SELECT id, Disponibilite_stock__c
                                                                    FROM Product2
                                                                    WHERE id IN: productIdSet]);
        
        return relatedProductMap;        
    }
    
    /***
	* @description Get all the related stocks
	* @param newStockList - list of stock
	* @return Map<id, Stock_Produit__c>
	*/
    public static Map<id, List<Stock_Produit__c>> getRelatedStocks(Map<id, Product2> relatedProductMap, List<Stock_Produit__c> newStockList){
                
       	// Query the stock
        List<Stock_Produit__c> relatedStockList = [SELECT id, Produit__c, 
                                                   Code_distributeur_stock__c, Code_distributeur_stock__r.Name, 
                                                   Date_retour__c, Date_retrait_souhaitee__c
                                                   FROM Stock_Produit__c
                                                   WHERE Produit__c IN: relatedProductMap.keySet()
                                                   AND id NOT IN: newStockList];
        
        system.debug('-- relatedStockList ' + relatedStockList);
        
        // Add the new stocks to the already present ones
        for(Stock_produit__c s : newStockList){
            if(relatedProductMap.keySet().contains(s.Produit__c)){
                relatedStockList.add(s);
            }
        }
        
        // And map them to their related product
        Map<id, List<Stock_Produit__c>> productIdStockMap = new Map<id, List<Stock_Produit__c>>();
        for(Stock_Produit__c s : relatedStockList){
            if(!productIdStockMap.keySet().contains(s.Produit__c)){
                List<Stock_Produit__c> tmpList = new List<Stock_Produit__c>();
                productIdStockMap.put(s.Produit__c, tmpList);
            }
            productIdStockMap.get(s.Produit__c).add(s);
        }
        
        return productIdStockMap;        
    }
    
    /***
	* @description Get all the related distributeurs
	* @param productIdStockMap - map of stock
	* @return Map<id, Account>
	*/
    public static Map<id, Account> getDistributeur(Map<id, List<Stock_Produit__c>> productIdStockMap){
        
        // Get the distributeur ids
        Set<id> distribIdSet = new Set<id>();
        for(List<Stock_produit__c> sList : productIdStockMap.values()){
            for(Stock_produit__c s : sList){
                distribIdSet.add(s.Code_distributeur_stock__c);
            }
        }
        
        Map<id, Account> distributeurMap = new Map<id, Account>([SELECT id, Name, Compte_test__c, 
                                                                 Proprietaire_stock__c
                                                                 FROM Account
                                                                 WHERE id IN: distribIdSet]);
        return distributeurMap;        
    }
}