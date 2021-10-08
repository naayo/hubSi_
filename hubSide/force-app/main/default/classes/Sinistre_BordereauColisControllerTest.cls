/***
* @author Ariane Tanguy (GFI)
* @date 27/11/2020
* @description Sinistre_BordereauColisController test class
* @VFP Sinistre_BordereauColis
*/

@isTest
public class Sinistre_BordereauColisControllerTest {
    
    /***
    * @description Check whether the custom controller does the job
    * @see Sinistre_BordereauColis
    */
    @isTest
    public static void Sinistre_BordereauColisTest(){
        
        // Create a Reception Colis
        Reception_colis__c rc = new Reception_colis__c();
        rc.Name = 'La Poste - SAV - ' +  system.today();
        rc.Date_reception__c = system.today();
        rc.Nombre_colis_scannes__c = 1;
        insert rc;
        
        // Create three colis
        List<Colis__c> colisList = new List<Colis__c>();
        for(Integer i = 0; i<3; i++){
            Colis__c c = new Colis__c();
            c.Name = 'HJDFK78976KJHFD' + i;
            c.Reception_colis__c = rc.id;
            colisList.add(c);
        }
        insert colisList;
        
        // Create a VFP
        PageReference pageRef = Page.Sinistre_BordereauColis;
        Test.setCurrentPage(pageRef);
        
        Sinistre_BordereauColisController sC; 
        // Verify that page fails without parameters
        try {
            sC = new Sinistre_BordereauColisController();
            System.assert(false, 'The controller has been created - This is wrong');
        } catch(QueryException e) {
            System.assert(e.getMessage().contains('no rows'), 'The controller shouldnt find any reception colis - This is wrong');
        }
 
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', rc.id);
        system.assertEquals(rc.Id, ApexPages.currentPage().getParameters().get('id'));
        sC = new Sinistre_BordereauColisController();
        
        // Check the display column
        system.assertEquals(colisList[0].Name, sC.getColisColumn1()[0].Name, 
                           'The display column should contain the created colis - This is wrong');
        system.assertEquals(colisList[1].Name, sC.getColisColumn2()[0].Name, 
                           'The display column should contain the created colis - This is wrong');
        system.assertEquals(colisList[2].Name, sC.getColisColumn3()[0].Name, 
                           'The display column should contain the created colis - This is wrong');
    }
}