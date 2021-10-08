/***
* @author Ariane Tanguy (GFI)
* @date 23/09/2020
* @description Handler class for PieceJustificative
*/

public class PieceJustificativeTriggerHandler {
    
    /***
	* @description Check whether there should be a case update on create
	* @param newPJList - new pj
	* @param relatedCaseMap - related case map
	* @return NA
	*/
    public static void updateCaseOnCreate(List<Piece_justificative_Sinistre__c> newPJList, Map<id, Case> relatedCaseMap){
     
        // Loop over the newly created PJs to clear TECH_MissingDocs__c
        for(Piece_justificative_Sinistre__c pj : newPJList){
            if(relatedCaseMap.get(pj.Case__c).TECH_MissingDocs__c == null) {
            	relatedCaseMap.get(pj.Case__c).TECH_MissingDocs__c = ''; 
            }
        }
        
        for(Piece_justificative_Sinistre__c pj : newPJList){            
            if(relatedCaseMap.get(pj.Case__c).Status == 'En cours d\'examen'){
                relatedCaseMap.get(pj.Case__c).Status = 'Incomplet';
            }
            relatedCaseMap.get(pj.Case__c).Attente_documents__c = 'Expected';
            
            Types_piece_justificative__c tpj = [SELECT LongTitle__c FROM Types_piece_justificative__c WHERE Name = :pj.Name];
            relatedCaseMap.get(pj.Case__c).TECH_MissingDocs__c += tpj.LongTitle__c + '\n';
        }
        
        update relatedCaseMap.values();
    }
    
    /***
	* @description Check whether there should be a case update on create
	* @param newPJList - new pj
	* @param relatedCaseMap - related case map
	* @return NA
	*/
    public static void updatePJOnCreate(List<Piece_justificative_Sinistre__c> newPJList, 
                                        Map<id, List<id>> documentIdContentIdMap){
        
        // Loop over the newly update PJs
        for(Piece_justificative_Sinistre__c pj : newPJList){
            
            if(pj.Document__c != NULL &&
               documentIdContentIdMap.keySet().contains(pj.Document__c)){
                   pj.ContentDocumentId__c = documentIdContentIdMap.get(pj.Document__c)[0];
                   pj.ContentVersionId__c = documentIdContentIdMap.get(pj.Document__c)[1];
               } else {
                   pj.ContentDocumentId__c = NULL;
                   pj.ContentVersionId__c = NULL;
               }
        }
    }
    
    /***
	* @description Check whether there should be a case update
	* @param newPJList - new pj
	* @param relatedCaseMap - related case map
	* @return NA
	*/
    public static void updateCaseOnUpdate(List<Piece_justificative_Sinistre__c> newPJList, 
                                          Map<id, Piece_justificative_Sinistre__c> oldPJMap, 
                                          Map<id, Case> relatedCaseMap, 
                                          Map<id, List<Piece_justificative_Sinistre__c>> otherRelatedPJMap){
        
        // Loop over the newly update PJs
        List<Case> caseToUpdate = new List<Case>();
        for(Piece_justificative_Sinistre__c pj : newPJList){
            
            // Change the case status
            if((pj.Validite_document__c != oldPJMap.get(pj.id).Validite_document__c ||
               pj.Document__c != oldPJMap.get(pj.id).Document__c) &&
               relatedCaseMap.get(pj.Case__c).Status == 'Attribué'){
                   relatedCaseMap.get(pj.Case__c).Status = 'Incomplet';
            }
            
            // Update the Attente document checkbox
            if(pj.Validite_document__c != oldPJMap.get(pj.id).Validite_document__c && 
               (pj.Validite_document__c == 'Invalid' ||
                pj.Validite_document__c == 'Expected')){
                    relatedCaseMap.get(pj.Case__c).Attente_documents__c = 'Expected';
                }
            
            // Update the case TECH_MissingDocs__c 
            if(pj.Validite_document__c != oldPJMap.get(pj.id).Validite_document__c){
                
                relatedCaseMap.get(pj.Case__c).TECH_MissingDocs__c = '';
                
                // Otherwise, loop over expected PJ
                if(otherRelatedPJMap.keySet().contains(pj.Case__c)){
                    for(Piece_justificative_Sinistre__c p : otherRelatedPJMap.get(pj.Case__c)){
                        if(p.Validite_document__c == 'Expected'){
                            Types_piece_justificative__c tpj = [SELECT LongTitle__c FROM Types_piece_justificative__c WHERE Name = :p.Name];
                            relatedCaseMap.get(pj.Case__c).TECH_MissingDocs__c += tpj.LongTitle__c + '\n';
                        }
                    }
                }
            }  
        }
                                              
        update relatedCaseMap.values();
    }
    
    /***
	* @description Create new PJ when the status becomes not valid
	* @param newPJList - new pj
	* @param oldPJMap - old pj
	* @return NA
	*/
    public static void createNewPJ(List<Piece_justificative_Sinistre__c> newPJList, Map<id, Piece_justificative_Sinistre__c> oldPJMap){
        
        // Loop over the newly updated PJ
        List<Piece_justificative_Sinistre__c> pjToInsert = new List<Piece_justificative_Sinistre__c>();
        for(Piece_justificative_Sinistre__c pj : newPJList){
            
            // If the PJ status is now Not Valid
            if(pj.Validite_document__c != oldPJMap.get(pj.id).Validite_document__c &&
               pj.Validite_document__c == 'invalid'){
                   
                   // Create another PJ
                   Piece_justificative_Sinistre__c newPJ = new Piece_justificative_Sinistre__c();
                   newPJ.Validite_document__c = 'expected';
                   newPJ.Case__c = pj.Case__c;
                   newPJ.Name = pj.Name;
                   newPJ.Valideur__c = UserInfo.getUserId();
                   pjToInsert.add(newPJ);
               }
        }
        if(pjToInsert.size() > 0){
            insert pjToInsert;
        }
    }
    
    /***
	* @description Update the Case
	* @param validityCaseIdMap - map of case id / validity
	* @param caseToUpdateMap - map of case id / case
	* @return NA
	*/
    public static void updateSinistreOnUpdate(Map<id, Case> relatedCaseIdMap, List<Piece_justificative_Sinistre__c> relatedPJList){
        
        // Map the pj with their related case and check that all are received
        Map<String, List<Boolean>> caseIdPJMap = new Map<String, List<Boolean>>();
        //Init Tab
        for(Case c : relatedCaseIdMap.values()){
            List<Boolean> validityList = new List<Boolean>{FALSE, FALSE};
            caseIdPJMap.put(c.Id, validityList);
        }

        for(Piece_justificative_Sinistre__c p : relatedPJList){
            Boolean allReceived = p.Validite_document__c != 'Expected';
            Boolean allValid = p.Validite_document__c == 'Valid' || (p.NoTradable__c == true && p.Validite_document__c == 'NotNeeded');
            caseIdPJMap.put(p.Case__c, new List<Boolean>{allReceived, allValid});
        }
        
        // Get only the cases to be updated
        Map<Id, String> validityCaseIdMap = new Map<Id, String>();
        for(id caseId : caseIdPJMap.keySet()){
            
            if(caseIdPJMap.get(caseId)[0]){
                relatedCaseIdMap.get(caseId).Attente_documents__c = 'Received';
            }
            if(caseIdPJMap.get(caseId)[1]){
                relatedCaseIdMap.get(caseId).Attente_documents__c = 'Valid';
                if(relatedCaseIdMap.get(caseId).Attente_client_final__c == NULL && 
                   (relatedCaseIdMap.get(caseId).Status == 'Incomplet' ||
                    relatedCaseIdMap.get(caseId).Status == 'Attribué')){
                        relatedCaseIdMap.get(caseId).Status = 'En cours d\'examen';
                    }
            }
        }
        
        update relatedCaseIdMap.values();
    }

    /***
	* @description add alert if not needed piece
	* @param listPieces - List piece justificative 
	* @return NA
	*/
    public static void manageAlertNotNeeded(List<Piece_justificative_Sinistre__c> listPieces){

        List<Id> idsCaseAlertCreated = new List<Id>();
        List<Alert__c> lstAlertToCreated = new List<Alert__c>();

        for(Piece_justificative_Sinistre__c pjs : listPieces){
            if(pjs.Validite_document__c == 'NotNeeded' && pjs.NoTradable__c){
                if(!idsCaseAlertCreated.contains(pjs.Case__c)){
                    idsCaseAlertCreated.add(pjs.Case__c);
                }
            }
        }

        if(idsCaseAlertCreated.size()>0){
            List<Alert__c> alertExist = [SELECT Id,Case__c FROM Alert__c WHERE BusinessRulesNumber__c = 'RGSIN24' AND Case__c IN:idsCaseAlertCreated];
            List<Approval.ProcessSubmitRequest> lstApprovalProcessRequest = new List<Approval.ProcessSubmitRequest>();
            Map<Id,Alert__c> mapSinAlert = new Map<Id,Alert__c>();
            User currentUser = [SELECT Id,Montant_approbation__c FROM User WHERE Id=:UserInfo.getUserId()];
            for(Alert__c alert : alertExist){
                mapSinAlert.put(alert.Case__c,alert);
            }
            for(Id CaseId : idsCaseAlertCreated){
                if(!mapSinAlert.containsKey(CaseId)){
                    if(currentUser.Montant_approbation__c == 0){
                        lstAlertToCreated.add(new Alert__c(BusinessRulesNumber__c='RGSIN24',
                                                    Case__c = CaseId,
                                                    SalesDiscountMotif__c  = 'PrimaryDocNotClaim'));
                        
                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                        req.setObjectId(CaseId);
                        req.setProcessDefinitionNameOrId('AP01_CS_AlertToValidated');
                        req.setSkipEntryCriteria(true);
                        lstApprovalProcessRequest.add(req);
                    }
                    else{
                        lstAlertToCreated.add(new Alert__c(BusinessRulesNumber__c='RGSIN24',
                                                    Case__c = CaseId,
                                                    Status__c = 'Approved',
                                                    Type_Alert__c = 'Warning',
                                                    Validation_Reason__c = 'Validation par défaut car warning',
                                                    SalesDiscountMotif__c  = 'PrimaryDocNotClaim'));
                    }
                }
            }
            if(lstAlertToCreated.size()>0){
                insert lstAlertToCreated;
                List<Case> casetoUpdated = [SELECT Id,AlertText__c FROM Case WHERE Id IN :idsCaseAlertCreated];
                List<Case> caseUpdated = new List<Case>();
                for(Case cs : casetoUpdated){
                    if(String.isBlank(cs.AlertText__c)){
                        cs.AlertText__c = 'Pièce majeure plus réclamée';
                    }
                    else{
                        cs.AlertText__c = cs.AlertText__c + '\n' + 'Pièce majeure plus réclamée';
                    }
                    caseUpdated.add(cs);
                }
                if(caseUpdated.size()>0){
                    update caseUpdated;
                }
                if(currentUser.Montant_approbation__c == 0 && lstApprovalProcessRequest.size()>0){
                    List<Approval.ProcessResult> results = Approval.process(lstApprovalProcessRequest);
                }
            }
        }
    }
}