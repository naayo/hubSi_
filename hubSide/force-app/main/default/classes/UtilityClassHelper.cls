/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Utility class helper
*/

public class UtilityClassHelper {
    
    /***
	* @description Get a record type
	* @param recordTypeName - record type name
	* @return id - record type id
	*/
    public static Id getCreatedRecordType(String recordTypeName){
        
        // Get the record type 
        return [SELECT id
                FROM RecordType
                WHERE DeveloperName =: recordTypeName][0].id;
    }

    /***
	* @description Get a record type with object name because there are a recordtype with same name
    * @param recordTypeName - record type name
    * @param objectName - object name
	* @return id - record type id
	*/
    public static Id getCreatedRecordType(String recordTypeName,String objectName){
        
        // Get the record type 
        return [SELECT id
                FROM RecordType
                WHERE DeveloperName =: recordTypeName AND SobjectType =: objectName][0].id;
    }
    
    /***
	* @description Compare the date
	* @param dateSortie / dateRetour - date to be compared
	* @param dateSortieRef / dateRetourRef - date of the res / emp already in the system
	* @return boolean -
	*/
    public static boolean compareDate(Date dateSortie, Date dateRetour, Date dateSortieRef, Date dateRetourRef){
     
        Integer buffer = integer.valueof(System.Label.Location_DateBuffer);
        
        dateSortieRef = dateSortieRef.addDays(- buffer);
        dateRetourRef = dateRetourRef.addDays(buffer);
        
        boolean result = (dateSortieRef < dateSortie && dateSortie < dateRetourRef) || 
            (dateSortieRef < dateRetour && dateRetour < dateRetourRef) ||
            (dateSortie < dateSortieRef && dateRetour > dateRetourRef);
        system.debug('-- here result ' + result);
        
        return result;
    }
    
    /***
	* @description Format a date to a string
	* @param dateToFormat
	* @return String
	*/
    public static String formatDate(Date dateToFormat){
        
        String day = dateToFormat.day() < 10 ? '0' + String.valueOf(dateToFormat.day()) : String.valueOf(dateToFormat.day());
        String month = dateToFormat.month() < 10 ? '0' + String.valueOf(dateToFormat.month()) : String.valueOf(dateToFormat.month());
        
        String result = day + '/' + month + '/' + dateToFormat.year();
        
        return result;
    }
    
    /***
	* @description Return a random string
	* @param len
	* @return String
	*/
    public static String generateRandomString(Integer len) {
        
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        
        return randStr; 
    }
    
    /***
	* @description future method to create alert on sinistre
    * @param lstIdSinistre
    * @param processType
	* @return void
	*/
    public static void createDateAlertIfNotExist(List<Alert__c> listAlertToCreate, Id IdCase){

        List<Alert__c> listAlertToDelete = new List<Alert__c>();
        List<Alert__c> listNewAlerts = new List<Alert__c>();
        List<Alert__c> listDateAlert = [
            SELECT Id, BusinessRulesNumber__c FROM Alert__c 
            WHERE Case__c = :IdCase 
            AND BusinessRulesNumber__c IN ('RGSIN11', 'RGSIN15', 'RGSIN16', 'RGSIN17', 'RGSIN19')
        ];

        for(Alert__c al : listDateAlert){
            Boolean deleteAlert = true;
            for(Integer i = 0; i < listAlertToCreate.size(); i++) {
                if (al.BusinessRulesNumber__c == listAlertToCreate[i].BusinessRulesNumber__c) {
                    deleteAlert = false;
                    listAlertToCreate.remove(i);
                }
            }

            if (deleteAlert == true) {
                al.couldDeleted__c = true;
                update al;
                listAlertToDelete.add(al);
            }            
        }

        if(listAlertToDelete.size() > 0) {
            system.debug('--alertDeleted : '+listAlertToDelete);
            delete listAlertToDelete;
        } 

        for(Alert__c newAl : listAlertToCreate){
            if (newAl.BusinessRulesNumber__c == 'RGSIN19') {
                newAl.Status__c = 'Waiting';
                newAl.Case__c = IdCase;
                newAl.Type_Alert__c = 'Warning';
            } else {
                newAl.Status__c = 'Approved';
                newAl.Case__c = IdCase;
                newAl.Type_Alert__c = 'Warning';
                newAl.Validation_Reason__c = 'Validation par défaut car warning';
                newAl.Active_Inactive__c = 'SansObjet';
            }

            listNewAlerts.add(newAl);
        }

        if(listNewAlerts.size() > 0) {
            insert listNewAlerts;
        }      
    }

    /***
	* @description future method to update alert from sinistre id
    * @param lstIdSinistre
    * @param processType
	* @return void
	*/
    @future
    public static void updateAlert(List<String> lstIdSinistre,Boolean processType){
        updateAlertNoFuture(lstIdSinistre,processType);
    }

    /***
	* @description no future method to update alert from sinistre id
    * @param lstIdSinistre
    * @param processType
	* @return void
	*/
    public static void updateAlertNoFuture(List<String> lstIdSinistre,Boolean processType){
        List<Alert__c> listAlert = [SELECT Id,Status__c FROM Alert__c WHERE Case__c IN :lstIdSinistre];
        if(listAlert.size()>0){
            List<Alert__c> listAlertUpdate = new List<Alert__c>();
            for(Alert__c al : listAlert){
                if(processType){
                    al.Status__c = 'Approved';
                }
                else{
                    al.Status__c = 'Refused';
                }
                listAlertUpdate.add(al);
            }
            update listAlertUpdate;
        }
    }

    /***
	* @description no future method to update alert from sinistre id
    * @param lstIdSinistre
    * @param processType
    * @param validationReason
	* @return void
	*/
    public static void updateAlertNoFuture(List<String> lstIdSinistre,Boolean processType, String validationReason, String userId){
        List<Alert__c> listAlert = [SELECT Id,Status__c FROM Alert__c WHERE Case__c IN :lstIdSinistre];
        if(listAlert.size()>0){
            List<Alert__c> listAlertUpdate = new List<Alert__c>();
            for(Alert__c al : listAlert){
                if(processType){
                    al.Status__c = 'Approved';
                    al.Validation_Reason__c = validationReason;
                    al.ValidatorUserId__c = userId;
                }
                else{
                    al.Status__c = 'Refused';
                    al.ValidatorUserId__c = userId;
                }
                listAlertUpdate.add(al);
            }
            update listAlertUpdate;
        }
    }

    /***
	* @description future method to update asset from case
    * @param assetId
	* @return void
	*/
    public static void assetKPICalculator(List<Case> listCase,List<Id> lstCaseCurrentClosed){
        
        system.debug('-- listCase ' + listCase);
        
        Map<Id, List<Case>> mapAssetCase = new Map<Id, List<Case>>();
        Integer nbMonth;
        Date dateDebutContrat;
        Date nextChange;
        for(Case c : listCase){
            if(!mapAssetCase.keySet().contains(c.AssetId)){
                List<Case> tmpList = new List<Case>();
                nbMonth = (Integer)c.Asset.Formule__r.Formule_options__r.NbMounthKPIContract__c;
                dateDebutContrat = c.Asset.Date_debut_contrat__c;
                nextChange = c.Asset.TECH_CalculatorIndicNextChange__c;
                mapAssetCase.put(c.AssetId, tmpList);
            }
            mapAssetCase.get(c.AssetId).add(c);
        }
        system.debug('-- mapAssetCase ' + mapAssetCase);
        
        // Loop over the assets
        List<Asset> lstAssetToUpdate = new List<Asset>();
        List<Case> caseToUpdateList = new List<Case>();
        for(Id idAsset : mapAssetCase.keySet()){
            
            Integer nbCase, nbCaseEchange, nbCaseRep = 0;
            Decimal montantIndem, montantPrevious, plafond, gesteCoSum = 0;
            nbCase = nbCaseEchange = nbCaseRep = 0;
            montantIndem = plafond = montantPrevious = 0;
            
            // And over their related cases
            for(Case c : mapAssetCase.get(idAsset)){
                
                if(c.IsDeleted == false){
                    
                    system.debug('-- c ' + c);
                    
                    nbCase++;
                    gesteCoSum += c.Montant_geste_co__c;
                    
                    if((c.Status == 'closed_repaired' || c.Status == 'closed_exchange') ||
                        lstCaseCurrentClosed !=null && lstCaseCurrentClosed.contains(c.Id)){
                        
                        if(plafond == 0 && c.Asset.Plafond__c != NULL){
                            plafond = c.Asset.Plafond__c;
                            system.debug('-- plafond ' + plafond);
                        }
                        
                        if(c.Date_sinistre__c >= c.Asset.TECH_LastBirthDayContract__c && 
                            c.Date_sinistre__c <= c.Asset.TECH_CalculatorIndicLastChange__c){
                                montantIndem = montantIndem + c.Montant_sinistre__c;
                                system.debug('-- montantIndem ' + montantIndem);
                                if(c.Status == 'closed_exchange'){
                                    nbCaseEchange++;
                                }
                                if(c.Status == 'closed_repaired'){
                                    nbCaseRep++;
                                }
                           }
                        if(c.Date_sinistre__c < c.Asset.TECH_LastBirthDayContract__c &&
                           c.Date_sinistre__c > c.Asset.TECH_LastBirthDayContract__c.addMonths(-1*nbMonth)){
                                montantPrevious = montantPrevious + c.Montant_sinistre__c;
                                system.debug('-- montantPreviousIndem ' + montantIndem);
                          }
                    }
                }
            }
            
            // Check whether the indemn restante (- other cases geste co) is now negative
            if((plafond - montantIndem + gesteCoSum) < 0){
                
                // If that's the case, update the last update case with a new geste co
                Case c = mapAssetCase.get(idAsset)[0];
                c.Montant_geste_co__c = -(plafond - montantIndem + gesteCoSum);
                caseToUpdateList.add(c);
            }
            
            Asset ast = new Asset();
            if(System.isBatch()){
                ast.TECH_CalculatorIndicLastChange__c = nextChange;
                ast.TECH_LastBirthDayContract__c = System.now().date();
                ast.TECH_PreviousAmountIndem__c = montantPrevious;
            }
            ast.Id = idAsset;
            ast.Sinistre_declares_asset__c = nbCase;
            ast.Montant_indemnisation__c = montantIndem;
            ast.Echanges_realises__c = nbCaseEchange;
            ast.NbRepMake__c = nbCaseRep;
            ast.TECH_PreviousAmountIndem__c = montantPrevious;
            
            lstAssetToUpdate.add(ast);
        }
        
        system.debug('-- lstAssetToUpdate ' + lstAssetToUpdate);
        system.debug('-- caseToUpdateList ' + caseToUpdateList);
        
        if(lstAssetToUpdate.size() > 0){
            update lstAssetToUpdate; 
        }
        if(caseToUpdateList.size() > 0){
            update caseToUpdateList; 
        }
    }
    
    /***
	* @description Get the picklist values of an object
	* @param sObj
	* @param picklistField
	* @return Map<String, String>
	*/
    public static Map<String, String> getPicklistValues(SObject sObj, String picklistField){
        
        // Get a map of fields for the SObject
        Map<String, Schema.SObjectField> fieldMap = sObj.getSObjectType().getDescribe().fields.getMap();
        
        // Get the list of picklist values for this field.
        List<Schema.PicklistEntry> picklistValueList = fieldMap.get(picklistField).getDescribe().getPickListValues();
        
        // Map these values
        Map<String, String> picklistValueMap = new Map<String, String>();
        for (Schema.PicklistEntry p : picklistValueList){ 
            picklistValueMap.put(p.getLabel(), p.getValue()); 
        }
        
        return picklistValueMap;
    }
    
    /***
	* @description Get the picklist values of an object
	* @param objectName
	* @param picklistField
	* @return Map<String, String>
	*/
    public static Map<String, String> getPicklistValues(String objectName, String picklistField){
        
        // Get a map of fields for the SObject
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get the list of picklist values for this field.
        List<Schema.PicklistEntry> picklistValueList = describeResult.fields.getMap().get(picklistField).getDescribe().getPicklistValues();
        
        // Map these values
        Map<String, String> picklistValueMap = new Map<String, String>();
        for (Schema.PicklistEntry p : picklistValueList){ 
            picklistValueMap.put(p.getLabel(), p.getValue()); 
        }
        
        return picklistValueMap;
    }
    
    /***
	* @description Get the controlling / dependant field map
	* @param objectName
	* @param controllingField
	* @param dependentField
	* @return Map<String,List<String>>
	*/
    public static Map<String,List<String>> getDependentPicklistValues(String objectName, String controllingField, String dependentField){
        
        // Get the picklist info
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        List<Schema.PicklistEntry> controllerValues = describeResult.fields.getMap().get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = describeResult.fields.getMap().get(dependentField).getDescribe().getPicklistValues();
        
        // String used to decode the characters of the validFor fields. 
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        
        // Get the controlling labels
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for(Schema.PicklistEntry currControllingValue : controllerValues){
            dependentPicklistValues.put(currControllingValue.getLabel(), new List<String>());
        }
        
        // And map the dependant labels
        for (Schema.PicklistEntry entry : dependentValues){
            
            // If the dependant value is used
            if (entry.isActive()){
                
                // Get the dependancy info
                List<String> base64chars = String.valueOf(((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                
                if(base64chars.size() == 0 || 
                   (base64chars.size() == 1 && 
                    base64chars[0] == '')){
                        continue;
                    }
                
                for (Integer i = 0; i < controllerValues.size(); i++){
                    String controllerValue = (controllerValues[i].isActive() ? controllerValues[i].getLabel() : null);
                    
                    Integer bitIndex = i / 6;
                    if (bitIndex > base64chars.size()-1) { 
                        break; 
                    }
                    Integer bitShift = 5 - Math.mod(i, 6); 
                    
                    if(controllerValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0){
                        continue;
                    }
                    dependentPicklistValues.get(controllerValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
    
    /***
	* @description Send an email
	* @param whatId - id of the related object / needed for the template
	* @param toId - id related contact / account
	* @param templateId - template id
	* @param emailClient - email address where the mail is to be sent
	* @param whatId - id of the related object / needed for the template
	* @return NA
	*/
    public static Messaging.SingleEmailMessage createEmail(Id whatId, String toEmailAddress, Id templateId){
        
        system.debug('-- whatId ' + whatId);
        system.debug('-- toEmailAddress ' + toEmailAddress);
        system.debug('-- templateId ' + templateId);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //mail.setToAddresses(new List<String>{'ariane.tanguy@gfi.fr'});
        mail.setTemplateId(templateId);
        mail.setWhatId(whatId);
        
        OrgWideEmailAddress o = [SELECT Id, Address, DisplayName FROM 
                                 OrgWideEmailAddress 
                                 WHERE Address LIKE 'noreplycelside%'];
        mail.setOrgWideEmailAddressId(o.id);
        
        if (Test.IsRunningTest()){
            mail.setHtmlBody('223');
        }        
        
        if(toEmailAddress != NULL){
            // Create a dummy contact
            Contact c = new Contact(LastName = 'Dummy' + toEmailAddress, Email = toEmailAddress);
            
            // Check whether there is already a contact existing with that email address
            List<Contact> potentialContactList = [SELECT id FROM Contact WHERE Email =: toEmailAddress LIMIT 1];
            
            if(potentialContactList.size() > 0){
            	c = potentialContactList[0];
            } else {
                insert c;
            }
            
            mail.setTargetObjectId(c.Id);
        }
        
        return mail;
    }
    
    /***
	* @description Insert an attachment on a object
	* @param whatId - related object id
	* @param currentBlob - attachment
	* @param fileName - filename
	* @return NA
	*/
    public static void insertFile(Id whatId, Blob currentBlob, String fileName) {
        
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        newContentVersion.PathOnClient = fileName; // The file name /!\ extension
        newContentVersion.Title = fileName; // Display name
        // converting the binary String to Blog
        newContentVersion.VersionData = currentBlob;// EncodingUtil.base64Decode(EncodingUtil.base64Encode(currentBlob)); 
        insert newContentVersion;
        
        // Get the content document Id from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id =: newContentVersion.id].ContentDocumentId;
                        
        // Create the ContentDocumentLink                    
        ContentDocumentLink newContentDocLink = new ContentDocumentLink();
        newContentDocLink.ContentDocumentId = contentDocumentId;
        newContentDocLink.LinkedEntityId = whatId; // could be objectId, GroupId or any other id
        newContentDocLink.ShareType = 'V'; //'I'; // Inferred permission, see ContentDocumentLink Object
        newContentDocLink.Visibility = 'AllUsers'; // 'InternalUsers';        
        insert newContentDocLink;
    }

    /***
	* @description Manage date on asset process
	* @param NbMonthToAdd
	* @param dateDebutContrat
	* @return Map<String,Date>
	*/
    public static Map<String,Date> manageCalculatorDate(Integer NbMonthToAdd,Date dateDebutContrat){
        Map<String,Date> mapField = new Map<String,Date>();

        Date dateCalculator,dateLastBirthDayCalculator;
        if(nbMonthToAdd != null && nbMonthToAdd != 0){

            dateLastBirthDayCalculator = dateDebutContrat;
            while (dateLastBirthDayCalculator.addMonths(NbMonthToAdd) < System.now().date()) {
                dateLastBirthDayCalculator = dateLastBirthDayCalculator.addMonths(NbMonthToAdd);
            }

            //Update TECH_CalculatorIndicLastChange__c with the nbMonthToAdd cacul previous
            dateCalculator = dateLastBirthDayCalculator.addMonths(nbMonthToAdd);
            mapField.put('TECH_CalculatorIndicLastChange__c',dateCalculator);
            mapField.put('TECH_LastBirthDayContract__c',dateLastBirthDayCalculator);
        }
        return mapField;
    }
    
    /***
	* @description future method to update alert from sinistre id
    * @param lstIdSinistre
    * @param processType
	* @return void
	*/
    @future
    public static void updateCalculIndemnisationInProgress(List<String> lstIdSinistre,Boolean processType){
        List<Mouvements_financiers__c> listCalculIndemnisation = [SELECT Id, Statut__c FROM Mouvements_financiers__c WHERE Case__c IN :lstIdSinistre AND Statut__c = 'En cours d\'approbation'];
        if(listCalculIndemnisation.size()>0){
            List<Mouvements_financiers__c> listCalculIndemnisationUpdate = new List<Mouvements_financiers__c>();
            for(Mouvements_financiers__c cal : listCalculIndemnisation){
                if(processType){
                    cal.Statut__c = 'Demande en cours';
                }
                else{
                    cal.Statut__c = 'Rejected';
                }
                listCalculIndemnisationUpdate.add(cal);
            }
            update listCalculIndemnisationUpdate;
        }
    }
}