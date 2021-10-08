/***
* @author Nicolas Brancato (GFI)
* @date 19/02/2020
* @description Helper class for EquipementSinistreTrigger
*/

public class EquipementSinistreTriggerHelper {    
    
    static final String DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE = 'Equipement_vole_perdu';
    static final String BAPPLISTOCKNAME_SFAMRESA = 'SFAM 3';
    
    /***
	* @description Get the related case
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, Case>
	*/
    public Map<id, Case> getRelatedCase(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedCaseIdSet.add(e.Sinistre__c);
        }
        
        Map<id, Case> relatedCaseMap = new Map<id, Case>([SELECT id, 
                                                          Numero_sinistre__c,
                                                          TECH_CheckChoixClientValidate__c, 
                                                          TECH_NumberIndemToProcess__c,
                                                          TECH_NumberAlertWaiting__c,
                                                          TECH_ExchangeDateChoosed__c,
                                                          TECH_MatriceCoutChoiceExchange__c, 
                                                          Typologie_sinistre__c,
                                                          Record_type_Name__c
                                                          FROM Case
                                                          WHERE id IN: relatedCaseIdSet]);
        return relatedCaseMap;
    }
    
    /***
	* @description Get the related case
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, Case>
	*/
    public Map<Id, Equipement_sinistre__c> getRelatedEquipSin(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedCaseIdSet.add(e.Sinistre__c);
        }
        
        List<Equipement_sinistre__c> relatedEquipSin = [SELECT id, Sinistre__c
                                                        FROM Equipement_sinistre__c
                                                        WHERE Sinistre__c IN: relatedCaseIdSet
                                                        AND id NOT IN: newEquipSinList];
        
        Map<Id, Equipement_sinistre__c> relatedEquipSinMap = new Map<Id, Equipement_sinistre__c>();
        for(Equipement_sinistre__c e : relatedEquipSin){
            relatedEquipSinMap.put(e.Sinistre__c, e);
        }
        return relatedEquipSinMap;
    }
    
    /***
	* @description Get the related insured item
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, vlocity_ins__AssetInsuredItem__c>
	*/
    public Map<id, vlocity_ins__AssetInsuredItem__c> getRelatedInsuredItem(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedInsuredItemIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedInsuredItemIdSet.add(e.Equipement_client__c);
        }
        
        Map<id, vlocity_ins__AssetInsuredItem__c> relatedInsuredItempMap = 
            new Map<id, vlocity_ins__AssetInsuredItem__c>([SELECT id, Name, Date_achat__c, 
                                                           Brand_not_recognized__c, Category_not_recognized__c, 
                                                           Dernier_sinistre__c, Etat__c, Famille_produit_sinistre__c, 
                                                           LastReparationDate__c, Motif__c, Name_not_recognized__c, 
                                                           Numero_de_serie__c, IMEI_non_identifiable__c, 
                                                           Operator__c, OperatorCountry__c, Product2Id__c, 
                                                           RecordTypeId, ReparationCount__c,  
                                                           vlocity_ins__PolicyAssetId__c
                                                           FROM vlocity_ins__AssetInsuredItem__c
                                                           WHERE id IN: relatedInsuredItemIdSet]);
        return relatedInsuredItempMap;
    }
    
    /***
	* @description Get the related calcul indemnisation
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, Case>
	*/
    public Map<id, List<Mouvements_financiers__c>> getRelatedCalcIndemn(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedCaseIdSet.add(e.Sinistre__c);
        }
        
        List<Mouvements_financiers__c> calcIndemnList = [SELECT id, Case__c, Statut__c, Cout_choisi__c, 
                                                         Libelle__c, Montant__c, Type_mouvement__c
                                                         FROM Mouvements_financiers__c
                                                         WHERE Case__c IN: relatedCaseIdSet
                                                         AND (Cout_choisi__c = 'Réparation' 
                                                              OR Cout_choisi__c = 'Echange')
                                                         AND Statut__c != 'Completed' 
                                                         AND Statut__c != 'Rejected'
                                                         AND Statut__c != 'Invalidated'];
        
        Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap = new Map<id, List<Mouvements_financiers__c>>();
        for(Mouvements_financiers__c c : calcIndemnList){
            if(!relatedCalcIndemnMap.keySet().contains(c.Case__c)){
                List<Mouvements_financiers__c> tmpList = new List<Mouvements_financiers__c>();
                relatedCalcIndemnMap.put(c.Case__c, tmpList);
            }
            relatedCalcIndemnMap.get(c.Case__c).add(c);
        }
        
        return relatedCalcIndemnMap;
    }

    /***
	* @description Get the related calcul indemnisation
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, Case>
	*/
    public Map<id, List<Mouvements_financiers__c>> getRelatedCalcIndemnRepa(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedCaseIdSet.add(e.Sinistre__c);
        }
        
        List<Mouvements_financiers__c> calcIndemnList = [SELECT id, Case__c, Statut__c, Cout_choisi__c, 
                                                         Libelle__c, Montant__c, Type_mouvement__c
                                                         FROM Mouvements_financiers__c
                                                         WHERE Case__c IN: relatedCaseIdSet
                                                         AND Statut__c != 'Completed' 
                                                         AND Statut__c != 'Rejected'
                                                         AND Statut__c != 'Invalidated'];
        
        Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap = new Map<id, List<Mouvements_financiers__c>>();
        for(Mouvements_financiers__c c : calcIndemnList){
            if(!relatedCalcIndemnMap.keySet().contains(c.Case__c)){
                List<Mouvements_financiers__c> tmpList = new List<Mouvements_financiers__c>();
                relatedCalcIndemnMap.put(c.Case__c, tmpList);
            }
            relatedCalcIndemnMap.get(c.Case__c).add(c);
        }
        
        return relatedCalcIndemnMap;
    }
    
    /***
	* @description Get the related calcul indemnisation
	* @param newEquipSinList - list of new Equipement_sinistre__c
	* @return Map<id, Case>
	*/
    public Map<id, Product2> getRelatedCatalogueProduit(List<Equipement_sinistre__c> newEquipSinList){
        
        Set<id> relatedMCEIdSet = new Set<id>();
        for(Equipement_sinistre__c e : newEquipSinList){
            relatedMCEIdSet.add(e.ChooseEqp__c);
        }
        
        List<Product2> relatedCatalogueList = [SELECT id, MatriceId__c, CreatedDate
                                               FROM Product2
                                               WHERE MatriceId__c IN: relatedMCEIdSet];
        
        Map<id, Product2> relatedCatalogueProduitMap = new Map<id, Product2>();
        for(Product2 p : relatedCatalogueList){
            if(!relatedCatalogueProduitMap.keySet().contains(p.MatriceId__c) ||
               (relatedCatalogueProduitMap.keySet().contains(p.MatriceId__c) 
                && p.CreatedDate < relatedCatalogueProduitMap.get(p.MatriceId__c).CreatedDate)){
                    relatedCatalogueProduitMap.put(p.MatriceId__c, p);
                }
        }
        
        return relatedCatalogueProduitMap;
    }
     
    /***
	* @description Trigger callout to Bappli stock after reception of the order. 
	* This method is called from the flow NewActionEquipSin when the value "Destockage sur stock Réservé" is selected
	* @param List<id> eqsId eqsId set in the flow NewActionEquipSin
	* @return null
	*/
    @InvocableMethod(label = 'Get Stock From Bappli' 
                     description = 'Trigger callout to Bappli to check stock')
    public static void getStockAfterOrderReception(List<id> eqsId){
        
        Equipement_sinistre__c eqs;
        eqs = [SELECT Id, ChooseEqp__r.Id_externe__c, Grade__c, Operator__c, Sinistre__c, ClientChoiceDate__c 
               FROM Equipement_sinistre__c
               WHERE Id =: eqsId[0]
               AND RecordType.DeveloperName =: DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE];
        if(eqs != null){
        	BAppliCallout.getFromStock(BAPPLISTOCKNAME_SFAMRESA, eqs.ChooseEqp__r.Id_externe__c, eqs.Grade__c, eqs.Operator__c, eqs.Id, eqs.Sinistre__c);
        }
    }
}