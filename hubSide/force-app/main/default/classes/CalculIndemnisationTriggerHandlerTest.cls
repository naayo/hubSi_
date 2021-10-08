/***
* @author Nicolas Brancato (GFI)
* @date 12/03/2021
* @description Class test for CalculIndemnisationTriggerHandler
*/
@isTest
public class CalculIndemnisationTriggerHandlerTest {
    
    public static final String PROFILE_GS = 'SFAM GS';
    public static User GSUser;
    public static Account a;
    public static Asset c;
    public static Case s;
    public static Mouvements_financiers__c calCulIndemExchangeStorePremiumCost;
    public static Mouvements_financiers__c calCulIndemExchangeRepair;
    public static Mouvements_financiers__c calCulIndemFranchise;
    public static Equipement_sinistre__c eqs;
    public static Equipement_sinistre__c eqsRepair;
    
    /***
    * @description Static method to initialize all the datas for the test methods
    */
    static{
        
        List<Mouvements_financiers__c> lstMouv = new List<Mouvements_financiers__c>();
        List<Equipement_sinistre__c> lstEquip = new List<Equipement_sinistre__c>();
        
        Id profileGSId = [SELECT Id 
                          FROM Profile  
                          WHERE name =: PROFILE_GS].Id;
        
        GSUser = TestFactory.createUser();
        GSUser.ProfileId = profileGSId;
        GSUser.Email = 'guillaume.gs@yopmail.com';
        insert GSUser;
        
        // Create a new contract as system admin because the contract is sent by Bappli
        c = TestFactory.createAssuranceAssetWithFormula();
        
        // Create a insured item
        vlocity_ins__AssetInsuredItem__c InsuredItem = new vlocity_ins__AssetInsuredItem__c(Account__c = c.accountId, vlocity_ins__PolicyAssetId__c = c.id);
        insert InsuredItem;
        
        // Create a sinistre
        s = TestFactory.createSinistre(c.AccountId, c.id);
        s.Email_Contact__c = 'temp@yopmail.com';
        s.Equipement_client__c = InsuredItem.id;
        insert s;
        
        System.runAs(GSUser){
            
           //Create a calcul indemnisation type exchange
            calCulIndemExchangeStorePremiumCost = TestFactory.createMouvementFinancier(s.id);
            calCulIndemExchangeStorePremiumCost.Libelle__c = 'TEST';
            calCulIndemExchangeStorePremiumCost.Cout_choisi__c = 'Echange';
            calCulIndemExchangeStorePremiumCost.Montant__c = 100;
            calCulIndemExchangeStorePremiumCost.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_STOREPRIMECOST;

            //Create a calcul indemnisation type repair
            calCulIndemExchangeRepair = TestFactory.createMouvementFinancier(s.id);
            calCulIndemExchangeRepair.Libelle__c = 'TEST';
            calCulIndemExchangeRepair.Cout_choisi__c = 'Réparation';
            calCulIndemExchangeRepair.Montant__c = 120;
            calCulIndemExchangeRepair.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_REPAIR;
           
            //Create a calcul indemnisation type franchise
            calCulIndemFranchise = TestFactory.createMouvementFinancier(s.id);
            calCulIndemFranchise.Libelle__c = 'TEST';
            calCulIndemFranchise.Cout_choisi__c = 'Règlement par le client';
            calCulIndemFranchise.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_FRANCHISE;
            calCulIndemFranchise.Montant__c = -55;
            
            lstMouv.add(calCulIndemExchangeStorePremiumCost);
            lstMouv.add(calCulIndemExchangeRepair);
            lstMouv.add(calCulIndemFranchise);
            insert lstMouv;
            
            // Create a damaged equipement
        	eqs = new Equipement_sinistre__c(Sinistre__c = s.id, EquipmentAmount__c = 12, RealCost__c = 0, Montant_equipement__c = 12, ClientChoiceDate__c = Date.today());
            lstEquip.add(eqs);
            

            // Create a damaged equipement
        	eqsRepair = new Equipement_sinistre__c(Sinistre__c = s.id, EquipmentAmount__c = 12, RealCost__c = 0, Montant_equipement__c = 12, ClientChoiceDate__c = Date.today());
            lstEquip.add(eqsRepair);
            insert lstEquip;
        }      
    }    

    /***
    * @description Test method for the handleBeforeUpdate method in CalculIndemnisationTriggerHandler
    */
    @isTest
    static void test_handleBeforeUpdate() {
        
        Test.startTest();
        System.runAs(GSUser){
            try{
                calCulIndemExchangeStorePremiumCost.Name = 'Test';
                update calCulIndemExchangeStorePremiumCost;
            }
            catch(Exception e){
                String message = e.getMessage();
                system.assert(message.contains(Label.Sinistre_ErrorMessageEditionNameCalculIndem), 'message=' + message);
                system.debug('message' + message);
            }
        }
        
        
        Test.stopTest();
        system.assertNotEquals('Test', [SELECT id, Name 
                                        FROM Mouvements_financiers__c 
                                        WHERE id =: calCulIndemExchangeStorePremiumCost.id].Name);
    }    

    /***
    * @description Checks whether the recently updated status on MF are closed - if so, proceeds to close the related case
    * @see updateRelatedCase
    */
    @isTest
    static void updateRelatedCaseTest() {
        
        List<Mouvements_financiers__c> lstMovToUpdate= new List<Mouvements_financiers__c>();

        test.startTest();
        
        // Create another MF
        Mouvements_financiers__c m = TestFactory.createMouvementFinancier(s.id);
        m.Cout_choisi__c = 'Echange';
        m.Type_mouvement__c = 'Cout prime magasin';
        insert m;
        
        // And close it
        m.Statut__c = 'Rejected';
        update m;
        
        // Check whether the case has been closed
        s = [SELECT id, Status FROM Case WHERE id =: s.id];
        system.assertEquals('Reception_dossier', s.Status, 
                            'The case shouldnt have been closed - This is wrong');
        
        // Close the previous MF
        calCulIndemExchangeRepair.Statut__c = 'Completed';

        // Then close the current MF
        calCulIndemExchangeStorePremiumCost.Cout_choisi__c = 'Primes';
        calCulIndemExchangeStorePremiumCost.Type_mouvement__c = 'Prime pour echange';
        calCulIndemExchangeStorePremiumCost.Statut__c = 'Completed';

        calCulIndemFranchise.Statut__c = 'Completed';

        lstMovToUpdate.add(calCulIndemExchangeRepair);
        lstMovToUpdate.add(calCulIndemExchangeStorePremiumCost);
        lstMovToUpdate.add(calCulIndemFranchise);
        update lstMovToUpdate;

        test.stopTest();
        
        // Check whether the case has been closed
        s = [SELECT id, Status, Equipement_client__c FROM Case WHERE id =: s.id]; 
        system.assertEquals('closed_exchange', s.Status, 
                            'The case shouldve been closed - This is wrong');
        
        // Check insured item status and reason
        vlocity_ins__AssetInsuredItem__c i = [SELECT id, Etat__c, Motif__c FROM vlocity_ins__AssetInsuredItem__c WHERE id =: s.Equipement_client__c]; 
        system.assertEquals(CalculIndemnisationTriggerHelper.INSUREDITEM_STATUS_INACTIVE, i.Etat__c, 
                            'The insured item shouldve been inactive - This is wrong');
        
        system.assertEquals(CalculIndemnisationTriggerHelper.INSUREDITEM_REASON_EXCHANGE, i.Motif__c, 
                            'The insured item state shouldve been Echange - This is wrong');
        
        // Check damaged equipment status and substatus
        Equipement_sinistre__c eq = [SELECT id, Statut_equipement__c, Sous_statut__c FROM Equipement_sinistre__c WHERE Sinistre__c =: s.id LIMIT 1]; 
        system.assertEquals(CalculIndemnisationTriggerHelper.EQUIPMENTSINISTRE_STATUS_EXCHANGE, eq.Statut_equipement__c, 
                            'The damaged equipment status shouldve been échangé - This is wrong');
        
        system.assertEquals(CalculIndemnisationTriggerHelper.EQUIPMENTSINISTRE_UNDERSTATUS_PRENIUM, eq.Sous_statut__c, 
                            'The damaged equipment sub status shouldve been "Via primes" - This is wrong');
    }    
    
    /***
    * @description Test method for the handleBeforeDelete method in CalculIndemnisationTriggerHandler
    */
    @isTest
    static void test_handleBeforeDelete() {
        
        Test.startTest();
        System.runAs(GSUser){
            calCulIndemExchangeStorePremiumCost.Statut__c = CalculIndemnisationTriggerHandler.STATUS_VALIDATED;
            update calCulIndemExchangeStorePremiumCost;
            try{
            	delete calCulIndemExchangeStorePremiumCost;
            }
            catch(Exception e){
         		String message = e.getMessage();
                system.assert(message.contains(Label.Sinistre_ErrorMessageDeletionCalculIndem), 'message=' + message);
        	}
        }
        Test.stopTest();
        system.assertNotEquals(null, [Select id, Name From Mouvements_financiers__c where id =: calCulIndemExchangeStorePremiumCost.id]);
    }
    
    /***
    * @description Test method for the handleAfterUpdate method in CalculIndemnisationTriggerHandler
    */
    @isTest
    static void test_handlerAfterUpdate() {
        
        Test.startTest();
        System.runAs(GSUser){
            Equipement_sinistre__c eqBefore = [Select Id,Statut_equipement__c,Sous_statut__c FROM Equipement_sinistre__c WHERE Id=:eqsRepair.Id];
            
            Id idRecordTypeRepairEquip = UtilityClassHelper.getCreatedRecordType(CalculIndemnisationTriggerHelper.EQUIPMENTRECORDTYPE_REPAIR);
            eqBefore.RecordTypeId = idRecordTypeRepairEquip;
            
            update eqBefore;
            
            calCulIndemExchangeRepair.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            calCulIndemExchangeStorePremiumCost.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            List<Mouvements_financiers__c> lstmv = new List<Mouvements_financiers__c>();
            lstmv.add(calCulIndemExchangeRepair);
            lstmv.add(calCulIndemExchangeStorePremiumCost);            
            
            update lstmv;
        }
        Test.stopTest();
        Equipement_sinistre__c eqAfter = [Select Id,Statut_equipement__c,Sous_statut__c FROM Equipement_sinistre__c WHERE Id=:eqsRepair.Id];
        Case caseAfter = [Select Id, Montant_sinistre__c FROM Case WHERE Id=:s.id];
        

        System.assertEquals(CalculIndemnisationTriggerHelper.EQUIPMENTSINISTRE_STATUS_INPROGRESSREPAIR,eqAfter.Statut_equipement__c);
        System.assertEquals(CalculIndemnisationTriggerHelper.EQUIPMENTSINISTRE_UNDERSTATUS_INPROGRESS,eqAfter.Sous_statut__c);
        System.assertEquals(165, caseAfter.Montant_sinistre__c);
        /*system.assertEquals(CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS, [Select id, Statut__c 
                                                                                        From Mouvements_financiers__c 
                                                                                        where id =: calCulIndemExchangeStorePremiumCost.id].Statut__c);*/
    }
    
    /***
    * @description Test method for the handleAfterDelete method in CalculIndemnisationTriggerHandler
    */
    @isTest
    static void test_handleAfterDelete() {
        
        Test.startTest();
        System.runAs(GSUser){
            delete calCulIndemExchangeStorePremiumCost;
        }
        Test.stopTest();
        Equipement_sinistre__c eqAfter = [Select Id,ClientChoiceDate__c FROM Equipement_sinistre__c WHERE Id=:eqs.Id];
        System.assertEquals(eqAfter.ClientChoiceDate__c,null);
    }
}