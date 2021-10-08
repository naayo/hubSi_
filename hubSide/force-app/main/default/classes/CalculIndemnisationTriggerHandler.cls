/***
* @author Nicolas Brancato (GFI)
* @date 11/02/2020
* @description Handler class for CalculIndemnisationTrigger
*/

public class CalculIndemnisationTriggerHandler {    
    
    public static final String STATUS_VALIDATED = 'Validé';    
    public static final String STATUS_DEMANDINPROGRESS = 'Demande en cours';
    public static final String COSTTYPE_INTERNCOSTEXCHANGE = 'Cout interne d\'echange';
    public static final String COSTTYPE_STOREPRIMECOST = 'Cout prime magasin';
    public static final String COSTTYPE_REPAIR = 'Cout interne reparation';
    public static final String COSTTYPE_FRANCHISE = 'Franchise';
    static final String BAPPLISTOCKNAME_SFAM = 'SFAM';

    /***
    * @description method to handle all before delete automatisms
    * @param lstOldCal list of old Mouvements_financiers__c
    */
    public void handleBeforeDelete(List<Mouvements_financiers__c> lstOldCal){
        CalculIndemnisationTriggerHelper.blockDeleteCalculIndemStatusCreated(lstOldCal);
    }

    /***
    * @description method to handle all before update automatisms
    * @param lstNewCal list of new Mouvements_financiers__c
    * @param mapOldCal map of old Mouvements_financiers__c
    */
    public void handleBeforeUpdate(List<Mouvements_financiers__c> lstNewCal, Map<id,Mouvements_financiers__c> mapOldCal){
        
        // Update related case on closed CalcIndem
        Map<id, List<Mouvements_financiers__c>> caseIdMFMap = CalculIndemnisationTriggerHelper.getOtherCalcIndem(Trigger.new);
        CalculIndemnisationTriggerHelper.updateRelatedCase(lstNewCal, mapOldCal, caseIdMFMap);
    }

    /***
    * @description method to handle all after insert automatisms
    * @param lstNewCal list of new Mouvements_financiers__c
    */
    public void handleAfterInsert(List<Mouvements_financiers__c> lstNewCal){
        updateCaseAmount(lstNewCal);
    }  

    /***
    * @description method to handle all after delete automatisms
    * @param lstOldCal list of old Mouvements_financiers__c
    */
    public void handleAfterDelete(List<Mouvements_financiers__c> lstOldCal){
        updateCaseAmount(lstOldCal);
        updateEquipSinistreChoice(lstOldCal);
    }

    /***
    * @description method to handle all after update automatisms
    * @param lstNewCal list of new Mouvements_financiers__c
    * @param mapOldCal map of old Mouvements_financiers__c
    */
    public void handleAfterUpdate(List<Mouvements_financiers__c> lstNewCal, Map<id,Mouvements_financiers__c> mapOldCal){
        processCalculIndemStatusDemande(lstNewCal,mapOldCal);
        updateCaseAmountUpdate(lstNewCal,mapOldCal);
    }
    
    /***
    * @description update amount Case
    * @param lstNewCal list of new Mouvements_financiers__c
    * @return nul
    * @exception none
    */
    public void updateCaseAmount(List<Mouvements_financiers__c> lstNewCal){
        Set<id> idSin = new Set<Id>();
        for(integer i=0; i<lstNewCal.size(); i++){
			idSin.add(lstNewCal[i].Case__c);
        }

        if(!idSin.isEmpty()){
 			CalculIndemnisationTriggerHelper.SumCalculIndemAmount(idSin);
        }
    }

    /***
    * @description update amount Case
    * @param lstNewCal list of new Mouvements_financiers__c
    * @return nul
    * @exception none
    */
    public void updateEquipSinistreChoice(List<Mouvements_financiers__c> lstOldCal){
        Set<id> idSin = new Set<Id>();
        for(integer i=0; i<lstOldCal.size(); i++){
            if(lstOldCal[i].Cout_choisi__c == 'Echange' && lstOldCal[i].Case__c != null){
                idSin.add(lstOldCal[i].Case__c);
            }
        }

        if(!idSin.isEmpty()){
 			CalculIndemnisationTriggerHelper.updateEquipeSinistreChoice(idSin);
        }
    }

    /***
    * @description update amount Case
    * @param lstNewCal list of new Mouvements_financiers__c
    * @return nul
    * @exception none
    */
    public void updateCaseAmountUpdate(List<Mouvements_financiers__c> lstNewCal,Map<id,Mouvements_financiers__c> mapOldCal){
        Set<id> idSin = new Set<Id>();
        for(integer i=0; i<lstNewCal.size(); i++){
			if(lstNewCal[i].Montant__c != mapOldCal.get(lstNewCal[i].id).Montant__c || 
                lstNewCal[i].Statut__c != mapOldCal.get(lstNewCal[i].id).Statut__c){
            	
                    idSin.add(lstNewCal[i].Case__c);    
            }
        }
        
        if(!idSin.isEmpty()){
 			CalculIndemnisationTriggerHelper.SumCalculIndemAmount(idSin);
        }
    }

    /***
    * @description method to handle all after update automatisms
    * @param lstNewCal list of new Mouvements_financiers__c
    * @param mapOldCal map of old Mouvements_financiers__c
    * @return nul
    * @exception none
    */
    public void processCalculIndemStatusDemande(List<Mouvements_financiers__c> lstNewCal, Map<id,Mouvements_financiers__c> mapOldCal){
        
        Set<id> idSin = new Set<Id>();
        Equipement_sinistre__c eqs;
        List<Equipement_sinistre__c> lstEquToUpdate;
        List<Mouvements_financiers__c> lstCal = new List<Mouvements_financiers__c>();
        List<Mouvements_financiers__c> lstCalforStoreCostPrime = new List<Mouvements_financiers__c>();
        Set<Id> lstIdCaseRepair = new Set<Id>();
        for(integer i=0; i<lstNewCal.size(); i++){
            // Choose Calcul Indem type exchange
            if( lstNewCal[i].Statut__c == STATUS_DEMANDINPROGRESS && 
                mapOldCal.get(lstNewCal[i].id).Statut__c != STATUS_DEMANDINPROGRESS && 
                lstNewCal[i].Type_mouvement__c == COSTTYPE_INTERNCOSTEXCHANGE) { 
                
                    lstCal.add(lstNewCal[i]);
            }
            // Choose Calcul Indem type prime store (magasin)
            if(lstNewCal[i].Statut__c == STATUS_DEMANDINPROGRESS 
               && mapOldCal.get(lstNewCal[i].id).Statut__c != STATUS_DEMANDINPROGRESS 
               && lstNewCal[i].Type_mouvement__c == COSTTYPE_STOREPRIMECOST) { 
                
                    lstCalforStoreCostPrime.add(lstNewCal[i]);
            }
            // Choose Calcul Indem type repair
            if(lstNewCal[i].Statut__c == STATUS_DEMANDINPROGRESS 
               && mapOldCal.get(lstNewCal[i].id).Statut__c != STATUS_DEMANDINPROGRESS 
               && lstNewCal[i].Type_mouvement__c == COSTTYPE_REPAIR) { 
                
                lstIdCaseRepair.add(lstNewCal[i].Case__c);
            }
        }

        // Process Calcul Indem type exchange
        if(!lstCal.isEmpty()){
            eqs = CalculIndemnisationTriggerHelper.GetDatasToTriggerDestockToBAppli(lstCal[0]);
            if(eqs != null){
                BAppliCallout.getFromStock(BAPPLISTOCKNAME_SFAM, eqs.ChooseEqp__r.Id_externe__c, eqs.Grade__c, eqs.Operator__c, eqs.Id, eqs.Sinistre__c);    
            }
        }
        // Process Calcul Indem type prime store
        if(!lstCalforStoreCostPrime.isEmpty()){
 			CalculIndemnisationTriggerHelper.sendEmailToCustomerAndDealer(lstCalforStoreCostPrime);
        }
        // Process Calcul Indem type repair
        if(!lstIdCaseRepair.isEmpty()){
            lstEquToUpdate = CalculIndemnisationTriggerHelper.GetEquipSinistreRepair(lstIdCaseRepair);
            if(lstEquToUpdate != null){
                // Update Status EquipSinistre
                CalculIndemnisationTriggerHelper.updateEquipeSinistreStatus(lstEquToUpdate);
                // Create Task To Owner EquipSinistre to start repair
                CalculIndemnisationTriggerHelper.createHistoToStartRepair(lstEquToUpdate);
            }
       }
    }
}