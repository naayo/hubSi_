/***
* @author Ariane Tanguy (GFI)
* @date 20/10/2020
* @description Helper class for ContentDocumentLinkTrigger
*/

public class ContentDocumentLinkTriggerHelper {
    
    /***
	* @description Get the related ContentVersion
	* @param newCDList - list of ContentDocument
	* @return List<ContentVersion>
	*/
    public static List<ContentVersion> getRelatedCDVersion(List<ContentDocumentLink> newCDLinkList){
        
        // Only get the relevant ids (linkedEntity = Document__c)
        Set<id> cdIdSet = new Set<id>();
        for(ContentDocumentLink cdLink : newCDLinkList){
             if(cdLink.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Document__c' ||
               cdLink.LinkedEntityId.getSObjectType().getDescribe().getName() == 'EmailMessage'){
                 cdIdSet.add(cdLink.ContentDocumentId);
             }
        }
        
        // Get the related CDVersion 
        List<ContentVersion> cVList = [SELECT id, Title
                                       FROM ContentVersion
                                       WHERE ContentDocumentId IN: cdIdSet];
        
        return cVList;
    }
}