/***
* @author Ariane Tanguy (GFI)
* @date 28/07/2020
* @description Handler class for Case
* DATE          DEV         DESCRIPTION
* 10/12/2020    PMB         add updateAlertOnUpdate
* 24/02/2021    KRE         add setReclamationNumber
*/

public class CaseTriggerHandler {
    
    /***
    * @description Update the Case technumber on create
    * @param newCaseList - list of all new cases
    * @param maxNumberMap - max number of all the already created cases per record type
    * @return NA
    */
    public static void setTechNumber(List<Case> newCaseList, Map<String, Decimal> maxNumberMap) {
        
        // For all the newly created cases
        for (Case c : newCaseList) {
            
            c.tech_numsin__c = 1;
            
            if(!c.vlocity_ins__Verified__c){
                
                if (maxNumberMap.keySet().contains(c.Record_type_Name__c)) {
                    
                    if(c.Record_type_Name__c == 'Sinistre' && maxNumberMap.keyset().contains('Sinistre clôturé')){
                        List<Decimal> whichIsMax = new List<Decimal>{maxNumberMap.get(c.Record_type_Name__c) + 1, 
                            maxNumberMap.get('Sinistre clôturé') + 1};
                                whichIsMax.sort();
                        c.tech_numsin__c = whichIsMax[1];
                    } else {
                        c.tech_numsin__c = maxNumberMap.get(c.Record_type_Name__c) + 1;
                    }
                    
                    maxNumberMap.put(c.Record_type_Name__c, c.tech_numsin__c);
                } else {
                    maxNumberMap.put(c.Record_type_Name__c, c.tech_numsin__c);
                }
            }
        }
    }
    
    /***
    * @description Update the Case record type
    * @param newCaseList - list of all new cases
    * @param maxNumber - max number of all the already created cases
    * @return NA
    */
    public static void setTechNumber(List<Case> newCaseList, Map<id, Case> oldCaseMap, Map<String, Decimal> maxNumberMap) {
        
        // For the newly created cases
        for (Case c : newCaseList) {
            
            // If the record type has just been changed
            if ((c.Record_type_Name__c != oldCaseMap.get(c.Id).Record_type_Name__c &&
                 c.tech_numsin__c == oldCaseMap.get(c.Id).tech_numsin__c) ||
                (c.vlocity_ins__Verified__c != oldCaseMap.get(c.Id).vlocity_ins__Verified__c)) {
                    
                    if(c.Record_type_Name__c == 'Sinistre clôturé'){
                        continue;
                    }
                    
                    if (maxNumberMap.keySet().contains(c.Record_type_Name__c)) {
                        
                        if(c.Record_type_Name__c == 'Sinistre' && maxNumberMap.keyset().contains('Sinistre clôturé')){
                            List<Decimal> whichIsMax = new List<Decimal>{maxNumberMap.get(c.Record_type_Name__c) + 1, 
                                maxNumberMap.get('Sinistre clôturé') + 1};
                                    whichIsMax.sort();
                            c.tech_numsin__c = whichIsMax[1];
                        } else {
                            c.tech_numsin__c = maxNumberMap.get(c.Record_type_Name__c) + 1;
                        }
                        
                        maxNumberMap.put(c.Record_type_Name__c, maxNumberMap.get(c.Record_type_Name__c) + 1);
                    }
                }
        }
    }
    
    /***
    * @description Update the Case technumber on create
    * @param newCaseList - list of all new cases
    * @param maxNumberMap - max number of all the already created cases per record type
    * @return NA
    */
    public static void updateAccountOnAssetUpdate(List<Case> newCaseList, Map<id, Asset> relatedAssetMap) {
        
        // For all the newly created cases
        for (Case c : newCaseList) {
            if (relatedAssetMap.keySet().contains(c.AssetId)) {
                c.AccountId = relatedAssetMap.get(c.AssetId).AccountId;
            }
        }
    }
    
    /***
    * @description Update the Case technumber on create
    * @param newCaseList - list of all new cases
    * @param maxNumberMap - max number of all the already created cases per record type
    * @return NA
    */
    public static void updateAccountOnAssetUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap, Map<id, Asset> relatedAssetMap) {
        
        // For all the newly created cases
        for (Case c : newCaseList) {
            if (c.AssetId != oldCaseMap.get(c.id).AssetId &&
                relatedAssetMap.keySet().contains(c.AssetId)) {
                    c.AccountId = relatedAssetMap.get(c.AssetId).AccountId;
                }
        }
    }
    
    /***
    * @description Update the related sinistre on reclamation update
    * @param newCaseList - list of new cases
    * @param oldCaseMap - map of old cases
    * @return NA
    */
    public static void updateSinistreOnReclaUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap){
        
        id caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
        
        // For all the newly created cases
        List<Case> sinistreToUpdate = new List<Case>();
        for (Case c : newCaseList){
            if (c.AnswerNature__c != oldCaseMap.get(c.id).AnswerNature__c &&
                c.AnswerNature__c == 'Favorable' &&
                c.Record_Type_Name__c == 'Réclamation'){
                    
                    if(caseSinistreId == NULL){
                        caseSinistreId = UtilityClassHelper.getCreatedRecordType('Sinistre');
                    }
                    
                    Case s = new Case(id = c.AssociatedSinister__c, 
                                      Status = 'En cours d\'examen', 
                                     RecordTypeId = caseSinistreId);
                    sinistreToUpdate.add(s);
                }
        }
        update sinistreToUpdate;
    }
    
    /***
    * @description Update the related equipement sinistre on case (sinistre + sav) validation
    * @param newCaseList - list of new cases
    * @param oldCaseMap - map of old cases
    * @param relatedEquipSinMap - related equip sin map
    * @return NA
    */
    public static void updateEquipSinOnCaseValidation(List<Case> newCaseList, Map<id, Case> oldCaseMap, Map<id, List<Equipement_sinistre__c>> relatedEquipSinMap){
        
        // For all the newly updated cases
        List<Equipement_sinistre__c> equipSinToUpdate = new List<Equipement_sinistre__c>();
        for (Case c : newCaseList){
            if (c.vlocity_ins__Verified__c != oldCaseMap.get(c.id).vlocity_ins__Verified__c &&
                (c.Record_Type_Name__c == 'Sinistre' ||
                 c.Record_Type_Name__c == 'SAV') &&
                relatedEquipSinMap.keySet().contains(c.id)){
                    for(Equipement_sinistre__c e : relatedEquipSinMap.get(c.id)){
                        e.Name = c.Numero_sinistre__c + '-' + e.Equipement_client__r.Name;
                        equipSinToUpdate.add(e);
                    }
                }
        }
        if(equipSinToUpdate.size() > 0){
            update equipSinToUpdate;
        }
    }
    
    /***
    * @description Checks the user's profile before delete
    * @param caseList - list of case to be deleted
    * @return NA
    */
    public static void isDeleteAuthorized(List<Case> caseList){
        
        // Get the current user's profile
        String currentUserProfile = [SELECT Name 
                                     FROM Profile 
                                     WHERE id =: System.UserInfo.getProfileId()].Name;
        
        if(currentUserProfile != 'System Administrator'){
            throw new DeleteNotAuthorizedException('Vous n\'avez pas les droits suffisants pour supprimer cette requête' + '\n' + 
                                                   'You don\'t have the permission to delete the current record.');
        }
    }
    
    public class DeleteNotAuthorizedException extends Exception {}
    
    /***
    * @description Update the Case on update
    * @param newCaseList - list of all new cases
    * @param oldCaseMap - map of all old cases
    * @return NA
    */
    public static void updateSinistreOnUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap, Map<id, List<Document__c>> caseIdDocumentMap, Id idDispatchSin) {
        
        // For the newly created cases
        for (Case c : newCaseList) {
            
            // If the case is a sinistre one
            if ((c.Record_Type_Name__c == 'Sinistre' &&
                 c.Attente_documents__c == 'Valid' &&
                 (c.Attente_client_final__c != oldCaseMap.get(c.id).Attente_client_final__c ||
                  c.RecordTypeId != oldCaseMap.get(c.id).RecordTypeId ||
                  c.OwnerId != oldCaseMap.get(c.Id).OwnerId)) &&
                ((c.Attente_client_final__c == '' ||
                 c.Attente_client_final__c == null) && c.OwnerId != idDispatchSin)) {
                     c.Status = 'En cours d\'examen';
                 }
            
            if (c.Record_Type_Name__c == 'Sinistre' &&
                caseIdDocumentMap.keySet().contains(c.Id) &&
                c.Status == 'Reception_dossier') {
                    c.Status = 'A attribuer';
                }
        }
    }
    
    /***
    * @description Update the Case
    * @param newCaseList - list of all new cases
    * @param Map<String, List<Types_piece_justificative__c>> - map
    * @return NA
    */
    public static void createNecessaryDocs(List<Case> newCaseList, Map<String, List<Types_piece_justificative__c>> typologyPieceJustificativeMap) {
        
        List<Piece_justificative_Sinistre__c> PJToCreateList = new List<Piece_justificative_Sinistre__c>();
        List<Case> caseToUpdate = new List<Case>();
        
        // Loop over the new cases
        for (Case c : newCaseList) {
            
            if (typologyPieceJustificativeMap.keySet().contains(c.Typologie_Sinistre__c)) {
                
                for (Types_piece_justificative__c t : typologyPieceJustificativeMap.get(c.Typologie_Sinistre__c)) {
                    
                    Piece_justificative_Sinistre__c p = new Piece_justificative_Sinistre__c();
                    p.Case__c = c.id;
                    p.Name = t.Name;
                    p.LongTitle__c = t.LongTitle__c;
                    p.NoTradable__c = t.NoTradable__c;
                    PJToCreateList.add(p);
                }
            }
        }
        
        insert PJToCreateList;
    }
    
    /***
    * @description Update the Case on update
    * @param newCaseList - list of all new cases
    * @param oldCaseMap - map of all old cases
    * @return NA
    */
    public static void updateAlertOnUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap) {
        
        List<String> idSinistreAlertToUpdateApprouved = new List<String>();
        List<String> idSinistreAlertToUpdateRejected = new List<String>();
        
        // For the newly created cases
        for (Case c : newCaseList) {
            
            // If the case is a sinistre one
            if (c.Record_Type_Name__c == 'Sinistre' &&
                oldCaseMap.get(c.id).TECH_ApprovalProcessStatus__c != null &&
                c.TECH_ApprovalProcessStatus__c !=
                oldCaseMap.get(c.id).TECH_ApprovalProcessStatus__c) {
                    
                    if (c.TECH_ApprovalProcessStatus__c == 'Approved') {
                        idSinistreAlertToUpdateApprouved.add(c.Id);
                    } else if (c.TECH_ApprovalProcessStatus__c == 'Rejected') {
                        idSinistreAlertToUpdateRejected.add(c.Id);
                    }
                }
        }
        
        if (idSinistreAlertToUpdateApprouved.size() > 0) {
            //send true in parameters if we should update alert to approuved
            UtilityClassHelper.updateAlert(idSinistreAlertToUpdateApprouved, true);
        }
        if (idSinistreAlertToUpdateRejected.size() > 0) {
            //send true in parameters if we should update alert to rejected
            UtilityClassHelper.updateAlert(idSinistreAlertToUpdateRejected, false);
        }
    }
    
    /***
    * @description Update the Case on update
    * @param newCaseList - list of all new cases
    * @param oldCaseMap - map of all old cases
    * @return NA
    */
    public static void updateAssetKPI(List<Case> newCaseList, Map<id, Case> oldCaseMap) {
        
        system.debug('-- newCaseList ' + newCaseList);
        system.debug('-- oldCaseMap ' + oldCaseMap);
        
        List<Id> lstContractToUpdate = new List<Id>();
        List<Id> lstCaseCurrentClosed = new List<Id>();
        
        for (Case c : newCaseList) {
            if (c.AssetId != null && 
                c.Record_Type_Name__c.contains('Sinistre')) {
                    lstContractToUpdate.add(c.AssetId);
                }
            if(c.AssetId != null &&
                c.Record_Type_Name__c.contains('Sinistre') &&
                oldCaseMap != null && oldCaseMap.get(c.Id).Status != c.Status &&
                (c.Status == 'closed_repaired' || c.Status == 'closed_exchange')){
                    lstCaseCurrentClosed.add(c.Id);
            }
        }
        
        if (lstContractToUpdate.size() > 0 &&
            !System.isBatch() &&
            !System.isFuture()) {
                system.debug('-- go calculatorProcess');
                calculatorProcess(lstContractToUpdate,lstCaseCurrentClosed);
            }
    }
    
    /***
    * @description future method to optimized process
    * @param newCaseList - list of asset ids
    * @return NA
    */
    @future
    public static void calculatorProcess(List<Id> assetId,List<Id> lstCaseCurrentClosed) {
        
        system.debug('-- assetId ' + assetId);
        
        List<Case> listCase = [SELECT Id, AssetId, IsDeleted, Montant_sinistre__c,
                               Date_sinistre__c, Status, Montant_geste_co__c,
                               Asset.Formule__r.Formule_options__r.NbMounthKPIContract__c, 
                               Asset.TECH_CalculatorIndicLastChange__c,
                               Asset.TECH_CalculatorIndicNextChange__c,
                               Asset.Date_debut_contrat__c,
                               Asset.TECH_LastBirthDayContract__c,
                               Asset.Plafond__c,
                               LastModifiedDate
                               FROM Case
                               WHERE AssetId IN :assetId
                               AND Record_Type_Name__c LIKE 'Sinistre%'
                               ORDER BY LastModifiedDate DESC
                               ALL ROWS];
                               
        UtilityClassHelper.assetKPICalculator(listCase,lstCaseCurrentClosed);
    }

        /***
    * @description future method to optimized process
    * @param newCaseList - list of asset ids
    * @return NA
    */
    public static void nofuturCalculatorProcess(List<Id> assetId,List<Id> lstCaseCurrentClosed) {
        
        system.debug('-- assetId ' + assetId);
        
        List<Case> listCase = [SELECT Id, AssetId, IsDeleted, Montant_sinistre__c,
                               Date_sinistre__c, Status, Montant_geste_co__c,
                               Asset.Formule__r.Formule_options__r.NbMounthKPIContract__c, 
                               Asset.TECH_CalculatorIndicLastChange__c,
                               Asset.TECH_CalculatorIndicNextChange__c,
                               Asset.Date_debut_contrat__c,
                               Asset.TECH_LastBirthDayContract__c,
                               Asset.Plafond__c,
                               LastModifiedDate
                               FROM Case
                               WHERE AssetId IN :assetId
                               AND Record_Type_Name__c LIKE 'Sinistre%'
                               ORDER BY LastModifiedDate DESC
                               ALL ROWS];
                               
        UtilityClassHelper.assetKPICalculator(listCase,lstCaseCurrentClosed);
    }

    /***
    * @description Force value to not approval to manage issue 
    * @param newCaseList - list of case update
    * @param oldCaseMap - Map of old case update
    * @return NA
    */
    public static void forceValueApprovalProcess(List<Case> newCaseList, Map<id, Case> oldCaseMap){
        
        for(Case c : newCaseList){
            if(oldCaseMap.get(c.Id).Id != null &&
               c.Record_Type_Name__c == 'Sinistre' &&
               ((c.TECH_ApprovalProcessStatus__c == 'Approved' ||
                 c.TECH_ApprovalProcessStatus__c == 'Rejected')
                ||
                (oldCaseMap.get(c.Id).TECH_ApprovalProcessStatus__c == 'Approved' ||
                 oldCaseMap.get(c.Id).TECH_ApprovalProcessStatus__c == 'Rejected')) 
               &&
               c.TECH_ApprovalProcessStatus__c != 'Not Approval'){
                   c.TECH_ApprovalProcessStatus__c = 'Not Approval';
               }
        }
    }
    
    /***
    * @description Create contract alert on case update
    * @param newCaseList - list of all new cases
    * @param oldCaseMap - map of all old cases
    * @return NA
    */
    public static void createAlertOnUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap) {        
        // For the newly created cases
        for (Case c : newCaseList) {            
            // If the case is a sinistre one
           // system.debug('--ForcerPaiement : '+ c.Pouss_par_Salesforce__c);
            if (c.Record_Type_Name__c == 'Sinistre' 
                && (
                    (oldCaseMap.get(c.id).Date_sinistre__c != null && c.Date_sinistre__c != oldCaseMap.get(c.id).Date_sinistre__c) 
                    || (oldCaseMap.get(c.id).ClientDeclarationValidationDate__c != null && c.ClientDeclarationValidationDate__c != oldCaseMap.get(c.id).ClientDeclarationValidationDate__c)
                    || c.Pouss_par_Salesforce__c == true 
                )) {
                    Asset a = [SELECT Date_debut_contrat__c, Date_cloture__c FROM Asset WHERE Id = :c.AssetId LIMIT 1];
                    List<Alert__c> listAlertToCreate = new List<Alert__c>();
                    if (a != null) {
                        if (c.Date_sinistre__c <= a.Date_debut_contrat__c) {
                            listAlertToCreate.add(new Alert__c(BusinessRulesNumber__c = 'RGSIN11', SalesDiscountMotif__c  = 'Date du sinistre inférieure au contrat'));
                        }

                        if (c.Date_sinistre__c > a.Date_cloture__c) {
                            listAlertToCreate.add(new Alert__c(BusinessRulesNumber__c = 'RGSIN17', SalesDiscountMotif__c  = 'Date de sinistre supérieure à la date du contrat'));
                        }
                        
                        system.debug('++++++'+  (c.Date_sinistre__c).daysBetween(c.ClientDeclarationValidationDate__c));
                   
                        if (
                            (c.Date_sinistre__c).daysBetween(c.ClientDeclarationValidationDate__c) > 10
                            || (c.Date_sinistre__c).daysBetween(c.ClientDeclarationValidationDate__c) < -10
                        ) {
                            if (
                                (c.Date_sinistre__c).daysBetween(c.ClientDeclarationValidationDate__c) >= 90
                                || (c.Date_sinistre__c).daysBetween(c.ClientDeclarationValidationDate__c) <= -90
                            ) {
                                listAlertToCreate.add(new Alert__c(BusinessRulesNumber__c = 'RGSIN15', SalesDiscountMotif__c  = 'Date de survenance du sinistre de plus de 3 mois'));
                            } else {
                                listAlertToCreate.add(new Alert__c(BusinessRulesNumber__c = 'RGSIN16', SalesDiscountMotif__c  = 'Date de survenance du sinistre supérieure à 10 jours de la date de déclaration'));
                            }
                        }
                        
                        if (
                            c.Pouss_par_Salesforce__c == true 
                        ) {
                             listAlertToCreate.add(new Alert__c(BusinessRulesNumber__c = 'RGSIN19', SalesDiscountMotif__c  = 'Demande contournement Règlement Contrat'));
                        }
                    } 
                    
                    system.debug('+++++++'+listAlertToCreate);
                    
                    UtilityClassHelper.createDateAlertIfNotExist(listAlertToCreate, c.id);
                }
        }
    }
    
     /***
    * @description Update calcul indemnisation on update
    * @param newCaseList - list of all new cases
    * @param oldCaseMap - map of all old cases
    * @return NA
    */
    public static void updateCalculIndemnisationOnUpdate(List<Case> newCaseList, Map<id, Case> oldCaseMap) {
        
        List<String> CaseCalculIndemToUpdateApprouved = new List<String>();
        List<String> CaseCalculIndemToUpdateRejected = new List<String>();
        
        // For the newly updated cases
        for (Case c : newCaseList) {
            
            // If the case is a sinistre one
            if (c.Record_Type_Name__c == 'Sinistre' &&
                oldCaseMap.get(c.id).TECH_ApprovalProcessStatus__c != null &&
                c.TECH_ApprovalProcessStatus__c !=
                oldCaseMap.get(c.id).TECH_ApprovalProcessStatus__c) {
                    
                    if (c.TECH_ApprovalProcessStatus__c == 'Approved') {
                        CaseCalculIndemToUpdateApprouved.add(c.Id);
                    } else if (c.TECH_ApprovalProcessStatus__c == 'Rejected') {
                        CaseCalculIndemToUpdateRejected.add(c.Id);
                    }
                }
        }
        
        if (CaseCalculIndemToUpdateApprouved.size() > 0) {
            //send true in parameters if we should update calcul indemn to approuved
            UtilityClassHelper.updateCalculIndemnisationInProgress(CaseCalculIndemToUpdateApprouved, true);
        }
        if (CaseCalculIndemToUpdateRejected.size() > 0) {
            //send true in parameters if we should update calcul indemnisation to rejected
            UtilityClassHelper.updateCalculIndemnisationInProgress(CaseCalculIndemToUpdateRejected, false);
        }
    }
}