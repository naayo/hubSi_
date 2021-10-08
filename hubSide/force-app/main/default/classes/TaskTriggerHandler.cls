/***
* @author Ariane Tanguy (GFI)
* @date 25/08/2020
* @description Handler class for TaskTrigger
*/

public class TaskTriggerHandler {
    
    /***
	* @description Update the record type on task creation
	* @param newTaskList - list of all new task
	* @param TCRecordType - TC record type id
	* @return NA
	*/
    public static void updateRecordTypeOnCreation(List<Task> newTaskList){
        
        id taskOwnerId = NULL;
        id TCRecordType = NULL;
        
        // For all new tasks
        for(Task t : newTaskList){
            
            // If the related object is a reservation
            if(t.WhatId != NULL && 
               t.WhatId.getSObjectType().getDescribe().getName() == 'Reservation__c'){
                   
                   if(taskOwnerId == NULL){
                       taskOwnerId = [SELECT id FROM GROUP WHERE DeveloperName = 'Rappel_pour_prereservation' LIMIT 1].id;
                   }
                   t.OwnerId = taskOwnerId;
                   
                   if(TCRecordType == NULL){
                       TCRecordType = UtilityClassHelper.getCreatedRecordType('TCVendeur');
                   }
                   t.RecordTypeId = TCRecordType;
               }            
        }
    }
    
    /***
	* @description Update the related case
	* @param newTaskList - list of new task
	* @param oldTaskMap - map of old task
	* @param caseIdMap - related case map
	* @return NA
	*/
    public static void updateRelatedCase(List<Task> newTaskList, Map<id, Task> oldTaskMap, Map<id, Case> caseIdMap){
        
        List<Case> caseToUpdateList = new List<Case>();
        
        // For all new tasks
        for(Task t : newTaskList){
            
            // If its status is now closed + it's a document request 
            if(((t.Status == 'Fermé KO' && oldTaskMap.get(t.id).Status != 'Fermé KO') ||
                (t.Status == 'Completed' && oldTaskMap.get(t.id).Status != 'Completed')) &&
               t.Record_type_name__c == 'Sinistre_Task_Action' &&
               t.Type_Action__c == 'Demande de document'){
                   
                   if(caseIdMap.keySet().contains(t.whatId)){
                       caseIdMap.get(t.whatId).Status = 'Incomplet';
                       caseToUpdateList.add(caseIdMap.get(t.whatId));
                   }
               }
        }
        
        if(caseToUpdateList.size() > 0){
            update caseToUpdateList;
        }
    }
    
    /***
	* @description Check the user's profile deleting a task
	* @param oldTaskList - list of old task
	* @return NA
	*/
    public static void checkProfileBeforeDelete(List<Task> oldTaskList){
        
        String currentUserProfile = [SELECT Name 
                                     FROM Profile 
                                     WHERE id =: System.UserInfo.getProfileId()].Name;
        
        // For all new tasks
        for(Task t : oldTaskList){
            
            // If the user's profile is TC
            if(currentUserProfile == 'SFAM TC' && t.isDeleteAuthorized__c == FALSE){
                t.addError('En tant que TC, vous n\'avez pas les droits suffisants pour supprimer une tâche -' + 
                           ' TC users dont have permission to delete task');
            }
        }
    }
    
    /***
	* @description Update task
	* @param t - new task
	* @param emailTemplateMap - map of short code / email template
	* @return NA
	*/
    private static String getEmailTemplate(Task t, Map<String, EmailTemplate> emailTemplateMap){
        
        String codeTemplate = NULL;
        
        // Find out the template's real code
        codeTemplate = (t.Canal_communication__c == 'Print' || t.Canal_communication__c == 'Phone') ?
            t.Code_template__c + '_PRINT' : t.Code_template__c + '_MAIL';
        if(!emailTemplateMap.keySet().contains(codeTemplate)){
            codeTemplate = (t.Canal_communication__c == 'Print' || t.Canal_communication__c == 'Phone') ? 
                t.Code_template__c + '_MAIL' : t.Code_template__c + '_PRINT';
            if(!emailTemplateMap.keySet().contains(codeTemplate)){
                throw new TemplateNotFoundException('Template not found');
            }
        }
        return codeTemplate;
    }
    
    /***
	* @description Update task
	* @param newTaskList - list of all new task
	* @return NA
	*/
    public static void updateTaskOnInsert(List<Task> newTaskList, Map<String, EmailTemplate> emailTemplateMap){

        // For all new tasks        
        id queueId = NULL;
        for(Task t : newTaskList){
            
            if(t.Code_template__c != NULL){
                
                // Find out the template's real code
                t.Subject = emailTemplateMap.get(getEmailTemplate(t, emailTemplateMap)).Name;
                
                // Check the communication type
                if(t.Canal_communication__c == 'Print' || t.Canal_communication__c == 'Phone'){
                    
                    // Add to queue Envoi papier à réaliser
                    if(queueId == NULL){
                        queueId = [SELECT id FROM Group WHERE DeveloperName = 'Envoi_papier_a_realiser'].id;
                    }
                    t.OwnerId = queueId;
                    t.Status = 'Open';
                } else {
                    t.isDeleteAuthorized__c = TRUE;
                }
            }
        }
    }
    
    /***
	* @description Send com'
	* @param newTaskList - list of all new task
	* @return NA
	*/
    public static void handleCommunication(List<Task> newTaskList, Map<String, EmailTemplate> emailTemplateMap){
        
        List<id> taskToDeleteIdSet = new List<id>();
        List<id> contactToDeleteIdSet = new List<id>();
        
        // For all new tasks
        for(Task t : newTaskList){
            
            if(t.Code_template__c != NULL){
                
                // Get the template sexy name
                EmailTemplate chosenTemplate = emailTemplateMap.get(getEmailTemplate(t, emailTemplateMap));
                
                // Create the email to be sent / stored
                Messaging.SingleEmailMessage mail = UtilityClassHelper.createEmail(t.whatId, 
                                                                                   [SELECT Email_Contact__c FROM Case WHERE id =: t.WhatId].Email_Contact__c, 
                                                                                   chosenTemplate.id);
                
                // Check the communication type
                if(t.Canal_communication__c == 'Print' || t.Canal_communication__c == 'Phone'){
                    
                    // Send the emails in a transaction, then roll it back
                    Savepoint sp = Database.setSavepoint();
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                    Database.rollback(sp);
                    
                    // Insert the email as a PDF
                    insertFile(mail.getHtmlBody(), chosenTemplate.Name, t.id);
                } else {                    
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                    taskToDeleteIdSet.add(t.id);
                }
                
                // Check whether the contact needs to be deleted
                Contact c = [SELECT id, LastName FROM Contact WHERE id =: mail.getTargetObjectId()];
                
                if(c.LastName.contains('Dummy') && 
                   !contactToDeleteIdSet.contains(mail.getTargetObjectId())){
                       contactToDeleteIdSet.add(mail.getTargetObjectId());
                   }
            }
        }
        
        Database.delete(taskToDeleteIdSet);
        Database.delete(contactToDeleteIdSet);
        
    }
    
    /***
	* @description Future method - calls the HtmlToPdfCallout method
	* @param newTaskList - list of all new task
	* @param TCRecordType - TC record type id
	* @return NA
	*/
    @Future(callout=true)
    public static void insertFile(String htmlBody, String fileName, String whatId){
        
        Blob pdfBlob;
        if (Test.IsRunningTest()){
            pdfBlob = Blob.valueOf('UNIT.TEST');
        } else {
            pdfBlob = HtmlToPdfCallout.convertHtmlToPdf(EncodingUtil.base64Encode(Blob.valueof(htmlBody)), 'Requete' + '.pdf');
        }
        
        // save the email as a pdf
        UtilityClassHelper.insertFile(whatId, pdfBlob, fileName + '.pdf');
    }
    
    public class TemplateNotFoundException extends Exception {}
}