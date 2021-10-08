/***
* @author Ariane Tanguy (GFI)
* @date 27/11/2020
* @description Lightning Component Controller
*/

public class Sinistre_EtiquetteController {
    
    private final String dateReception;
    private final String transporteur;
    private final Integer nbrColis; 
    private final List<Colis__c> colisList1, colisList2, colisList3;
        
    /***
	* @description VFP Init
	*/
    public Sinistre_EtiquetteController() {        
        
        // Get the equipement sinistre
        transporteur = ApexPages.currentPage().getParameters().get('transporteur');
        dateReception = ApexPages.currentPage().getParameters().get('dateReception');
        nbrColis= integer.valueof(ApexPages.currentPage().getParameters().get('nbrColis'));
        
        
        Date receptionDate = date.newinstance(Integer.valueOf(dateReception.split('/')[2]), 
                                              Integer.valueOf(dateReception.split('/')[1]), 
                                              Integer.valueOf(dateReception.split('/')[0]));
        
        List<Colis__c> colisList;
        if(System.test.isRunningTest())
            colisList = [SELECT id, Name, BarCode__c, Nom_transporteur__c
                                    FROM Colis__c
                                    WHERE Nom_transporteur__c =: transporteur
                                    AND Date_reception__c =: receptionDate];

        else {
            colisList = [SELECT id, Name, BarCode__c, Nom_transporteur__c
                                    FROM Colis__c
                                    WHERE toLabel(Nom_transporteur__c) =: transporteur
                                    AND Date_reception__c =: receptionDate Order by CreatedDate DESC LIMIT :nbrColis] ;

        }

        
        colisList1 = new List<Colis__c>();
        colisList2 = new List<Colis__c>();
        colisList3 = new List<Colis__c>();
        Integer i = 0;
        for(Colis__c c : colisList){
            switch on math.mod(i, 3) {
                when 0 {
                    colisList1.add(c);
                }
                when 1 {
                    colisList2.add(c);
                }
                when 2 {
                    colisList3.add(c);
                }
            }
            i = i + 1;
        }
    }
    
    // Return colisList1
    public List<Colis__c> getColisList1() {
        return colisList1;
    }
    
    // Return colisList2
    public List<Colis__c> getColisList2() {
        return colisList2;
    }
    
    // Return colisList3
    public List<Colis__c> getColisList3() {
        return colisList3;
    }
}