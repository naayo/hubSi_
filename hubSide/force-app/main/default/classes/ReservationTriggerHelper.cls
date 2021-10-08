/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Helper class for ReservationTrigger
*/

public class ReservationTriggerHelper {
    
    /***
	* @description Get all the emprunt which are already out there with a client
	* @param newReservationList - list of the new reservation
	* @return List<Emprunt__c> - List of the emprunt out
	*/
    public static List<Emprunt__c> getCurrentEmprunt(List<Reservation__c> newReservationList){
        
        // Get all the related stock ids
        List<id> wishedStockIdList = new List<id>();
        for(Reservation__c r : newReservationList){
            wishedStockIdList.add(r.Produit_reserve__c);
        }
        
        // Query the emprunts
        List<Emprunt__c> currentEmpruntList = [SELECT id, Date_sortie__c, Date_retour_prevu__c, 
                                               Produit_emprunte__c, Nombre_jours_depassement__c
                                               FROM Emprunt__c
                                               WHERE Status__c IN ('Sortie', 'En magasin')
                                               AND Produit_emprunte__c IN : wishedStockIdList
                                               AND Date_sortie__c != NULL
                                               AND Date_retour_prevu__c != NULL];
        return currentEmpruntList;
    }
    
    /***
	* @description Get all the planned reservations
	* @param newReservationList - list of the new reservation
	* @return List<Reservation__c> - List of the planned reservations
	*/
    public static List<Reservation__c> getPlannedReservation(List<Reservation__c> newReservationList){
        
        // Get all the related stock ids
        Set<id> wishedStockIdSet = new Set<id>();
        Set<id> reservationIdSet = new Set<id>();
        for(Reservation__c r : newReservationList){
            wishedStockIdSet.add(r.Produit_reserve__c);
            reservationIdSet.add(r.Id);
        }
        
        List<Reservation__c> plannedReservationList = [SELECT id, Date_retrait__c, Duree_emprunt__c, 
                                                       Produit_reserve__c
                                                       FROM Reservation__c
                                                       WHERE Status__c = 'Réservé'
                                                       AND Produit_reserve__c IN : wishedStockIdSet
                                                       AND id NOT IN: reservationIdSet
                                                       AND Date_retrait__c != NULL
                                                       AND Duree_emprunt__c != NULL];
        return plannedReservationList;
    }
    
    /***
	* @description Get all the related coef de decompte
	* @param newReservationList - list of the new reservation
	* @return Map<id, Boolean> - Tells whether the reservation needs to be converted back into the Reserve status
	*/
    public static Map<id, String> getRelatedDecompte(List<Reservation__c> newReservationList){
        
        // Get all the related client ids
        Set<id> relatedStockIdSet = new Set<id>();
        Set<id> relatedClientIdSet = new Set<id>();
        for(Reservation__c r : newReservationList){
            if(r.Status__c == 'Pré-réservé'){
                relatedStockIdSet.add(r.Produit_reserve__c);
                relatedClientIdSet.add(r.Client__c);
            }
        }
        
        // Query the assets
        List<Asset> relatedAssetList = [SELECT id, AccountId, Code_formule__r.Gamme_formule__c
                                        FROM Asset
                                        WHERE AccountId IN: relatedClientIdSet
                                        AND Status = 'valid'];
        
        // Map them to their accounts
        Map<id, List<Asset>> accountIdAssetMap = new Map<id, List<Asset>>();
        for(Asset a : relatedAssetList){
            if(!accountIdAssetMap.keySet().contains(a.accountId)){
                List<Asset> tmpList = new List<Asset>();
                accountIdAssetMap.put(a.AccountId, tmpList);
            }
            accountIdAssetMap.get(a.AccountId).add(a);
        }
        
        // Query the assets
        Map<id, Stock_produit__c> relatedStockMap = new Map<id, Stock_produit__c>([SELECT id, Produit__r.Gamme_produit__c
                                                                                   FROM Stock_produit__c
                                                                                   WHERE Id IN: relatedStockIdSet]);
        
        // Map both gammes to their related reservations
        Set<id> gammeFormuleIdSet = new Set<id>();
        Set<id> gammeStockIdSet = new Set<id>();
        for(Reservation__c r : newReservationList){
            if(accountIdAssetMap.keySet().contains(r.Client__c) &&
               relatedStockMap.keySet().contains(r.Produit_reserve__c)){
                   for(Asset a : accountIdAssetMap.get(r.Client__c)){
                       gammeFormuleIdSet.add(a.Code_formule__r.Gamme_formule__c);
                   }
                   gammeStockIdSet.add(relatedStockMap.get(r.Produit_reserve__c).Produit__r.Gamme_produit__c);
               }
        }
        
        // Query the coefficient de decompte
        List<Table_decompte__c> coefDecList = [SELECT Gamme_formule__c, Gamme_produit__c, Coefficient_decompte__c
                                               FROM Table_decompte__c
                                               WHERE Gamme_formule__c IN: gammeFormuleIdSet
                                               AND Gamme_produit__c IN: gammeStockIdSet];
        
        // Loop again over the reservations
        Map<id, String> cannotMap = new Map<id, String>();
        for(Reservation__c r : newReservationList){
            
            // Rule 3 : no active contract
            if(!accountIdAssetMap.keySet().contains(r.Client__c) &&
               r.Status__c == 'Pré-réservé'){
                   cannotMap.put(r.id, 'Prospect à qualifier');
                   continue;
               }
            
            // Rule 2 : gamme default
            if(accountIdAssetMap.keySet().contains(r.Client__c) &&
               relatedStockMap.keySet().contains(r.Produit_reserve__c)){
                   
                   // Get the related coef de decompte
                   for(Table_decompte__c t : coefDecList){
                       
                       // If the gammes are the same as the current reservation ones
                       if(t.Gamme_produit__c == relatedStockMap.get(r.Produit_reserve__c).Produit__r.Gamme_produit__c){
                           
                           // Check the coef de decompte
                           Boolean gammeOk = false;
                           for(Asset a : accountIdAssetMap.get(r.Client__c)){
                               if(t.Gamme_formule__c == a.Code_formule__r.Gamme_formule__c){
                                   if(t.Coefficient_decompte__c > 0){
                                       gammeOk = true;
                                       break;
                                   }
                               }
                           }
                           if(!gammeOk){
                               cannotMap.put(r.id, 'Défaut de gamme');
                           }
                       }
                   }
                if(cannotMap.keySet().contains(r.id)){
                    break;
                }
            }
        }
        
        return cannotMap;
    }
    
    /***
	* @description Get the related stock
	* @param newReservationList - list of the new reservation
	* @return List<Stock_Produit__c>
	*/
    public static List<Stock_Produit__c> getRelatedStock(List<Reservation__c> newReservationList){
        
        // Get all the related stock ids
        Set<id> stockIdSet = new Set<id>();
        for(Reservation__c r : newReservationList){
            stockIdSet.add(r.Produit_reserve__c);
        }
        
        return [SELECT id, Date_retrait_souhaitee__c, Prochaine_reservation__c
                FROM Stock_produit__c
                WHERE id IN: stockIdSet];
    }
    
    /***
	* @description Get the related stock
	* @param newReservationList - list of the new reservation
	* @return List<Stock_Produit__c>
	*/
    public static List<Stock_Produit__c> getRelatedStock(List<Reservation__c> newReservationList, Map<id, Reservation__c> oldReservationMap){
        
        // Get all the related stock ids
        Set<id> stockIdSet = new Set<id>();
        for(Reservation__c r : newReservationList){
            if(r.Date_retrait__c != oldReservationMap.get(r.id).Date_retrait__c ||
               r.Produit_reserve__c != oldReservationMap.get(r.id).Produit_reserve__c){
                   stockIdSet.add(r.Produit_reserve__c);
               }
        }
        
        if(stockIdSet.size() == 0){
            return new List<Stock_Produit__c>();
        }
        
        return [SELECT id, Date_retrait_souhaitee__c, Prochaine_reservation__c
                FROM Stock_produit__c
                WHERE id IN: stockIdSet];
    }
}