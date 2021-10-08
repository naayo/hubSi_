/***
* @author Ariane Tanguy (GFI)
* @date 20/10/2020
* @description ContentDocumentLinkTrigger test class
* @Object ContentDocument
*/

@isTest
public class ContentDocumentLinkTriggerHandlerTest {
    
    /***
	* @description Create a new ContentDistribution on ContentDocumentLink creation
	* @see createContentDistribution
	*/
    @isTest
    public static void createContentDistributionTest(){
        
        // Create a Document__c
        Document__c d = new Document__c();
        insert d;
        
        // Create a new content version
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = d.id;
        insert cv;
        
        // Get Content Version
        cv = [SELECT Id, Title, ContentDocumentId 
              FROM ContentVersion 
              WHERE Id = :cv.Id];        
        List<ContentDocumentLink> cdLinkList = [SELECT id, LinkedEntityId 
                                                FROM ContentDocumentLink 
                                                WHERE ContentDocumentId =: cv.ContentDocumentId];
        Set<String> linkedEntityIdSet = new Set<String>();
        for(ContentDocumentLink cdLink : cdLinkList){
            linkedEntityIdSet.add(cdLink.LinkedEntityId.getSObjectType().getDescribe().getName());
        }
        system.assert(linkedEntityIdSet.contains('Document__c'), 
                            'There should be at least one cdlink related to a document - This is wrong');
        
        // Check whether the public link has been generated
        ContentDistribution cd = [SELECT id, ContentVersionId 
                                  FROM ContentDistribution 
                                  WHERE ContentDocumentId =: cv.ContentDocumentId];
        system.assert(cd.ContentVersionId == cv.id, 
                     'A new ContentDistribution should have been created - This is wrong');        
    }
}