/***
* @author Ariane Tanguy (GFI)
* @date 19/04/2021
* @description Lightning Component Controller
*/

public class Sinistre_BordereauColisStatusController {
    
    private final String newStatus;
    private final Integer nbColis;
    private String sender;
    private final List<Colis__c> colisColumn1, colisColumn2, colisColumn3;
        
    /***
	* @description VFP Init
	*/
    public Sinistre_BordereauColisStatusController() {        
        
        // Get the equipement sinistre
        newStatus = ApexPages.currentPage().getParameters().get('newStatus');
        List<Colis__c> colisList = [SELECT id, Name, CreatedBy.FirstName, CreatedBy.LastName
                                    FROM Colis__c
                                    WHERE Statut__c =: newStatus];

        sender = [SELECT CreatedBy.FirstName FROM Colis__c WHERE Statut__c =: newStatus Group by CreatedBy.FirstName, CreatedBy.LastName].size() == 1 ?  'Agent Réception' + colisList[0].CreatedBy.FirstName + colisList[0].CreatedBy.LastName : 'Service Reception';
        
        nbColis = colisList.size();
        
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
    
    // Return newStatus
    public String getNewStatus() {
        return newStatus;
    }
    
    // Return nbColis
    public Integer getNbColis() {
        return nbColis;
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

    public String getSender() {
        return sender;
    }
}