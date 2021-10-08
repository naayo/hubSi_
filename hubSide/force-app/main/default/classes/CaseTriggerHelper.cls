/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Helper class for CaseTrigger
*/

public class CaseTriggerHelper {
    
    /***
	* @description Check all the case tech_numsin__c and assign the max
	* @return Decimal
	*/
    public static Map<String, Decimal> getMaxNumber(List<Case> newCaseList){
        
        // Get the recordTypes
        Set<String> caseRTIdSet = new Set<String>();
        for(Case c : newCaseList){
            caseRTIdSet.add(c.Record_type_Name__c);
            if(c.Record_type_Name__c == 'Sinistre'){
                caseRTIdSet.add('Sinistre clôturé');
            }
        }
        
        Map<String, Decimal> maxNumberMap = new Map<String, Decimal>();
        for(String cId : caseRTIdSet){
            List<Case> c = [SELECT id, tech_numsin__c 
                            FROM Case 
                            WHERE Record_type_name__c =: cId
                            AND vlocity_ins__Verified__c = FALSE
                            ORDER BY tech_numsin__c DESC LIMIT 1];
            if(c.size() > 0){
                maxNumberMap.put(cId, c[0].tech_numsin__c);
            }
        }
        
        return maxNumberMap;
    }

    /***
	* @description get id dispatch sinistre
	* @return Id
	*/
    public static Id getQueueIdDispatchSin(){
        Group gr = [SELECT Id FROM Group WHERE DeveloperName = 'Dispatch_sinistre' and Type = 'Queue' LIMIT 1];
        return gr.Id;
    }
    
    /***
	* @description Get the asset's related account
	* @return Map<id, Account>
	*/
    public static Map<id, Asset> getRelatedAccount(List<Case> newCaseList){
        
        // Get the account ids
        Set<id> assetIdSet = new Set<id>();
        for(Case c : newCaseList){
            assetIdSet.add(c.AssetId);
        }
        
        Map<id, Asset> relatedAssetMap = new Map<id, Asset>([SELECT id, AccountId
                                                             FROM Asset
                                                             WHERE id IN: assetIdSet]);
        return relatedAssetMap;
    }
    
    /***
	* @description Get the related documents
	* @return Map<id, List<Document__c>>
	*/
    public static Map<id, List<Document__c>> getRelatedDocument(List<Case> newCaseList){
        
        // Get the related documents
        List<Document__c> relatedDocumentList = [SELECT id, Related_sinistre__c
                                                FROM Document__c
                                                WHERE Related_sinistre__c IN: newCaseList];
        
        Map<id, List<Document__c>> caseIdDocumentMap = new Map<id, List<Document__c>>();
        for(Document__c d : relatedDocumentList){
            if(!caseIdDocumentMap.keySet().contains(d.Related_sinistre__c)){
                List<Document__c> tmpList = new List<Document__c>();
                caseIdDocumentMap.put(d.Related_sinistre__c, tmpList);
            }
            caseIdDocumentMap.get(d.Related_sinistre__c).add(d);
        }        
        
        return caseIdDocumentMap;
    }
    
    /***
	* @description Get all the related pieces justificatives
	* @param newCaseList - list of new cases
	* @return Map<String, List<Types_piece_justificative__c>>
	*/
    public static Map<String, List<Types_piece_justificative__c>> getRelatedPieceJustificative(List<Case> newCaseList){
                       
        // Query the sinistre cases
        List<Types_piece_justificative__c> relatedPieceJustificativeList = [SELECT id, Name, 
                                                                            LongTitle__c, 
                                                                            Oxydation__c, 
                                                                            Casse__c, 
                                                                            Vol_caracterise__c, 
                                                                            Vol_toute_cause__c, 
                                                                            Perte__c,
                                                                            NoTradable__c
                                                                            FROM Types_piece_justificative__c];
        
        // Map the whole thing 
        Map<String, List<Types_piece_justificative__c>> typologyPieceJustificativeMap = new Map<String, List<Types_piece_justificative__c>>();
        for(Case c : newCaseList){
            
            if(!typologyPieceJustificativeMap.keySet().contains(c.Typologie_Sinistre__c) &&
               c.Typologie_Sinistre__c != NULL){
                   List<Types_piece_justificative__c> tmpList = new List<Types_piece_justificative__c>();
                   typologyPieceJustificativeMap.put(c.Typologie_Sinistre__c, tmpList);
               } else {
                   continue;
               }
            
            for(Types_piece_justificative__c t : relatedPieceJustificativeList){
                
                if((t.Oxydation__c && c.Typologie_Sinistre__c.contains('Oxidised')) ||
                   (t.Casse__c && c.Typologie_Sinistre__c == 'Broken') ||
                   (t.Vol_caracterise__c && c.Typologie_Sinistre__c == 'Robbed') ||
                   (t.Vol_toute_cause__c && c.Typologie_Sinistre__c == 'Pickpocketed') ||
                   (t.Perte__c && c.Typologie_Sinistre__c == 'Lost')){
                       typologyPieceJustificativeMap.get(c.Typologie_Sinistre__c).add(t);
                   }
            }
        }
        
        return typologyPieceJustificativeMap;
    }
    
    /***
	* @description Get all related equipement sinistre
	* @return Map<id, List<Equipement_sinistre__c>>
	*/
    public static Map<id, List<Equipement_sinistre__c>> getRelatedEquipSin(List<Case> newCaseList){
        
        List<Equipement_sinistre__c> relatedEquipSinList = [SELECT id, Name, Equipement_client__r.Name, Sinistre__c
                                                            FROM Equipement_sinistre__c
                                                            WHERE Sinistre__c IN: newCaseList];
        
        Map<id, List<Equipement_sinistre__c>> relatedEquipSinMap = new Map<id, List<Equipement_sinistre__c>>();
        for(Equipement_sinistre__c e : relatedEquipSinList){
            if(!relatedEquipSinMap.keySet().contains(e.Sinistre__c)){
                List<Equipement_sinistre__c> tmpList = new List<Equipement_sinistre__c>();
                relatedEquipSinMap.put(e.Sinistre__c, tmpList);
            }
            relatedEquipSinMap.get(e.Sinistre__c).add(e);
        }
        
        return relatedEquipSinMap;
    }
}