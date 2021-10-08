/***
* @author Ariane Tanguy (GFI)
* @date 27/11/2020
* @description Sinistre_BordereauEquipSinController test class
* @VFP Sinistre_BordereauEquipementSinistre
*/

@isTest
public class Sinistre_BordereauEquipSinControllerTest {
    
    /***
	* @description Check whether the custom controller does the job
	* @see Sinistre_BordereauColis
	*/
    @isTest
    public static void Sinistre_BordereauEquipSinTest(){
        
        // Create three sinistre
        List<Case> caseList = new List<Case>();
        for(integer i=0; i<3; i++){
            Case c = TestFactory.createSinistre();
            caseList.add(c);
        }
        insert caseList;
        
        // Create three equipement sinistre
        List<Equipement_sinistre__c> equipList = new List<Equipement_sinistre__c>();
        for(integer i=0; i<3; i++){
            Equipement_sinistre__c e = new Equipement_sinistre__c();
            e.Name = 'Apple-Iphone6';
            e.Sinistre__c = caseList[i].id;
            equipList.add(e);
        }
        insert equipList;
        
        List<Name__c> equipHistory = new List<Name__c>();
        for(integer i=0; i<3; i++){
            Name__c hist = new Name__c();
            hist.Name = 'Old Status';
            hist.Equipement_sinistre__c = equipList.get(i).id;
            equipHistory.add(hist);
        }
        insert equipHistory;
        
        Equipement_sinistre__c e = [SELECT Statut_equipement__c
                                    FROM Equipement_sinistre__c
                                    WHERE id =: equipList[0].id];
        system.assertEquals('En Analyse', e.Statut_equipement__c);
        
        // Create a VFP
        PageReference pageRef = Page.Sinistre_BordereauEquipementSinistre;
        Test.setCurrentPage(pageRef);
        
        Sinistre_BordereauEquipSinController sC = new Sinistre_BordereauEquipSinController();
        system.assertEquals(0, sC.getSinistreColumn1().size(), 
                           'There should be no returned sinistre - This is wrong');
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('newStatus', 'En Analyse');
        sC = new Sinistre_BordereauEquipSinController();
        
        system.assertEquals('En Analyse', sC.getNewStatus(), 
                           'The new status shouldve been updated - This is wrong');
        system.assertEquals(NULL, sC.getNewSousStatus(), 
                           'The new sous status should be null - This is wrong');
        
        // Check the display column
        system.assertEquals('INS000002', sC.getSinistreColumn2()[0].Sinistre__r.Numero_Sinistre__c, 
                           'The display column should contain the created sinistre - This is wrong');
        system.assertEquals('INS000003', sC.getSinistreColumn3()[0].Sinistre__r.Numero_Sinistre__c, 
                           'The third display column should contain the created sinistre - This is wrong');
        
    }
}