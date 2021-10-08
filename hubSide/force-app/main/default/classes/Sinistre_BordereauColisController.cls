/***
* @author Ariane Tanguy (GFI)
* @date 05/11/2020
* @description Sinistre_BordereauColis controller
*/

public class Sinistre_BordereauColisController {
    
    private final Reception_colis__c rc;
    private String businessProfileName;
    private final List<Colis__c> colisColumn1, colisColumn2, colisColumn3;
        
    /***
	* @description VFP Init
	*/
    public Sinistre_BordereauColisController() {

        businessProfileName = [SELECT BusinessProfile__c FROM User WHERE Id = :UserInfo.getUserId()][0].BusinessProfile__c;
        
        // Get the Reception Colis infos
        rc = [SELECT Id, Name, Date_reception__c, 
              Nombre_colis_scannes__c, 
              CreatedBy.FirstName, CreatedBy.LastName, toLabel(Nom_transporteur__c)
              FROM Reception_colis__c 
              WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        
        // Get the colis infos
        List<Colis__c> colisList = [SELECT id, Name
                                    FROM Colis__c
                                    WHERE Reception_colis__c =: rc.Id];
        
        colisColumn1 = new List<Colis__c>();
        colisColumn2 = new List<Colis__c>();
        colisColumn3 = new List<Colis__c>();
        Integer i = 0;
        for(Colis__c c : colisList){
            switch on math.mod(i, 3) {
                when 0 {
                    colisColumn1.add(c);
                }
                when 1 {
                    colisColumn2.add(c);
                }
                when 2 {
                    colisColumn3.add(c);
                }
            }
            i = i + 1;
        }
    }
    
    // Return rc
    public Reception_colis__c getRC() {
        return rc;
    }
    
    // Return colis1
    public List<Colis__c> getColisColumn1() {
        return colisColumn1;
    }
    
    // Return colis2
    public List<Colis__c> getColisColumn2() {
        return colisColumn2;
    }
    
    // Return colis3
    public List<Colis__c> getColisColumn3() {
        return colisColumn3;
    }

    public String getBusinessProfileName(){
        return businessProfileName;
    }
}