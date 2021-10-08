/***
* @author Ariane Tanguy (GFI)
* @date 28/07/2020
* @description Case test class
* @Object Case
*/

@isTest
public class CaseTriggerHandlerTest {

    /***
    * @description Update the record type on formule creation
    * @see setSinistreNumber
    */
    @isTest
    public static void setSinistreNumberOnCreationTest(){
        
        Account a = TestFactory.createClient();
        insert a;
        
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseSinistreId;
        insert c;

        List<Case> lstCase = [SELECT id, tech_numsin__c,AccountId FROM Case WHERE RecordTypeId =: caseSinistreId];
        system.assertEquals(1, lstCase[0].tech_numsin__c, 
                            'The field doesnt have the correct tech number - This is wrong');
        
        system.assertEquals(1, lstCase.size());
        
        // Create another sinistre
        Case c1 = new Case();
        c1.RecordTypeId = caseSinistreId;
        c1.AccountId = lstCase[0].AccountId;
        insert c1;
        Test.startTest();
        c1 = [SELECT id, tech_numsin__c, Numero_sinistre__c FROM Case WHERE id =: c1.id];
        system.assertEquals(2, c1.tech_numsin__c, 
                            'The field shouldnt have been incremented - This is wrong');
        system.assertEquals('INS000002', c1.Numero_sinistre__c, 
                            'The number is not the expected one - This is wrong');
        
        // Close the first sinistre
        lstCase[0].Status = 'closed_exchange';
        update lstCase[0];
        Case c1update = [SELECT id, tech_numsin__c, Numero_sinistre__c, Record_Type_Name__c FROM Case WHERE id =: lstCase[0].id];
        system.assertEquals('Sinistre clôturé', c1update.Record_Type_Name__c, 
                            'The number is not the expected one - This is wrong');
        system.assertEquals('INS000001', c1update.Numero_sinistre__c, 
                            'The number is not the expected one - This is wrong');
        
        // Create a last sinistre, unvalidated
        Case c2 = new Case();
        c2.RecordTypeId = caseSinistreId;
        c2.AccountId = lstCase[0].AccountId;
        c2.vlocity_ins__Verified__c = true;
        insert c2;
        
        c2 = [SELECT id, tech_numsin__c, Numero_sinistre__c FROM Case WHERE id =: c2.id];
        system.assertEquals(1, c2.tech_numsin__c, 
                            'The field shouldnt have been incremented - This is wrong');
        system.assert(c2.Numero_sinistre__c.contains('TMP'), 
                            'The number is not the expected one - This is wrong');
        
        // The last sinistre is actually ok
        c2.vlocity_ins__Verified__c = false;
        update c2;
        
        c2 = [SELECT id, tech_numsin__c, Numero_sinistre__c FROM Case WHERE id =: c2.id];
        system.assertEquals(3, c2.tech_numsin__c, 
                            'The field should have been incremented - This is wrong');
        system.assertEquals('INS000003', c2.Numero_sinistre__c, 
                            'The number is not the expected one - This is wrong');
        Test.stopTest();
    }
    
    /***
    * @description Set the Reclamation Number on Reclamation creation
    * @see setReclamationNumber
    */
    @isTest
    public static void setReclamationNumberOnCreationTest(){
        
        // Create an account 
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a Contract
        Asset c = TestFactory.createAssuranceAsset(a.id);
        insert c;
        
        // Create a Reclamation
        Case r = TestFactory.createReclamation(a.id, c.id);
        insert r;
        
        r = [SELECT id, tech_numsin__c, Numero_sinistre__c FROM Case WHERE id =: r.id];
        system.assertEquals(1, r.tech_numsin__c, 
                            'The field doesnt have the correct tech number - This is wrong');
        system.assertEquals('REC000001', r.Numero_sinistre__c, 
                            'The field doesnt have the correct reclamation number - This is wrong');
        
        // Create a second Reclamation
        Case c1 = TestFactory.createReclamation(a.id, c.id);
        insert c1;
        
        c1 = [SELECT id, tech_numsin__c, Numero_sinistre__c  FROM Case WHERE id =: c1.id];
        system.assertEquals(2, c1.tech_numsin__c, 
                            'The field doesnt have the correct tech number - This is wrong');
        system.assertEquals('REC000002', c1.Numero_sinistre__c, 
                            'The field doesnt have the correct reclamation number - This is wrong');
    }

    /***
    * @description Update the account if needed
    * @see updateAccountOnAssetUpdate
    */
    @isTest
    public static void updateAccountOnAssetUpdateTest(){
        
        // Create an asset
        Asset a = TestFactory.createAssuranceAsset();
        insert a;
        
        // Create a sinistre
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AssetId = a.id;
        c.RecordTypeId = caseSinistreId;
        insert c;
        
        a = [SELECT id, AccountId FROM Asset WHERE id =: a.id];
        c = [SELECT id, AccountId FROM Case WHERE id =: c.id];
        system.assertEquals(a.AccountId, c.AccountId, 
                            'The case doesnt have the correct accountId - This is wrong');
        
        // Create another asset
        Asset a1 = TestFactory.createAssuranceAsset();
        insert a1;
        
        c.AssetId = a1.id;
        update c;
        
        a1 = [SELECT id, AccountId FROM Asset WHERE id =: a1.id];
        c = [SELECT id, AccountId FROM Case WHERE id =: c.id];
        system.assertEquals(a1.AccountId, c.AccountId, 
                            'The case doesnt have the correct accountId - This is wrong');
    }

    /***
    * @description Update the related sinistre if needed
    * @see updateSinistreOnReclaUpdate
    */
    @isTest
    public static void updateSinistreOnReclaUpdateTest(){
        
        // Create an account
        Account acc = TestFactory.createClient();
        insert acc;
        
        // Create an asset
        Asset a = TestFactory.createAssuranceAsset(acc.id);
        insert a;        
        
        // Create a sinistre
        Case c = TestFactory.createSinistre(acc.id, a.id);
        insert c;
        
        // Create its related reclamation
        Case r = TestFactory.createReclamation(acc.id, a.id);
        r.Theme__c = 'Sinister';
        r.AssociatedSinister__c = c.id;
        insert r;
        
        // Update the reclamation
        r.AnswerNature__c = 'Favorable';
        update r;
        
        c = [SELECT id, Status, RecordTypeId FROM Case WHERE id =: c.id];
        system.assertEquals('En cours d\'examen', c.Status, 
                            'The sinistre status hasnt been updated - This is wrong');
        system.assertEquals(UtilityClassHelper.getCreatedRecordType('Sinistre'), c.RecordTypeId, 
                            'The sinistre record type hasnt been updated - This is wrong');
    }

    /***
    * @description Update the related equipement sinistre on case (sinistre + sav) validation
    * @see updateEquipSinOnCaseValidation
    */
    @isTest
    public static void updateEquipSinOnCaseValidationTest(){
        
        // Create an account
        Account acc = TestFactory.createClient();
        insert acc;
        
        // Create an asset
        Asset a = TestFactory.createAssuranceAsset(acc.id);
        insert a;
        
        // Create a sinistre
        Case c = TestFactory.createSinistre(acc.id, a.id);
        insert c;
        
        // Create another sinistre
        Case c1 = TestFactory.createSinistre(acc.id, a.id);
        c1.vlocity_ins__Verified__c = true;
        insert c1;
        
        // Create an equipement sinistre
        Equipement_Sinistre__c e = new Equipement_Sinistre__c();
        e.sinistre__c = c1.id;
        insert e;
        
        c1 = [SELECT id, Numero_sinistre__c FROM Case WHERE id =: c1.id];
        e = [SELECT id, Name FROM Equipement_Sinistre__c WHERE id =: e.id];
        system.assert(e.Name.contains('TMP'), 
                            'The equipSin name shouldve been initiated with the case TMP number - This is wrong');
        
        // Actually, the sinistre is validated
        c1.vlocity_ins__Verified__c = false;
        update c1;
        
        c1 = [SELECT id, Numero_sinistre__c FROM Case WHERE id =: c1.id];
        system.assertEquals('INS000002', c1.Numero_sinistre__c, 
                            'The number is not the expected one - This is wrong');
        
        e = [SELECT id, Name FROM Equipement_Sinistre__c WHERE id =: e.id];
        system.assert(e.Name.contains('INS000002'), 
                            'The equipSin name shouldve been updated with the case INS number - This is wrong');        
    }
    
    /***
    * @description Checks the user's profile before delete
    * @see isDeleteAuthorized
    */
    @isTest
    public static void isDeleteAuthorizedTest(){
        
        // Create a sinistre
        Case c = TestFactory.createSinistre();
        insert c;
        
        // Create a user
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SFAM GS'].id;
        u.email = 'michael.jockson@123.com';
        insert u;
        
        // Try deleting the case as a GS
        system.runAs(u){
            try{
                delete c;
                system.assert(false, 
                              'The case shouldnt have been deleted - This is wrong');
            }
            catch(Exception e){
                system.assert(e.getMessage().contains('pas les droits suffisants pour supprimer'), 
                              'The error message isnt the expected one - This is wrong' + e);
            }
        }
        
        // Try again, as a super admin
        delete c;        
        system.assertEquals(0, [SELECT id FROM Case].size(), 
                            'The case shouldve been deleted - This is wrong');
    }

    /***
    * @description Convert a decla web into sinistre
    * @see setSinistreNumber
    * @see createNecessaryDocs
    */
    @isTest
    public static void convertDeclaWebTest(){
        
        // Create a type de piece justificative
        Types_piece_justificative__c t = new Types_piece_justificative__c();
        t.Perte__c = TRUE;
        t.Name = 'Permis de chasse';
        insert t;
        
        // Create a client
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a decla web
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Declaration');
        c.Typologie_Sinistre__c = 'lost';
        insert c;
        
        // Check whether a piece justificative has been created
        List<Piece_justificative_Sinistre__c> pList = [SELECT id, Case__c FROM Piece_justificative_Sinistre__c WHERE Case__c =: c.id];
        system.assertEquals(1, pList.size(), 
                           'There should have been at least one pj created - This is wrong');
        
        // Convert the declaration into a sinitre
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        update c;
        
        c = [SELECT id, tech_numsin__c, Numero_sinistre__c FROM Case WHERE id =: c.id];
        system.assertEquals(1, c.tech_numsin__c, 
                            'The field should have been incremented - This is wrong');
        system.assertEquals('INS000001', c.Numero_sinistre__c, 
                            'The number is not the expected one - This is wrong');
        
        pList = [SELECT id, Case__c FROM Piece_justificative_Sinistre__c WHERE Case__c =: c.id];
        system.assertEquals(1, pList.size(), 
                           'There should have been at least one pj created - This is wrong');
    }
    
    /***
    * @description Check whether empty piece justificatives are created on case creation
    * @see createNecessaryDocs
    */
    @isTest
    public static void createNecessaryDocsTest(){
        
        // Create a type de piece justificative
        Types_piece_justificative__c t = new Types_piece_justificative__c();
        t.Perte__c = TRUE;
        t.Name = 'Permis de chasse';
        insert t;
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a case
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'lost';
        insert c;
        
        // Check whether a piece justificative has been created
        Piece_justificative_Sinistre__c p = [SELECT id, Case__c FROM Piece_justificative_Sinistre__c WHERE Case__c =: c.id];
        system.assertEquals(c.id, p.Case__c, 
                           'There should have been at least one pj created - This is wrong');
    }

    /***
    * @description test method Alert use initUpdateAlertOnUpdate to init data
    */
    @isTest
    public static void updateAlertOnUpdate(){
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        Asset cSinitre = TestFactory.createAssuranceAsset(a.Id);
        cSinitre.Etat_paiement__c = 'valid';
        insert cSinitre;

        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'lost';
        c.Attente_documents__c = 'Received';
        c.AssetId = cSinitre.Id;
        insert c;

        Alert__c al = TestFactory.createAlert(c.Id);
        insert al;

        Approval.ProcessSubmitRequest req1 = 
            new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(c.id); 
        req1.setProcessDefinitionNameOrId('AP01_CS_AlertToValidated');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        
        c = [SELECT id, TECH_ApprovalProcessStatus__c
             FROM Case 
             WHERE id =: c.id];

        Map<Id,ProcessInstance> listProcessInstance = new Map<Id,ProcessInstance>([SELECT Id, CreatedBy.Name, Status, 
                                                                                   TargetObject.Name, TargetObject.Id 
                                                                                   FROM ProcessInstance]);
        List<Id> setIds = new List<Id>(listProcessInstance.keySet());
        List<String> idsProcess = (List<String>) setIds;
        idsProcess.addAll(setIds);
        String comment = 'Commentaire ';
        
        Test.StartTest();
        List<ProcessInstanceWorkItem> pIWItem = [SELECT Id 
                                                 FROM ProcessInstanceWOrkItem 
                                                 WHERE ProcessInstanceId IN :setIds];
        if(pIWItem.size() > 0){
            
            //Manage approval process request
            List<Approval.ProcessWorkitemRequest> listApproval = new List<Approval.ProcessWorkitemRequest>();
            
            for(ProcessInstanceWorkItem record : pIWItem){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(comment);
                req.setWorkitemId(record.Id);
                req.setAction('Approve');
                listApproval.add(req);
            }
            Approval.ProcessResult[] listResultApproval =  Approval.process(listApproval);
        }

        ProcessInstance processInstance = [SELECT Id,Status FROM ProcessInstance LIMIT 1 ]; // HERE
        system.assertEquals('Approved', processInstance.Status, 
        'Approval process is not Approved');
        Test.StopTest();

        al = [SELECT Id,Status__c FROM Alert__c LIMIT 1];
        system.assertEquals('Approved', al.Status__c, 
        'Alert record is not updated');
    }

    /***
    * @description test method Alert use initUpdateAlertOnUpdate to init data
    */
    @isTest
    public static void updateAssetKPITest(){
        
        // Create an asset
        Asset a = TestFactory.createAssuranceAssetWithFormula();
        
        // Create a sinistre
        Case c = TestFactory.createSinistre(a.AccountId, a.Id);
        c.Date_sinistre__c = System.today().addMonths(-11);
        c.Montant_sinistre__c = 2600;
        c.Status = 'closed_exchange';
        
        Test.StartTest();
        insert c;
        Test.StopTest();
        
        // Check whether the asset has been updated
        a = [SELECT Sinistre_declares_asset__c, Montant_indemnisation__c, Plafond__c, AccountId
            FROM Asset 
            WHERE id =: a.id];
        
        system.assertEquals(a.Sinistre_declares_asset__c, 1, 
                            'The number of declared sinistre shouldve been updated - This is wrong');
        system.assertEquals(a.Montant_indemnisation__c, c.Montant_sinistre__c, 
                            'The montant indemn shouldve been updated - This is wrong');
        
        // Check whether the geste co has been updated on the sinistre
        c = [SELECT Montant_geste_co__c, Montant_sinistre__c
            FROM Case
            WHERE id =: c.id];
        system.assertEquals(-(a.Plafond__c - c.Montant_sinistre__c), c.Montant_geste_co__c, 
                            'The montant indemn shouldve been updated - This is wrong');
    }

    
    /***
    * @description tes method to test ForceValueApprovalProcess method
    */
    @isTest
    public static void testForceValueApprovalProcess(){
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        // Create an asset
        Asset ast = TestFactory.createAssuranceAssetWithFormula();
        Case cs = TestFactory.createSinistre(ast.AccountId,ast.Id);
        cs.Date_sinistre__c = System.today().addMonths(-11);
        cs.Montant_sinistre__c = 200;
        cs.RecordTypeId = caseSinistreId;
        cs.TECH_ApprovalProcessStatus__c = 'In Progress';
    
        Test.StartTest();
        insert cs;
        cs.TECH_ApprovalProcessStatus__c = 'Approved';
        update cs;
        Test.StopTest();
        Case csAfter = [SELECT Id,TECH_ApprovalProcessStatus__c FROM Case WHERE Id =:cs.Id];
        system.assertEquals('Not Approval',csAfter.TECH_ApprovalProcessStatus__c, 
        'TECH_ApprovalProcessStatus__c updated');
    }
    
     /***
    * @description test method to test createAlertOnUpdate method
    */
    @isTest
    public static void createAlertOnUpdate(){
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create an asset
        Asset cSinistre = TestFactory.createAssuranceAsset(a.Id);
        cSinistre.Etat_paiement__c = 'valid';
        cSinistre.Date_debut_contrat__c = Date.valueOf('2022-07-07 00:00:00');
        cSinistre.Date_cloture__c = Date.valueOf('2021-07-07 00:00:00');
        insert cSinistre;

        // Create Case (Sinistre)
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseSinistreId;
        c.Typologie_Sinistre__c = 'lost';
        c.Attente_documents__c = 'Received';
        c.AssetId = cSinistre.Id;
        c.Date_sinistre__c = Date.valueOf('2021-07-05 00:00:00');
        c.ClientDeclarationValidationDate__c = Date.valueOf('2021-07-10 00:00:00');
        insert c;

        // Update Date Sinistre
        c.Date_sinistre__c = Date.valueOf('2021-07-02 00:00:00');
        update c;
        
        Test.StartTest();
        
        List<Alert__c> CaseAlert = [SELECT Id FROM Alert__c WHERE Case__c =: c.Id AND BusinessRulesNumber__c = 'RGSIN11'];
        system.assert(CaseAlert.size() > 0, 'No RGSIN11 alert on case');

        // Update Date Sinistre
        c.Date_sinistre__c = Date.valueOf('2021-07-08 00:00:00');
        update c;

        List<Alert__c>CaseAlert2 = [SELECT Id FROM Alert__c WHERE Case__c =: c.Id AND BusinessRulesNumber__c = 'RGSIN17'];
        system.assert(CaseAlert2.size() > 0, 'No RGSIN17 alert on case');

        // Update Date Sinistre
        c.Date_sinistre__c = Date.valueOf('2021-07-10 00:00:00');
        c.ClientDeclarationValidationDate__c = Date.valueOf('2021-07-25 00:00:00');
        update c;

        List<Alert__c> CaseAlert3 = [SELECT Id FROM Alert__c WHERE Case__c =: c.Id AND BusinessRulesNumber__c = 'RGSIN16'];
        system.assert(CaseAlert3.size() > 0, 'No RGSIN16 alert on case');

        // Update Date Sinistre
        c.ClientDeclarationValidationDate__c = Date.valueOf('2021-11-10 00:00:00');
        update c;

        List<Alert__c> CaseAlert4 = [SELECT Id FROM Alert__c WHERE Case__c =: c.Id AND BusinessRulesNumber__c = 'RGSIN15'];
        system.assert(CaseAlert4.size() > 0, 'No RGSIN15 alert on case');
    }
    
    /***
    * @description test method to test updateCalculIndemnisationOnUpdate method
    */
    @isTest
    public static void updateCalculIndemnisationOnUpdateTest(){
       // Create an account
       Account a = TestFactory.createClient();
       insert a;
       
       Asset cSinitre = TestFactory.createAssuranceAsset(a.Id);
       cSinitre.Etat_paiement__c = 'valid';
       insert cSinitre;

       id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
       Case c = new Case();
       c.AccountId = a.id;
       c.RecordTypeId = caseSinistreId;
       c.Typologie_Sinistre__c = 'lost';
       c.Attente_documents__c = 'Received';
       c.AssetId = cSinitre.Id;
       insert c;

       Mouvements_financiers__c cal = TestFactory.createMouvementFinancier(c.Id);
       insert cal;
       cal.Statut__c = 'En cours d\'approbation';
       update cal;

       Approval.ProcessSubmitRequest req1 = 
           new Approval.ProcessSubmitRequest();
       req1.setComments('Submitting request for approval.');
       req1.setObjectId(c.id); 
       req1.setProcessDefinitionNameOrId('AP01_CS_AlertToValidated');
       req1.setSkipEntryCriteria(true);
       Approval.ProcessResult result = Approval.process(req1);
       
       c = [SELECT id, TECH_ApprovalProcessStatus__c
            FROM Case 
            WHERE id =: c.id];

       Map<Id,ProcessInstance> listProcessInstance = new Map<Id,ProcessInstance>([SELECT Id, CreatedBy.Name, Status, 
                                                                                  TargetObject.Name, TargetObject.Id 
                                                                                  FROM ProcessInstance]);
       List<Id> setIds = new List<Id>(listProcessInstance.keySet());
       List<String> idsProcess = (List<String>) setIds;
       idsProcess.addAll(setIds);
       String comment = 'Commentaire ';
       
       Test.StartTest();
       List<ProcessInstanceWorkItem> pIWItem = [SELECT Id 
                                                FROM ProcessInstanceWOrkItem 
                                                WHERE ProcessInstanceId IN :setIds];
       if(pIWItem.size() > 0){
           
           //Manage approval process request
           List<Approval.ProcessWorkitemRequest> listApproval = new List<Approval.ProcessWorkitemRequest>();
           
           for(ProcessInstanceWorkItem record : pIWItem){
               Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
               req.setComments(comment);
               req.setWorkitemId(record.Id);
               req.setAction('Approve');
               listApproval.add(req);
           }
           Approval.ProcessResult[] listResultApproval =  Approval.process(listApproval);
       }

       ProcessInstance processInstance = [SELECT Id,Status FROM ProcessInstance LIMIT 1 ]; // HERE
       system.assertEquals('Approved', processInstance.Status, 
       'Approval process is not Approved');
       Test.StopTest();

       cal = [SELECT Id,Statut__c FROM Mouvements_financiers__c WHERE Case__c = :c.Id LIMIT 1];
       system.assertEquals('Demande en cours', cal.Statut__c, 
       'Calcul indemnisation record is not updated');
    }
}