/***
* @author Ariane Tanguy (GFI)
* @date 06/04/2021
* @description Handler class for AlertTrigger
*/

public class AlertTriggerHandler {
    
    /***
	* @description Checks the user's profile before delete
	* @param alertList - list of alert to be deleted
	* @return NA
	*/
    public static void isDeleteAuthorized(List<Alert__c> alertList, Map<id, Case> relatedCaseMap){
        
        // Get the current user's profile
        String currentUserProfile = [SELECT Name 
                                     FROM Profile 
                                     WHERE id =: System.UserInfo.getProfileId()].Name;
        
        for(Alert__c a : alertList){
            system.debug('--alertList : ' + a);
            if(currentUserProfile != 'System Administrator' && a.couldDeleted__c != true
               /*!(relatedCaseMap.get(a.Case__c).TECH_Montant_Plafond__c > 0 &&
                 relatedCaseMap.get(a.Case__c).Number_of_Alert_plafond_depasse__c >= 1)*/ ){
                     throw new DeleteNotAuthorizedException('Vous n\'avez pas les droits suffisants pour supprimer cette alerte' + '\n' + 
                                                            'You don\'t have the permission to delete the current record.');
            }
        }
    }
    
      /***
	* @description Update Pouss_par_Salesforce__c field if alert is approved
	* @param alertList - list of alert
	* @return NA
	*/
    public static void updateCaseFields(List<Alert__c> alertList, Map<id, Case> relatedCaseMap){
        
        system.debug('--updateCaseFields');
        
        List<Case> caseToUpdate = new List<Case>();
        
        for(Alert__c a : alertList){
            
            system.debug('--Status__c'+a.Status__c);
            system.debug('--BusinessRulesNumber__c'+a.BusinessRulesNumber__c);
            
            if( a.Status__c == 'Approved' &&
                a.BusinessRulesNumber__c == 'RGSIN19'
               ){
                relatedCaseMap.get(a.Case__c).Pouss_par_Salesforce__c = true;
                caseToUpdate.add(relatedCaseMap.get(a.Case__c));
            }
        }

        update caseToUpdate;
    }
    
    public class DeleteNotAuthorizedException extends Exception {}
}