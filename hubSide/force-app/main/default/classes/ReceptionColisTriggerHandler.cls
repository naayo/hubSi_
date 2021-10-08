/***
* @author Ariane Tanguy (GFI)
* @date 01/06/2021
* @description Handler class for ReceptionColisTrigger
*/

public class ReceptionColisTriggerHandler {
    
    /***
	* @description Set batchNumber field
	* @param newReceptionColisList - list of new Reception_colis__c
	* @param maxBatchNumber - today's max batch  number
	*/
    public static void setBatchNumber(List<Reception_colis__c> newReceptionColisList, Map<String, Decimal> maxBatchNumberMap){
        
        // Loop over the new Reception colis
        for(Reception_colis__c r : newReceptionColisList){
            if(maxBatchNumberMap.keySet().contains(r.Nom_transporteur__c)){
                Decimal maxBatchNumber = maxBatchNumberMap.get(r.Nom_transporteur__c);
                maxBatchNumber ++;
                r.tech_batchNumber__c = maxBatchNumber;
                maxBatchNumberMap.put(r.Nom_transporteur__c, maxBatchNumber);
            }
        }
    }
}