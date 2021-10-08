/***
* @author Nicolas Brancato (GFI)
* @date 07/01/2020
* @description Helper class for PaiementVersementTrigger
*/

public class PaiementVersementTriggerHelper {

    /***
	* @description Get related Mouvements_financiers__c
	* @param newPVList list of new Paiement_Versement__c 
	* @return Map<id, List<Mouvements_financiers__c>> map of related MF
	*/
    public static Map<id, List<Mouvements_financiers__c>> getRelatedMF(List<Paiement_Versement__c> newPVList){
        
        Set<id> caseIdSet = new Set<id>();
        for(Paiement_Versement__c pv : newPVList){
            caseIdSet.add(pv.Case__c);
        }
        
        List<Mouvements_financiers__c> relatedMFList = [SELECT id, Case__c, Paiement_Versement__c
                                                        FROM Mouvements_financiers__c
                                                        WHERE Case__c IN: caseIdSet
                                                        AND Statut__c = 'Validé'
                                                        AND Cout_choisi__c IN ('Primes','Règlement par le client')];
        
        Map<id, List<Mouvements_financiers__c>> relatedMFMap = new Map<id, List<Mouvements_financiers__c>>();
        for(Mouvements_financiers__c mf : relatedMFList){
            if(!relatedMFMap.keySet().contains(mf.Case__c)){
                List<Mouvements_financiers__c> tmpList = new List<Mouvements_financiers__c>();
                relatedMFMap.put(mf.Case__c, tmpList);
            }
            relatedMFMap.get(mf.Case__c).add(mf);
        }
        
        return relatedMFMap;
    }
    
    /***
	* @description Get Id_contrat_B_appli__c to trigger payment to BAppli
	* @param lstPay list of Paiement_Versement__c with status equal to "Demande Versement"
	* @return List<Paiement_Versement__c> List of Paiement_Versement__c with the Id_contrat_B_appli__c from the parent asset
	*/
    public static List<Paiement_Versement__c> GetDatasToTriggerPaymentToBAppli(List<Paiement_Versement__c> lstPay){
        
        return new list<Paiement_Versement__c>([SELECT id, Case__c, Case__r.Asset.Name, Montant__c
                                                FROM Paiement_Versement__c
                                                WHERE Id IN: lstPay]);
    }
}