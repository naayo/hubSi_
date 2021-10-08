/***
* @author Ariane Tanguy (GFI)
* @date 19/11/2020
* @description AssetTrigger test class
* @Object Document__c
*/

@isTest
public class DocumentTriggerHandlerTest {
    
    /***
    * @description Update attente GS on case
    * @see updateCaseOnUpdate
    */
    @isTest
    public static void updateCaseOnUpdateTest(){
        
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
        
        // Create a document
        Document__c d = new Document__c();
        d.Name = 'MaLicence.pdf';
        d.Related_sinistre__c = c.id;
        d.Statut__c = 'attached';
        insert d;
        
        // Query the case
        c = [SELECT id, Attente_action_GS__c
             FROM Case
             WHERE id =: c.id];
        
        system.assertEquals(TRUE, c.Attente_action_GS__c, 
                           'There should still be an action pending on the GS side - This is wrong');
        
        // Update the document's status
        d.Statut__c = 'codified';
        update d;
        
        // Query the case
        c = [SELECT id, Attente_action_GS__c
             FROM Case
             WHERE id =: c.id];
        
        system.assertEquals(FALSE, c.Attente_action_GS__c, 
                           'There shouldnt be an action pending on the GS side - This is wrong');
    }
    
    /***
    * @description Update attente GS on case
    * @see updateCaseOnUpdate
    */
    @isTest
    public static void  deleteContentDocumentIfRemovedStatusTest(){
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;

        // Create a document
        Document__c d = new Document__c();
        d.Name = 'MaLicence.pdf';
        d.Related_sinistre__c = c.id;
        d.Statut__c = 'attached';
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

        d.Statut__c = 'Removed';
        update d;
        
        // Query the ContentDocumentLink
        List<ContentDocumentLink> cdlAfterUpdate = [SELECT Id
             FROM ContentDocumentLink
             WHERE LinkedEntityId =: d.id];
        
        system.assert(cdlAfterUpdate.size() == 0, 'ContentDocumentLink has not been removed');
        
        // Query the ContentDocument
        List<ContentDocument> cdAfterUpdate = [SELECT Id
             FROM ContentDocument
             WHERE Id =: cv.ContentDocumentId];
        
        system.assert(cdAfterUpdate.size() == 0, 'ContentDocument has not been removed');
        
        // Query the ContentVersion
        List<ContentVersion> cvAfterUpdate = [SELECT Id
             FROM ContentVersion
             WHERE Id =: cv.ContentDocumentId];
        
        system.assert(cvAfterUpdate.size() == 0, 'ContentDocument has not been removed');
    }
}