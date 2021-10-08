/***
* @author Ariane Tanguy (GFI)
* @date 23/09/2020
* @description Helper class for PieceJustificative
*/

public class PieceJustificativeTriggerHelper {
    
    /***
	* @description Get the related case
	* @param newPJList - new pj lsit
	* @return Map<Id, Case>
	*/
    public static Map<Id, Case> getRelatedCase(List<Piece_justificative_Sinistre__c> newPJList){
        
        // Get the case ids
        Set<id> caseIdSet = new Set<id>();
        for(Piece_justificative_Sinistre__c p : newPJList){
            caseIdSet.add(p.Case__c);
        }
        
        Map<id, Case> relatedCaseIdMap = new Map<id, Case>([SELECT id, 
                                                            Attente_documents__c,
                                                            Attente_client_final__c, 
                                                            Status, 
                                                            TECH_MissingDocs__c
                                                            FROM Case
                                                            WHERE id IN: caseIdSet]);        
        return relatedCaseIdMap;
    }
    
    /***
	* @description Get the other related piece justificatives
	* @param newPJList - new pj list
	* @return Map<Id, Piece_justificative_Sinistre__c>
	*/
    public static Map<id, List<Piece_justificative_Sinistre__c>> getOtherRelatedPJ(List<Piece_justificative_Sinistre__c> newPJList){
        
        // Get the case ids
        Set<id> caseIdSet = new Set<id>();
        for(Piece_justificative_Sinistre__c p : newPJList){
            caseIdSet.add(p.Case__c);
        }
        
        List<Piece_justificative_Sinistre__c> relatedPJList = [SELECT id, LongTitle__c, Case__c, 
                                                               Validite_document__c, Name,NoTradable__c
                                                               FROM Piece_justificative_Sinistre__c
                                                               WHERE Case__c IN: caseIdSet
                                                               AND Validite_document__c = 'Expected'];
        
        // Map the other related pj to their case
        Map<id, List<Piece_justificative_Sinistre__c>> otherRelatedPJMap = new Map<id, List<Piece_justificative_Sinistre__c>>();
        for(Piece_justificative_Sinistre__c p : relatedPJList){
            if(!otherRelatedPJMap.keySet().contains(p.Case__c)){
                List<Piece_justificative_Sinistre__c> tmpList = new List<Piece_justificative_Sinistre__c>();
                otherRelatedPJMap.put(p.Case__c, tmpList);
            }
            otherRelatedPJMap.get(p.Case__c).add(p);
        }
        
        return otherRelatedPJMap;
    }
    
    /***
	* @description Get the related case info
	* @param newPJList - new pj lsit
	* @return Map<Id, Case>
	*/
    public static Map<Id, List<id>> getRelatedDocument(List<Piece_justificative_Sinistre__c> newPJList){
        
        // Get the case ids
        Set<id> documentIdSet = new Set<id>();
        for(Piece_justificative_Sinistre__c p : newPJList){
            if(p.Document__c != NULL){
            	documentIdSet.add(p.Document__c);
            }
        }
        
        return getRelatedContentDocument(documentIdSet);
    }
    
    /***
	* @description Get the related case info
	* @param newPJList - new pj lsit
	* @return Map<Id, Case>
	*/
    public static Map<Id, List<id>> getRelatedDocument(List<Piece_justificative_Sinistre__c> newPJList, 
                                                      Map<id, Piece_justificative_Sinistre__c> oldPJMap){
        
        // Get the case ids
        Set<id> documentIdSet = new Set<id>();
        for(Piece_justificative_Sinistre__c p : newPJList){
            if(p.Document__c != oldPJMap.get(p.id).Document__c && 
               p.Document__c != NULL){
                documentIdSet.add(p.Document__c);
            }
        }
        
        return getRelatedContentDocument(documentIdSet);
    }
    
    /***
	* @description Get the related case info
	* @param newPJList - new pj lsit
	* @return Map<Id, Case>
	*/
    private static Map<Id, List<id>> getRelatedContentDocument(Set<id> documentIdSet){
        
        Map<Id, List<id>> documentIdPjIdMap = new Map<Id, List<id>>();
        
        if(documentIdSet.size() > 0){
            
            // Find out the ContentDocumentIds
            List<ContentDocumentLink> cdLinkList = [SELECT id, ContentDocumentId, LinkedEntityId
                                                    FROM ContentDocumentLink 
                                                    WHERE LinkedEntityId IN: documentIdSet];
            
            // Find out the ContentVersionIds
            Set<id> contentDocumentIdSet = new Set<id>();
            for(ContentDocumentLink cdLink : cdLinkList){
                contentDocumentIdSet.add(cdLink.ContentDocumentId);
            }        
            List<ContentVersion> contentVersionList = [SELECT id, ContentDocumentId
                                                       FROM ContentVersion
                                                       WHERE ContentDocumentId IN: contentDocumentIdSet];
            
            // Map it to its contentDocumentId
            Map<id, ContentVersion> CDocIdCVMap = new Map<id, ContentVersion>();
            for(ContentVersion cv : contentVersionList){
                CDocIdCVMap.put(cv.ContentDocumentId, cv);
            }
            
            // Map the whole thing
            for(ContentDocumentLink cdLink : cdLinkList){
                if(!documentIdPjIdMap.keySet().contains(cdLink.LinkedEntityId)){
                    List<id> tmpList = new List<id>();
                    documentIdPjIdMap.put(cdLink.LinkedEntityId, tmpList);
                }
                documentIdPjIdMap.get(cdLink.LinkedEntityId).add(cdLink.ContentDocumentId);
                documentIdPjIdMap.get(cdLink.LinkedEntityId).add(CDocIdCVMap.get(cdLink.ContentDocumentId).id);
            }            
        }
        return documentIdPjIdMap;
    }
    
    /***
	* @description Get the piece jointes related to the case
	* @param newPJList - new pj
	* @param oldPJMap - old pj
	* @return Map<Id, String>
	*/
    public static List<Piece_justificative_Sinistre__c> getRelatedPJ(List<Piece_justificative_Sinistre__c> newPJList, 
                                                                     Map<id, Piece_justificative_Sinistre__c> oldPJMap){
        
        // Get only the changed status pj
        Set<id> changedPJList = new Set<id>();
        for(Piece_justificative_Sinistre__c p : newPJList){
            
            // If the validity is changed AND the it matches two status
            if(p.Validite_document__c != oldPJMap.get(p.id).Validite_document__c){
                changedPJList.add(p.Case__c);
            }
        }
                                                        
        system.debug('-- changedPJList ' + changedPJList);
        
        // Query the pj
        List<Piece_justificative_Sinistre__c> pjList = new List<Piece_justificative_Sinistre__c>();
        if(changedPJList.size() > 0){
            pjList = [SELECT id, Case__c, 
                      Validite_document__c,NoTradable__c
                      FROM Piece_justificative_Sinistre__c
                      WHERE Case__c IN: changedPJList];
        }
        
        pjList.addAll(newPJList);
        system.debug('-- pjList ' + pjList);
                                                                         
        return pjList;
    }
}