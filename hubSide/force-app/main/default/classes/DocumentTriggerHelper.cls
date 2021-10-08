/***
* @author Ariane Tanguy (GFI)
* @date 19/11/2020
* @description Helper class for DocumentTrigger
*/

public class DocumentTriggerHelper {
    
    /***
	* @description Get all the related cases
	* @param newDocumentList - list of document
	* @return Map<id, Case> - Map of the case and their id
	*/
    public static Map<id, Case> getRelatedCase(List<Document__c> newDocumentList){
        
        // List sinistre ids
        Set<id> sinistreIdSet = new Set<id>();
        for(Document__c d : newDocumentList){
            sinistreIdSet.add(d.Related_sinistre__c);
        }
        
        // Query the emprunts
        return new Map<id, Case>([SELECT id, Attente_action_GS__c
                                  FROM Case
                                  WHERE Id IN: sinistreIdSet
                                  AND Attente_action_GS__c = TRUE]);
    }
    
    /***
	* @description Get all the related cases
	* @param documentList - list of document
	* @return Map<id, Case> - Map of the case and their id
	*/
    public static List<Document__c> getRelatedDocument(List<Document__c> newDocumentList, Set<id> caseIdSet){
        
        // Query the documents
        List<Document__c> otherDocumentList = [SELECT id, Related_sinistre__c, Statut__c
                                               FROM Document__c
                                               WHERE Related_sinistre__c IN: caseIdSet
                                               AND id NOT IN: newDocumentList];
        otherDocumentList.addAll(newDocumentList);
        
        return otherDocumentList;
    }
}