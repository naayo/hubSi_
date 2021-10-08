/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Handler class for StockMagasin
*/

public class StockProduitTriggerHandler {
    
    /***
	* @description Update the record type on stock creation
	* @param newStockList - list of all new stock
	* @param createdStockRecordType - stock record type id
	* @return NA
	*/
    public static void updateRecordTypeOnCreation(List<Stock_produit__c> newStockList, id createdStockRecordType){
        
        // For all new stocks
        for(Stock_produit__c s : newStockList){
            s.RecordTypeId = createdStockRecordType;
        }
    }
    
    /***
	* @description Update the record type on stock update
	* @param newStockList - list of all new stock
	* @param oldStockMap - map of old stock
	* @param createdStockRecordType - stock record type id
	* @param bookedStockRecordType - stock record type id without new emprunt button
	* @return NA
	*/
    public static void updateRecordTypeOnUpdate(List<Stock_produit__c> newStockList, 
                                                Map<id, Stock_produit__c> oldStockMap, 
                                                id createdStockRecordType, 
                                                id bookedStockRecordType){
                
        for(Stock_produit__c s : newStockList){
            
            // if the status becomes Sortie client
            if(s.Statut__c == 'Sortie client' && oldStockMap.get(s.id).Statut__c != 'Sortie client'){
                s.RecordTypeId = bookedStockRecordType;
            }
            
            // if the status is not Sortie client anymore
            if(s.Statut__c != 'Sortie client' && oldStockMap.get(s.id).Statut__c == 'Sortie client'){
                s.RecordTypeId = createdStockRecordType;
            }
        }
    }
    
    /***
	* @description Handle the before insert updates
	* @param newStockList - list of all new stock
	* @param u - related user info
	* @param relatedProductMap - related product map
	* @return NA
	*/
    public static void handleBeforeInsert(List<Stock_produit__c> newStockList, User u, Map<id, Product2> relatedProductMap){
        
        // For all new stocks
        for(Stock_produit__c s : newStockList){
            
            // Update distributeurs
            if(s.Code_distributeur_initial__c == NULL){
                s.Code_distributeur_initial__c = u.Distributeur_de_reference__c;
            }
            if(s.Code_distributeur_stock__c == NULL){
                s.Code_distributeur_stock__c = u.Distributeur_de_reference__c;
            }
            
            // Handle the numero de serie
            if(s.Numero_serie__c == NULL && 
               relatedProductMap.keySet().contains(s.Produit__c) &&
               relatedProductMap.get(s.Produit__c).Produit_avec_numero_de_serie__c == FALSE){
                   s.Numero_serie__c = s.Numero_serie_genere__c;
               }
            
            // Update the name
            if(relatedProductMap.keySet().contains(s.Produit__c)){
                s.Name = relatedProductMap.get(s.Produit__c).Name + ' - ' + s.Numero_serie__c;
            }
        }
    }
    
    /***
	* @description Handle the before insert updates - Part 2
	* @param newStockList - list of all new stock
	* @param distributeurMap - related distributeur map
	* @return NA
	*/
    public static void handleBeforeInsert(List<Stock_produit__c> newStockList, Map<id, Account> distributeurMap){
        
        // For all new stocks
        for(Stock_produit__c s : newStockList){
            
            // And the proprietaire stock
            if(distributeurMap.keySet().contains(s.Code_distributeur_stock__c)){
                s.Proprietaire_Stock__c = distributeurMap.get(s.Code_distributeur_stock__c).Proprietaire_stock__c;
            }
        }
    }
    
    /***
	* @description Update the related product on update
	* @param relatedProductMap - map of the related products
	* @param relatedStock - map od product id and related stock
	* @return NA
	*/
    public static void updateRelatedProductAvailability(List<Product2> relatedProductList, 
                                                        Map<id, List<Stock_Produit__c>> relatedStockMap, 
                                                        Map<id, Account> distributeurMap){
        
        // For all products, check whether the product is available, and in which store
        // Disponibilite_stock__c
        for(Product2 p : relatedProductList){
            
            if(relatedStockMap.keySet().contains(p.id)){
                
                // Map the stocks to their related distributeurs
                Map<String, List<Stock_Produit__c>> distribIdStockMap = new Map<String, List<Stock_Produit__c>>();
                for(Stock_Produit__c s : relatedStockMap.get(p.id)){
                    
                    String accName = s.Code_distributeur_stock__r.Name;
                    if(distributeurMap != NULL && 
                       distributeurMap.keySet().contains(s.Code_distributeur_stock__c)){
                           accName = distributeurMap.get(s.Code_distributeur_stock__c).Name;
                           
                           // Check whether the distributeur isn't a test one
                           if(distributeurMap.get(s.Code_distributeur_stock__c).Compte_test__c){
                               accName = NULL;
                           }
                       }
                    
                    if(accName == NULL){
                        continue;
                    }
                    
                    if(!distribIdStockMap.keySet().contains(accName)){
                        List<Stock_Produit__c> tmpList = new List<Stock_Produit__c>();
                        distribIdStockMap.put(accName, tmpList);
                    }
                    distribIdStockMap.get(accName).add(s);
                }
                
                system.debug('-- distribIdStockMap ' + distribIdStockMap);
                
                // Loop over the distributeurs
                Map<String, String> dispoStockMap = new Map<String, String>();
                for(String a : distribIdStockMap.keySet()){
                    
                    system.debug('-- a ' + a);
                    
                    // Check if the product is available for that distributeur
                    Date closestDateRetour = system.today() + 365;
                    Date furthestDateRetrait = system.today();
                    for(Stock_produit__c s : distribIdStockMap.get(a)){
                        
                        system.debug('-- s.Date_retour__c ' + s.Date_retour__c);
                        system.debug('-- s.Date_retrait_souhaitee__c ' + s.Date_retrait_souhaitee__c);
                        
                        // If there is a stock available right now
                        if(s.Date_retour__c == NULL && s.Date_retrait_souhaitee__c == NULL){
                            dispoStockMap.put(a, a + ' : Votre produit est disponible.');
                            system.debug('--  ' + a + ' : Votre produit est disponible.');
                            break;
                        }
                        
                        // If the stock isn't available, check what's the nearest available date
                        closestDateRetour = closestDateRetour > s.Date_retour__c ? 
                            s.Date_retour__c : closestDateRetour;
                        
                        furthestDateRetrait = furthestDateRetrait < s.Date_retrait_souhaitee__c ? 
                            s.Date_retrait_souhaitee__c : furthestDateRetrait;
                    }
                    
                    // If there was no easy stock, check the dates
                    if(!dispoStockMap.keySet().contains(a)){
                        if(closestDateRetour == system.today() + 365){
                            dispoStockMap.put(a, a + ' : Votre produit est disponible jusqu\'au ' + 
                                              UtilityClassHelper.formatDate(furthestDateRetrait));
                            system.debug('--  ' + a + ' : Votre produit est disponible jusqu\'au ' + 
                                         UtilityClassHelper.formatDate(furthestDateRetrait));
                            continue;
                        }
                        if(furthestDateRetrait == system.today()){
                            dispoStockMap.put(a, a + ' : Votre produit est disponible à partir du ' + 
                                         UtilityClassHelper.formatDate(closestDateRetour));
                            system.debug('--  ' + a + ' : Votre produit est disponible à partir du ' + 
                                         UtilityClassHelper.formatDate(closestDateRetour));
                            continue;
                        }
                        dispoStockMap.put(a, a + ' : Votre produit est disponible à partir du ' + 
                                          UtilityClassHelper.formatDate(closestDateRetour) +
                                          ' et jusqu\'au ' + 
                                          UtilityClassHelper.formatDate(furthestDateRetrait));
                        system.debug('-- ' + a + ' : Votre produit est disponible à partir du ' + 
                                          UtilityClassHelper.formatDate(closestDateRetour) +
                                          ' et jusqu\'au ' + 
                                          UtilityClassHelper.formatDate(furthestDateRetrait));
                    }
                }
                // Assign the availability to the product
                p.Disponibilite_stock__c = '';
                for(String a : dispoStockMap.keySet()){
                    p.Disponibilite_stock__c += dispoStockMap.get(a) + '\n';
                }
            }
        }
        
        update relatedProductList;
    }
}