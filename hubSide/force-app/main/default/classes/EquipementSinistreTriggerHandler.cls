/***
* @author Nicolas Brancato (GFI)
* @date 19/02/2020
* @description Handler class for EquipementSinistreTrigger
*/

public class EquipementSinistreTriggerHandler {
    
    static final String RT_REPARATION = 'Equipement_a_reparer';
    static final String RT_ECHANGE = 'Equipement_vole_perdu';
    
    /***
    * @description method to handle all before insert automatisms
    * @param newEquipSinList list of new Equipement_sinistre__c
    * @return null
    * @exception none
    */
    public void handleBeforeInsert(List<Equipement_sinistre__c> newEquipSinList, 
                                   Map<id, Case> relatedCaseMap, 
                                   Map<id, Equipement_sinistre__c> relatedEquipSinMap){
        
        Id reparationRT, echangeRT = NULL;
        
        for(Equipement_sinistre__c e : newEquipSinList){
            
            // Update the name
            e.Name = relatedCaseMap.get(e.Sinistre__c).Numero_sinistre__c + '-' + e.Name;
            
            // Check whether the RT is correct
            if(!relatedEquipSinMap.keySet().contains(e.Sinistre__c) &&
               relatedCaseMap.keySet().contains(e.Sinistre__c) && 
               relatedCaseMap.get(e.Sinistre__c).Record_type_name__c != 'SAV'){
                   
                   if(relatedCaseMap.get(e.Sinistre__c).Typologie_sinistre__c == 'Broken' ||
                      relatedCaseMap.get(e.Sinistre__c).Typologie_sinistre__c == 'Oxydised'){
                          if(reparationRT == NULL){
                              reparationRT = UtilityClassHelper.getCreatedRecordType(RT_REPARATION);
                          }
                          e.RecordTypeId = reparationRT;
                      } else {
                          if(echangeRT == NULL){
                              echangeRT = UtilityClassHelper.getCreatedRecordType(RT_ECHANGE);
                          }
                          e.RecordTypeId = echangeRT;
                      }
               }
        }
    }
    
    /***
    * @description Update Valeur reparation on realCost change
    * And update the status when the client made his choice
    * @param newEquipSinList - list of new Equipement_sinistre__c
    * @param oldEquipSinMap - map of old Equipement_sinistre__c
    * @return null
    * @exception none
    */
    public void handleBeforeUpdate(List<Equipement_sinistre__c> newEquipSinList, 
                                   Map<id, Equipement_sinistre__c> oldEquipSinMap, 
                                   Map<id, Case> relatedCaseMap, 
                                   Map<id, vlocity_ins__AssetInsuredItem__c> relatedInsuredItemMap){

        Id DamagedEquipmentRTIdRep = [SELECT id 
                                      FROM Recordtype WHERE 
                                      DeveloperName =: RT_REPARATION].id;

        for(Equipement_sinistre__c e : newEquipSinList){
            
            // Update the name
            if(relatedCaseMap.keySet().contains(e.Sinistre__c) && 
               relatedInsuredItemMap.keySet().contains(e.Equipement_client__c)){
                   e.Name = relatedCaseMap.get(e.Sinistre__c).Numero_sinistre__c + '-' + relatedInsuredItemMap.get(e.Equipement_client__c).Name;
               }
            
            // Check whether the real cost has been updated
            if(e.RealCost__c != null && 
               e.RealCost__c != oldEquipSinMap.get(e.id).RealCost__c && 
               e.RecordTypeId == DamagedEquipmentRTIdRep){
                   
                   // Update the valeur reparation
                   e.Valeur_reparation__c = e.RealCost__c;	
               }
            
            // Check whether the client has made his choice
            if(e.ClientChoiceDate__c != NULL &&
               e.ClientChoiceDate__c != oldEquipSinMap.get(e.id).ClientChoiceDate__c &&
               e.RecordTypeId != DamagedEquipmentRTIdRep && e.ChosenEquip__c != 'RefusingProposals' && e.Statut_equipement__c != 'En commmande' && e.Statut_equipement__c != 'En destockage'){
                   e.Statut_equipement__c = 'Choix client échange';
               }
        }
    }
    
    /***
    * @description Update related InsuredItem + CalcIndemn on equipSin update
    * @param newEquipSinList - list of new Equipement_sinistre__c
    * @param oldEquipSinMap - map of old Equipement_sinistre__c
    * @param relatedInsuredItemMap - related insured item map
    * @return null
    * @exception none
    */
    public void handleEquipSinReparation(List<Equipement_sinistre__c> newEquipSinList, 
                                         Map<id, Equipement_sinistre__c> oldEquipSinMap, 
                                         Map<id, vlocity_ins__AssetInsuredItem__c> relatedInsuredItemMap, 
                                         Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap, 
                                         Map<id, Product2> relatedCatalogueProduitMap, 
                                         Map<id, Case> relatedCaseMap){
        
		List<vlocity_ins__AssetInsuredItem__c> insuredItemToUpsertList = new List<vlocity_ins__AssetInsuredItem__c>();
		List<Mouvements_financiers__c> calcIndemToUpdate = new List<Mouvements_financiers__c>();
        Boolean createInsuredItem = false;
        Boolean isEquiSinReparation =false;

        // Loop over the new equipement sinistre
        for(Equipement_sinistre__c e : newEquipSinList){
            
            // Do 
            if(relatedCaseMap.keySet().contains(e.Sinistre__c) && 
               (relatedCaseMap.get(e.Sinistre__c).Record_Type_Name__c == 'Sinistre' ||
                relatedCaseMap.get(e.Sinistre__c).Record_Type_Name__c == 'SAV')){
                    
                    // Check whether the statut got updated
                    if((e.Statut_equipement__c == 'CustomerReception' ||
                        e.Statut_equipement__c == 'Réparé Réception client') &&
                       oldEquipSinMap.get(e.id).Statut_equipement__c != e.Statut_equipement__c &&
                       relatedInsuredItemMap.keySet().contains(e.Equipement_client__c)){                           
                           
                           system.debug('-- e ' + e);
                           
                           // Get the related insured item
                           vlocity_ins__AssetInsuredItem__c i = relatedInsuredItemMap.get(e.Equipement_client__c);

                           if(e.Record_Type_Name__c == 'Equipement_a_reparer'){
                                isEquiSinReparation = true;
                           }
                           else{
                                isEquiSinReparation = false;
                           }
                           
                           // Check the related calcul indemnisation
                           if(relatedCalcIndemnMap.keySet().contains(e.Sinistre__c)){
                               createInsuredItem = false;
                               for(Mouvements_financiers__c m : relatedCalcIndemnMap.get(e.Sinistre__c)){
                                   
                                   // If it's a reparation
                                   if(m.Cout_choisi__c == 'Réparation' && isEquiSinReparation){
                                       m.Statut__c = m.Statut__c != 'Rejected' ? 'Completed' : 'Rejected';
                                       calcIndemToUpdate.add(m);
                                       i.Etat__c = e.Statut_equipement__c == 'CustomerReception' ? 'inactive' : 'Active';
                                       i.Motif__c = 'Réparation';
                                   } else if(!isEquiSinReparation && (m.Cout_choisi__c == 'Echange' || m.Cout_choisi__c == 'Primes')){
                                       // If it's an echange
                                       m.Statut__c = 'Completed';
                                       calcIndemToUpdate.add(m);
                                       i.Etat__c = 'inactive';
                                       i.Motif__c = 'Echange';
                                       createInsuredItem = true;
                                   }
                               }
                           }
                           
                           i.Dernier_sinistre__c = e.Sinistre__c;
                           i.LastReparationDate__c = e.ExpeditionDate__c;
                           i.ReparationCount__c += 1;
                           insuredItemToUpsertList.add(i);
                           
                           if (createInsuredItem) {                           
                               // Create a new insured item
                               vlocity_ins__AssetInsuredItem__c newI = i.clone(false, true, false, false);
                               newI.Category__c = e.Category__c;
                               newI.Date_achat__c = e.ExpeditionDate__c;
                               newI.Dernier_sinistre__c = e.Sinistre__c;
                               newI.Etat__c = 'Active';
                               newI.Famille_produit_sinistre__c = i.Famille_produit_sinistre__c;
                               newI.Origine_equipement__c = 'replacedBySFAM';
                               newI.Matrice_cout_equipement__c = e.ChooseEqp__c;
                               if(relatedCatalogueProduitMap.keySet().contains(e.ChooseEqp__c) && 
                                  e.ChooseEqp__c != NULL){
                                      newI.Product2Id__c = relatedCatalogueProduitMap.get(e.ChooseEqp__c).id; 
                                  }
                               newI.ReparationCount__c = 0;
                               newI.serialNumberType__c = e.serialNumberType__c;
                               newI.Numero_de_serie__c = e.SerieNumberEC__c; // serialNumberType__c;
                               newI.Statut_equipement__c = 'Actif';
                               insuredItemToUpsertList.add(newI);
                           }
                       }
                }
        }
		update calcIndemToUpdate;
        upsert insuredItemToUpsertList;
    }    
    
    /***
    * @description method to handle all after update automatisms
    * @param newEquipSinList list of new Equipement_sinistre__c
    * @param oldEquipSinMap map of old Equipement_sinistre__c
    * @return nul
    * @exception none
    */
    public void handleAfterUpdate(List<Equipement_sinistre__c> newEquipSinList, Map<id, Equipement_sinistre__c> oldEquipSinMap, 
                                         Map<id, List<Mouvements_financiers__c>> relatedCalcIndemnMap){

        Map<Id, Case> mapCase = new Map<Id, Case>();
        List<Equipement_sinistre__c> lstEqs = new List<Equipement_sinistre__c>();
        List<Equipement_sinistre__c> equipSinEchangeList = new List<Equipement_sinistre__c>();
        List<Equipement_sinistre__c> equipSinReparationList = new List<Equipement_sinistre__c>();
        
        for(integer i = 0; i < newEquipSinList.size(); i++){
            
            // Check if the equipement sinistre have a choice date and a matrice equipement 
            if(newEquipSinList[i].ClientChoiceDate__c != null &&
               newEquipSinList[i].ChooseEqp__c != null && 
               newEquipSinList[i].Sinistre__c != null &&
               (oldEquipSinMap.get(newEquipSinList[i].id).ClientChoiceDate__c == null && oldEquipSinMap.get(newEquipSinList[i].id).ChooseEqp__c == null) ||
               (oldEquipSinMap.get(newEquipSinList[i].id).ClientChoiceDate__c != null && oldEquipSinMap.get(newEquipSinList[i].id).ChooseEqp__c == null) ||
               (oldEquipSinMap.get(newEquipSinList[i].id).ClientChoiceDate__c == null && oldEquipSinMap.get(newEquipSinList[i].id).ChooseEqp__c != null)) {
                   Case currentCase = new Case();
                   currentCase.Id = newEquipSinList[i].Sinistre__c;
                   currentCase.TECH_ExchangeDateChoosed__c = newEquipSinList[i].ClientChoiceDate__c;
                   currentCase.TECH_MatriceCoutChoiceExchange__c = newEquipSinList[i].ChooseEqp__c;
                   mapCase.put(newEquipSinList[i].Sinistre__c,currentCase);
                   lstEqs.add(newEquipSinList[i]);
               }
            
            // Check whether the Valeur Echange has changed
            if((newEquipSinList[i].EquipmentAmount__c != null && 
               newEquipSinList[i].EquipmentAmount__c != oldEquipSinMap.get(newEquipSinList[i].id).EquipmentAmount__c) || 
			   newEquipSinList[i].RealCost__c != oldEquipSinMap.get(newEquipSinList[i].id).RealCost__c) { 
                   equipSinEchangeList.add(newEquipSinList[i]);
               }
            
            // Check whether the Valeur Reparation has changed
            if(newEquipSinList[i].Valeur_reparation__c != null && 
               newEquipSinList[i].Valeur_reparation__c != oldEquipSinMap.get(newEquipSinList[i].id).Valeur_reparation__c) { 
                   equipSinReparationList.add(newEquipSinList[i]);
               }
        }
        
        if(!mapCase.isEmpty()){
            update mapCase.values();
            EquipementSinistreTriggerHelper helper = new EquipementSinistreTriggerHelper();
            Map<Id,Case> mapCaseUpdated = helper.getRelatedCase(lstEqs);
            Flow.Interview flow = new Flow.Interview.CASE_Manage_PaiementVersement(new map<String,Object> 
                                                                                   {'VAR_ListCase' => mapCaseUpdated.values()});     
            flow.start();
        }
        
        List<Mouvements_financiers__c> calcIndemnToUpdateList = new List<Mouvements_financiers__c>();
        system.debug('--equipementEchange : '+equipSinEchangeList);
        system.debug('--newEquipSinList : '+newEquipSinList);
                                             
        // Check the Echange calc indemn
        if(!equipSinEchangeList.isEmpty()){
            
            // Check whether there's a calc indemn to update
            // (Only one Equipement_sinistre__c row can be updated at a time)
            if(relatedCalcIndemnMap.keySet().contains(equipSinEchangeList[0].Sinistre__c)){
                for(Mouvements_financiers__c m : relatedCalcIndemnMap.get(equipSinEchangeList[0].Sinistre__c)){
                    if(m.Type_mouvement__c == CalculIndemnisationTriggerHandler.COSTTYPE_INTERNCOSTEXCHANGE){
                           m.Montant__c = equipSinEchangeList[0].RealCost__c == NULL ? equipSinEchangeList[0].EquipmentAmount__c 
                               : equipSinEchangeList[0].RealCost__c;
                           if(m.Statut__c == CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS) {
                              m.Libelle__c = m.Libelle__c + '\r\n' + 'Mise à jour suite à remontée de stock';
                           }
                          
                           calcIndemnToUpdateList.add(m);
                           break;
                       }
                }
            }
        }
        
        // Check the Reparation calc indemn
        if(!equipSinReparationList.isEmpty()){
            
            // Check whether there's a calc indemn to update
            // (Only one Equipement_sinistre__c row can be updated at a time)
            if(relatedCalcIndemnMap.keySet().contains(equipSinReparationList[0].Sinistre__c)){
                for(Mouvements_financiers__c m : relatedCalcIndemnMap.get(equipSinReparationList[0].Sinistre__c)){
                    if(m.Statut__c == CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS &&
                       m.Type_mouvement__c == CalculIndemnisationTriggerHandler.COSTTYPE_REPAIR){
                           m.Montant__c = equipSinReparationList[0].RealCost__c == NULL ? 
                               equipSinReparationList[0].Valeur_reparation__c : equipSinReparationList[0].RealCost__c;
                           calcIndemnToUpdateList.add(m);
                           break;
                       }
                }
            }
        }
        
        if(calcIndemnToUpdateList.size() > 0){
            update calcIndemnToUpdateList;
        }
    }
}