/***
* @author Nicolas Brancato (GFI)
* @date 09/02/2021
* @description Controller class for PickUpSearch component
*/

public class PickUpSearchController {
    
    
    static final String DELIVERYMODE_PICKUP = 'En point relais'; 
    
    /***
    * @description Trigger pick up search to Chronopost when the button "Rechercher" on the lightning aura component PickUpSearch. 
    * This component is embbeded in the "Changement Mode de Livraison" flow.
    * @param string address Adress type by the user for searching
    * @param string zipCode ZipCode type by the user for searching
    * @param string city City type by the user for searching
    * @return cxfRecherchebtSoapChronopostFr.pointCHRResult res Result of the callout as a class object.
    */
    @AuraEnabled
    public static cxfRecherchebtSoapChronopostFr.pointCHRResult searchPickUp(string address, string zipCode, string city, id caseId) {
        
        return ChronopostCallout.recherchePointChronopostInter(address, zipCode, city, caseId);
    }
    
    
    /***
    * @description Save pick address in Adresse_de_livraison__c and relay point identifier in RelayPointIdExterne__c in Equipement_sinistre__c.
    * @param id damagedEquipmentId Id of the Equipement_sinistre__c
    * @param string IdExterneAndAddress Identifier and Address of the pick up point
    * @return string msg Error message if the commit fails
    */
    @AuraEnabled
    public static string savePickUpAddress(id damagedEquipmentId, string IdExterneAndAddress){
        
    	String msg;
        try{
            Equipement_sinistre__c damagedEquiptoUpdate = new Equipement_sinistre__c(id = damagedEquipmentId, DeliveryMode__c = DELIVERYMODE_PICKUP, Adresse_de_livraison__c = IdExterneAndAddress.substringAfter(' Address:'), RelayPointIdExterne__c = IdExterneAndAddress.substringBefore(' Address:'));
            update damagedEquiptoUpdate;            
        }catch (Exception e) {
            msg = String.valueOf(e);
        }
        return msg;
    }
}