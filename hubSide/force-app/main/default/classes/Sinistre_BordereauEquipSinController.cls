/***
* @author Ariane Tanguy (GFI)
* @date 27/11/2020
* @description Lightning Component Controller
*/

public class Sinistre_BordereauEquipSinController {
    
    private final String newStatus;
    private final String newSousStatus;
    private final String saisieSinistre;
    private final Integer nbColis;
    private final List<Equipement_sinistre__c> sinistreColumn1, sinistreColumn2, sinistreColumn3;
    private Boolean preValidation = false;
    private List<Equipement_sinistre__c> equipSinList;
   
    /***
	* @description VFP Init
	*/
    public Sinistre_BordereauEquipSinController() {        
        
        // Get the equipement sinistre
        newStatus = ApexPages.currentPage().getParameters().get('newStatus');
        newSousStatus = ApexPages.currentPage().getParameters().get('newSousStatus');
        saisieSinistre = ApexPages.currentPage().getParameters().get('numSinistre');
        
        if(saisieSinistre != null) {
            preValidation = true;
            equipSinList = [SELECT id, Statut_equipement__c,  Sinistre__r.Numero_sinistre__c, Sous_statut__c
                            FROM Equipement_Sinistre__c
                            WHERE Numero_sinistre__c IN: saisieSinistre.split(' ')];
        } else {
            equipSinList = [SELECT id, Sinistre__r.Numero_sinistre__c
                                                     FROM Equipement_Sinistre__c
                                                     WHERE Statut_equipement__c =: newStatus
                                                     AND Sous_statut__c =: newSousStatus
                                                     AND Id In (SELECT Equipement_sinistre__c From Name__c Where CreatedDate = TODAY)];


            List<Name__c> allThatHistory = [SELECT ID,Equipement_sinistre__c, CreatedDate, Name FROM NAME__c WHERE Equipement_sinistre__c IN: equipSinList Order by CreatedDate DESC];
            System.debug(allThatHistory.size());
            setLastStatuses(equipSinList, allThatHistory);
        }
        
        nbColis = equipSinList.size();
        
        sinistreColumn1 = new List<Equipement_sinistre__c>();
        sinistreColumn2 = new List<Equipement_sinistre__c>();
        sinistreColumn3 = new List<Equipement_sinistre__c>();
        Integer i = 0;
        for(Equipement_sinistre__c e : equipSinList){
            switch on math.mod(i, 3) {
                when 0 {
                    sinistreColumn1.add(e);
                }
                when 1 {
                    sinistreColumn2.add(e);
                }
                when 2 {
                    sinistreColumn3.add(e);
                }
            }
            i = i + 1;
        }
    }
    
    // Return newStatus
    public String getNewStatus() {
        return newStatus;
    }
    
    // Return newSousStatus
    public String getNewSousStatus() {
        return newSousStatus;
    }
    
    // Return nbColis
    public Integer getNbColis() {
        return nbColis;
    }

    public Boolean getPrevalidation(){ 
        return preValidation;
    }
    
    // Return sinistre1
    public List<Equipement_sinistre__c> getSinistreColumn1() {
        return sinistreColumn1;
    }
    
    // Return sinistre2
    public List<Equipement_sinistre__c> getSinistreColumn2() {
        return sinistreColumn2;
    }
    
    // Return sinistre3
    public List<Equipement_sinistre__c> getSinistreColumn3() {
        return sinistreColumn3;
    }

    public List<Equipement_sinistre__c> getEquipSinList() {
        return equipSinList;
    }

    private void setLastStatuses(List<Equipement_sinistre__c> equipSinistre, List<Name__c> history){
        for(Equipement_sinistre__c eq : equipSinistre) {
            Integer findSecond = 0;
            for(Name__c hist : history) {
                if(hist.Equipement_sinistre__c.equals(eq.Id)) {
                    eq.LastStatus__c = hist.Name;
                    eq.LastStatusModification__c = hist.CreatedDate;
                    if (findSecond == 1)
                        break;
                    findSecond ++;
                }
            }
        }
    }
}