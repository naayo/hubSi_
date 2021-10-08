/***
* @author Ariane Tanguy (GFI)
* @date 01/06/2021
* @description Helper class for ReceptionColisTrigger
*/

public class ReceptionColisTriggerHelper {
    
    /***
	* @description Get today's max batch number
	* @param newReceptionColisList - list of new Reception_colis__c
	* @return Integer
	*/
    public static Map<String, Decimal> getMaxBatchNumber(){
        
        List<AggregateResult> todaysRCList = [SELECT Nom_transporteur__c, MAX(tech_batchNumber__c)
                                              FROM Reception_colis__c
                                              WHERE Date_reception__c = TODAY
                                              GROUP BY Nom_transporteur__c];
        
        Map<String, Decimal> maxNumberMap = new Map<String, Decimal>();
        for(AggregateResult a : todaysRCList){
            Decimal maxNumber = (Decimal)a.get('expr0') == NULL ? 0 : (Decimal)a.get('expr0');
            maxNumberMap.put((String)a.get('Nom_transporteur__c'), maxNumber);
        }
        
        return maxNumberMap;
    }
}