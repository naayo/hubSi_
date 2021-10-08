/***
* @author Ariane Tanguy (GFI)
* @date 11/01/2020
* @description DeclaWeb_MassValidationController test class
* @Class DeclaWeb_MassValidationControllerTest
*/

@isTest
public class DeclaWeb_MassValidationControllerTest {
    
    /***
	* @description Mass validate declaration web
	* @LightningComponent DeclaWeb_MassValidationController
	*/
    @isTest
    public static void updateCaseTest(){
        
        // Create a client
        Account a = TestFactory.createClient();
        insert a;
                
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        
        // Create a sinistre
        Case c = new Case();
        c.AccountId = a.id;
        c.Typologie_Sinistre__c = 'Broken';
        c.RecordTypeId = caseSinistreId;
        insert c;
        
        // And another one
        Case c1 = new Case();
        c1.AccountId = a.id;
        c1.Typologie_Sinistre__c = 'Broken';
        c1.RecordTypeId = caseSinistreId;
        insert c1;
        
        List<Case> caseList = new List<Case>{c, c1};
        
        // Create a VFP
        PageReference pageRef = Page.DeclaWeb_MassValidation;
        Test.setCurrentPage(pageRef);
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', c.id);
        system.assertEquals(c.Id, ApexPages.currentPage().getParameters().get('id'));
        
        ApexPages.StandardSetController sC = new ApexPages.StandardSetController(caseList);
        sC.setSelected(caseList);
        DeclaWeb_MassValidationController d = new DeclaWeb_MassValidationController(sC);
        d.getCases();
        d.updateCases();
        
        c = [SELECT id, Status FROM Case WHERE id =: c.id];
        system.assertEquals('Valid', c.Status, 
                           'The case status shouldve been changed - This is wrong');
    }
}