/***
* @author Ariane Tanguy (GFI)
* @date 26/05/2020
* @description Lightning Component Controller
*/

public without sharing class Flow_OnlineReservation {
    
    /***
	* @description Retrieve all available stock - Reservation web
	* @param productId - Product2 id selected on the previous screen
	* @param dateRetrait - Date chosen
	* @param dureeLocation - Number of days
	* @return List<Id> - List of available stock
	*/
    @AuraEnabled
    public static List<Id> retrieveStock(Id productId, Date dateRetrait, Integer dureeLocation, String enseigne, Boolean livraisonDomicile, boolean getStock){
                
        system.debug('-- here productId ' + productId);
        system.debug('-- here dateRetrait ' + dateRetrait);
        system.debug('-- here dureeLocation ' + dureeLocation);
        system.debug('-- here enseigne ' + enseigne);
        system.debug('-- here livraisonDomicile ' + livraisonDomicile);
        system.debug('-- here getStock ' + getStock);
                
        // Get all the available stocks
        List<Stock_Produit__c> allStockList = new List<Stock_Produit__c>();
        
        if(enseigne == 'SFAM'){
            if(!livraisonDomicile){
                allStockList = [SELECT id, Code_distributeur_stock__c, 
                                Code_distributeur_stock__r.Compte_test__c
                                FROM Stock_Produit__c
                                WHERE Produit__c =: productId
                                AND Statut__c IN ('En stock', 'Sortie client', 'Réservé')
                                AND Code_distributeur_stock__r.Compte_test__c = FALSE
                                AND Code_distributeur_stock__r.Enseigne__c =: enseigne
                                AND Code_distributeur_stock__r.Magasin_central__c =: livraisonDomicile];
            } else {
                allStockList = [SELECT id, Code_distributeur_stock__c, 
                                Code_distributeur_stock__r.Compte_test__c
                                FROM Stock_Produit__c
                                WHERE Produit__c =: productId
                                AND Statut__c IN ('En stock', 'Sortie client', 'Réservé')
                                AND Code_distributeur_stock__r.Compte_test__c = FALSE
                                AND (Code_distributeur_stock__r.Enseigne__c =: enseigne
                                OR Code_distributeur_stock__r.Magasin_central__c =: livraisonDomicile)];
            }
        } else {
            allStockList = [SELECT id, Code_distributeur_stock__c, 
                            Code_distributeur_stock__r.Compte_test__c
                            FROM Stock_Produit__c
                            WHERE Produit__c =: productId
                            AND Statut__c IN ('En stock', 'Sortie client', 'Réservé')
                            AND Code_distributeur_stock__r.Compte_test__c = FALSE
                            AND Code_distributeur_stock__r.Magasin_central__c = TRUE];
        }
        
        // Get all the related emprunts 
        List<Emprunt__c> currentEmpruntList = [SELECT id, Date_sortie__c, Date_retour_prevu__c, 
                                               Produit_emprunte__c, Nombre_jours_depassement__c
                                               FROM Emprunt__c
                                               WHERE Status__c IN ('Sortie', 'En magasin')
                                               AND Produit_emprunte__c IN : allStockList
                                               AND Date_sortie__c != NULL
                                               AND Date_retour_prevu__c != NULL];
        
        // Map it to the stock id
        Map<Id, Emprunt__c> stockIdEmpruntMap = new Map<Id, Emprunt__c>();
        for(Emprunt__c e : currentEmpruntList){
            stockIdEmpruntMap.put(e.Produit_emprunte__c, e);
        }
        
        // And all the related reservations
        List<Reservation__c> plannedReservationList = [SELECT id, Date_retrait__c, Duree_emprunt__c, 
                                                       Produit_reserve__c
                                                       FROM Reservation__c
                                                       WHERE Status__c = 'Réservé'
                                                       AND Produit_reserve__c IN : allStockList
                                                       AND Date_retrait__c != NULL
                                                       AND Duree_emprunt__c != NULL];
        
        // Map it to the stock id
        Map<Id, List<Reservation__c>> stockIdReservationMap = new Map<Id, List<Reservation__c>>();
        for(Reservation__c r : plannedReservationList){
            if(!stockIdReservationMap.keySet().contains(r.Produit_reserve__c)){
                List<Reservation__c> tmpList = new List<Reservation__c>();
                stockIdReservationMap.put(r.Produit_reserve__c, tmpList);
            }
            stockIdReservationMap.get(r.Produit_reserve__c).add(r);
        }
        
        system.debug('--- here stockIdEmpruntMap ' + stockIdEmpruntMap);
        system.debug('--- here stockIdReservationMap ' + stockIdReservationMap);
        
        Date dateRetour = dateRetrait.addDays(dureeLocation);
        
        // Check them all
        List<id> availableStockId = new List<Id>();
        List<id> availableDistribId = new List<Id>();
        for(Stock_Produit__c s : allStockList){
                
            system.debug('--- here s ' + s);
            
            Id empruntStockId, reservationStockId;
            
            // -- EMPRUNT 
            // Check whether that particular stock is free from any emprunt
            if(!stockIdEmpruntMap.keySet().contains(s.id)){
                empruntStockId = s.Id;
            } else {
                // Otherwise, check the dates
                Emprunt__c e = stockIdEmpruntMap.get(s.id);
                system.debug('--- here e ' + e);
                
                // If there is already an emprunt, exit the current iteration
                if(UtilityClassHelper.compareDate(dateRetrait, dateRetour, e.Date_sortie__c, e.Date_retour_prevu__c) ||
                   e.Nombre_jours_depassement__c > 0){
                       continue;
                   } else {
                       empruntStockId = s.Id;
                   }
            }
            
            // -- RESERVATION
            // Check whether that particular stock is free from any reservation
            if(!stockIdReservationMap.keySet().contains(s.id) && 
               s.id == empruntStockId &&
               !availableStockId.contains(s.id)){
                   system.debug('--- here found ' + s.id);
                   availableStockId.add(s.id);
                   availableDistribId.add(s.Code_distributeur_stock__c);
                   
               } else {
                   // Otherwise, check the dates for ALL reservations
                   List<Reservation__c> resList = stockIdReservationMap.get(s.id);
                   for(Reservation__c r : resList){
                       
                       system.debug('--- here r ' + r);
                       
                       // If there is already a reservation, exit the reservation loop
                       if(UtilityClassHelper.compareDate(dateRetrait, dateRetour, r.Date_retrait__c, r.Date_retrait__c.addDays((integer)r.Duree_emprunt__c))){
                           reservationStockId = null;
                           break;
                       } else {
                           reservationStockId = s.id;
                       }
                   }
                   
                   // Check if both values are same
                   if(empruntStockId == reservationStockId && 
                      ! availableStockId.contains(s.id)){
                          system.debug('--- here found ' + s.id);
                          availableStockId.add(s.id);
                          availableDistribId.add(s.Code_distributeur_stock__c);
                      }
               }
        }
        
        // Handle the case where there is no stock available, but somehow a reservation needs to be created
        if(availableStockId.size() == 0 &&
           dateRetrait > system.today() + 30){
               availableStockId.add(allStockList[0].id);
               availableDistribId.add(allStockList[0].Code_distributeur_stock__c);
           }
        
        if(getStock && availableStockId.size() > 0)
            return availableStockId;
        if(!getStock && availableDistribId.size() > 0)
            return availableDistribId;
        
        return null;
    }
    
    /***
	* @description Return available distributeur for the user to choose from - Reservation web
	* @param stockIdList - available stock
	* @param distributeurId - Chosen distributeur
	* @return selectedId - stock id
	*/
    @AuraEnabled
    public static List<Object> getAllDistributeur(Id productId, Date dateRetrait, Integer dureeLocation, String enseigne, Boolean livraisonDomicile){
        
        List<id> distributeurIdList = retrieveStock(productId, dateRetrait, dureeLocation, enseigne, livraisonDomicile, false);
        
        system.debug('--- here distributeurIdList ' + distributeurIdList);
        
        // Get all distributeur related information
        List<Object> lstObj = new List<Object>();
        for(Account a : [SELECT Id, Name, ShippingPostalCode, ShippingCity
                         FROM Account
                         WHERE id IN :distributeurIdList 
                         AND Compte_test__c = FALSE]){
                             
                             Map<String, Object> mapOfres = new Map<String, Object>();
                             mapOfres.put('id', a.id);
                             mapOfres.put('name', a.Name);
                             mapOfres.put('city', '' + a.ShippingPostalCode + ' - ' + a.ShippingCity);
                             
                             lstObj.add(mapOfres);
                         }
        
        system.debug('--- here lstObj ' + lstObj);
        return lstObj;
    }
    
    
    /***
	* @description Return one stock - Reservation web
	* @param stockIdList - available stock
	* @param distributeurId - Chosen distributeur
	* @return selectedId - stock id
	*/
    @AuraEnabled
    public static Id returnOneStockFromList(List<id> stockIdList, Id distributeurId){
        
        system.debug('--- here stockIdList ' + stockIdList);
        system.debug('--- here distributeurId ' + distributeurId);
                
        // Get all the stocks
        List<Stock_Produit__c> allStockList = [SELECT id 
                                               FROM Stock_Produit__c
                                               WHERE Id IN: stockIdList
                                               AND Code_distributeur_stock__c =: distributeurId
                                               AND Statut__c IN ('En stock', 'Sortie client', 'Réservé')];
        
        system.debug('--- here allStockList ' + allStockList);
        
        // Return the first id
        if(allStockList.size() > 0){
            return allStockList[0].id;
        }
        
        return null;
    }
    
    /***
	* @description Return one stock - Reservation en magasin
	* @param productId - Product2 id selected on the previous screen
	* @param dateRetrait - Date chosen
	* @param dureeLocation - Number of days
	* @param distributeurId - Chosen distributeur
	* @return selectedId - stock id
	*/
    @AuraEnabled
    public static Id returnOneStock(Id productId, Date dateRetrait, Integer dureeLocation, Id distributeurId, boolean isEmprunt){
        
        system.debug('--- here productId ' + productId);
        system.debug('--- here dateRetrait ' + dateRetrait);
        system.debug('--- here dureeLocation ' + dureeLocation);
        system.debug('--- here distributeurId ' + distributeurId);
        system.debug('--- here isEmprunt ' + isEmprunt);
        
        Date dateRetour = dateRetrait.addDays(dureeLocation);
                
        // Get all the available stocks
        List<Stock_Produit__c> allStockList = [SELECT id 
                                               FROM Stock_Produit__c
                                               WHERE Produit__c =: productId
                                               AND Code_distributeur_stock__c =: distributeurId
                                               AND Statut__c IN ('En stock', 'Sortie client', 'Réservé')];
        
        system.debug('--- here allStockList ' + allStockList);
        
        // Get all the related emprunts 
        List<Emprunt__c> currentEmpruntList = [SELECT id, Date_sortie__c, Date_retour_prevu__c, 
                                               Produit_emprunte__c, Nombre_jours_depassement__c
                                               FROM Emprunt__c
                                               WHERE Status__c IN ('Sortie', 'En magasin')
                                               AND Produit_emprunte__c IN : allStockList
                                               AND Date_sortie__c != NULL
                                               AND Date_retour_prevu__c != NULL];
        
        system.debug('--- here currentEmpruntList ' + currentEmpruntList);
        
        // Map it to the stock id
        Map<Id, Emprunt__c> stockIdEmpruntMap = new Map<Id, Emprunt__c>();
        for(Emprunt__c e : currentEmpruntList){
            stockIdEmpruntMap.put(e.Produit_emprunte__c, e);
        }
        
        // And all the related reservations
        List<Reservation__c> plannedReservationList = [SELECT id, Date_retrait__c, Duree_emprunt__c, 
                                                       Produit_reserve__c
                                                       FROM Reservation__c
                                                       WHERE Status__c = 'Réservé'
                                                       AND Produit_reserve__c IN : allStockList
                                                       AND Date_retrait__c != NULL
                                                       AND Duree_emprunt__c != NULL];
        
        system.debug('--- here plannedReservationList ' + plannedReservationList);
        
        // Map it to the stock id
        Map<Id, List<Reservation__c>> stockIdReservationMap = new Map<Id, List<Reservation__c>>();
        for(Reservation__c r : plannedReservationList){
            if(!stockIdReservationMap.keySet().contains(r.Produit_reserve__c)){
                List<Reservation__c> tmpList = new List<Reservation__c>();
                stockIdReservationMap.put(r.Produit_reserve__c, tmpList);
            }
            stockIdReservationMap.get(r.Produit_reserve__c).add(r);
        }
        
        // Quick check : is there a stock missing in both lists ? 
        for(Stock_Produit__c s : allStockList){
            if(stockIdEmpruntMap.get(s.id) == NULL &&
               stockIdReservationMap.get(s.id) == NULL){
                   system.debug('--- here quick win ' + s.id);
                   return s.id;
               }
        }
        
        // Too bad, the long check now
        for(Stock_Produit__c s : allStockList){
                
            system.debug('--- here s ' + s);
            
            Id empruntStockId, reservationStockId;
            
            // Check whether that particular stock is free from any emprunt
            if(!stockIdEmpruntMap.keySet().contains(s.id)){
                empruntStockId = s.Id;
            } else 
                // Only check the current emprunt if this is for a reservation
                if(isEmprunt == FALSE) {
                    
                    Emprunt__c e = stockIdEmpruntMap.get(s.id);
                    system.debug('--- here e ' + e);
                    
                    if(!UtilityClassHelper.compareDate(dateRetrait, dateRetour, e.Date_sortie__c, e.Date_retour_prevu__c) &&
                       e.Nombre_jours_depassement__c == 0){
                           empruntStockId = s.Id;
                       }
                }
            
            // Check whether that particular stock is free from any reservation
            if(!stockIdReservationMap.keySet().contains(s.id)){
                if(empruntStockId == s.id){
                    system.debug('--- here return ' + s.id);
                    return empruntStockId;
                }
            } else {
                List<Reservation__c> resList = stockIdReservationMap.get(s.id);
                for(Reservation__c r : resList){
                    
                    system.debug('--- here r ' + r);
                    
                    if(UtilityClassHelper.compareDate(dateRetrait, dateRetour, r.Date_retrait__c, r.Date_retrait__c.addDays((Integer)r.Duree_emprunt__c))){
                        reservationStockId = null; // here
                        break;
                    } else {
                        reservationStockId = s.id;
                    }
                }
                
                // Check if both values are same
                if(empruntStockId == reservationStockId && 
                   empruntStockId != null){
                       system.debug('--- here return ' + s.id);
                       return empruntStockId;
                   }
            }
        }
        
        system.debug('--- here return null');
        return null;
    }
    
}