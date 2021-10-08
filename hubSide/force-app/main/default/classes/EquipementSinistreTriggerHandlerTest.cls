/***
* @author Nicolas Brancato (GFI)
* @date 22/02/2021
* @description Class test for EquipementSinistreTriggerHandler
*/
@isTest
public class EquipementSinistreTriggerHandlerTest {    
    
    public static final String PROFILE_GS = 'SFAM GS';
    public static final String PROFILE_LOGISTIQUE = 'SFAM Logistique';
    public static User LogisticUser;
    public static User GSUser;
    public static Account a;
    public static Asset c;
    public static Case s;
    public static Mouvements_financiers__c calCulIndemExchange;
    public static Equipement_sinistre__c eqsExchangeWithNoCalculIndemExch;
    public static Equipement_sinistre__c eqs;
    public static Case SinistreNoCalculIndem;
    public static Matrice_cout_equipement__c matrice;
    
    /***
    * @description Static method to initialize all the datas for the test methods
	*/
    static{
        
        // Create two users
        Id profileGSId = [SELECT Id 
                          FROM Profile  
                          WHERE name =: PROFILE_GS].Id;
        Id profileLogisticId = [SELECT Id 
                                FROM Profile  
                                WHERE name =: PROFILE_LOGISTIQUE].Id;
        
        List<User> userToInsert = new List<User>();
        
        GSUser = TestFactory.createUser();
        GSUser.ProfileId = profileGSId;
        GSUser.Email = 'guillaume.gs@yopmail.com';
        userToInsert.add(GSUser);
        
        LogisticUser = TestFactory.createUser();
        LogisticUser.ProfileId = profileLogisticId;
        LogisticUser.Email = 'didier.logistique@yopmail.com';
        LogisticUser.Username = 'didier.logistique@yopmail.com.test';
        userToInsert.add(LogisticUser);
        
        insert userToInsert;

        // Create a new contract as system admin because the contract is sent by Bappli
        c = TestFactory.createAssuranceAssetWithFormula();
        
        // Create two sinistre
        List<Case> caseToInsert = new List<Case>();
        SinistreNoCalculIndem = TestFactory.createSinistre(c.AccountId, c.id);
        caseToInsert.add(SinistreNoCalculIndem);
        s = TestFactory.createSinistre(c.AccountId, c.id);
        caseToInsert.add(s);
        insert caseToInsert;

        matrice = TestFactory.createMatrice(null, true);
        insert matrice;
        
        System.runAs(GSUser){
            
            //Create a calcul indemnisation type exchange
            calCulIndemExchange = TestFactory.createMouvementFinancier(s.id);
            calCulIndemExchange.Libelle__c = 'TEST';
            calCulIndemExchange.Cout_choisi__c = 'Echange';
            calCulIndemExchange.case__c = s.id;
            calCulIndemExchange.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_INTERNCOSTEXCHANGE;
            insert calCulIndemExchange;
            
            // Create an insured item
            vlocity_ins__AssetInsuredItem__c i = new vlocity_ins__AssetInsuredItem__c();
            i.vlocity_ins__PolicyAssetId__c = c.id;
            insert i;
            
            // Create two equipement sinistre - a damaged one and one with no calcul indemnisation exchange type
            List<Equipement_sinistre__c> equipSinToInsert = new List<Equipement_sinistre__c>();
            
            eqs = new Equipement_sinistre__c(Sinistre__c = s.id, 
                                             EquipmentAmount__c = 12, 
                                             RealCost__c = 0, 
                                             Montant_equipement__c = 12, 
                                             equipement_client__c = i.id, 
                                             RecordTypeId = UtilityClassHelper.getCreatedRecordType('Equipement_vole_perdu'));
            equipSinToInsert.add(eqs);
            eqsExchangeWithNoCalculIndemExch = new Equipement_sinistre__c(Sinistre__c = SinistreNoCalculIndem.id);
            equipSinToInsert.add(eqsExchangeWithNoCalculIndemExch);
            insert equipSinToInsert;
        }      
    }
    
    /***
    * @description Update the equipSin name on insert
    * @see handleBeforeInsert
    */
    @isTest
    public static void handleBeforeInsertTest(){
        
        // Get the sinistre and equipSin
        s = [SELECT id, Numero_sinistre__c
             FROM Case
             WHERE id =: s.id];
        eqs = [SELECT id, Name 
               FROM Equipement_sinistre__c
               WHERE id =: eqs.id];
        
        system.assertEquals(true, eqs.Name.contains(s.Numero_sinistre__c), 
                           'The equipSin name shouldve been updated with the sinistres number - This is wrong');        
    }
    
    /***
    * @description Update some insured item fields on equipement sinistre update
    * @see handleEquipSinReparation
    */
    @isTest
    public static void handleEquipSinReparationTest(){
        
        test.startTest();
        
        // Get the equipSin
        eqs = [SELECT id, Sinistre__c, 
               Statut_equipement__c, Equipement_client__c
               FROM Equipement_sinistre__c
               WHERE id =: eqs.id];
        
        // Create a calcul indemnisation
        Mouvements_financiers__c m = new Mouvements_financiers__c();
        m.Case__c = eqs.Sinistre__c;
        m.Cout_choisi__c = 'Echange';
        m.Montant__c = 100;
        insert m;
        
        // Update its status
        eqs.Statut_equipement__c = 'CustomerReception';
        update eqs;
        
        // Get the updated insured item
        vlocity_ins__AssetInsuredItem__c i = [SELECT id, Etat__c, Motif__c, Dernier_sinistre__c, LastReparationDate__c, ReparationCount__c
                                             FROM vlocity_ins__AssetInsuredItem__c
                                             WHERE id =: eqs.Equipement_client__c];
        
        system.assertEquals('inactive', i.Etat__c, 
                           'The insured item status shouldve been updated - This is wrong');
        
        // Get the updated calcul indemnisation
        m = [SELECT id, Statut__c
             FROM Mouvements_financiers__c
             WHERE id =: m.id];
        
        test.stopTest();
        
        system.assertEquals('Completed', m.Statut__c, 
                           'The calc indemn status shouldve been updated - This is wrong');
        
        // Check the new insured item created
        /*vlocity_ins__AssetInsuredItem__c newI = [SELECT id, Dernier_sinistre__c
                                                 FROM vlocity_ins__AssetInsuredItem__c
                                                 WHERE id !=: eqs.Equipement_client__c];
        system.assertEquals(eqs.Sinistre__c, newI.Dernier_sinistre__c, 
                           'A new insured item shouldve been created - This is wrong');*/
    }
    
    /***
    * @description Test method for the handleAfterUpdate method in EquipementSinistreTriggerHandler
    */
    @isTest
    static void test_handlerAfterUpdate() {
        
        Test.startTest();
        System.runAs(GSUser){
            calCulIndemExchange.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            update calCulIndemExchange;
            
        	eqs.ClientChoiceDate__c = Date.today();
            eqs.ChooseEqp__c = matrice.Id;
            eqs.EquipmentAmount__c = 10;
            update eqs;
            
            eqsExchangeWithNoCalculIndemExch.ClientChoiceDate__c = Date.today();
            update eqsExchangeWithNoCalculIndemExch;
        }
        Test.stopTest();
        
        // Check whether the calc indemn has been updated with the equipSin real cost
        calCulIndemExchange = [SELECT id, Montant__c 
                               FROM Mouvements_financiers__c 
                               WHERE id =: calCulIndemExchange.id];
        eqs = [SELECT id, RealCost__c FROM Equipement_sinistre__c WHERE id =: eqs.id];
        
        system.assertEquals(eqs.RealCost__c, calCulIndemExchange.Montant__c,
                           'The calcIndemn montant shouldve been updated - This is wrong');
        
        /*TO REFACTORING 
            system.assertEquals(CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS, 
                            [SELECT id, Statut__c 
                             FROM Mouvements_financiers__c 
                             WHERE id =: calCulIndemExchange.id].Statut__c);*/
    }
    
    
    /***
    * @description Test method for the getStockAfterOrderReception method in EquipementSinistreTriggerHelper
    */
    @isTest
    static void test_getStockAfterOrderReception() {
        
        Test.startTest();
        System.runAs(LogisticUser){
            EquipementSinistreTriggerHelper.getStockAfterOrderReception(new list<id>{eqs.id});
        }
        Test.stopTest();
    }
}