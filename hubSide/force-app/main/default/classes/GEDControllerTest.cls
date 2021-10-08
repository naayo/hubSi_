/***
* @author Ariane Tanguy (GFI)
* @date 11/02/2021
* @description GEDController
* @LWC showPdfRelatedToRecordId
* @LWC showPJList
*/

@isTest
public class GEDControllerTest {
    
    /***
    * @description Get the current user profile
    * @see getUserProfile
    */
    @isTest
    public static void getUserProfileTest(){
        
        system.assert(GEDController.getUserProfile(), 
                      'The sys admin should have access - This is wrong');
        
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id FROM Profile WHERE name =: 'SFAM TC'].Id;
        insert u;
        
        system.runAs(u){
            system.assert(!GEDController.getUserProfile(), 
                      'The TC shouldnt have access - This is wrong');
        }
    }
    
    /***
    * @description Get all the case related files
    * @see getRelatedFilesByRecordId
    */
    @isTest
    public static void getRelatedFilesByRecordIdTest(){
        
        // Create a case GED
        Case c = new Case();
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Affectation_document');
        insert c;
        
        // Create an EmailMessage
        EmailMessage em = new EmailMessage();
        em.ParentId = c.id;
        insert em;
        
        // Create a new content version
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestDocument';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('TestContent');
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = em.id;
        insert cv;
        
        // Get all the related contentDocument ids
        Map<String, String> mapIdTitle = GEDController.getRelatedFilesByRecordId(c.id);
        system.assertEquals(1, mapIdTitle.keySet().size(), 'There should be one document mapped - This is wrong');
    }
    
    /***
    * @description Get all the case related piece justificatives
    * + Update PJ on the fly
    * @see getPJMap + getPJList + updatePJTest
    */
    @isTest
    public static void getPJTest(){
        
        // Create a type de piece justificative
        Types_piece_justificative__c t = new Types_piece_justificative__c();
        t.Perte__c = TRUE;
        t.Name = 'Permis de chasse';
        insert t;
        
        // Create a sinistre
        Case c = new Case();
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        c.Typologie_Sinistre__c = 'lost';
        insert c;
        
        // Create a document
        Document__c d = new Document__c();
        d.Related_sinistre__c = c.id;
        insert d;
        
        // Get all the related contentDocument ids
        List<Piece_justificative_Sinistre__c> pjList = GEDController.getPJList(d.id);
        system.assertEquals(t.Name, pjList[0].Name, 'The pj should be Permis de chasse - This is wrong');
        
        Map<String, String> pjNameValidityMap = GEDController.getPJMap(d.id);
        system.assertEquals(1, pjNameValidityMap.keySet().size(), 'There should be one pj mapped - This is wrong');
        
        // Get the created PJ
        Piece_justificative_Sinistre__c pj = [SELECT Id, Validite_document__c, Document__c
                                              FROM Piece_justificative_Sinistre__c
                                              WHERE Case__c =: c.id];
        
        GEDController.updatePJ(pj.id, 'Received', d.id);
        
        pj = [SELECT Id, Validite_document__c, Document__c
              FROM Piece_justificative_Sinistre__c
              WHERE Case__c =: c.id];
        
        system.assertEquals('Received', pj.Validite_document__c, 'The pj validity shouldve been updated - This is wrong');
    }
    
    /***
    * @description Get the validité document picklist values
    * @see getPicklistValues + getPJOptions
    */
    @isTest
    public static void getPJOptionsTest(){
        
        // Get all the related contentDocument ids
        Map<String, String> pjOptionMap = GEDController.getPJOptions();
        system.assertEquals(5, pjOptionMap.keySet().size(), 'There should be 5 pj status - This is wrong');
        system.assert(pjOptionMap.keySet().contains('1-Attendue'), 'There should be an expected status - This is wrong');
    }
}