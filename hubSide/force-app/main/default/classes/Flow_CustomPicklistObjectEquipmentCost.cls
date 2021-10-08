/***
* @author Nicolas Brancato (GFI)
* @date 16/02/2021
* @description Controller class for Flow_CustomPicklistObjectEquipmentCost component
*/

public class Flow_CustomPicklistObjectEquipmentCost {
	
    /***
    * @description Create custom list of strings to populate picklist value "Objet" in the flow "Ajout Coût Equipement Sinistré" (api name : EqsAddCost)
    * @param Id recordTypeId Record type id of the equipments cost type to fetch according to the record type of the damaged equipment
    * @return List<String> Custom list of strings to populate custom picklist in the Flow_CustomPicklistObjectEquipmentCost component
    */
    @AuraEnabled
    public static List<String> createPicklist(Id recordTypeId){
        
        set<String> customPicklistObject = new set <string>();
        for (EquipmentCostType__c eq : [SELECT Id, Object__c from EquipmentCostType__c where RecordTypeId =: recordTypeId]) {
            customPicklistObject.add(eq.Object__c);
        }
        return new list<String>(customPicklistObject);        
    }
}