/***
* @author Nicolas Brancato (GFI)
* @date 20/01/2021
* @description Callout class test for outbound call with BAppli services
* DATE          DEV         DESCRIPTION
*/
@isTest
public class BAppliCalloutTest {    
    
	static final String STATUS_TRANSFER = 'Demande Versement';
    public static final String PROFILE_GS = 'SFAM GS';
    public static User GSUser;
    public static Asset c;
    public static Asset wrongContract;
    public static Case s;
    public static Case wrongSinistre;
    public static Mouvements_financiers__c mf;
    public static Mouvements_financiers__c calCulIndemExchange;
    public static Mouvements_financiers__c calCulIndemExchangeWithNoDamagedEquipmentExch;
    public static Equipement_sinistre__c eqs;
    
    /***
    * @description Static method to initialize all the datas for the test methods
    */
    static{
        
        GSUser = TestFactory.createUser();
        GSUser.ProfileId = [SELECT Id FROM Profile WHERE name =: PROFILE_GS].Id;
        GSUser.Email = 'guillaume.gs@yopmail.com';
        insert GSUser;
        
        // Create two contracts
        List<Asset> assetList = TestFactory.createAssuranceAssetList(2);
        
        // Create a new contract as system admin because the contract is sent by Bappli        
        c = assetList[0];
        c.Name = '0220010102';
        c.Id_externe__c = 'INS0220010102';
        c.Id_contrat_B_appli__c = '5343473';
        
        // Create a wrong contract which is not existing in Bappli
        wrongContract = assetList[1];
        wrongContract.Name = '0220010102';
        wrongContract.Id_externe__c = 'INS0220010103';
        wrongContract.Id_contrat_B_appli__c = '000000';
        insert assetList;
        
        List<Account> accList = [SELECT id FROM Account];
        
        // Create two cases
        List<Case> caseList = TestFactory.createSinistreList(accList, assetList, 2);
        s = caseList[0];
        wrongSinistre = caseList[1];
        insert caseList;
        
        System.runAs(GSUser){
            
            // Create three calcul indemnisation
            List<Mouvements_financiers__c> mvtFinToInsertList = new List<Mouvements_financiers__c>();
            
            mf = TestFactory.createMouvementFinancier(s.id);
			mf.Sens_mouvement__c = 'Règlement par le client';
            mf.Type_mouvement__c = null;
			mvtFinToInsertList.add(mf); 
            
            //Create a calcul indemnisation type exchange
            calCulIndemExchange = TestFactory.createMouvementFinancier(s.id);
            calCulIndemExchange.Cout_choisi__c = 'Echange';
            calCulIndemExchange.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_INTERNCOSTEXCHANGE;
            mvtFinToInsertList.add(calCulIndemExchange);
            
            //Create a calcul indemnisation type exchange with no damaged equipment
            calCulIndemExchangeWithNoDamagedEquipmentExch = TestFactory.createMouvementFinancier(wrongSinistre.id);
            calCulIndemExchangeWithNoDamagedEquipmentExch.Cout_choisi__c = 'Echange';
            calCulIndemExchangeWithNoDamagedEquipmentExch.Type_mouvement__c = CalculIndemnisationTriggerHandler.COSTTYPE_INTERNCOSTEXCHANGE;
            mvtFinToInsertList.add(calCulIndemExchangeWithNoDamagedEquipmentExch);
            insert mvtFinToInsertList;
            
            Id rtId = UtilityClassHelper.getCreatedRecordType(CalculIndemnisationTriggerHelper.DAMAGEDEQUIPMENTRECORDTYPE_ECHANGE);
            // Create a damaged equipement
        	eqs = new Equipement_sinistre__c(Sinistre__c = s.id, ClientChoiceDate__c = Date.today(), RecordTypeId = rtId );
        	insert eqs;
        }      
    }
    
    
    /***
    * @description Test method for the CalculIndemnisationTrigger and the getFROMStock method in BAppliCallout class. 
    * This test method mocks a fake response with a success in return.
    * The body returns an imei number, a stock fluctuation reference and the cost of material removed FROM storage.
    */
    @isTest
    static void test_getFromStock200() {
        
        HttpMockFactory mock = new HttpMockFactory(200, '', 
                                                   '{"imei":"355328086961253","stockFluctuationRef":"NUM_99999999","cost":"100"}', 
                                                   new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        
        System.runAs(GSUser){
        	calCulIndemExchange.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            update calCulIndemExchange;
        }
        Test.stopTest();
        
        system.assertEquals(BAppliCallout.DAMAGEDEQUIPMENTSTATUS_DESTOCK, [SELECT id, Statut_equipement__c 
                                                                           FROM Equipement_sinistre__c 
                                                                           WHERE id =: eqs.id].Statut_equipement__c);
        system.assertEquals('355328086961253', [SELECT id, SerieNumberEC__c 
                                                FROM Equipement_sinistre__c 
                                                WHERE id =: eqs.id].SerieNumberEC__c);
        system.assertEquals('NUM_99999999', [SELECT id, BAppliStockFluctuationRef__c 
                                             FROM Equipement_sinistre__c 
                                             WHERE id =: eqs.id].BAppliStockFluctuationRef__c);
        system.assertEquals(null, [SELECT id, CalloutErrorMessage__c 
                                   FROM CalloutErrorsManagement__c 
                                   WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c);
        system.assertEquals(200, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE CaseRecord__c =: s.id].CalloutStatusCode__c));
    }
    
    /***
    * @description Test method for the CalculIndemnisationTrigger and the getFromStock method in BAppliCallout class. 
    * This test method mocks a fake response with a 404 error in return.
    * A 404 error from Bappli means the error is functional. 
    * Possible message is « imei not available ».
    */
    @isTest
    static void test_getFromStock404() {
        
        HttpMockFactory mock = new HttpMockFactory(404,'Bad Request', 'imei not available', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        
        System.runAs(GSUser){
        	calCulIndemExchange.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            update calCulIndemExchange;
        }
        Test.stopTest();
        
        system.assertEquals(BAppliCallout.DAMAGEDEQUIPMENTSTATUS_ORDER, [SELECT id, Statut_equipement__c 
                                                                         FROM Equipement_sinistre__c 
                                                                         WHERE id =: eqs.id].Statut_equipement__c);
        system.assertEquals(null, [SELECT id, BAppliStockFluctuationRef__c 
                                   FROM Equipement_sinistre__c 
                                   WHERE id =: eqs.id].BAppliStockFluctuationRef__c);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c.contains('imei not available'));
        system.assertEquals(404, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE CaseRecord__c =: s.id].CalloutStatusCode__c));
    }
    
    /***
    * @description Test method for the CalculIndemnisationTrigger and the getFromStock method in BAppliCallout class. 
    * This test method mock a fake response with a 500 error in return.
    * A 500 error from Bappli means the error is technical. Possible message can be « erreur interne ».
    */
    @isTest
    static void test_getFromStock500() {
        
        HttpMockFactory mock = new HttpMockFactory(500,'Bad Request', 'erreur interne', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.runAs(GSUser){
        	calCulIndemExchange.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            update calCulIndemExchange;
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, SerieNumberEC__c 
                                   FROM Equipement_sinistre__c 
                                   WHERE id =: eqs.id].SerieNumberEC__c);
        system.assertEquals(null, [SELECT id, BAppliStockFluctuationRef__c 
                                   FROM Equipement_sinistre__c 
                                   WHERE id =: eqs.id].BAppliStockFluctuationRef__c);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c.contains('erreur interne'));
        system.assertEquals(500, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE CaseRecord__c =: s.id].CalloutStatusCode__c));
    }
    
    
    /***
    * @description Test method for the CalculIndemnisationTrigger and the getFromStock method in BAppliCallout class. This test method mock a catch exception.
    */
    @isTest
    static void test_getFromStockCatchTest() {
        
        HttpMockFactory mock = new HttpMockFactory(200,'', '{\'imei\' => \'355328086961253\',\'stockFluctuationRef\' => \'NUM_99999999\',\'cost\' => \'100\'}',
                                                   new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.runAs(GSUser){
        	calCulIndemExchange.Statut__c = CalculIndemnisationTriggerHandler.STATUS_DEMANDINPROGRESS;
            update calCulIndemExchange;
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, SerieNumberEC__c 
                                   FROM Equipement_sinistre__c 
                                   WHERE id =: eqs.id].SerieNumberEC__c);
        system.assertEquals(null, [SELECT id, BAppliStockFluctuationRef__c 
                                   FROM Equipement_sinistre__c 
                                   WHERE id =: eqs.id].BAppliStockFluctuationRef__c);
        system.assertNotEquals(null, [SELECT id, CalloutErrorMessage__c 
                                      FROM CalloutErrorsManagement__c 
                                      WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c);
        system.assertEquals(200, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE CaseRecord__c =: s.id].CalloutStatusCode__c));
    }
    
    
	/***
    * @description Test method for the PaiementVersementTrigger and the sendPayment method in BAppliCallout class.
    * This test method mock a fake response with a success in return.
    * The Bappli event identifiant is returned in the body.
    */
    @isTest
    static void test_sendPayment200() {
        
        HttpMockFactory mock = new HttpMockFactory(200,'', '1860219693', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Paiement_Versement__c pv;
        Test.startTest();
        System.runAs(GSUser){
            pv = new Paiement_Versement__c(Case__c = s.id, 
                                           Montant__c = mf.Montant__c, 
                                           Name = 'REG' +'-'+ string.valueof(DateTime.Now())+' - GMT', Statut__c = STATUS_TRANSFER);
            insert pv;            
        }
        Test.stopTest();
        system.assertEquals('1860219693', [SELECT id, BAppliEventId__c FROM Paiement_Versement__c WHERE id =: pv.id].BAppliEventId__c);
        system.assertEquals(null, [SELECT id, CalloutErrorMessage__c 
                                   FROM CalloutErrorsManagement__c 
                                   WHERE PaiementVersementLink__c =: pv.id].CalloutErrorMessage__c);
        system.assertEquals(200, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE PaiementVersementLink__c =: pv.id].CalloutStatusCode__c));
    }
    
    
    /***
    * @description Test method for the PaiementVersementTrigger and the sendPayment method in BAppliCallout class. 
    * This test method mock a fake response with a 400 error in return.
    * A 400 error from Bappli means the error is functional. 
    * Possible messages can be « type not found », « contract not found », « user not found », « invalid amount ».
    */
    @isTest
    static void test_sendPayment400() {
        
        HttpMockFactory mock = new HttpMockFactory(400,'Bad Request', 'contract not found', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Paiement_Versement__c pv;
        Test.startTest();
        System.runAs(GSUser){
            pv = new Paiement_Versement__c(Case__c = wrongSinistre.id, 
                                           Montant__c = mf.Montant__c, 
                                           Name = 'REG' +'-'+ string.valueof(DateTime.Now())+' - GMT', 
                                           Statut__c = STATUS_TRANSFER);
            insert pv;
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, BAppliEventId__c FROM Paiement_Versement__c WHERE id =: pv.id].BAppliEventId__c);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE PaiementVersementLink__c =: pv.id].CalloutErrorMessage__c.contains('contract not found'));
        system.assertEquals(400, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE PaiementVersementLink__c =: pv.id].CalloutStatusCode__c));
    }
    
    
    /***
    * @description Test method for the PaiementVersementTrigger and the sendPayment method in BAppliCallout class. 
    * This test method mock a fake response with a 500 error in return.
    * A 500 error from Bappli means the error is technical. Possible message can be « erreur interne de création du paiement ».
    */
    @isTest
    static void test_sendPayment500() {
        
        HttpMockFactory mock = new HttpMockFactory(500,'Bad Request', 'erreur interne de création du paiement', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Paiement_Versement__c pv;
        Test.startTest();
        System.runAs(GSUser){
            pv = new Paiement_Versement__c(Case__c = wrongSinistre.id, 
                                           Montant__c = mf.Montant__c, 
                                           Name = 'REG' +'-'+ string.valueof(DateTime.Now())+' - GMT', 
                                           Statut__c = STATUS_TRANSFER);
            insert pv;
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, BAppliEventId__c FROM Paiement_Versement__c WHERE id =: pv.id].BAppliEventId__c);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE PaiementVersementLink__c =: pv.id].CalloutErrorMessage__c.contains('erreur interne de création du paiement'));
        system.assertEquals(500, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE PaiementVersementLink__c =: pv.id].CalloutStatusCode__c));
    }
    
    /***
    * @description Test method for the PaiementVersementTrigger and the sendPayment method in BAppliCallout class. 
    * This test method mock a catch exception.
    */
    @isTest
    static void test_sendPaymentCatchTest() {
        
        HttpMockFactory mock = new HttpMockFactory(null,'', null, new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Paiement_Versement__c pv;
        Test.startTest();
        System.runAs(GSUser){
            pv = new Paiement_Versement__c(Case__c = wrongSinistre.id, 
                                           Montant__c = mf.Montant__c, 
                                           Name = 'REG' +'-'+ string.valueof(DateTime.Now())+' - GMT', 
                                           Statut__c = STATUS_TRANSFER);
            insert pv;
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, BAppliEventId__c FROM Paiement_Versement__c WHERE id =: pv.id].BAppliEventId__c);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE PaiementVersementLink__c =: pv.id].CalloutErrorMessage__c.contains('Argument 1 cannot be null'));
    }  
}