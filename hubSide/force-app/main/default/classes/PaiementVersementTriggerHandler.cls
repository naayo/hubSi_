/***
* @author Nicolas Brancato (GFI)
* @date 07/01/2020
* @description Handler class for PaiementVersementTrigger
*/

public class PaiementVersementTriggerHandler {    
    
    static final String STATUS_TRANSFER = 'Demande Versement';
    
    /***
    * @description Update related MF after insert
    * @param newPVList list of new Paiement_Versement__c
    * @return null
    * @exception none
    */
    public void updateRelatedMF(List<Paiement_Versement__c> newPVList, Map<id, List<Mouvements_financiers__c>> relatedMFMap){
        
        List<Mouvements_financiers__c> MFToUpdate = new List<Mouvements_financiers__c>();
        for(Paiement_Versement__c pv : newPVList){
            if(relatedMFMap.keySet().contains(pv.Case__c)){
                for(Mouvements_financiers__c mf : relatedMFMap.get(pv.Case__c)){
                    MFToUpdate.add(new Mouvements_financiers__c(id = mf.id, 
                                                                Paiement_Versement__c = pv.id));
                }
            }
        }
        update MFToUpdate;
    }
    
    /***
    * @description method to handle all after insert automatisms
    * @param lstNewPay list of new Paiement_Versement__c
    * @return nul
    * @exception none
    */
    public void handleAfterInsert(List<Paiement_Versement__c> lstNewPay){
        
        List<Paiement_Versement__c> lstPay = new List<Paiement_Versement__c>();
        for(integer i=0; i<lstNewPay.size(); i++){
            if(lstNewPay[i].Statut__c == STATUS_TRANSFER){ 
                lstPay.add(lstNewPay[i]);
            }
        }
        List<Paiement_Versement__c>listPayWithBAppliContractId = PaiementVersementTriggerHelper.GetDatasToTriggerPaymentToBAppli(lstPay);
        
        for(integer i=0; i<listPayWithBAppliContractId.size(); i++){
            BAppliCallout.sendPayment(listPayWithBAppliContractId[i].Case__c, listPayWithBAppliContractId[i].id, listPayWithBAppliContractId[i].Case__r.Asset.Name, listPayWithBAppliContractId[i].Montant__c);
            
        }
    }
}