/***
* @author Ariane Tanguy (GFI)
* @date 02/12/2020
* @description Sinistre_EtiquetteController test class
* @VFP Sinistre_Etiquette
*/

@isTest
public class Sinistre_EtiquetteControllerTest {
    
    /***
    * @description Check whether the custom controller does the job
    * @see Sinistre_Etiquette
    */
    @isTest
    public static void Sinistre_BordereauEquipSinTest(){
        
        // Create a Reception Colis
        Reception_colis__c rc = new Reception_colis__c();
        rc.Name = 'La Poste - SAV - ' +  system.today();
        rc.Date_reception__c = system.today();
        rc.Nombre_colis_scannes__c = 1;
        insert rc;
        
        // Create three colis
        List<Colis__c> colisList = new List<Colis__c>();
        for(integer i=0; i<3; i++){
            Colis__c c = new Colis__c();
            c.Reception_colis__c = rc.id;
            c.Nom_transporteur__c = 'LaPosteSav';
            c.Date_reception__c = system.today();
            colisList.add(c);
        }
        insert colisList;
                        
        // Create a VFP
        PageReference pageRef = Page.Sinistre_Etiquette;
        Test.setCurrentPage(pageRef);
        
        // Verify that page fails without parameter
        Sinistre_EtiquetteController sC;
        try {
            sC = new Sinistre_EtiquetteController();
            System.assert(false, 'The controller has been created - This is wrong');
        } catch(NullPointerException e) {
            System.assert(e.getMessage().contains('null'), 'The controller shouldnt find any reception colis - This is wrong');
        }
        
        // Add parameters to page URL
        String dateReception = String.valueOf(system.today().day()) + '/' + String.valueOf(system.today().month() + '/' + String.valueOf(system.today().year()));
        ApexPages.currentPage().getParameters().put('transporteur', 'LaPosteSav');
        ApexPages.currentPage().getParameters().put('dateReception', dateReception);
    	ApexPages.currentPage().getParameters().put('nbrColis', '0');
        
        
        sC = new Sinistre_EtiquetteController();
        
        // Check the display column
        system.assertEquals(1, sC.getColisList1().size(), 
                            sC.getColisList1() + ' The first display column should contain the created colis - This is wrong');
        system.assertEquals(1, sC.getColisList1().size(), 
                            sC.getColisList2() + ' The second display column should contain the created colis - This is wrong');
        system.assertEquals(1, sC.getColisList1().size(), 
                            sC.getColisList3() + ' The third display column should contain the created colis - This is wrong');
    }
}