/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Handler class for PolicyCoverage
*/

public class PolicyCoverageTriggerHandler {
    
    /***
	* @description Check the previous formules : if there's already an open one, throw an error
	* @param newFormuleList - list of all new formule
	* @param assetIdFormuleMap - previous formules mapped to their asset id
	* @param assetIdOptionMap - previous options mapped to their asset id
	* @return NA
	*/
    public static void checkPreviousFormuleOnCreation(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                                      Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap, 
                                                      Map<id, List<vlocity_ins__AssetCoverage__c>> assetIdOptionMap){
        
        // For the newly created Formules
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If it's a formula and if there's another formula open, stop it from happening
            if(assetIdFormuleMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) &&
               assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Statut__c == 'open' &&
               f.vlocity_ins__Type__c == 'Formula'){
                   f.isErrorAPI__c = TRUE;
            }
            
            // If it's an option and if there's another formula open, stop it from happening
            if(assetIdOptionMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) 
               && f.vlocity_ins__Type__c == 'Option'){
                   // Check em all
                   for(vlocity_ins__AssetCoverage__c p : assetIdOptionMap.get(f.vlocity_ins__PolicyAssetId__c)){
                       if(p.Formule_options__c == f.Formule_options__c 
                          && p.Statut__c == 'open'){
                              f.isErrorAPI__c = TRUE;
                          }
                   }
            }
        }
    }
    
    /***
	* @description Update the Policy Coverage
	* @param newFormuleList - list of all new formule
	* @param relatedProductFormuleMap - map of the related product
	* @param formuleLocationId - formule location record type id
	* @return NA
	*/
    public static void updateFormuleOnCreation(List<vlocity_ins__AssetCoverage__c> newFormuleList,
                                               Map<id, Product2> relatedProductFormuleMap, 
                                               id formuleLocationId){
        
        // For the newly created Formules
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If the formule has been created via the temporary manual workaround
            if(f.Name == 'FORMULE_LOCATION'){
                
                // Update record type
                f.RecordTypeId = formuleLocationId;
            }
            
            // For all the formula + options created, update the formule's name
            if(relatedProductFormuleMap.get(f.Formule_options__c).Id_externe__c != 'ProductNotFound01'){
                f.Name = relatedProductFormuleMap.get(f.Formule_options__c).Name + ' - ' + system.today();
            }
        }
    }
    
    /***
	* @description Update the Policy Coverage
	* @param newFormuleList - list of all new formule
	* @param oldFormuleMap - map of old formule
	* @param relatedProductFormuleMap - map of the related product
	* @return NA
	*/
    public static void updateFormuleOnUpdate(List<vlocity_ins__AssetCoverage__c> newFormuleList,
                                             Map<id, vlocity_ins__AssetCoverage__c> oldFormuleMap){
        
        // For the newly created Formules
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // For all the formula + options created, update the formule's name
            if(f.Name != oldFormuleMap.get(f.id).Name){
                f.Name = oldFormuleMap.get(f.id).Name;
            }
        }
    }
    
    /***
	* @description Combine the different forumule + option to update the policies at the asset level
	* @param newFormuleList - list of all new formule
	* @param relatedAssetMap - related asset map
	* @param assetIdFormuleMap - previous formules mapped to their asset id
	* @param assetIdOptionMap - previous options mapped to their asset id
	* @param relatedProductFormuleMap - map of the related product
	* @return NA
	*/
    public static void updateRelatedAsset(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                          Map<id, Asset> relatedAssetMap, 
                                          Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap, 
                                          Map<id, List<vlocity_ins__AssetCoverage__c>> assetIdOptionMap, 
                                          Map<id, Product2> relatedProductFormuleMap){
		
		// Map the newly created policy coverage to their asset
		for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // Check whether the related asset is assurance
            if(f.Statut__c == 'open' &&
               relatedAssetMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) && 
               relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Record_Type_Name__c == 'Contrat_assurance'){
                   
                   // If the new policy coverage is a formule
                   if(f.vlocity_ins__Type__c == 'Formula'){
                       
                       // If so, update the asset formule map with the current formule
                       assetIdFormuleMap.put(f.vlocity_ins__PolicyAssetId__c, f);                       
                   } else {
                       if(!assetIdOptionMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                           List<vlocity_ins__AssetCoverage__c> tmpList = new List<vlocity_ins__AssetCoverage__c>();
                           assetIdOptionMap.put(f.vlocity_ins__PolicyAssetId__c, tmpList);
                       }
                       assetIdOptionMap.get(f.vlocity_ins__PolicyAssetId__c).add(f);
                   } 
               }
        }
                                  
		// Handle the number of insured products
		Map<String, String> nbProduitsPicklistMap = UtilityClassHelper.getPicklistValues(new Product2(), 'Nombre_produits_assures__c');
		List<String> picklistValueList = new List<String>(nbProduitsPicklistMap.keySet());
                                              
        // For the newly created policy coverages
        Set<id> updatedAssetIdSet = new Set<id>();
        Map<String,Date> mapDate = new Map<String,Date>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If the asset is an Assurance one
            if(relatedAssetMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) && 
               relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Record_Type_Name__c == 'Contrat_assurance'){
                   
                   Product2 currentFormule = relatedProductFormuleMap.get(f.Formule_options__c);
                   mapDate = UtilityClassHelper.manageCalculatorDate((Integer)currentFormule.NbMounthKPIContract__c,relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Date_debut_contrat__c);
                   
                   // Policy coverage field init
                   f.Casse__c = currentFormule.Casse__c;
                   f.Communication_frauduleuse__c = currentFormule.Communication_frauduleuse__c;
                   f.FranchiseAmount1__c = currentFormule.FranchiseAmount1__c;
                   f.FranchiseAmount2__c = currentFormule.FranchiseAmount2__c;
                   f.FranchiseAmount3__c = currentFormule.FranchiseAmount3__c;
                   f.FranchiseLevel1__c = currentFormule.FranchiseLevel1__c;
                   f.FranchiseLevel2__c = currentFormule.FranchiseLevel2__c;
                   f.FranchiseLevel3__c = currentFormule.FranchiseLevel3__c;
                   f.Nombre_echanges__c = currentFormule.Nombre_echanges__c;
                   f.Nombre_mobiles_couverts__c = currentFormule.Nombre_mobiles_couverts__c;
                   f.Nombre_produits_assures__c = currentFormule.Nombre_produits_assures__c;
                   f.Nombre_produits_multimedia_couverts__c = currentFormule.Nombre_produits_multimedia_couverts__c;
                   f.Oxydation__c = currentFormule.Oxydation__c;
                   f.Perte__c = currentFormule.Perte__c;
                   f.Pertes_avec_franchise__c = currentFormule.Pertes_avec_franchise__c;
                   f.Plafond__c = currentFormule.Plafond__c;
                   f.Reparation__c = currentFormule.Reparation__c;
                   f.Tout_risques__c = currentFormule.Tout_risques__c;
                   f.Type_produit__c = currentFormule.Type_produit__c;
                   f.vlocity_ins__Type__c = currentFormule.vlocity_ins__Type__c;
                   f.Vol_Caracterise__c = currentFormule.Vol_Caracterise__c;
                   f.Vol_toute_cause__c = currentFormule.Vol_toute_cause__c;
                   f.NbMounthKPIContract__c = currentFormule.NbMounthKPIContract__c;
                   
                   // Don't update more than once the asset
                   if(!updatedAssetIdSet.contains(f.vlocity_ins__PolicyAssetId__c)){
                       
                       updatedAssetIdSet.add(f.vlocity_ins__PolicyAssetId__c);
                       
                       // If the policy is a option
                       if(f.vlocity_ins__Type__c == 'Option'){
                           currentFormule = relatedProductFormuleMap.get(assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Formule_options__c);
                           
                           /*
                           // Handle the bad data scenario
                           if(assetIdFormuleMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) && 
                              relatedProductFormuleMap.keySet().contains(assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Formule_options__c)){
                                  currentFormule = relatedProductFormuleMap.get(assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Formule_options__c);
                              } else {
                                  continue;
                              }*/
                       }                 
                       
                       // Asset field init
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Casse__c = currentFormule.Casse__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Communication_frauduleuse__c = currentFormule.Communication_frauduleuse__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_echanges__c = currentFormule.Nombre_echanges__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_mobiles_couverts__c = currentFormule.Nombre_mobiles_couverts__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_assures__c = currentFormule.Nombre_produits_assures__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_multimedia_couverts__c = currentFormule.Nombre_produits_multimedia_couverts__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Oxydation__c = currentFormule.Oxydation__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Perte__c = currentFormule.Perte__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Pertes_avec_franchise__c = currentFormule.Pertes_avec_franchise__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Plafond__c = currentFormule.Plafond__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Reparation__c = currentFormule.Reparation__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Tout_risques__c = currentFormule.Tout_risques__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).vlocity_ins__Type__c = currentFormule.vlocity_ins__Type__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Type_de_contrat__c = currentFormule.Type_produit__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Vol_Caracterise__c = currentFormule.Vol_Caracterise__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Vol_toute_cause__c = currentFormule.Vol_toute_cause__c;
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).TECH_CalculatorIndicLastChange__c = mapDate.get('TECH_CalculatorIndicLastChange__c');
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).TECH_LastBirthDayContract__c = mapDate.get('TECH_LastBirthDayContract__c');
                   }
               }
        }

		// Loop again, this time to add the options
		updatedAssetIdSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If the asset is an Assurance one
            if(relatedAssetMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) && 
               relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Record_Type_Name__c == 'Contrat_assurance' &&
               !updatedAssetIdSet.contains(f.vlocity_ins__PolicyAssetId__c)){
                   
                   // If the policy is a formula and is there are other options
                   if(f.vlocity_ins__Type__c == 'Option' &&
                      assetIdOptionMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                          
                          updatedAssetIdSet.add(f.vlocity_ins__PolicyAssetId__c);
                          
                          // Find out all the related options and merge the necessary fields                       
                          for(vlocity_ins__AssetCoverage__c p : assetIdOptionMap.get(f.vlocity_ins__PolicyAssetId__c)){
                              if(p.Statut__c == 'open'){
                                  
                                  Product2 currentFormule = relatedProductFormuleMap.get(p.Formule_options__c);
                                  
                                  // Add up option values to the asset
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Casse__c |= currentFormule.Casse__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Communication_frauduleuse__c |= currentFormule.Communication_frauduleuse__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_echanges__c += currentFormule.Nombre_echanges__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_mobiles_couverts__c += currentFormule.Nombre_mobiles_couverts__c;
                                                                    
                                  String a = relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_assures__c == NULL ? 
                                      '0' : relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_assures__c;
                                  String b = currentFormule.Nombre_produits_assures__c == NULL ?
                                      '0' : currentFormule.Nombre_produits_assures__c;
                                                                    
                                  Integer nbProduitsAssures = picklistValueList.indexOf(a) + picklistValueList.indexOf(b);
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_assures__c = nbProduitsAssures > 5 ?
                                      picklistValueList[5] : picklistValueList[nbProduitsAssures];
                                  
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_produits_multimedia_couverts__c += currentFormule.Nombre_produits_multimedia_couverts__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Oxydation__c |= currentFormule.Oxydation__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Perte__c |= currentFormule.Perte__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Pertes_avec_franchise__c |= currentFormule.Pertes_avec_franchise__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Plafond__c += currentFormule.Plafond__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Reparation__c |= currentFormule.Reparation__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Tout_risques__c |= currentFormule.Tout_risques__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Vol_Caracterise__c |= currentFormule.Vol_Caracterise__c;
                                  relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Vol_toute_cause__c |= currentFormule.Vol_toute_cause__c;
                              }
                          }
                      }
               }
        }
		
		update relatedAssetMap.values();
    }
    
    /***
	* @description Update the asset with the formule id
	* @param newFormuleList - list of all new formule
	* @param relatedAssetMap - related asset map
	* @return NA
	*/
    public static void updateRelatedAsset(List<vlocity_ins__AssetCoverage__c> newFormuleList, Map<id, Asset> relatedAssetMap){
        
        // For the newly created Formules
        List<Asset> assetToUpdateList = new List<Asset>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If the asset is an Assurance one
            if(relatedAssetMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c) && 
               relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Record_Type_Name__c == 'Contrat_assurance'){
                   
                   // If the policy is a formula
                   if(f.vlocity_ins__Type__c == 'Formula'){
                       
                       relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c).Formule__c = f.id;
                       assetToUpdateList.add(relatedAssetMap.get(f.vlocity_ins__PolicyAssetId__c));
                   }
               }
        }
        system.debug('-- assetToUpdateList ' + assetToUpdateList);
        update assetToUpdateList;
    }
    
    /***
	* @description Update the old formule if it was stopped
	* @param newFormuleList - list of all new formule
	* @param assetIdFormuleMap - map of the related assets
	* @param relatedProductFormuleMap - map of the related product
	* @param formuleLocationId - formule location record type id
	* @return List<SObject>
	*/
    public static void handleFormuleResiliation(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                                Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap, 
                                                Map<id, Product2> relatedProductFormuleMap, 
                                                id formuleLocationId){
        
        Map<String, Integer> gammeNameCoef = new Map<String, Integer>{'Nomade' => 0, 
            'Agile' => 1, 
            'Aventure' => 2, 
            'ProduitsInf1500' => 1, 
            'ProduitsSup1500' => 2};
                
        List<vlocity_ins__AssetCoverage__c> formuleToUpdateList = new List<vlocity_ins__AssetCoverage__c>();
        
        // For the newly created Formules
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // If there's another formula on that contract
            if(assetIdFormuleMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                
                // If that formula is open and both formula are from the location stream
                if(f.Statut__c == 'Open' &&
                   f.RecordTypeId == formuleLocationId &&
                   assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).RecordTypeId == formuleLocationId){
                    
                       id oldFormuleId = assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Formule_options__c;
                       
                       String nameOldGamme = relatedProductFormuleMap.get(oldFormuleId).Gamme_Formule__r.Name;
                       String nameNewGamme = relatedProductFormuleMap.get(f.Formule_options__c).Gamme_Formule__r.Name;
                       
                       Decimal nbJourOldFormule = relatedProductFormuleMap.get(oldFormuleId).Nombre_jours_inclus__c;
                       Decimal nbJourNewFormule = relatedProductFormuleMap.get(f.Formule_options__c).Nombre_jours_inclus__c;
                       
                       // Compare the gamme and the number of days
                       // If the new gamme is higher
                       if(gammeNameCoef.get(nameOldGamme) < gammeNameCoef.get(nameNewGamme) ||
                          // Or is the gamme is same same but there are more days
                          (gammeNameCoef.get(nameOldGamme) == gammeNameCoef.get(nameNewGamme) &&
                           nbJourOldFormule < nbJourNewFormule)){
                               assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Motif_de_resiliation__c = 'upgrade';
                           } else {
                               
                               // If the new gamme is lower
                               if(gammeNameCoef.get(nameOldGamme) > gammeNameCoef.get(nameNewGamme) ||
                                  // Or is the gamme is same same but there are less days
                                  (gammeNameCoef.get(nameOldGamme) == gammeNameCoef.get(nameNewGamme) &&
                                   nbJourOldFormule > nbJourNewFormule)){
                                       assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Motif_de_resiliation__c = 'downgrade';
                                   } else {
                                       assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).Motif_de_resiliation__c = 'unknown';
                                   }
                           }
                       
                       formuleToUpdateList.add(assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c));
                   }
            }
        }
        update formuleToUpdateList;
    }
    
    /***
	* @description Update the facture for which the formule has changed
	* @param newFormuleList - list of all new formule
	* @param assetIdFactureMap - related facture list mapped to their asset id
	* @param relatedProductFormuleMap - related product map
	* @return NA
	*/
    public static void updateRelatedFacture(List<vlocity_ins__AssetCoverage__c> newFormuleList,
                                            Map<id, Facture__c> assetIdFactureMap, 
                                            Map<id, Product2> relatedProductFormuleMap){
        
        List<Facture__c> factureToUpdateList = new List<Facture__c>();
        
        // For all newly created formules
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            // Check whether there was previously a formule, and if there was, update the related facture
            if(assetIdFactureMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                
                // Check how many days were left on the facture                
                if((assetIdFactureMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_jours_formule__c < 
                    relatedProductFormuleMap.get(f.Formule_options__c).Nombre_jours_inclus__c ||
                    assetIdFactureMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_jours_formule__c == NULL) &&
                   relatedProductFormuleMap.get(f.Formule_options__c).Nombre_jours_inclus__c != 0){
                       assetIdFactureMap.get(f.vlocity_ins__PolicyAssetId__c).Nombre_jours_formule__c = 
                           relatedProductFormuleMap.get(f.Formule_options__c).Nombre_jours_inclus__c;
                       factureToUpdateList.add(assetIdFactureMap.get(f.vlocity_ins__PolicyAssetId__c));
                   }
            }
        }
        update factureToUpdateList;
    }
}