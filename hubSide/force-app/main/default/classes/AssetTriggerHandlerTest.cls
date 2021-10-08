/***
* @author Ariane Tanguy (GFI)
* @date 12/05/2020
* @description AssetTrigger test class
* @Object Asset
*/

@isTest
public class AssetTriggerHandlerTest {
    
    /***
    * @description Update the account record type
    * @see updateAccountRecordType
    */
    @isTest
    public static void updateAccountRecordTypeTest(){
        
        // Create a client
        Account a = TestFactory.createClient();
        a.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Client_SFAM');
        insert a;
        
        // Create a contract
        Asset c = TestFactory.createContract(a.id);
        insert c;
        
        // Query the account and check whether the record type is location
        a = [SELECT id, Record_Type_Name__c FROM Account WHERE id =: a.id];
        system.assertEquals('Client_location', a.Record_Type_Name__c, 
                            'The record type should have been updated after the asset creation - This is wrong');
        
        // Create another contract
        Asset c1 = TestFactory.createContract(a.id);
        c1.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        insert c1;
        
        // Query the account and check whether the record type is now assurance
        a = [SELECT id, Record_Type_Name__c FROM Account WHERE id =: a.id];        
        system.assertEquals('Client_SFAM', a.Record_Type_Name__c, 
                            'The record type should have been updated after the asset creation - This is wrong');
    }
    
    /***
    * @description Update the record type
    * @see updateRecordTypeOnCreation
    */
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Query the contract and check whether the record type has been correctly updated
        c = [SELECT id, RecordType.DeveloperName FROM Asset WHERE id =: c.id];
        
        system.assertEquals(c.RecordType.DeveloperName, 'Contrat_location', 
                            'The record type should have been updated on the contract - This is wrong');
    }
    
    /***
    * @description Handle user creation
    * @see handleAccountActivation
    */
    @isTest
    public static void handlePassLocActivationTest(){
        
        // Create a SFAM distributeur
        Account d = TestFactory.createDistributeur();
        d.Enseigne__c = 'SFAM';
        insert d;
        
        // Create a new SFAM Contract
        Asset c = TestFactory.createContract();
        c.Id_distributeur__c = d.id;
        test.startTest();
        insert c;
        Test.stopTest();
        
        // Query the account
        Account a = [SELECT id, PersonContactId, IsCustomerPortal FROM Account WHERE id =: c.accountId];
        system.assertEquals(TRUE, a.IsCustomerPortal, 
                            'The account should now be portal enabled - This is wrong');
        User u = [SELECT id, Profile.Name FROM User WHERE ContactID =: a.PersonContactId];
        //replace Community Plus License by Community License >
        //system.assertEquals('Passloc Customer community Plus Login User', u.Profile.Name,
        system.assertEquals('Passloc Customer community Login User', u.Profile.Name,
        // <  
                            'The new user profile should be PassLoc - This is wrong');        
    }
    
    /***
    * @description Handle user creation
    * @see handleAccountActivation
    */
    @isTest
    public static void handleIlliPassActivationTest(){
        
        // Create a SFAM distributeur
        Account d = TestFactory.createDistributeur();
        d.Enseigne__c = 'INDEP';
        insert d;
        
        // Create a new SFAM Contract
        Asset c = TestFactory.createContract();
        c.Id_distributeur__c = d.id;
        test.startTest();
        insert c;
        Test.stopTest();
        
        // Query the account
        Account a = [SELECT id, PersonContactId, IsCustomerPortal FROM Account WHERE id =: c.accountId];
        system.assertEquals(TRUE, a.IsCustomerPortal, 
                            'The account should now be portal enabled - This is wrong');
        User u = [SELECT id, Profile.Name FROM User WHERE ContactID =: a.PersonContactId];
        //replace Community Plus License by Community License >
        //system.assertEquals('Illipass Customer community Plus Login User', u.Profile.Name,
        system.assertEquals('Illipass Customer community Login User', u.Profile.Name,
        // < 
                            'The new user profile should be PassLoc - This is wrong');        
    }
    
    /***
    * @description Handle resiliation
    * @see handleResiliation
    */
    @isTest
    public static void handleResiliationTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Stop it
        c.Motif_cloture__c = 'Résiliation client';
        c.Date_cloture__c = system.today();
        update c;
        
        // Query the Facture and check the contract status
        List<Facture__c> relatedFacture = [SELECT Date_fin_periode__c FROM Facture__c WHERE Contrat__c =: c.id];
        system.assertEquals(c.Date_cloture__c, relatedFacture[0].Date_fin_periode__c, 
                           'The related facture should have been updated - This is wrong');
        
        c = [SELECT Status FROM Asset WHERE id =: c.id];
        system.assertEquals('closed', c.Status, 
                           'The contract status should have been updated - this is wrong');
    }
    
    /***
    * @description Handle the etat paiement update
    * @see handleValidPayment
    */
    @isTest
    public static void handleValidPaymentTest(){
        
        // Create a new Contract
        Asset a = TestFactory.createAssuranceAsset();
        a.Etat_paiement__c = 'unpaid';
        insert a;
        
        // Create a new case
        Case c = TestFactory.createSinistre(a.AccountId);
        c.Attente_documents__c = 'Valid';
        c.Status = 'Incomplet';
        c.AssetId = a.Id;
        insert c;
        
        // Update the contract
        a.Etat_paiement__c = 'valid';
        update a;
        
        c = [SELECT id, Status FROM Case WHERE id =: c.id];
        system.assertEquals('En cours d\'examen', c.Status, 
                           'The status should have changed - This is wrong');
    }

    /***
    * @description Handle the CalculatorIndicLastChange
    * @see handleCalculatorIndicLastChange
    */
    @isTest
    public static void handleCalculatorIndicLastChange(){
        
        // Create a new Contract
        Asset a = TestFactory.createAssuranceAssetWithFormula();
        a.Date_debut_contrat__c = System.today().addDays(-1);
        update a;
        
        vlocity_ins__AssetCoverage__c formsous = [SELECT Id,Formule_options__r.NbMounthKPIContract__c FROM vlocity_ins__AssetCoverage__c WHERE Id = :a.Formule__c];

        Asset aUpdated = [SELECT Id,TECH_CalculatorIndicLastChange__c,TECH_LastBirthDayContract__c FROM Asset WHERE Id = :a.Id];
        system.assertEquals(System.today().addMonths((Integer)formsous.Formule_options__r.NbMounthKPIContract__c).addDays(-1), aUpdated.TECH_CalculatorIndicLastChange__c, 
                           'The TECH_CalculatorIndicLastChange__c not add month');
        system.assertEquals(System.today().addDays(-1), aUpdated.TECH_LastBirthDayContract__c, 
                           'The TECH_LastBirthDayContract__c is today');
    }
}