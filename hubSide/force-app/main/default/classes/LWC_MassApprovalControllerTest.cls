/***
* @author Pierre-Mickael BARRAL (INETUM)
* @date 13/11/2020
* @description GED CLWC Controller
* DATE          DEV         DESCRIPTION
* 13/11/2020    PMB         Inital version
* 08/01/2021    PMB         update LWC_MassApprovalController method
* 19/02/2021    PMB         update init method error limit
*/
@isTest
public with sharing class LWC_MassApprovalControllerTest {
    
    @testSetup static void init() {
        
        // Create data
        Asset cSinitre = TestFactory.createAssuranceAsset();
        insert cSinitre;
        
        Case c = TestFactory.createSinistre(cSinitre.AccountId, cSinitre.Id);
        insert c;
        
        User u = TestFactory.createUser();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SFAM GS'].id;
        u.email = 'michael.jockson@123.com';
        u.Montant_approbation__c = 1000.00;
        insert u;
        
        Alert__c al = TestFactory.createAlert(c.Id);
        insert al;
        
        Mouvements_financiers__c mv = TestFactory.createMouvementFinancier(c.Id);
        insert mv;
        
        System.runAs(u){
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(mv.id);
            req1.setProcessDefinitionNameOrId('Approbation_TEST_V_4');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
        }
    }

    @isTest
    public static void getApprovalTest(){
        test.startTest();
        Case c = [SELECT Id,Status FROM Case LIMIT 1];
        c.Status = 'En cours d\'examen';
        update c;
        
        List<ProcessInstance> listProcessInstance = [SELECT  Id, CreatedBy.Name, Status, TargetObject.Name, TargetObject.Id 
                                                     FROM ProcessInstance];
        User u = [SELECT Id,Montant_approbation__c FROM USER WHERE Email='michael.jockson@123.com' LIMIT 1];
        System.runAs(u){
            system.assertEquals(LWC_MassApprovalController.getApprovals().size(), listProcessInstance.size(), 
                                'The approval process is not initialised');
        }
        test.stopTest();
    }

    @isTest
    public static void approvedOrRejectedApprovedTest(){
        
        String validationReason = 'Accepté processus métier';
        
        test.startTest();
        // Get a case
        Case c = [SELECT Id,Status FROM Case LIMIT 1];
        c.Status = 'En cours d\'examen';
        update c;

        Map<Id,ProcessInstance> listProcessInstance = new Map<Id,ProcessInstance>([SELECT Id, CreatedBy.Name, Status, TargetObject.Name, 
                                                                                   TargetObject.Id, ProcessDefinition.DeveloperName 
                                                                                   FROM ProcessInstance]);
        
        Map<String,String> mapIdRecordApprovalProcess = new Map<String,String>();
        for(Id IdProcess : listProcessInstance.keySet()){
            mapIdRecordApprovalProcess.put(IdProcess,listProcessInstance.get(IdProcess).ProcessDefinition.DeveloperName);
        }
        String comment = 'Commentaire ';
        
        // Approval type is defined by the boolean in parameters true = accept     
        User u = [SELECT Id FROM USER LIMIT 1];   
        LWC_MassApprovalController.approvedOrRejected(mapIdRecordApprovalProcess, true, comment, validationReason, u.Id);

        ProcessInstance processInstance = [SELECT Id, Status FROM ProcessInstance LIMIT 1 ];
        system.assertEquals('Approved', processInstance.Status, 'Approval process is not Approved');
        Test.StopTest();
    }

    @isTest
    public static void approvedOrRejectedRejectedTest(){
        
        Test.StartTest();
        // Get a case
        Case c = [SELECT Id,Status FROM Case LIMIT 1];
        c.Status = 'En cours d\'examen';
        update c;
        
        Map<Id,ProcessInstance> listProcessInstance = new Map<Id,ProcessInstance>([SELECT Id, CreatedBy.Name, Status, TargetObject.Name, TargetObject.Id,
                                                                                   ProcessDefinition.DeveloperName 
                                                                                   FROM ProcessInstance ]);
        Map<String,String> mapIdRecordApprovalProcess = new Map<String,String>();
        for(Id IdProcess : listProcessInstance.keySet()){
            mapIdRecordApprovalProcess.put(IdProcess,listProcessInstance.get(IdProcess).ProcessDefinition.DeveloperName);
        }
        String comment = 'Commentaire ';
        
        // Approval type is defined by the boolean in parameters true = accept
        User u = [SELECT Id FROM USER LIMIT 1];
        LWC_MassApprovalController.approvedOrRejected(mapIdRecordApprovalProcess, false, comment, null, u.Id);
        
        ProcessInstance processInstance = [SELECT Id,Status FROM ProcessInstance LIMIT 1 ];
        system.assertEquals('Rejected', processInstance.Status, 'Approval process is not Approved');
        
        Test.StopTest();
    }
}