/***
* @author Ariane Tanguy (GFI)
* @date 13/10/2020
* @description Helper class for CaseTrigger
*/

public class TaskTriggerHelper {
    
    /***
	* @description Get the related cases
	* @param newTaskList - all new tasks
	* @return Map<id, Case>
	*/
    public static Map<String, EmailTemplate> getRelatedTemplate(List<Task> newTaskList){
        
        // Get the related email template
        Set<String> relatedTemplateSet = new Set<String>();
        for(Task t : newTaskList){
            relatedTemplateSet.add(t.code_template__c + '%');
        }
        
        List<EmailTemplate> emailTemplateList = [SELECT id, Name, developername 
                                                 FROM EmailTemplate
                                                 WHERE developername LIKE: relatedTemplateSet];
        
        // Map it to the name
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate e : emailTemplateList){
            emailTemplateMap.put(e.developername, e);
        }
        return emailTemplateMap;
    }
    
    /***
	* @description Get the related cases
	* @param newTaskList - all new tasks
	* @return Map<id, Case>
	*/
    public static Map<id, Case> getRelatedCase(List<Task> newTaskList){
        
        // Get the related case ids
        Set<id> relatedCaseIdSet = new Set<id>();
        for(Task t : newTaskList){
            relatedCaseIdSet.add(t.WhatId);
        }
        
        // Query the cases
        Map<id, Case> caseIdMap = new Map<id, Case>([SELECT id, Status
                                                     FROM Case
                                                     WHERE id IN: relatedCaseIdSet
                                                     AND Status IN ('A attribuer', 'Attribué', 'En cours d\'examen')]);
        return caseIdMap;
        
    }
}