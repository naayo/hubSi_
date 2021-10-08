/***
* @author Ariane Tanguy (GFI)
* @date 12/05/2020
* @description Handler class for AssetTrigger
*/

public class AssetTriggerHandler {
    
    /***
	* @description Update the account record type if needed
	* @param newAssetList - list of all new assets
	* @param relatedAccountMap - map of related account
	*/
    public static void updateAccountRecordType(List<Asset> assetList, 
                                               Map<id, Account> relatedAccountMap, 
                                               Map<id, String> accountAssetMap){
        
        Id clientHubsideId, clientLocId = NULL;
        
        // For every new asset, check the related account record type
        List<Account> accountToUpdate = new List<Account>();
        for(Asset a : assetList){
            
            if(relatedAccountMap.keySet().contains(a.AccountId)){
                
                // If the asset is an insurance one, make sure the account is too
                if(a.Record_Type_Name__c == 'Contrat_assurance' &&
                   relatedAccountMap.get(a.AccountId).Record_Type_Name__c != 'Client_SFAM'){
                       
                       if(clientHubsideId == NULL){
                           clientHubsideId = UtilityClassHelper.getCreatedRecordType('Client_SFAM');
                       }
                       relatedAccountMap.get(a.AccountId).RecordTypeId = clientHubsideId;
                       relatedAccountMap.get(a.AccountId).Compte_test__c = TRUE;
                       accountToUpdate.add(relatedAccountMap.get(a.AccountId));
                   }
                
                // If the asset is a location one, and if the previous assets were location's as well, check whether the account is location
                if((a.Record_Type_Name__c == 'Contrat_location' ||
                    (a.Record_Type_Name__c != 'Contrat_location' &&
                     a.Record_Type_Name__c != 'Contrat_assurance')) &&
                   relatedAccountMap.get(a.AccountId).Record_Type_Name__c != 'Client_location'){
                       
                       if((accountAssetMap.keySet().contains(a.AccountId) && 
                           accountAssetMap.get(a.AccountId) == 'Contrat_location') ||
                          !accountAssetMap.keySet().contains(a.AccountId)){
                              if(clientLocId == NULL){
                                  clientLocId = UtilityClassHelper.getCreatedRecordType('Client_location');
                              }
                              relatedAccountMap.get(a.AccountId).RecordTypeId = clientLocId;
                              relatedAccountMap.get(a.AccountId).Compte_test__c = TRUE;
                              accountToUpdate.add(relatedAccountMap.get(a.AccountId));
                          }
                   }
            }
        }
  
		// Update the accounts
		update accountToUpdate;
    }
    
    /***
	* @description Handle the account activation
	* @param newAssetList - list of all new assets
	* @param newContratLocRecordType - asset location record type
	* @return void
	*/
    public static void handleAccountActivation(List<Asset> newAssetList, id newContratLocRecordType){
        
        Set<id> passlocAccountIdSet = new Set<id>();
        Set<id> illipassAccountIdSet = new Set<id>();
        
        // Loop over those new assets
        for(Asset a : newAssetList){
            
            // Get only the location contracts
            if(a.RecordTypeId == newContratLocRecordType){
                // Sort the account depending on their shop name
                // [SFAMI-2119> (1/2) prevent temporarily asset trigger to create user if the contract is Spanish or Belgian
                if (!(a.Name.startsWith('ES') || a.Name.startsWith('BE'))){
                // <SFAMI-2119]
                    if(a.Enseigne__c == 'SFAM'){
                        passlocAccountIdSet.add(a.AccountId);
                    } else {
                        illipassAccountIdSet.add(a.AccountId);
                    }    
                // [SFAMI-2119> (2/2) prevent temporarily asset trigger to create user if the contract is Spanish or Belgian >
                }
                // <SFAMI-2119]
            }
        }
        
        if(passlocAccountIdSet.size() > 0){
            id passlocProfileId = [SELECT Id
                                   FROM Profile
                                   //replace Community Plus License by Community License >
                                   //WHERE Name =: 'Passloc Customer community Plus Login User'].id;
                                   WHERE Name =: 'Passloc Customer community Login User'].id;
                                   // <
            createUser(passlocAccountIdSet, passlocProfileId);
        }
        if(illipassAccountIdSet.size() > 0){
            id illipassProfileId = [SELECT Id
                                   FROM Profile
                                   //replace Community Plus License by Community License >
                                   //WHERE Name =: 'Illipass Customer community Plus Login User'].id;
                                   WHERE Name =: 'Illipass Customer community Login User'].id;
                                   // <
            createUser(illipassAccountIdSet, illipassProfileId);
        }
        
    }
    
    /***
	* @description Handle the account activation
	* @param newAssetList - list of all new assets
	* @param newContratLocRecordType - asset location record type
	* @return void
	*/
    @future
    public static void createUser(Set<id> accIdSet, id profileId){
        
        List<Account> accountList = [SELECT id, 
                                     FirstName, LastName, 
                                     PersonContactId, 
                                     Email_Connexion__c, 
                                     Phone, PersonMobilePhone, 
                                     PersonMailingCity, PersonMailingCountry, 
                                     PersonMailingPostalCode, 
                                     PersonMailingStreet
                                     FROM Account
                                     WHERE id IN: accIdSet
                                     AND IsCustomerPortal = FALSE];
        
        // Loop over the accounts and create the users
        List<User> userToInsert = new List<User>();
        for(Account a : accountList){
            
            // Create a new user
            User u = new User();
            
            u.ProfileId = profileId;
            
            u.ContactID = a.PersonContactId;
            u.FirstName = a.FirstName;
            u.LastName = a.LastName;
            u.alias = u.FirstName.left(1) + u.LastName.left(4);
            u.Email = a.Email_Connexion__c;
            u.username = u.Email;
            u.CommunityNickname = u.Email.left(39);
            
            u.Phone = a.Phone == NULL ? a.PersonMobilePhone : a.Phone;
            
            u.city = a.PersonMailingCity;
            u.country = a.PersonMailingCountry;
            u.postalCode = a.PersonMailingPostalCode;
            u.street = a.PersonMailingStreet;
            
            u.TimeZoneSidKey = 'GMT';
            u.LocaleSidKey = 'fr_FR_EURO';
            u.EmailEncodingKey = 'ISO-8859-1';
            u.LanguageLocaleKey = 'fr';
            
            userToInsert.add(u);
        }
        
        system.debug('-- userToInsert ' + userToInsert);
        insert userToInsert;
    }
    
    /***
	* @description Handle the contract resiliation
	* @param newAssetList - list of all new assets
	* @param oldAssetMap - map of all old assets
	* @param relatedFactureMap - map of all related facture
	* @param relatedPolicyCoverageMap - map of all related policy coverage
	*/
    public static void handleResiliation(List<Asset> assetList, 
                                         Map<id, Asset> oldAssetMap,
                                         Map<id, Facture__c> relatedFactureMap, 
                                         Map<id, vlocity_ins__AssetCoverage__c> relatedPolicyCoverageMap){
        
        List<SObject> toUpdateList = new List<SObject>();
        
        // Check the status for all the assets
        for(Asset a : assetList){
            
            // If the motif is changed, and the date is given
            if(a.Motif_cloture__c != oldAssetMap.get(a.id).Motif_cloture__c &&
            a.Motif_cloture__c != NULL &&
            a.Date_cloture__c != NULL){
                
                // Update the related facture
                if(relatedFactureMap.keySet().contains(a.id) && 
                    a.Date_cloture__c < relatedFactureMap.get(a.id).Date_fin_periode__c){
                        relatedFactureMap.get(a.id).Date_fin_periode__c = a.Date_cloture__c;
                        toUpdateList.add(relatedFactureMap.get(a.id));
                    }
                
                // Update the asset
                a.Date_fin_contrat__c = a.Date_cloture__c;
                
                // And the policy coverage
                if(relatedPolicyCoverageMap.keySet().contains(a.id) &&
                    relatedPolicyCoverageMap.get(a.id).RecordType.Name == 'Formule_option_location'){
                        relatedPolicyCoverageMap.get(a.id).Date_de_resiliation__c = a.Date_cloture__c;
                        relatedPolicyCoverageMap.get(a.id).Motif_de_resiliation__c = 'Unknown';
                        toUpdateList.add(relatedPolicyCoverageMap.get(a.id));
                    }
            }
        }
        
        // Update the objects
        if(toUpdateList.size() > 0){
            update toUpdateList;
        }
    }
    
    /***
	* @description Handle the etat paiement update
	* @param newAssetList - list of all new assets
	* @param newContratLocRecordType - asset location record type
	* @return void
	*/
    public static void handleValidPayment(List<Asset> newAssetList, Map<id, Asset> oldAssetMap, Map<id, List<Case>> relatedCaseMap){
        
        // Loop over those new assets
        List<Case> caseToUpdate = new List<Case>();
        for(Asset a : newAssetList){
            
            // If the etat paiement is changed and there are cases on that asset
            if(a.Etat_paiement__c != oldAssetMap.get(a.id).Etat_paiement__c &&
               a.Etat_paiement__c == 'valid' &&
               relatedCaseMap.keySet().contains(a.id)){
                   
                   // Loop over the cases
                   for(Case c : relatedCaseMap.get(a.id)){
                       if(c.Attente_documents__c == 'Valid'){
                              c.Status = 'En cours d\'examen';
                              caseToUpdate.add(c);
                          }
                   }
            }
        }
        
        if(caseToUpdate.size() > 0){
            update caseToUpdate;
        }
    }

    /***
	* @description Handle the etat paiement update
	* @param newAssetMap - list of all new assets
    * @param oldAssetMap - map of all old assets
	* @param newContratLocRecordType - asset insurance record type
	* @return void
	*/
    public static void handleCalculatorIndicLastChange(List<Asset> listAsset,Map<id, Asset> oldAssetMap, id contratInsuranceRecordType){
        
        List<Id> listIdPolicyCoverage = new List<Id>(); 
        for(Asset ast : listAsset){
            if(ast.Formule__c != null){
                listIdPolicyCoverage.add(ast.Formule__c);
            }
        }

        Map<Id,vlocity_ins__AssetCoverage__c> mapPolicies;
        if(listIdPolicyCoverage.size() > 0){
            mapPolicies = AssetTriggerHelper.getRelatedPolicies(listIdPolicyCoverage);
        } 
        
        Map<String,Date> mapDateCalculator = new Map<String,Date>();

        Date dateCalculator,dateLastBirthDayCalculator;
        for(Asset a : listAsset){
            if(a.RecordTypeId == contratInsuranceRecordType &&
                a.Date_debut_contrat__c != null &&
                mapPolicies != null &&
                mapPolicies.get(a.Formule__c) != null &&
                mapPolicies.get(a.Formule__c).Formule_options__r.NbMounthKPIContract__c != null &&
                (a.TECH_CalculatorIndicLastChange__c == null || 
                (oldAssetMap != null && oldAssetMap.get(a.Id) != null && oldAssetMap.get(a.Id).Date_debut_contrat__c != null &&
                a.Date_debut_contrat__c != oldAssetMap.get(a.Id).Date_debut_contrat__c))){

                    // Get NbMonth to know how many month need to add
                    Integer nbMonthToAdd = (Integer)mapPolicies.get(a.Formule__c).Formule_options__r.NbMounthKPIContract__c;

                    if(nbMonthToAdd != null){
                        mapDateCalculator = UtilityClassHelper.manageCalculatorDate(NbMonthToAdd,a.Date_debut_contrat__c);

                        a.TECH_CalculatorIndicLastChange__c = mapDateCalculator.get('TECH_CalculatorIndicLastChange__c');
                        a.TECH_LastBirthDayContract__c = mapDateCalculator.get('TECH_LastBirthDayContract__c');
                    }
            }
        }

    }
}