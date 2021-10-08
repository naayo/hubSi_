/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Handler class for EmpruntTrigger
*/

public class EmpruntTriggerHandler {
    
    /***
	* @description update emprunt on create
	* @param newEmpruntList - list of emprunt
	* @param relatedFactureList - list of related factures
	* @return NA
	*/
    public static void updateEmpruntOnCreate(List<Emprunt__c> newEmpruntList, 
                                             List<Facture__c> relatedFactureList, 
                                             id createdEmpruntRecordType, 
                                             Map<List<String>, Decimal> tableDecompteMap, 
                                             List<Asset> relatedAssetList, 
                                             List<Stock_Produit__c> relatedStockList){
        
        // Map the factures with their contract id
        Map<Id, Facture__c> factureContractIdMap = new Map<Id, Facture__c>();
        for(Facture__c f : relatedFactureList){
            factureContractIdMap.put(f.Contrat__c, f);
        }
                                                 
        // Map the assets with their id
        Map<Id, Asset> assetIdMap = new Map<Id, Asset>();
        for(Asset a : relatedAssetList){
            assetIdMap.put(a.id, a);
        }
                                                 
        // Map the stock with their id
        Map<Id, Stock_Produit__c> stockIdMap = new Map<Id, Stock_Produit__c>();
        for(Stock_Produit__c s : relatedStockList){
            stockIdMap.put(s.id, s);
        }
        
        for(Emprunt__c e : newEmpruntList){
            
            // For each new emprunt, set the facture
            if(factureContractIdMap.keySet().contains(e.Contrat__c)){
                e.Facture__c = factureContractIdMap.get(e.Contrat__c).id;
                e.Nombre_de_jours_consommation__c = factureContractIdMap.get(e.Contrat__c).Nombre_jours_restants__c;
            }
            
            // Update the record type
            e.RecordTypeId = createdEmpruntRecordType;
            
            // Update the coefficient de decompte
            List<String> gammeNames = new List<String>{e.Gamme_formule__c, e.Gamme_produit__c};
            if(tableDecompteMap.keySet().contains(gammeNames)){
                e.Coefficient_decompte__c = tableDecompteMap.get(gammeNames);
            }
            
            // Update the emprunt with the asset info
            if(assetIdMap.containsKey(e.Contrat__c)){
                e.Client__c = assetIdMap.get(e.Contrat__c).accountId;
                e.Email_client__c = assetIdMap.get(e.Contrat__c).Account.Email_connexion__c;
            }
            
            // Update the emprunt with the stock info
            if(stockIdMap.containsKey(e.Produit_emprunte__c)){
                e.Etat_sortie__c = stockIdMap.get(e.Produit_emprunte__c).Etat__c;
                e.Montant_caution_sortie__c = stockIdMap.get(e.Produit_emprunte__c).Produit__r.Caution__c;
                e.Observation_sortie__c = stockIdMap.get(e.Produit_emprunte__c).Observation__c;
            }
            
            // Update other fields
            e.Date_sortie__c = system.today();
        }
    }
    
    /***
	* @description From the emprunt fields, update the facture on emprunt creation
	* RIP RollUpSummary, sweet summer child
	* @param newEmpruntList - list of emprunt
	* @param relatedFactureList - previously queried related facture
	* @param empruntIdJourCarenceMap - previously queried jour de carence map
	* @return NA
	*/
    public static List<Facture__c> updateFactureOnCreation(List<Emprunt__c> newEmpruntList, 
                                                           List<Facture__c> relatedFactureList, 
                                                           List<Asset> relatedAssetList){
        
        Map<Id, List<Decimal>> empruntIdJourCarenceMap = getRelatedJourCarence(newEmpruntList, relatedAssetList);
                                                               
        // Check whether there are changes to make
        if(relatedFactureList.size() == 0){
            return new List<Facture__c>();
        }
        
        // Get all the related facture ids
        Map<Id, Facture__c> factureIdMap = new Map<Id, Facture__c>();
        for(Facture__c f : relatedFactureList){
            factureIdMap.put(f.id, f);
        }
                                                               
        // Loop over the Emprunt 
        List<Facture__c> factureToUpdate = new List<Facture__c>();
        for(Emprunt__c e : newEmpruntList){
            
            // Add the location days
            factureIdMap.get(e.Facture__c).Nombre_jours_consommes__c += e.Nombre_jours_imputes__c;
            
            // And add the updated montant co
            factureIdMap.get(e.Facture__c).Montant_facture__c += e.Montant_facture__c;
            
            // Add the depassement days
            factureIdMap.get(e.Facture__c).Nombre_jours_depassement__c += e.Nombre_jours_depassement__c;
            
            factureToUpdate.add(factureIdMap.get(e.Facture__c));
        }                                              
        return factureToUpdate;
    }
    
    /***
	* @description Get the emprunt fields and update them on the facture 
	* RIP RollUpSummary, sweet summer child
	* @param newEmpruntList - list of emprunt
	* @param relatedFactureList - previously queried related facture
	* @return NA
	*/
    public static List<Facture__c> updateFacture(List<Emprunt__c> newEmpruntList, 
                                                 Map<id, Emprunt__c> oldEmpruntMap, 
                                                 List<Facture__c> relatedFactureList, 
                                                 List<Asset> relatedAssetList){
        
        Map<Id, List<Decimal>> empruntIdJourCarenceMap = getRelatedJourCarence(newEmpruntList, relatedAssetList);
                                                     
        // Check whether there are changes to make
        if(relatedFactureList.size() == 0){
            system.debug('-- return null');
            return new List<Facture__c>();
        }
        
        // Get all the related facture ids
        Map<Id, Facture__c> factureIdMap = new Map<Id, Facture__c>();
        for(Facture__c f : relatedFactureList){
            factureIdMap.put(f.id, f);
        }
                                                     
        system.debug('-- factureIdMap ' + factureIdMap);
        
        // Loop over the Emprunt 
        List<Facture__c> factureToUpdate = new List<Facture__c>(); 
        for(Emprunt__c e : newEmpruntList){
            
            if(factureIdMap.keySet().contains(e.Facture__c)){
                
                // Add the location days
                factureIdMap.get(e.Facture__c).Nombre_jours_consommes__c += (e.Nombre_jours_imputes__c - oldEmpruntMap.get(e.Id).Nombre_jours_imputes__c);
                
                // And add the updated montant co
                factureIdMap.get(e.Facture__c).Montant_facture__c += (e.Montant_facture__c - oldEmpruntMap.get(e.Id).Montant_facture__c);
                
                // Add the depassement days
                if((e.Nombre_jours_imputes__c - oldEmpruntMap.get(e.Id).Nombre_jours_imputes__c) > 0){                
                    factureIdMap.get(e.Facture__c).Nombre_jours_depassement__c += (e.Nombre_jours_depassement__c - oldEmpruntMap.get(e.Id).Nombre_jours_depassement__c);
                }
                factureToUpdate.add(factureIdMap.get(e.Facture__c));
            }
        }
        
        system.debug('-- factureToUpdate ' + factureToUpdate);
        return factureToUpdate;
    }
    
    /***
	* @description Get the related jour de carence
	* @param contractIdSet - list of the related contrat id
	* @return Map<Id, List<Decimal>>
	*/
    private static Map<Id, List<Decimal>> getRelatedJourCarence(List<Emprunt__c> newEmpruntList, List<Asset> relatedAssetList){
                        
        // Map the emprunt to their contrat
        Map<id, id> contratIdEmpruntIdMap = new Map<id, id>();
        for(Emprunt__c e : newEmpruntList){
            if(e.Status__c != 'Retourné' &&
               e.Status__c != 'Retour avec défaut'){
            	contratIdEmpruntIdMap.put(e.Contrat__c, e.id);    
            }
        }
        
        Map<Id, List<Decimal>> empruntIdJourCarenceMap = new Map<Id, List<Decimal>>();
        for(Asset a : relatedAssetList){
            if(!empruntIdJourCarenceMap.keySet().contains(a.Id)){
                empruntIdJourCarenceMap.put(contratIdEmpruntIdMap.get(a.Id), new List<Decimal>());
            }
            empruntIdJourCarenceMap.get(contratIdEmpruntIdMap.get(a.Id)).add(a.Code_formule__r.Nombre_jours_carence__c);
            empruntIdJourCarenceMap.get(contratIdEmpruntIdMap.get(a.Id)).add(a.Code_formule__r.Tarif_depassement__c);
        }

        return empruntIdJourCarenceMap;
    }
    
    /***
	* @description Substract the fields from deleted emprunt on the facture
	* @param newEmpruntList - list of emprunt
	* @param relatedFactureList - previously queried related facture
	* @return NA
	*/
    public static List<Facture__c> cleanFactureOnDelete(List<Emprunt__c> newEmpruntList, List<Facture__c> relatedFactureList){
        
        // Map the emprunts and their related facture ids
        Map<id, List<Emprunt__c>> factureIdEmpruntMap = new Map<id, List<Emprunt__c>>();
        for(Emprunt__c e : newEmpruntList){
            if(factureIdEmpruntMap.keySet().contains(e.Facture__c)){
                factureIdEmpruntMap.get(e.Facture__c).add(e);
            } else {
                List<Emprunt__c> empruntList = new List<Emprunt__c>();
                empruntList.add(e);
                factureIdEmpruntMap.put(e.Facture__c, empruntList);
            }
        }
        
        // Loop over the factures
        List<Facture__c> factureToUpdate = new List<Facture__c>();
        for(Facture__c f : relatedFactureList){
            if(factureIdEmpruntMap.keySet().contains(f.id)){
                for(Emprunt__c e : factureIdEmpruntMap.get(f.id)){
                    f.Nombre_jours_consommes__c -= e.Nombre_jours_imputes__c;
                    f.Montant_facture__c -= e.Montant_facture__c;
                    f.Nombre_jours_depassement__c -= e.Nombre_jours_depassement__c;
                    factureToUpdate.add(f);
                }
            }
        }
        
        return factureToUpdate;
    }
    
    /***
	* @description When creating an emprunt, check whether there isn't already a reservation.
	* @param newEmpruntList - list of emprunt
	* @param plannedReservationList - already planned reservation
	* @return NA
	*/
    public static void checkStockPlanning(List<Emprunt__c> newEmpruntList, List<Reservation__c> plannedReservationList){
        
        // Loop over the emprunt
        for(Emprunt__c e : newEmpruntList){
            
            // For any emprunt which is not back yet
            if(e.Status__c == 'En magasin' || e.Status__c == 'Sortie'){
                
                system.debug('--- here e' + e);
                
                e.Stock_disponible__c = TRUE;
                
                // And over the reservation
                for(Reservation__c r : plannedReservationList){
                    
                    system.debug('--- here r' + r);
                    
                    if(r.Date_retrait__c != null && r.Duree_emprunt__c != null){
                        
                        if(UtilityClassHelper.compareDate(e.Date_sortie__c, 
                                                          e.Date_retour_prevu__c, 
                                                          r.Date_retrait__c, 
                                                          r.Date_retrait__c.addDays((Integer)r.Duree_emprunt__c)) && 
                           e.Produit_emprunte__c == r.Produit_reserve__c){
                               if(e.Reservation_origine__c != r.id){
                                   e.Stock_disponible__c = FALSE;
                                   system.debug('--- FALSE');
                                   break;
                               }
                           }
                    }
                }   
            }
        }
    }
    
    /***
	* @description Check the emprunt status and do the necessary operations
	* @param newEmpruntList - list of emprunt
	* @return NA
	*/
    public static void automateEmpruntStatus(List<Emprunt__c> newEmpruntList){
        
		String filename;
        
        // Loop over the emprunts
        for(Emprunt__c e : newEmpruntList){
            
            // All fields in the Sortie section are there
            if(e.Date_sortie__c != null &&
               e.Date_retour_prevu__c != null &&
               e.Heure_sortie__c != null &&
               e.Heure_retour_prevue__c != null &&
               e.Etat_sortie__c != null &&
               e.Montant_caution_sortie__c != null &&
               e.Point_de_vente_sortie__c != null &&
               e.Caution_recue__c &&
               e.Status__c == 'En magasin'){
                   
                   // Change the emprunt status
                   e.Status__c = 'Sortie';
                   //filename = 'Bon de sortie ' + e.Name + ' - ' + e.ClientLastName__c + '.pdf';
                   filename = 'Bon de location ' + e.Name + ' - ' + e.ClientLastName__c + '.pdf';
                   
                   // Generate the Bon de sortie
                   EmpruntEmailHandler.sendEmailWithAttachment(e.id, e.Status__c, e.Email_client__c, fileName);
                   break;
               }
            
            // All fields in the Retour section are there
            if(e.Date_retour__c != null &&
               e.Heure_retour__c != null &&
               e.Etat_retour__c != null &&
               e.Montant_caution_retour__c != null &&
               e.Point_de_vente_retour__c != null &&
               e.Caution_restituee__c &&
               e.Status__c == 'Sortie'){
                   
                   // Change the emprunt status and handle the defect status
                   if((e.Etat_retour__c == 'Rayé' ||
                       e.Etat_retour__c == 'Cassé') &&
                      (e.Etat_sortie__c == 'Neuf' ||
                       e.Etat_sortie__c == 'Bon état' ||
                       e.Etat_sortie__c == 'Sans défaut apparent')){
                           e.Status__c = 'Retour avec défaut';
                       } else {
                           e.Status__c = 'Retourné';
                       }
                   /*
                   filename = 'Bon de retour ' + e.Name + ' - ' + e.ClientLastName__c + '.pdf';
                   
                   // Generate the Bon de retour
                   EmpruntEmailHandler.sendEmailWithAttachment(e.id, e.Status__c, e.Email_client__c, fileName);*/
               }
        }
    }
}