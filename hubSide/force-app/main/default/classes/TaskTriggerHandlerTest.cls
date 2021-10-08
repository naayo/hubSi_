/***
* @author Ariane Tanguy (GFI)
* @date 25/08/2020
* @description TaskTrigger test class
* @Object Task
*/

@isTest
public class TaskTriggerHandlerTest {
    
    /***
    * @description Update the record type on stock creation
    * @see updateRecordTypeOnCreation
    */
    @isTest
    public static void updateRecordTypeOnCreationTest(){
        
        // Create a reservation
        Reservation__c r = TestFactory.createReservation();
        r.Status__c = 'Pré-réservé';
        insert r;
        
        // Query product and check whether the record type has been correctly updated
        Task t = [SELECT id, Motif_Objet__c, RecordType.DeveloperName FROM Task WHERE WhatId =: r.id];
        
        system.assertEquals(t.RecordType.DeveloperName, 'TCVendeur', 
                            'The record type should have been updated on the task - This is wrong');
        system.assertEquals(t.Motif_Objet__c, 'Prospect à qualifier', 
                            'The Motif should have been updated on the task - This is wrong');
    }
    
    /***
    * @description Update the related case
    * @see updateRelatedCase
    */
    @isTest
    public static void updateRelatedCaseTest(){
        
        // Create a case
        Case c = TestFactory.createSinistre();
        c.Status = 'Attribué';
        c.Email_Contact__c = 'jonyBgool@yopmail.com';
        insert c;
        
        // Create a task
        id taskRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre_Task_Action');
        Task t = new Task();
        t.RecordTypeId = taskRecordType;
        t.whatId = c.id;
        t.Type_Action__c = 'Demande de document';
        insert t;
        
        t.Status = 'Completed';
        update t;
        
        c = [SELECT id, Status FROM Case WHERE Id =: c.id];
        system.assertEquals('Incomplet', c.Status, 
                           'The case status shouldve changed - This is wrong');
    }
    
    /***
    * @description Handle communication to client
    * @see handleCommunication
    */
    @isTest
    public static void handleCommunicationEmailTest(){
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a case
        id caseRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.Email_Contact__c = 'dummy@123.com';
        c.RecordTypeId = caseRecordType;
        c.Status = 'Attribué';
        insert c;
        
        Test.startTest();
        Integer emailbefore = Limits.getEmailInvocations();
        
        // Create a task
        id taskRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre_Task_Action');
        Task t = new Task();
        t.Subject = 'Sinistre';
        t.OwnerId = system.UserInfo.getUserId();
        t.RecordTypeId = taskRecordType;
        t.whatId = c.id;
        t.Canal_communication__c = 'Mail sortant';
        t.Code_template__c = 'SIN_001';
        insert t;
        
        system.assertNotEquals(emailbefore, Limits.getEmailInvocations(),
                               'An email shouldve been sent - This is wrong');
        Test.stopTest();
        
        // Check that there is no task anymore
        List<Task> taskList = [SELECT id, Status FROM Task WHERE id =: t.id];
        system.assertEquals(0, taskList.size(), 
                           'There should be no task no more - This is wrong');
    }
    
    /***
    * @description Handle communication to client
    * @see handleCommunication
    */
    @isTest
    public static void handleCommunicationPrintTest(){
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a case
        id caseRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.Email_Contact__c = 'dummy@123.com';
        c.RecordTypeId = caseRecordType;
        c.Status = 'Attribué';
        insert c;
        
        Test.startTest();
        
        // Create a task
        id taskRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre_Task_Action');
        Task t = new Task();
        t.Subject = 'Sinistre';
        t.OwnerId = system.UserInfo.getUserId();
        t.RecordTypeId = taskRecordType;
        t.whatId = c.id;
        t.Canal_communication__c = 'Print';
        t.Code_template__c = 'SIN_001';
        insert t;
        
        Test.stopTest();
        
        // Query the file created
        List<ContentDocumentLink> cdLinkList = [SELECT id FROM ContentDocumentLink WHERE LinkedEntityId =: t.id];
        system.assertEquals(1, cdLinkList.size(), 
                           'A document shouldve been inserted - This is wrong');
        
        // Check that the task got assigned to the correct queue
        t = [SELECT id, OwnerId FROM Task WHERE id =: t.id];
        system.assertEquals([SELECT id FROM Group WHERE DeveloperName = 'Envoi_papier_a_realiser'].id, t.OwnerId, 
                           'The task owner should be a queue - This is wrong');
    }
    
    /***
    * @description Handle communication to client
    * @see handleCommunication
    */
    @isTest
    public static void handleFailedCommunicationTest(){
        
        // Create an account
        Account a = TestFactory.createClient();
        insert a;
        
        // Create a case
        id caseRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre');
        Case c = new Case();
        c.AccountId = a.id;
        c.RecordTypeId = caseRecordType;
        c.Status = 'Attribué';
        insert c;
        
        // Create a task
        id taskRecordType = UtilityClassHelper.getCreatedRecordType('Sinistre_Task_Action');
        Task t = new Task();
        t.Subject = 'Sinistre';
        t.OwnerId = system.UserInfo.getUserId();
        t.RecordTypeId = taskRecordType;
        t.whatId = c.id;
        t.Canal_communication__c = 'Print';
        t.Code_template__c = 'FAKE_0045684';
        
        try{
            insert t;
            system.assert(false, 'The task shouldnt have been created - This is wrong');
        } catch (Exception e) {
            system.assert(e.getMessage().contains('Template not found'), 
                               'The exception thrown shouldve been a custom one - This is wrong');
        }
    }
}