/***
* @author Ariane Tanguy (GFI)
* @date 08/06/2021
* @description Handler class for AssociatedCostTrigger
*/

public class AssociatedCostTriggerHandler {
    
    /***
	* @description Update the case + equipSin cout global on update
	* @param newAssociatedCostList - list of new associated cost
	* @param oldAssociatedCostMap - map of old associated cost
	* @return NA
	*/
    public static void updateCoutReelOnUpdate(List<AssociatedCost__c> newAssociatedCostList, Map<id, AssociatedCost__c> oldAssociatedCostMap){
        
        // Map the equipSin to their associated costs if there's a change in the montant
        Map<String, List<AssociatedCost__c>> equipSinIdAssociatedCostMap = new Map<String, List<AssociatedCost__c>>();
        for(AssociatedCost__c a : newAssociatedCostList){
            if((a.UnitCost__c != oldAssociatedCostMap.get(a.id).UnitCost__c ||
                a.ManpowerCost__c != oldAssociatedCostMap.get(a.id).ManpowerCost__c) &&
               !equipSinIdAssociatedCostMap.keySet().contains(a.DamagedEquipment__c)){
                   List<AssociatedCost__c> tmpList = new List<AssociatedCost__c>();
                   equipSinIdAssociatedCostMap.put(a.DamagedEquipment__c, tmpList);
               }
        }
        
        for(AssociatedCost__c a : newAssociatedCostList){
            if(equipSinIdAssociatedCostMap.keySet().contains(a.DamagedEquipment__c)){
                equipSinIdAssociatedCostMap.get(a.DamagedEquipment__c).add(a);
            }
        }
        
        updateCoutReel(equipSinIdAssociatedCostMap);
    }
    
    /***
	* @description Update the case + equipSin cout global on delete
	* @param oldAssociatedCostList - list of associated cost
	* @return NA
	*/
    public static void updateCoutReelOnDelete(List<AssociatedCost__c> oldAssociatedCostList){
        
        // Map the equipSin to their associated costs
        Map<String, List<AssociatedCost__c>> equipSinIdAssociatedCostMap = new Map<String, List<AssociatedCost__c>>();
        for(AssociatedCost__c a : oldAssociatedCostList){
            if(!equipSinIdAssociatedCostMap.keySet().contains(a.DamagedEquipment__c)){
                List<AssociatedCost__c> tmpList = new List<AssociatedCost__c>();
                equipSinIdAssociatedCostMap.put(a.DamagedEquipment__c, tmpList);
            }
            equipSinIdAssociatedCostMap.get(a.DamagedEquipment__c).add(a);
        }
        
        updateCoutReel(equipSinIdAssociatedCostMap);
    }
    
    /***
	* @description Update the case + equipSin cout global on delete
	* @param newAssociatedCostList - list of new associated cost
	* @param oldAssociatedCostMap - map of old associated cost
	* @return NA
	*/
    public static void updateCoutReel(Map<String, List<AssociatedCost__c>> equipSinIdAssociatedCostMap){
        
        // Loop over the equipSin ids
        Map<String, Flow.Interview> equipSinIdFlowMap = new Map<String, Flow.Interview>();
        for(String equipSinId : equipSinIdAssociatedCostMap.keySet()){
            Flow.Interview flow = new Flow.Interview.AssociatedCostSum(new map<String,Object> 
                                                                       {'EquipSinId' => equipSinId});
            flow.start();
            equipSinIdFlowMap.put(equipSinId, flow);
        }
        
        // Check whether we have all the case ids
        Set<id> missingEquipSinId = new Set<id>();
        for(String equipSinId : equipSinIdFlowMap.keySet()){
            if((Id)equipSinIdFlowMap.get(equipSinId).getVariableValue('CaseId') == NULL){
                missingEquipSinId.add(equipSinId);
            }
        }
        
        Map<id, Equipement_sinistre__c> equipSinMap = new Map<id, Equipement_sinistre__c>();
        if(missingEquipSinId.size() > 0){
            equipSinMap = new Map<id, Equipement_sinistre__c>([SELECT id, Sinistre__c 
                                                               FROM Equipement_sinistre__c
                                                               WHERE id IN: missingEquipSinId]);
        }
        
        // And update the related case + equipSin
        List<SObject> objectToUpdate = new List<SObject>();
        for(String equipSinId : equipSinIdFlowMap.keySet()){
            
            Decimal montantToUpdate = (Decimal)equipSinIdFlowMap.get(equipSinId).getVariableValue('SumCoutUnitaire');
            
            // And of the equipement sinistre
            Equipement_sinistre__c e = new Equipement_sinistre__c(id = equipSinId, 
                                                                  RealCost__c = montantToUpdate);
            objectToUpdate.add(e);
        }
        
        // Do the update
        update objectToUpdate;
    }
}