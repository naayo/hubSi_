/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Helper class for AssetTrigger
*/

public class AssetTriggerHelper {
    
    /***
	* @description Get the related accounts
	* @param assetList - list of asset
	* @return Map<id, Account> - Map of the related accounts
	*/
    public static Map<id, Account> getRelatedAccount(List<Asset> assetList){
        
        Set<id> accountIdSet = new Set<Id>();
        for(Asset a : assetList){
            accountIdSet.add(a.AccountId);
        }                                            
        
        // Query the account
        List<Account> relatedAccountList = [SELECT id, 
                                            RecordTypeId,
                                            Record_Type_Name__c, 
                                            Compte_test__c
                                            FROM Account
                                            WHERE id IN: accountIdSet];
        
        // Map the asset ids with their related account
        Map<id, Account> accountMap = new Map<id, Account>();
        for(Account a : relatedAccountList){
            accountMap.put(a.id, a);
        }
        
        return accountMap;
    }
    
    /***
	* @description Get the other asset on a particular account
	* @param assetList - list of asset
	* @return Map<id, Account> - Map of the related accounts
	*/
    public static Map<id, String> getPreviousAsset(List<Asset> assetList){
        
        Set<id> accountIdSet = new Set<Id>();
        for(Asset a : assetList){
            accountIdSet.add(a.AccountId);
        }
        
        // Query the assets
        List<Asset> relatedAssetList = [SELECT id, AccountId, Record_Type_Name__c
                                        FROM Asset
                                        WHERE AccountId IN: accountIdSet];
        
        // Map the asset with their related account ids
        Map<id, String> accountAssetMap = new Map<id, String>();
        for(Asset a : relatedAssetList){
            if(!accountAssetMap.keySet().contains(a.AccountId)){
                accountAssetMap.put(a.AccountId, 'Contrat_location');
            }
            if(accountAssetMap.get(a.AccountId) == 'Contrat_location' &&
              a.Record_Type_Name__c == 'Contrat_assurance'){
                accountAssetMap.put(a.AccountId, 'Contrat_assurance');
            }
        }
        
        return accountAssetMap;
    }
    
    /***
	* @description Get all the related facture
	* @param assetList - list of location asset
	* @return Map<id, Facture__c> - Map of the asset ids with their related facture
	*/
    public static Map<id, Facture__c> getRelatedFacture(List<Asset> assetList){
        
        // Query the facture
        List<Facture__c> relatedFactureList = [SELECT id, Date_debut_periode__c, 
                                               Date_fin_periode__c , Contrat__c
                                               FROM Facture__c
                                               WHERE Contrat__c IN: assetList];
        
        // Map the asset ids with their related facture
        Map<id, Facture__c> contratIdFactureMap = new Map<id, Facture__c>();
        for(Facture__c f : relatedFactureList){
            contratIdFactureMap.put(f.Contrat__c, f);
        }
        
        return contratIdFactureMap;
    }
    
    /***
	* @description Get all the related formules
	* @param assetList - list of location asset
	* @return Map<id, vlocity_ins__AssetCoverage__c> - Map of the asset ids with their related formules
	*/
    public static Map<id, vlocity_ins__AssetCoverage__c> getRelatedFormule(List<Asset> assetList){
        
        // Query the emprunts
        List<vlocity_ins__AssetCoverage__c> relatedFormuleList = [SELECT id, 
                                                                  Date_souscription__c, 
                                                                  Date_de_resiliation__c, 
                                                                  Motif_de_resiliation__c, 
                                                                  vlocity_ins__PolicyAssetId__c, 
                                                                  RecordType.Name
                                                                  FROM vlocity_ins__AssetCoverage__c
                                                                  WHERE vlocity_ins__PolicyAssetId__c IN: assetList];
        
        // Map the asset ids with their related facture
        Map<id, vlocity_ins__AssetCoverage__c> contratIdFormuleMap = new Map<id, vlocity_ins__AssetCoverage__c>();
        for(vlocity_ins__AssetCoverage__c f : relatedFormuleList){
            contratIdFormuleMap.put(f.vlocity_ins__PolicyAssetId__c, f);
        }
        
        return contratIdFormuleMap;
    }
    
    /***
	* @description Get all the related case
	* @param assetList - list of location asset
	* @return Map<id, List<Case>> - Map of the asset ids with their related case
	*/
    public static Map<id, List<Case>> getRelatedCase(List<Asset> assetList){
        
        // Query the emprunts
        List<Case> relatedCaseList = [SELECT id, AssetId, 
                                      Attente_documents__c, Status
                                      FROM Case
                                      WHERE AssetId IN: assetList];
        
        // Map the asset ids with their related case
        Map<id, List<Case>> contratIdCaseMap = new Map<id, List<Case>>();
        for(Case c : relatedCaseList){
            if(!contratIdCaseMap.keySet().contains(c.AssetId)){
                List<Case> tmpList = new List<Case>();
                contratIdCaseMap.put(c.AssetId, tmpList);
            }
            contratIdCaseMap.get(c.AssetId).add(c);
        }
        
        return contratIdCaseMap;
    }

    /***
	* @description Get PolicyCoverage By Id
	* @param policyIds - list of id Of PolicyCoverage
	* @return Map<Id,vlocity_ins__AssetCoverage__c> - Map of the Policy Id and their data
	*/
    public static Map<Id,vlocity_ins__AssetCoverage__c> getRelatedPolicies(List<Id> policiesId){
        
        // Query the emprunts
        Map<Id,vlocity_ins__AssetCoverage__c> mapReturn = new Map<Id,vlocity_ins__AssetCoverage__c>([SELECT Id,
                                                                                                            Formule_options__r.NbMounthKPIContract__c 
                                                                                                        FROM vlocity_ins__AssetCoverage__c
                                                                                                        WHERE Id IN :policiesId]);
        
        return mapReturn;
    }
}