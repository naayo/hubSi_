/***
* @author Ariane Tanguy (GFI)
* @date 19/11/2020
* @description Handler class for DocumentTrigger
*/

public class DocumentTriggerHandler {
    
    static final String STATUS_ATTACHED = 'Attached';
	static final String ORIGINDOCUMENT_MAIL = 'Courrier';
        
    /***
	* @description Update attente GS on case
	* @param newDocumentList - list of all new document
	* @param relatedCaseMap - Map of the related cases and their id
	*/
    public static void updateCaseOnUpdate(List<Document__c> newDocumentList, Map<id, Case> relatedCaseMap){
        
        // Map document to their sinistre
        Map<id, List<Document__c>> sinistreIdDocumentListMap = new Map<id, List<Document__c>>();
        for(Document__c d : newDocumentList){
            if(!sinistreIdDocumentListMap.keySet().contains(d.Related_sinistre__c)){
                List<Document__c> tmpList = new List<Document__c>();
                sinistreIdDocumentListMap.put(d.Related_sinistre__c, tmpList);
            }
            sinistreIdDocumentListMap.get(d.Related_sinistre__c).add(d);
        }
        
        // Check whether all the documents are codified
        List<Case> caseToUpdate = new List<Case>();
        for(Id sinistreId : sinistreIdDocumentListMap.keySet()){
            
            // Loop over all the documents in that sinistre
            Boolean allCodified = TRUE;
            for(Document__c d : sinistreIdDocumentListMap.get(sinistreId)){
                if(d.Statut__c != 'codified'){
                    allCodified = FALSE;
                }
            }
            
            // If all the documents are codified, update the flag
            if(allCodified 
               && relatedCaseMap.keySet().contains(sinistreId)){
                   relatedCaseMap.get(sinistreId).Attente_action_GS__c = FALSE;
                   caseToUpdate.add(relatedCaseMap.get(sinistreId));
               }
        }
        
        update caseToUpdate;
    }
    
    /***
	* @description delete content documents related to Document__c if removed status
	* @param newDocumentList - list of all new document
	*/
    public static void deleteContentDocumentIfRemovedStatus(List<Document__c> newDocumentList){
        for(Document__c d : newDocumentList){
            if (d.Statut__c == 'Removed') {
                // Find content document Ids
                List<ContentDocumentLink> cdLinkList = [SELECT ContentDocumentId
                                                        FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId =: d.id];

                Set<id> contentDocumentIdSet = new Set<id>();
                for(ContentDocumentLink cdLink : cdLinkList){
                    contentDocumentIdSet.add(cdLink.ContentDocumentId);
                }
                
                // Find content documents
                List<ContentDocument> cdList = [SELECT Id
                                                FROM ContentDocument
                                                WHERE Id IN: contentDocumentIdSet];


                if (cdList.size() > 0) {
                    delete cdList;
                }
            }
        }        
    }
}