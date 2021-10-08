/***
* @author Ariane Tanguy (GFI)
* @date 27/08/2020
* @description Handler class for AccountTrigger
*/

public class AccountTriggerHandler {
    
    /***
	* @description Check record type on update
	* @param newAccountList - list of all new accounts
	* @param oldAccountMap - map of old accounts
	* @return NA
	*/
    public static void checkRecordTypeOnUpdate(List<Account> newAccountList, Map<id, Account> oldAccountMap){
        
        Id clientLocId = NULL;
        
        // Loop over the account and check whether the record type has been updated
        for(Account a : newAccountList){
            
            // If the record type has been updated
            if(a.Record_Type_Name__c != oldAccountMap.get(a.id).Record_Type_Name__c){
                
                if(a.Compte_test__c == FALSE){
                    if(a.Record_Type_Name__c == 'Client_SFAM'){                           
                        if(clientLocId == NULL){
                            clientLocId = UtilityClassHelper.getCreatedRecordType('Client_location');
                        }                       
                        a.RecordTypeId = clientLocId;
                    }                    
                } else {
                    a.Compte_test__c = FALSE;
                }
            }
        }
    }
    
    /***
	* @description Update the users
	* @param newAccountList - list of all new accounts
	* @param accountIdUserMap - map of user
	* @return NA
	*/
    public static void updateRelatedUser(List<Account> newAccountList, Map<id, Account> oldAccountMap){
        
        // Loop over the account and update the user if needed
        for(Account a : newAccountList){
            if(a.IsCustomerPortal &&
               (oldAccountMap.get(a.id).FirstName != a.FirstName ||
                oldAccountMap.get(a.id).LastName != a.LastName ||
                oldAccountMap.get(a.id).Email_connexion__c != a.Email_connexion__c ||
                oldAccountMap.get(a.id).PersonMobilePhone != a.PersonMobilePhone ||
                oldAccountMap.get(a.id).Phone != a.Phone ||
                oldAccountMap.get(a.id).PersonMailingStreet != a.PersonMailingStreet ||
                oldAccountMap.get(a.id).PersonMailingCity != a.PersonMailingCity ||
                oldAccountMap.get(a.id).PersonMailingPostalCode != a.PersonMailingPostalCode ||
                oldAccountMap.get(a.id).PersonMailingCountry != a.PersonMailingCountry)){
                    updateRelatedUser(a.id);
                }
        }
    }
    
    /***
	* @description Update the users - future method
	* @param User
	* @return NA
	*/
    @future
    private static void updateRelatedUser(id accountId){
        
        // Query the account again
        Account a = [SELECT id, FirstName, LastName, Email_connexion__c, 
                     PersonMobilePhone, Phone, 
                     PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry
                     FROM Account
                     WHERE id =: accountId];
        
        // Query the related user
        List<User> userList = [SELECT id, FirstName, LastName, Email, Username, 
                               MobilePhone, Phone, 
                               Street, City, PostalCode, Country
                               FROM User
                               WHERE AccountId =: accountId];
        
        if(userList.size() == 1){
            User u = userList[0];
            
            u.FirstName = a.FirstName;
            u.LastName = a.LastName;
            u.Email = a.Email_connexion__c;
            u.Username = a.Email_connexion__c;
            u.MobilePhone = a.PersonMobilePhone;
            u.Phone = a.Phone;
            u.Street = a.PersonMailingStreet;
            u.City = a.PersonMailingCity;
            u.PostalCode = a.PersonMailingPostalCode;
            u.Country = a.PersonMailingCountry;
            update u;
        }
    }
}