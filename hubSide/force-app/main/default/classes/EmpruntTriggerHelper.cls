/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Helper class for EmpruntTrigger
*/

public class EmpruntTriggerHelper {
    
    /***
	* @description Get all the factures related to the newly created emprunt
	* @param newEmpruntList - list of emprunt
	* @return List<Facture__c>
	*/
    public static List<Facture__c> getAllRelatedFacture(List<Emprunt__c> newEmpruntList){
        
        // Get the related contract ids
        Set<id> contractIdSet = new Set<Id>();
        for(Emprunt__c e : newEmpruntList){
            contractIdSet.add(e.Contrat__c);
        }
        
        // Query the related factures
        return queryFacture(contractIdSet);
    }
    
    /***
	* @description Get all the factures related to the updated emprunt
	* @param oldEmpruntMap - map of the old emprunt with their ids
	* @param newEmpruntList - list of the new emprunt
	* @return List<Facture__c>
	*/
    public static List<Facture__c> getRelatedFactureOnEmpruntChange(Map<id, Emprunt__c> oldEmpruntMap, List<Emprunt__c> newEmpruntList){
        
        // Get the related contract ids
        Set<id> contractIdSet = new Set<Id>();
        for(Emprunt__c e : newEmpruntList){
            if(e.Date_retour_prevu__c != oldEmpruntMap.get(e.id).Date_retour_prevu__c ||
               e.Date_retour__c != oldEmpruntMap.get(e.id).Date_retour__c ||
               e.Date_sortie__c != oldEmpruntMap.get(e.id).Date_sortie__c ||
               e.Status__c != oldEmpruntMap.get(e.id).Status__c||
               //SFAMI-2160 : update facture on external consumption change>
               e.ExternalCons_EquivDaysNumber__c != oldEmpruntMap.get(e.id).ExternalCons_EquivDaysNumber__c){
               //<SFAMI-2160
                    contractIdSet.add(e.Contrat__c);
               }
        }
        
        // Query the related factures
        return queryFacture(contractIdSet);
    }
    
    /***
	* @description Backend function to get the facture
	* @param contractIdSet - list of the related contrat id
	* @return List<Facture__c> List queried factures
	*/
    private static List<Facture__c> queryFacture(Set<id> contractIdSet){
        
        if(contractIdSet.size() == 0){
            return new List<Facture__c>();
        }
        
        return new List<Facture__c>([SELECT id, Contrat__c, 
                                     Montant_facture__c, 
                                     Nombre_jours_consommes__c, 
                                     Nombre_jours_depassement__c, 
                                     Nombre_jours_restants__c
                                     FROM Facture__c
                                     WHERE Contrat__c IN :contractIdSet
                                     AND Facture_active__c = TRUE]);
    }
    
    /***
	* @description Get all the table de decompte related to the newly created emprunt
	* @param newEmpruntList - list of the new emprunt
	* @return Map<List<String>, Decimal> (map a list of gamme with the related coef de decompte)
	*/
    public static Map<List<String>, Decimal> getRelatedTableDecompte(List<Emprunt__c> newEmpruntList){
        
        // Get the related gamme names
        Set<String> gammeProduit = new Set<String>();
        Set<String> gammeFormule = new Set<String>();
        for(Emprunt__c e : newEmpruntList){
            gammeFormule.add(e.Gamme_formule__c);
            gammeProduit.add(e.Gamme_produit__c);
        }
        
        // Query the related table de decompte
        List<Table_decompte__c> tableDecompteList = [SELECT Gamme_formule__r.Name, Gamme_Produit__r.Name, 
                                                     Coefficient_decompte__c
                                                     FROM Table_decompte__c
                                                     WHERE Gamme_formule__r.Name IN : gammeFormule
                                                     AND Gamme_Produit__r.Name IN : gammeProduit];
        
        // Map the whole thing
        Map<List<String>, Decimal> tableDecompteMap = new Map<List<String>, Decimal>();
        for(Table_decompte__c t : tableDecompteList){
            List<String> gammeNameList = new List<String>{t.Gamme_formule__r.Name, t.Gamme_Produit__r.Name};
                tableDecompteMap.put(gammeNameList, t.Coefficient_decompte__c);
        }
        
        return tableDecompteMap;
    }
    
    /***
	* @description Get all the planned reservations
	* @param newEmpruntList - list of the new emprunt
	* @return List<Reservation__c> - List of the planned reservations
	*/
    public static List<Reservation__c> getPlannedReservation(List<Emprunt__c> newEmpruntList){
        
        // Get all the related stock ids
        List<id> wishedStockIdList = new List<id>();
        for(Emprunt__c e : newEmpruntList){
            wishedStockIdList.add(e.Produit_emprunte__c);
        }
        
        return queryReservation(wishedStockIdList);
    }
    
    /***
	* @description Get all the planned reservations
	* @param newEmpruntList - list of the new emprunt
	* @return List<Reservation__c> - List of the planned reservations
	*/
    public static List<Reservation__c> getPlannedReservation(Map<id, Emprunt__c> oldEmpruntMap, List<Emprunt__c> newEmpruntList){
        
        // Get all the related stock ids
        List<id> wishedStockIdList = new List<id>();
        for(Emprunt__c e : newEmpruntList){
            if(e.Produit_emprunte__c != oldEmpruntMap.get(e.Id).Produit_emprunte__c){
                wishedStockIdList.add(e.Produit_emprunte__c);
            }
        }
        
        return queryReservation(wishedStockIdList);
    }
    
    /***
	* @description Backend function to get the facture
	* @param contractIdSet - list of the related contrat id
	* @return List<Facture__c> List queried factures
	*/
    public static List<Reservation__c> queryReservation(List<id> wishedStockIdList){
        
        if(wishedStockIdList.size() == 0){
            return new List<Reservation__c>();
        }
        
        return new List<Reservation__c>([SELECT id, Date_retrait__c, Duree_emprunt__c, 
                                         Produit_reserve__c
                                         FROM Reservation__c
                                         WHERE Status__c = 'Réservé'
                                         AND Produit_reserve__c IN : wishedStockIdList]);
    }
    
    /***
	* @description Get the related contract
	* @param newEmpruntList - list of the new emprunt
	* @return List<Asset> List queried assets
	*/
    public static List<Asset> getRelatedAsset(List<Emprunt__c> newEmpruntList){
                        
        // Map the emprunt to their contrat
        Set<id> contratIdSet = new Set<id>();
        for(Emprunt__c e : newEmpruntList){
            contratIdSet.add(e.Contrat__c);
        }
        
        List<Asset> queriedContratList = [SELECT Code_formule__r.Nombre_jours_carence__c, 
                                          Code_formule__r.Tarif_depassement__c, 
                                          AccountId, 
                                          Account.Email_connexion__c, 
                                          Facture__c
                                          FROM Asset
                                          WHERE id IN: contratIdSet];

        return queriedContratList;
    }
    
    /***
	* @description Get the related stock info
	* @param newEmpruntList - list of the new emprunt
	* @return List<Stock_Produit__c> List queried stock
	*/
    public static List<Stock_Produit__c> getRelatedStock(List<Emprunt__c> newEmpruntList){
                        
        // Map the emprunt to their contrat
        Set<id> stockIdSet = new Set<id>();
        for(Emprunt__c e : newEmpruntList){
            stockIdSet.add(e.Produit_emprunte__c);
        }
        
        List<Stock_Produit__c> relatedStockList = [SELECT Etat__c, 
                                                   Produit__r.Caution__c, 
                                                   Observation__c
                                                   FROM Stock_Produit__c
                                                   WHERE id IN: stockIdSet];

        return relatedStockList;
    }
}