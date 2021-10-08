/***
* @author Ariane Tanguy (GFI)
* @date 23/09/2020
* @description PieceJustificative test class
* @Object Piece_justificative_Sinistre__c
*/

@isTest
public class PieceJustificativeTriggerHandlerTest {
    
    @testSetup 
    public static void testSetup(){
        
        // Create two types de piece justificative
        Types_piece_justificative__c t = TestFactory.createTypePJ('Permis de chasse');
        insert t;
        
        Types_piece_justificative__c t1 = TestFactory.createTypePJ('Licence de bouliste');
        insert t1;
        
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
        
        // Create a document
        Document__c d = new Document__c();
        d.Related_sinistre__c = c.id;
        insert d;
        
        // Create a new content version
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = d.id;
        insert cv;
    }
    
    /***
    * @description Update the case on pj creation
    * @see updateCaseOnCreate
    */
    @isTest
    public static void updateCaseOnCreateTest(){
        
        // Get a sinistre
        Case c = [SELECT id, TECH_MissingDocs__c FROM Case LIMIT 1];
        
        // Query the piece justificative
        List<Piece_justificative_Sinistre__c> pList = [SELECT id, Validite_document__c, LongTitle__c
                                                       FROM Piece_justificative_Sinistre__c 
                                                       WHERE Case__c =: c.id];
        
        String longTitle = pList[0].LongTitle__c;
        for(Integer i = 1; i<pList.size(); i++){
            longTitle += '\n' + pList[i].LongTitle__c ;
        }
        
        system.assertEquals(longTitle, c.TECH_MissingDocs__c, 
                            'The missing docs string shouldve been udpated - this is wrong');
        
        // Update the status
        pList[0].Validite_document__c = 'valid';        
        pList[1].Validite_document__c = 'valid';
        update pList;
        
        c = [SELECT id, Status
             FROM Case
             WHERE id =: c.id];
        system.assertEquals('En cours d\'examen', c.Status, 
                           'The case status should have been updated - This is wrong');
        
        // Add another PJ
        Types_piece_justificative__c t = TestFactory.createTypePJ('CNI');
        insert t;
        Piece_justificative_Sinistre__c pj = TestFactory.createPJ(t);
        pj.Case__c = c.id;
        insert pj;
        
        c = [SELECT id, Status FROM Case WHERE id =: c.id];
        system.assertEquals('Incomplet', c.Status, 
                           'The case status should have been changed to incomplete - This is wrong');
    }
    
    /***
    * @description Update the PJ on creation
    * @see updateCaseOnCreate
    */
    @isTest
    public static void updatePJOnCreateTest(){
        
        // Get a sinistre
        Case c = [SELECT id FROM Case LIMIT 1];
        
        // Get a document
        ContentVersion cv = [SELECT id, FirstPublishLocationId 
                             FROM ContentVersion LIMIT 1];
        
        // Query the piece justificative
        Piece_justificative_Sinistre__c pj = [SELECT id, Validite_document__c 
                                              FROM Piece_justificative_Sinistre__c 
                                              WHERE Name = 'Permis de chasse'];
        
        // Add the document
        pj.Document__c = cv.FirstPublishLocationId;
        update pj;
        
        pj = [SELECT id, ContentDocumentId__c, ContentVersionId__c
             FROM Piece_justificative_Sinistre__c
             WHERE id =: pj.id];
        system.assertEquals(cv.id, pj.ContentVersionId__c, 
                           'The PJ shouldve been updated with ContentVersion info - This is wrong');
    }
    
    /***
    * @description Update the Case on update
    * @see updateCaseOnUpdate
    */
    @isTest
    public static void updateCaseOnUpdateTest(){
        
        // Get a sinistre
        Case c = [SELECT id FROM Case LIMIT 1];
        c.Status = 'Attribué';
        update c;
        
        // Get a document
        Document__c d = [SELECT id FROM Document__c LIMIT 1];
        
        // Query the piece justificative
        Piece_justificative_Sinistre__c pj = [SELECT id, Validite_document__c 
                                              FROM Piece_justificative_Sinistre__c 
                                              WHERE Name = 'Permis de chasse'];
        
        // Add the document
        pj.Document__c = d.id;
        pj.Validite_document__c = 'received';
        update pj;
        
        c = [SELECT id, Status
             FROM Case
             WHERE id =: c.id];
        system.assertEquals('Incomplet', c.Status, 
                           'The case status should have been changed to incomplete - This is wrong');
    }
    
    /***
    * @description Update the case on pj modification
    * @see createNewPJ
    */
    @isTest
    public static void createNewPJTest(){
                
        // Query the piece justificative
        Piece_justificative_Sinistre__c pj = [SELECT id, Validite_document__c 
                                              FROM Piece_justificative_Sinistre__c 
                                              WHERE Name = 'Permis de chasse'];
        
        // The current pj is not valid
        pj.Validite_document__c = 'invalid';
        update pj;
        
        List<Piece_justificative_Sinistre__c> pjList = [SELECT id, Validite_document__c
                                                        FROM Piece_justificative_Sinistre__c
                                                        WHERE Name = 'Permis de chasse'];
        
        system.assertEquals('Invalid', pjList[0].Validite_document__c, 
                            'The previous pj shouldnt be valid anymore - This is wrong');
        system.assertEquals('Expected', pjList[1].Validite_document__c, 
                            'The new pj should be needed - This is wrong');
    }
    
    /***
    * @description Update the case on pj modification
    * @see updateSinistreOnUpdate
    */
    @isTest
    public static void updateSinistreOnUpdateTest(){
        
        test.startTest();
        
        // Get a sinistre
        Case c = [SELECT id FROM Case LIMIT 1];
        
        // Set an owner
        c.Status = 'Attribué';
        update c;
        
        // Query the piece justificative
        List<Piece_justificative_Sinistre__c> pList = [SELECT id, Validite_document__c 
                                                       FROM Piece_justificative_Sinistre__c 
                                                       WHERE Case__c =: c.id];
        pList[0].Validite_document__c = 'received';
        update pList;
        
        test.stopTest();
        
        // Update the status again
        for(Piece_justificative_Sinistre__c p : pList){
            p.Validite_document__c = 'valid';
        }
        update pList;
        
        c = [SELECT id, Status
             FROM Case
             WHERE id =: c.id];
        system.assertEquals('En cours d\'examen', c.Status, 
                           'The case status should have been updated - This is wrong');
    }

    /***
    * @description Update the case on pj modification
    * @see updateSinistreOnUpdate
    */
    @isTest
    public static void manageAlertNotNeededTest(){
        
        test.startTest();
        
        // Get a sinistre
        Case c = [SELECT id FROM Case LIMIT 1];
        
        // Set an owner
        c.Status = 'Attribué';
        update c;
        
        // Query the piece justificative
        List<Piece_justificative_Sinistre__c> pList = [SELECT id, Validite_document__c,Case__c
                                                       FROM Piece_justificative_Sinistre__c 
                                                       WHERE Case__c =: c.id];
        pList[0].Validite_document__c = 'NotNeeded';
        update pList;
        
        test.stopTest();
        
        Alert__c al = [SELECT Id,BusinessRulesNumber__c
                FROM Alert__c 
                WHERE Case__c =: c.id
                AND BusinessRulesNumber__c='RGSIN24'];
        system.assertEquals('RGSIN24', al.BusinessRulesNumber__c, 
                           'Not alert created');
    }
}