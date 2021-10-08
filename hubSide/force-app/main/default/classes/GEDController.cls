/***
* @author Ariane Tanguy (GFI)
* @date 14/10/2020
* @description GED LWC Controller
*/
public with sharing class GEDController {

    /***
    * @description Get the current user profile
    * @return boolean - true if the profile can edit the picklist
    */
    @AuraEnabled(cacheable=true)
    public static boolean getUserProfile() {
        
        boolean canEdit = true;
        
        // Get the related sinistre id
        User u = [SELECT Profile.Name 
                  FROM User
                  WHERE id =: system.UserInfo.getUserId()];
        
        if(u.Profile.Name == 'SFAM TC'){
            canEdit = false;
        }
        return canEdit;
    }
    
    /***
    * @description Get all the case related files
    * @param caseId - case id
    * @return Map<String, String> - contentDocument DistributionPublicUrl mapped to the document title
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getRelatedFilesByRecordId(String caseId) {
        
        // Check whether the case has an email
        List<EmailMessage> emailMessageList = [SELECT id
                                               FROM EmailMessage
                                               WHERE RelatedToId =: caseId];
        
        Set<id> linkedIdSet = new Set<id>();
        linkedIdSet.add(caseId);
        for(EmailMessage em : emailMessageList){
            linkedIdSet.add(em.id);
        }
        
        // Get all the related contentDocument ids
        List<ContentDocumentLink> cdLinkList = [SELECT ContentDocumentId
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN :linkedIdSet];
        
        Set<ID> cdIdSet = new Set<ID>();
        for (ContentDocumentLink cdLink : cdLinkList) {
            cdIdSet.add(cdLink.ContentDocumentId);
        }
        
        // Filter PDF files 
        List<ContentVersion> CVList = [SELECT ContentDocumentId, FileExtension, Title 
                                       FROM ContentVersion 
                                       WHERE ContentDocumentId IN : cdIdSet 
                                       AND FileExtension = 'pdf'];
        
        // And add the other file types 
        List<ContentDistribution> cdList = [SELECT id, DistributionPublicUrl, Name, ContentVersionId
                                            FROM ContentDistribution
                                            WHERE ContentDocumentId IN: cdIdSet];
        
        Map<String, String> mapIdTitle = new Map<String, String>();
        Set<id> ContentVersionIdSet = new Set<id>();
        for (ContentDistribution cd : cdList) {
            if(!ContentVersionIdSet.contains(cd.ContentVersionId)){
                mapIdTitle.put(cd.DistributionPublicUrl, cd.Name.substringBefore(' '));
                ContentVersionIdSet.add(cd.ContentVersionId);
            }
        }
        
        return mapIdTitle;
    }

    /***
    * @description Get all the case related piece justificatives
    * @param documentId - document__c id
    * @return Map<String, String> - pj id mapped to pj name
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPJMap(String documentId) {
        
        // Get the related sinistre id
        id sinistreId = [SELECT Related_sinistre__c 
                         FROM Document__c
                         WHERE id =: documentId].Related_sinistre__c;
        
        Map<String, String> pjNameValidityMap = new Map<String, String>();
        for(Piece_justificative_Sinistre__c pj : [SELECT Id, Name, Validite_document__c
                                                  FROM Piece_justificative_Sinistre__c
                                                  WHERE Case__c =: sinistreId
                                                  AND Validite_document__c != 'invalid']){
                                                      pjNameValidityMap.put(pj.Id, pj.Name);                                                      
                                                  }
        return pjNameValidityMap;
    }

    /***
    * @description Get all the case related piece justificatives
    * @param documentId - document__c id
    * @return List<Piece_justificative_Sinistre__c> - Related pj list
    */
    @AuraEnabled(cacheable=true)
    public static List<Piece_justificative_Sinistre__c> getPJList(String documentId) {
        
        // Get the related sinistre id
        id sinistreId = [SELECT Related_sinistre__c 
                         FROM Document__c
                         WHERE id =: documentId].Related_sinistre__c;
        
        List<Piece_justificative_Sinistre__c> pjList = [SELECT Id, Name, Validite_document__c
                                                        FROM Piece_justificative_Sinistre__c
                                                        WHERE Case__c =: sinistreId
                                                        AND Validite_document__c != 'invalid'];
        return pjList;
    }

    /***
    * @description Get the validité document picklist values
    * @param - NA
    * @return Map<String, String> - picklist label mapped to picklist values
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPJOptions() {
        
        return(getPicklistValues(new Piece_justificative_Sinistre__c(), 
                                 'Validite_document__c'));
    }
    
    /***
	* @description Get the picklist values of an object
	* @param sObj
	* @param picklistField
	* @return Map<String, String>
	*/
    private static Map<String, String> getPicklistValues(SObject sObj, String picklistField){
        
        // Get a map of fields for the SObject
        Map<String, Schema.SObjectField> fieldMap = sObj.getSObjectType().getDescribe().fields.getMap();       
        
        // Get the list of picklist values for this field.
        List<Schema.PicklistEntry> picklistValueList = fieldMap.get(picklistField).getDescribe().getPickListValues();
        
        // Map these values
        Map<String, String> picklistValueMap = new Map<String, String>();
        for (Schema.PicklistEntry p : picklistValueList){ 
            picklistValueMap.put(p.getLabel(), p.getValue()); 
        }
        
        return picklistValueMap;
    }
    
    /***
	* @description Update PJ on the fly
	* @param pjId - pj id
	* @param newValidity - new picklist value
	* @return void
	*/
    @AuraEnabled
    public static void updatePJ(String pjId, String newValidity, String documentId) {
        
		// Get PJ
        Piece_justificative_Sinistre__c pj = [SELECT Id, Validite_document__c, Document__c
                                              FROM Piece_justificative_Sinistre__c
                                              WHERE id =: pjId.substringBefore('-')];
        
        // Unlink the document if the pj is not there anymore
        if(newValidity == 'expected'){
            pj.Document__c = NULL;
        } else {
            pj.Document__c = documentId;
        }
        
        if(newValidity == 'Valid'){
            pj.ValidationDate__c = system.today();
        } 
        
        pj.Validite_document__c = newValidity;
        pj.Valideur__c = system.UserInfo.getUserId();
        update pj;
    }
}