/***
* @author Nicolas Brancato (GFI)
* @date 11/02/2020
* @description Helper class for CalculIndemnisationTrigger
*/


public class CalculIndemnisationTriggerHelper {    
    
    public static final String DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE = 'Equipement_vole_perdu';
    public static final String EQUIPMENTRECORDTYPE_REPAIR = 'Equipement_a_reparer';
    public static final String TASKCOMMUNICATIONCHANNEL_OUTBOUNDEMAIL = 'Mail sortant';
    public static final String EQUIPMENTSINISTRE_STATUS_INPROGRESSREPAIR = 'En Cours de Réparation';
    public static final String EQUIPMENTSINISTRE_UNDERSTATUS_INPROGRESS = 'En cours';
    public static final String EQUIPMENTSINISTRE_STATUS_EXCHANGE = 'Echangé';
    public static final String EQUIPMENTSINISTRE_UNDERSTATUS_PRENIUM = 'Via prime';
    public static final String TASK_SUBJECT_REPAIRVALID = 'Réparation validée';
    public static final String STATUS_CREATED = 'Crée';
    public static final String INSUREDITEM_STATUS_INACTIVE = 'inactive';
    public static final String INSUREDITEM_REASON_EXCHANGE = 'Echange';
    
	/***
	* @description Get datas on the Equipement_sinistre__c to trigger destock to BAppli
	* @param Cal Mouvements_financiers__c with Type_mouvement__c equal to 'Cout interne d'echange' 
	* and Statut__c equal to 'Demande en cours'
	* @return Equipement_sinistre__c with the Id Externe B-appli Equipement Echange(Id_externe__c) 
	* on the Matrice_cout_equipement__c object, Grade__c and Operator__c on the Equipement_sinistre__c
	*/
    public static Equipement_sinistre__c GetDatasToTriggerDestockToBAppli(Mouvements_financiers__c Cal){  
        
        Equipement_sinistre__c eq = [SELECT id, 
                                     ChooseEqp__r.Id_externe__c, 
                                     Grade__c, 
                                     Operator__c, 
                                     Sinistre__c, 
                                     ClientChoiceDate__c
                                     FROM Equipement_sinistre__c
                                     WHERE Sinistre__c =: Cal.Case__c 
                                     AND RecordType.DeveloperName =: DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE
                                     LIMIT 1];
        
        return eq;
    }

    /***
	* @description Get datas on the Equipement_sinistre__c to trigger destock to BAppli
	* @param Cal Mouvements_financiers__c with Type_mouvement__c equal to 'Cout interne reparation' and Statut__c equal to 'Demande en cours'
	* @return Equipement_sinistre__c reparation
	*/
    public static List<Equipement_sinistre__c> GetEquipSinistreRepair(Set<Id> listIdSinistre){  
        
        List<Equipement_sinistre__c> listEq = [SELECT id, 
                                               Statut_equipement__c,
                                               Sous_statut__c,
                                               OwnerId
                                               FROM Equipement_sinistre__c
                                               WHERE Sinistre__c =: listIdSinistre
                                               AND RecordType.DeveloperName =: EQUIPMENTRECORDTYPE_REPAIR];
        
        return listEq;
    }
    
    /***
	* @description Sum all amount of calcul indemnisation rows linked to the same case
	* @param set<id> idSin
	* @return nul
	* @exception none
    */
    public static void SumCalculIndemAmount(set<id> idSin){  
        
        List<Case> ListCaseToUpdate = new list<Case>();
        List<Mouvements_financiers__c> lstCal = new List<Mouvements_financiers__c>([SELECT id, Case__c, Montant__c 
                                                                                    FROM Mouvements_financiers__c 
                                                                                    WHERE Statut__c NOT IN ('Invalidated','Rejected') 
                                                                                    AND Case__c IN: idSin]);
        
        Map<id,List<Mouvements_financiers__c>> mapIdCaseListCalIndem = new map<Id,List<Mouvements_financiers__c>>();        
        if(!lstCal.isEmpty()){
            for(Mouvements_financiers__c j: lstCal){
                if(mapIdCaseListCalIndem.get(j.Case__c) != null){
                    mapIdCaseListCalIndem.get(j.Case__c).add(j);                    
                }else{
                    mapIdCaseListCalIndem.put(j.Case__c, new list<Mouvements_financiers__c>{j});    
                }
            }
            for(Id id: mapIdCaseListCalIndem.keyset()){
                decimal sum = 0;
                for(Mouvements_financiers__c cal: mapIdCaseListCalIndem.get(id)){
                     sum = sum + cal.Montant__c;
                }
                ListCaseToUpdate.add(new Case(id = id, Montant_sinistre__c = sum));
            }
        }else{
            for(Id i: idSin){
                ListCaseToUpdate.add(new Case(id = i, Montant_sinistre__c = 0));        
            }   
        }
        if(!ListCaseToUpdate.isEmpty()){
            update ListCaseToUpdate;
        }
    }
    
    /***
	* @description send email to customer and dealer 
	* @param List<id> lstCalforStoreCostPrime
	* @return nul
	* @exception none
    */
    public static void sendEmailToCustomerAndDealer(List<Mouvements_financiers__c> lstCalforStoreCostPrime){  
        
        List<Task> TaskToInsert = new list<Task>();
        
        // Only one Mouvements_financiers__c row can be updated to 'Demande en cours' at a time
        for(Mouvements_financiers__c i: lstCalforStoreCostPrime){
            task t = new task();
            t.ActivityDate = date.today();
            t.Canal_communication__c = TASKCOMMUNICATIONCHANNEL_OUTBOUNDEMAIL;
            t.Code_template__c = Label.SinistreEmailTemplatePremiumExchange;
            t.WhatId = i.Case__c;
            TaskToInsert.add(t);
            
            string relatedTemplate = Label.SinistreEmailTemplatePremiumExchangeDealer + '%';
            Id templateDealerId = [SELECT id, developername 
                                   FROM EmailTemplate 
                                   WHERE developername LIKE: relatedTemplate].id;
            String dealerEmail = [SELECT id, TECH_StorePremium__r.vlocity_ins__Email__c 
                                  FROM Case 
                                  WHERE id =: i.Case__c].TECH_StorePremium__r.vlocity_ins__Email__c;
            
			// Create the dealer email to be sent 
			Messaging.SingleEmailMessage dealerMail = UtilityClassHelper.createEmail(i.Case__c, dealerEmail, templateDealerId); 
            
            if(dealerEmail != null){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{dealerMail});
                Contact c = [SELECT id, LastName 
                             FROM Contact 
                             WHERE LastName =: dealerEmail];
                delete c;
            }
            if(!TaskToInsert.isEmpty()){
                insert TaskToInsert;
            }
        }
    }
    
    /***
	* @description Get the asset's related account
	* @return Map<id, Account>
	*/
    public static Map<id, List<Mouvements_financiers__c>> getOtherCalcIndem(List<Mouvements_financiers__c> newCalcIndemnList){
        
        // Get the related case ids
        Set<id> caseIdSet = new Set<id>();
        for(Mouvements_financiers__c c : newCalcIndemnList){
            caseIdSet.add(c.Case__c);
        }
        
        List<Mouvements_financiers__c> relatedMFList = [SELECT id, Case__c, Statut__c, Cout_choisi__c
                                                        FROM Mouvements_financiers__c
                                                        WHERE Case__c IN: caseIdSet
                                                        AND id NOT IN: newCalcIndemnList];
        
        // Map the mouvement financiers to their cases
        Map<id, List<Mouvements_financiers__c>> caseIdMFMap = new Map<id, List<Mouvements_financiers__c>>();
        for(Mouvements_financiers__c m : relatedMFList){
            if(!caseIdMFMap.keySet().contains(m.Case__c)){
                List<Mouvements_financiers__c> tmpList = new List<Mouvements_financiers__c>();
                caseIdMFMap.put(m.Case__c, tmpList);
            }
            caseIdMFMap.get(m.Case__c).add(m);
        }
        return caseIdMFMap;
    }

    /***
    * @description update amount Case
    * @param lstNewCal list of new Mouvements_financiers__c
    * @return nul
    * @exception none
    */
    public static void blockDeleteCalculIndemStatusCreated(List<Mouvements_financiers__c> lstOldCal){
        for(integer i=0; i<lstOldCal.size(); i++){
            if(lstOldCal[i].Statut__c != STATUS_CREATED) { 
                lstOldCal[i].addError(Label.Sinistre_ErrorMessageDeletionCalculIndem);
            }
        }
    }

    /***
    * @description Checks whether the recently updated status on MF are closed - if so, proceeds to close the related case
    * @param newMFList - list of new Mouvements_financiers__c
    * @param oldMFMap - map of old Mouvements_financiers__c
    * @param caseIdMFMap - related MF mapped to their case id
    * @return null
    * @exception none
    */
    public static void updateRelatedCase(List<Mouvements_financiers__c> newMFList, Map<id, Mouvements_financiers__c> oldMFMap, Map<id, List<Mouvements_financiers__c>> caseIdMFMap){
        
        Map<id, String> caseToUpdate = new Map<id, String>();
        List<Id> lstAssetId = new List<Id>();
        
        // Loop over the new mouvements financiers
        for(Mouvements_financiers__c m : newMFList){
            
            // If the status is now closed
            if(m.Statut__c != oldMFMap.get(m.id).Statut__c &&
                m.Statut__c == 'Completed'){
                    
                    // Set the validation date
                    m.Indemnisation_date__c = system.today();
            
                    // And if there is no other open MF, but at least a completed one
                    boolean isThereAnOpenMF = FALSE;
                    boolean isThereACompletedMF = m.Statut__c == 'Completed';
                    boolean isThereOnlyReglCli = FALSE;
                    integer countOtherMF = 0;

                    if(m.Cout_choisi__c == 'Règlement par le client'){
                    	isThereOnlyReglCli = TRUE;
                    }
                    
                    if(caseIdMFMap.keySet().contains(m.Case__c)){
                        for(Mouvements_financiers__c relM : caseIdMFMap.get(m.Case__c)){
                            if(relM.Cout_choisi__c == 'Règlement par le client' && countOtherMF!=0){
                                isThereOnlyReglCli = TRUE;
                            }
                            if(relM.Statut__c == 'Crée' ||
                               relM.Statut__c == 'En cours d\'approbation' ||
                               relM.Statut__c == 'Validé' ||
                               relM.Statut__c == 'Demande en cours' ){
                                   isThereAnOpenMF = TRUE;
                                   break;
                               }
                            if(relM.Statut__c == 'Completed'){
                                isThereACompletedMF = TRUE;
                            }
                            if(relM.Cout_choisi__c != 'Règlement par le client'){
                                isThereOnlyReglCli = FALSE;
                                countOtherMF++;
                            }
                        }
                    }
                    
                    // Then close the case
                    if(!isThereAnOpenMF && isThereACompletedMF && !isThereOnlyReglCli){
                        if(m.TECH_AssetID__c != null || String.isNotBlank(m.TECH_AssetID__c)){
                            lstAssetId.add(m.TECH_AssetID__c);
                        }
                        if(m.Type_mouvement__c == 'Prime pour reparation par le client' ||
                           m.Cout_choisi__c == 'Réparation'){
                               caseToUpdate.put(m.Case__c, 'closed_repaired');
                           }
                        else{
                            caseToUpdate.put(m.Case__c, 'closed_exchange');
                            
                            if(m.Cout_choisi__c == 'Primes') {
                                // Update Insured Item (state and reason)
                            	updateInsuredItemForClosedExchange(m.Case__c);
                                // Update damaged equipment (status and sub status)
                                updateEquipeSinistreForClosedExchange(m.Case__c);
                            }
                        }
                    }
                }
        }
        if(caseToUpdate.keySet().size() > 0){
            updateCase(new List<id>(caseToUpdate.keySet()), caseToUpdate.values(),lstAssetId);
        }
    }
    
    /***
	* @description Update the metadata - future method
	* @param Case
	* @return NA
	*/
    @future
    private static void updateCase(List<id> caseIdList, List<String> caseStatusList, List<Id> lstAssetId){
        
        List<Case> caseToUpdate = new List<Case>();
        
        for(Integer i=0; i<caseIdList.size(); i++){
            Case c = new Case(id = caseIdList[i], 
                              ClosedDateBappli__c = system.today());
            if(caseStatusList[i] != ''){
                c.Status = caseStatusList[i];
            }
            caseToUpdate.add(c);
        }
        
        update caseToUpdate;
        CaseTriggerHandler.nofuturCalculatorProcess(lstAssetId,null);
    }

    /***
    * @description update status equipment sinistre
    * @param lstEquiToUpdate list of equipementSinistre to updated
    * @return nul
    * @exception none
    */
    public static void updateEquipeSinistreStatus(List<Equipement_sinistre__c> lstEquiToUpdate){
        List<Equipement_sinistre__c> lstEquToUpdate = new List<Equipement_sinistre__c>();

        for(Equipement_sinistre__c eq : lstEquiToUpdate){
            eq.Statut_equipement__c = EQUIPMENTSINISTRE_STATUS_INPROGRESSREPAIR; 
            eq.Sous_statut__c = EQUIPMENTSINISTRE_UNDERSTATUS_INPROGRESS;
            lstEquToUpdate.add(eq);
        }

        update lstEquToUpdate;
    }

    /***
    * @description create task to start repair
    * @param lstEquiToUpdate list of equipementSinistre to created task
    * @return nul
    * @exception none
    */
    public static void createHistoToStartRepair(List<Equipement_sinistre__c> lstEquiToUpdate){
        List<Equipement_sinistre__c> lstEquToUpdate = new List<Equipement_sinistre__c>();

        List<Name__c> lstHistoToCreated = new List<Name__c>();

        for(Equipement_sinistre__c eq : lstEquiToUpdate){
            Name__c histo = new Name__c();
            histo.Name = TASK_SUBJECT_REPAIRVALID;
            histo.OwnerId = eq.OwnerId;
            histo.Equipement_sinistre__c = eq.Id;
            lstHistoToCreated.add(histo);
        }

        insert lstHistoToCreated;
    }

    /***
	* @description Clean choice in EquipementSinistre
	* @param caseIdList Case Ids
	* @return NA
	*/
    public static void updateEquipeSinistreChoice(Set<id> caseIdList){
        
        List<Equipement_sinistre__c> equiSinToUpdate = [SELECT Id,
                                                                FirstChoice__c,
                                                                SecondChoice__c,
                                                                ThirdChoice__c,
                                                                ChosenEquip__c,
                                                                ClientChoiceDate__c,
                                                                Statut_equipement__c,
                                                                Grade__c,
                                                                FirstChoiceRank__c,
                                                                SecondChoiceRank__c,
                                                                ThirdChoiceRank__c
                                                                 FROM Equipement_sinistre__c WHERE Sinistre__c IN: caseIdList];
        List<Equipement_sinistre__c> equiSinUpdate = new List<Equipement_sinistre__c>();

        if(equiSinToUpdate != null && equiSinToUpdate.size()>0){
            for(Equipement_sinistre__c eq : equiSinToUpdate){
                eq.FirstChoice__c = null;
                eq.SecondChoice__c = null;
                eq.ThirdChoice__c = null;
                eq.ChosenEquip__c = null;
                eq.ClientChoiceDate__c = null;
                eq.Grade__c = null;
                eq.FirstChoiceRank__c = null;
                eq.SecondChoiceRank__c = null;
                eq.ThirdChoiceRank__c = null;
                eq.Statut_equipement__c = 'En Analyse';
                equiSinUpdate.add(eq);
            }
        }

        if(equiSinUpdate.size()>0){
            update equiSinUpdate;
        }
    }
    
    /***
    * @description update insured item
    * @param itemToUpdate Insured item to updated
    * @return nul
    * @exception none
    */
    public static void updateInsuredItemForClosedExchange(Id CaseId){
        List<Case> CaseList = [SELECT Equipement_client__c FROM Case WHERE id =: CaseId];
        
        if(CaseList.size() == 1){
            id InsuredItemId = CaseList[0].Equipement_client__c;
                
        	vlocity_ins__AssetInsuredItem__c InsuredItem = new vlocity_ins__AssetInsuredItem__c(
                id = InsuredItemId,
                Etat__c = INSUREDITEM_STATUS_INACTIVE,
                Motif__c = INSUREDITEM_REASON_EXCHANGE
            );
        
        	update InsuredItem;
        }
    }
    
    /***
    * @description update status equipment sinistre for closed exchange
    * @param lstEquiToUpdate equipementSinistre to updated
    * @return nul
    * @exception none
    */
    public static void updateEquipeSinistreForClosedExchange(Id CaseId){
        Equipement_sinistre__c eq = [SELECT id
                                    FROM Equipement_sinistre__c
                                    WHERE Sinistre__c =: CaseId
                                    AND RecordType.DeveloperName =: DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE
                                    LIMIT 1];
            
        if(eq != null){
            eq.Statut_equipement__c = EQUIPMENTSINISTRE_STATUS_EXCHANGE;
            eq.Sous_statut__c = EQUIPMENTSINISTRE_UNDERSTATUS_PRENIUM;
        
        	update eq;
        }
    }
}