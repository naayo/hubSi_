/***
* @author Pierre-Mickael BARRAL (INETUM)
* @date 15/07/2021
* @description LWC_PJManageStatusTest
* DATE          DEV         DESCRIPTION
* 15/07/2021    PMB         Inital version
*/
@isTest
public with sharing class LWC_PJManageStatusTest {
    @testSetup static void init() {
        
        // Create two types de piece justificative
        Types_piece_justificative__c t = TestFactory.createTypePJ('CNI');
        insert t;
        
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;

        Piece_justificative_Sinistre__c pj = TestFactory.createPJ(t);
        pj.Case__c = c.id;
        insert pj;
        
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

    @isTest
    public static void getPJTest(){
        Document__c doc = [SELECT Id FROM Document__c];
        List<Piece_justificative_Sinistre__c> lstPiece = [SELECT Id FROM Piece_justificative_Sinistre__c];
        
        test.startTest();
        system.assertEquals(LWC_PJManageStatus.getPJ(doc.Id).size(), lstPiece.size(), 
                                'No piece found');
        test.stopTest();
    }

    @isTest
    public static void updatPJTest(){
        Document__c doc = [SELECT Id FROM Document__c];
        List<Piece_justificative_Sinistre__c> lstPiece = [SELECT Id FROM Piece_justificative_Sinistre__c];
        List<LWC_PJManageStatus.WrapperManageStatus> listwrapperUpdated = new List<LWC_PJManageStatus.WrapperManageStatus>();
        List<LWC_PJManageStatus.WrapperManageStatus> listwrapper = LWC_PJManageStatus.getPJ(doc.Id);
        test.startTest();
        for(LWC_PJManageStatus.WrapperManageStatus wr : listwrapper){
            wr.status = 'Valid';
            listwrapperUpdated.add(wr);
        }
        system.assertEquals(LWC_PJManageStatus.updatePJ(listwrapperUpdated,doc.Id), 'OK', 
                                'Piece not updated');
        test.stopTest();
    }
}