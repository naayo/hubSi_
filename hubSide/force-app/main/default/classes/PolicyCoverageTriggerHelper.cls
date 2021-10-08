/***
* @author Ariane Tanguy (GFI)
* @date 10/07/2020
* @description Helper class for PolicyCoverage
*/

public class PolicyCoverageTriggerHelper {
    
    /***
	* @description Get the assets with previous policies
	* @param newFormuleList - list of all new policies
	* @return Map<id, Asset>
	*/
    public static List<vlocity_ins__AssetCoverage__c> getPreviousPolicies(List<vlocity_ins__AssetCoverage__c> newFormuleList){
        
        // For all newly open inserted formula, get the related asset id
        Set<id> relatedAssetSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            if(f.Statut__c == 'open'){
                relatedAssetSet.add(f.vlocity_ins__PolicyAssetId__c);
            }
        }
        
        // Get the formules
        return [SELECT id, 
                Name, 
                Statut__c,
                Formule_options__c, 
                vlocity_ins__PolicyAssetId__c, 
                vlocity_ins__Type__c, 
                RecordTypeId,
                CreatedDate
                FROM vlocity_ins__AssetCoverage__c
                WHERE vlocity_ins__PolicyAssetId__c IN: relatedAssetSet];
    }
    
    /***
	* @description Get the assets with previous policies
	* @param newFormuleList - list of all new policies
	* @return Map<id, Asset>
	*/
    public static List<vlocity_ins__AssetCoverage__c> getPreviousPolicies(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                                                          Map<id, vlocity_ins__AssetCoverage__c> oldFormuleMap){
        
        // For all newly open inserted formula, get the related asset id
        Set<id> relatedAssetSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            if(f.Statut__c != 'open' &&
               oldFormuleMap.get(f.id).Statut__c != f.Statut__c){
                   relatedAssetSet.add(f.vlocity_ins__PolicyAssetId__c);
               }
        }
        
        // Get the formules
        return [SELECT id, 
                Name, 
                Statut__c,
                Formule_options__c, 
                vlocity_ins__PolicyAssetId__c, 
                vlocity_ins__Type__c, 
                RecordTypeId,
                CreatedDate
                FROM vlocity_ins__AssetCoverage__c
                WHERE vlocity_ins__PolicyAssetId__c IN: relatedAssetSet
                AND id NOT IN : oldFormuleMap.keySet()];
    }
    
    /***
	* @description Get the assets with previous formules
	* @param formuleList - list of previous policies
	* @return Map<id, Asset>
	*/
    public static Map<id, vlocity_ins__AssetCoverage__c> mapPreviousFormules(List<vlocity_ins__AssetCoverage__c> formuleList){
        
        // And map them (the most recent one) to their contracts
        Map<id, vlocity_ins__AssetCoverage__c> assetIdFormuleMap = new Map<id, vlocity_ins__AssetCoverage__c>();
        for(vlocity_ins__AssetCoverage__c f : formuleList){
            if(f.vlocity_ins__Type__c == 'Formula'){
                if(!assetIdFormuleMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                    assetIdFormuleMap.put(f.vlocity_ins__PolicyAssetId__c, f);
                } else {
                    if(f.CreatedDate > assetIdFormuleMap.get(f.vlocity_ins__PolicyAssetId__c).CreatedDate){
                        assetIdFormuleMap.put(f.vlocity_ins__PolicyAssetId__c, f);
                    }
                }
            }
        }
        
        return assetIdFormuleMap;
    }
    
    /***
	* @description Get the assets with previous options
	* @param formuleList - list of previous policies
	* @return Map<id, Asset>
	*/
    public static Map<id, List<vlocity_ins__AssetCoverage__c>> mapPreviousOptions(List<vlocity_ins__AssetCoverage__c> formuleList){        
        
        // And map them (them with the same name) to their contracts
        Map<id, List<vlocity_ins__AssetCoverage__c>> assetIdOptionMap = new Map<id, List<vlocity_ins__AssetCoverage__c>>();
        for(vlocity_ins__AssetCoverage__c f : formuleList){
            if(f.vlocity_ins__Type__c == 'Option'){
                if(!assetIdOptionMap.keySet().contains(f.vlocity_ins__PolicyAssetId__c)){
                    List<vlocity_ins__AssetCoverage__c> tmpList = new List<vlocity_ins__AssetCoverage__c>();
                    assetIdOptionMap.put(f.vlocity_ins__PolicyAssetId__c, tmpList);
                }
                assetIdOptionMap.get(f.vlocity_ins__PolicyAssetId__c).add(f);
            }
        }
        return assetIdOptionMap;
    }
    
    /***
	* @description Get the formule (product2)
	* @param newFormuleList - list of all new formule
	* @return Map<id, Product2>
	*/
    public static Map<id, Product2> getRelatedProductFormule(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                                            List<vlocity_ins__AssetCoverage__c> previousPolicyList){
        
        Set<id> product2IdSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            product2IdSet.add(f.Formule_options__c);
        }
        for(vlocity_ins__AssetCoverage__c f : previousPolicyList){
            product2IdSet.add(f.Formule_options__c);
        }
        
        return new Map<id, Product2>([SELECT id, 
                                      Name, 
                                      Gamme_Formule__r.Name, 
                                      Nombre_jours_inclus__c, 
                                      Id_externe__c, 
                                      Casse__c, 
                                      Communication_frauduleuse__c, 
                                      FranchiseAmount1__c, 
                                      FranchiseAmount2__c, 
                                      FranchiseAmount3__c, 
                                      FranchiseLevel1__c, 
                                      FranchiseLevel2__c, 
                                      FranchiseLevel3__c, 
                                      Franchise__c, 
                                      Nombre_echanges__c, 
                                      Nombre_mobiles_couverts__c,
                                      Nombre_produits_assures__c, 
                                      Nombre_produits_multimedia_couverts__c,
                                      Oxydation__c, 
                                      Perte__c, 
                                      Pertes_avec_franchise__c, 
                                      Pertes_valeur_achat__c, 
                                      Plafond__c, 
                                      Reparation__c, 
                                      Tout_risques__c, 
                                      Type_produit__c, 
                                      vlocity_ins__Type__c,
                                      Vol_Caracterise__c, 
                                      Vol_toute_cause__c,
                                      NbMounthKPIContract__c
                                      FROM Product2
                                      WHERE id IN: product2IdSet]);
    }
    
    /***
	* @description Get the asset
	* @param newFormuleList - list of all new formule
	* @return Map<id, Asset>
	*/
    public static Map<id, Asset> getRelatedAsset(List<vlocity_ins__AssetCoverage__c> newFormuleList){
        
        Set<id> assetIdSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            assetIdSet.add(f.vlocity_ins__PolicyAssetId__c);
        }
        return queryAsset(assetIdSet);
    }
    
    /***
	* @description Get the asset
	* @param newFormuleList - list of all new formule
	* @return Map<id, Asset>
	*/
    public static Map<id, Asset> getRelatedAsset(List<vlocity_ins__AssetCoverage__c> newFormuleList, 
                                                 Map<id, vlocity_ins__AssetCoverage__c> oldFormuleMap){
        
        Set<id> assetIdSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            if(f.Statut__c != 'open' &&
               oldFormuleMap.get(f.id).Statut__c != f.Statut__c){
                   assetIdSet.add(f.vlocity_ins__PolicyAssetId__c);
               }
        }
        return queryAsset(assetIdSet);
    }
    
    /***
	* @description Query assets
	* @param assetIdSet - set of asset ids
	* @return Map<id, Asset>
	*/
    private static Map<id, Asset> queryAsset(Set<id> assetIdSet){
        
        return new Map<id, Asset>([SELECT id, 
                                   Name, 
                                   Casse__c, 
                                   Communication_frauduleuse__c, 
                                   Formule__c, 
                                   Nombre_echanges__c, 
                                   Nombre_mobiles_couverts__c, 
                                   Nombre_produits_assures__c, 
                                   Nombre_produits_multimedia_couverts__c, 
                                   Oxydation__c, 
                                   Perte__c, 
                                   Pertes_avec_franchise__c, 
                                   Plafond__c, 
                                   Record_Type_Name__c, 
                                   Reparation__c, 
                                   Tout_risques__c, 
                                   Type_de_contrat__c, 
                                   Vol_Caracterise__c, 
                                   Vol_toute_cause__c,
                                   vlocity_ins__Type__c,
                                   Date_debut_contrat__c,
                                   TECH_CalculatorIndicLastChange__c,
                                   TECH_LastBirthDayContract__c
                                   FROM Asset
                                   WHERE id IN: assetIdSet]);
    }
    
    /***
	* @description Get the facture for the asset with previous formules
	* @param newFormuleList - list of all new formule
	* @param relatedAssetMap - related location assets
	* @return Map<id, vlocity_ins__AssetCoverage__c>
	*/
    public static Map<id, Facture__c> getRelatedFacture(List<vlocity_ins__AssetCoverage__c> newFormuleList, id formuleLocationId){
        
        // For all newly inserted location policy coverages (formule), get the related asset id
        Set<id> relatedAssetSet = new Set<id>();
        for(vlocity_ins__AssetCoverage__c f : newFormuleList){
            
            if(f.Statut__c == 'open' && 
               f.vlocity_ins__Type__c == 'Formula' &&
               f.RecordTypeId == formuleLocationId){
                   relatedAssetSet.add(f.vlocity_ins__PolicyAssetId__c);
               }            
        }
        
        // Get the factures
        List<Facture__c> factureList = [SELECT id, 
                                        Contrat__c, 
                                        Date_debut_periode__c, 
                                        Nombre_jours_restants__c, 
                                        Nombre_jours_formule__c 
                                        FROM Facture__c
                                        WHERE Contrat__c IN: relatedAssetSet
                                        AND Facture_active__c = TRUE];
        
        // And map them to their contracts
        Map<id, Facture__c> assetIdFactureMap = new Map<id, Facture__c>();
        for(Facture__c f : factureList){
            if(assetIdFactureMap.keySet().contains(f.Contrat__c)){
                system.assert(false, 'There are two facture active on this asset - This is wrong');
            } else {
                assetIdFactureMap.put(f.Contrat__c, f);
            }
        }
        return assetIdFactureMap;
    }
}