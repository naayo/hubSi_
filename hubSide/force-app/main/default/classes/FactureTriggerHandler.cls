/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description Handler class for FactureTrigger
*/

public class FactureTriggerHandler {
        
    /***
	* @description Update the facture
	* @param newFactureList - list of all new facture
	* @return NA
	*/
    public static void updateFactureOnCreation(List<Facture__c> newFactureList){
        
        for(Facture__c f : newFactureList){
            
            boolean a = f.Date_debut_periode__c <= system.today();
            boolean b = system.today() <= (f.Date_debut_periode__c.addMonths(1) - 1);
            
            system.debug('-- f.Date_debut_periode__c <= system.today()' + a);
            system.debug('-- system.today() <= (f.Date_debut_periode__c.addMonths(1) - 1) ' + b);
            
            // For all the assets that started in the past (which facture do not cover today's date)
            if(!(f.Date_debut_periode__c <= system.today() &&
               system.today() <= (f.Date_debut_periode__c.addMonths(1) - 1))){
                   
                   f.Date_debut_periode__c = system.today();                
            }
            f.Date_fin_periode__c = f.Date_debut_periode__c.addMonths(1) - 1;
        }
    }
}