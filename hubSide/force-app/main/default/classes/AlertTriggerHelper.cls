/***
* @author Ariane Tanguy (GFI)
* @date 16/04/2021
* @description Helper class for AlertTrigger
*/

public class AlertTriggerHelper {
    
    /***
	* @description Get the related case
	* @return Map<id, Case>
	*/
    public static Map<id, Case> getRelatedCase(List<Alert__c> alertList){
        
        // Get the related case id
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Alert__c a : alertList){
            relatedCaseIdSet.add(a.Case__c);
        }
        
        Map<id, Case> relatedCaseMap = new Map<id, Case>([SELECT id, TECH_Montant_Plafond__c, Number_of_Alert_plafond_depasse__c
                                                          FROM Case
                                                          WHERE id IN: relatedCaseIdSet]);
        
        return relatedCaseMap;
    }
}