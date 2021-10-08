/***
* @author Ariane Tanguy (GFI)
* @date 27/04/2021
* @description Paiement Versement test class
* @Object Paiement Versement
*/

@isTest
public class PaiementVersementTriggerHandlerTest {

    /***
    * @description Update related MF after insert
    * @see updateRelatedMF
    */
    @isTest
    public static void updateRelatedMFTest(){
        
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
        
        // Create an indemnisation
        Mouvements_financiers__c m = TestFactory.createMouvementFinancier(c.id);
        insert m;
        
        // Approve the indemn
        m.Statut__c = 'Validé';
        update m;
        
        // And create a paiement versement
        Paiement_Versement__c p = new Paiement_Versement__c();
        p.Case__c = c.id;
        p.Montant__c = m.Montant__c;
        insert p;
        
        m = [SELECT id, Paiement_Versement__c 
             FROM Mouvements_financiers__c
             WHERE id =: m.id];
        
        system.assertEquals(p.id, m.Paiement_Versement__c, 
                            'The paiement versement shoulve been updated - This is wrong');
    }
}