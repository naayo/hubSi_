/***
* @author Pierre-Mickael BARRAL (INETUM)
* @date 10/11/2020
* @description GED CLWC Controller
* DATE          DEV         DESCRIPTION
* 10/11/2020    PMB         Inital version
*/
public without sharing class LWC_MassApprovalController {

    @AuraEnabled(cacheable=true)
    public static List<WrapperApproval> getApprovals(){
        //Use Wrapper class to manage element to send to lwc component
        List<WrapperApproval> listWrapper = new List<WrapperApproval>();
        //Get approval process Alert
        List<ProcessInstance> listProcessInstance = [
        SELECT  Id,
                CreatedBy.Name,
                Status,
                TargetObject.Name,
                TargetObject.Id,
                ProcessDefinition.DeveloperName
        FROM ProcessInstance 
        WHERE ProcessDefinition.DeveloperName IN ('AP01_CS_AlertToValidated','Approbation_TEST_V_4') AND Status = 'Pending' ];

        if(listProcessInstance.size()>0){
            List<Id> idsSinistre = new List<Id>();
            List<Id> idsCalculIndem = new List<Id>();
            for(ProcessInstance pi : listProcessInstance){
                Id currentId = pi.TargetObject.Id;
                if(currentId.getSObjectType().getDescribe().getName() == 'Case'){
                    idsSinistre.add(currentId);
                }
                else if(currentId.getSObjectType().getDescribe().getName() == 'Mouvements_financiers__c'){
                    idsCalculIndem.add(currentId);
                }
            }
            //Get infos calculIndem
            Map<Id,Mouvements_financiers__c> mapCalculIndem;
            Map<Id,Id> mapCalculIndemIdSinistre = new Map<Id,Id>();
            if(idsCalculIndem.size()>0){
                mapCalculIndem = new Map<Id,Mouvements_financiers__c>([SELECT Id,Case__c,Type_mouvement__c,Montant__c,Libelle__c FROM Mouvements_financiers__c WHERE Id IN :idsCalculIndem]);
                for(Mouvements_financiers__c mv :mapCalculIndem.values()){
                    idsSinistre.add(mv.Case__c);
                    mapCalculIndemIdSinistre.put(mv.Id,mv.Case__c);
                }
            }

            listWrapper = LWC_MassApprovalController.populateWrapper(listProcessInstance,idsSinistre,mapCalculIndemIdSinistre,mapCalculIndem);
        }
        return listWrapper;
    }

    @AuraEnabled
    public static String approvedOrRejected(Map<String,String> mapIdRecordApprovalProcess, Boolean processType, String comment, String validationReason, String userId){
        // processType equals true if is approve process and false if reject process
        String result = 'Not processing';

        // need to get InstanceWorkItem to init approval process request
        List<ProcessInstanceWorkItem> pIWItem = [SELECT Id,ProcessInstanceId FROM ProcessInstanceWOrkItem WHERE ProcessInstanceId = :mapIdRecordApprovalProcess.keySet()];

        if(pIWItem.size()>0){
            //Manage approval process request
            List<Approval.ProcessWorkitemRequest> listApproval = new List<Approval.ProcessWorkitemRequest>();
            for(ProcessInstanceWorkItem record : pIWItem){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(comment);
                
                req.setWorkitemId(record.Id);

                if(processType){
                    req.setAction('Approve');
                }
                else{
                    req.setAction('Reject');
                }
                listApproval.add(req);
            }
            Approval.ProcessResult[] listResultApproval =  Approval.process(listApproval);
            
            result = LWC_MassApprovalController.managedReturnApprovalRequest(listResultApproval,result,processType, validationReason, userId);
        }
        return result;
    }

    private static List<WrapperApproval> populateWrapper(List<ProcessInstance> listProcessInstance,List<Id> idsSinistre,Map<Id,Id> mapCalculIndemIdSinistre,Map<Id,Mouvements_financiers__c> mapCalculIndem){
        List<WrapperApproval> listWrapper = new List<WrapperApproval>();

        Map<Id,Case> mapSinitre = new Map<Id,Case>([SELECT Id,AlertText__c,Numero_sinistre__c,Asset.Formule__r.Name,Asset.Account.Name,Montant_sinistre__c FROM Case WHERE Id IN :idsSinistre]);
        User us = [SELECT Id,Montant_approbation__c FROM User WHERE Id=:System.UserInfo.getUserId()];
        for(ProcessInstance pi : listProcessInstance){
            
            
            Id currentObjId = pi.TargetObject.Id;
            Id idSinistre = pi.TargetObject.Id;
            Boolean isMouv = false;
            if(currentObjId.getSObjectType().getDescribe().getName() == 'Mouvements_financiers__c'){
                idSinistre = mapCalculIndemIdSinistre.get(currentObjId);
                isMouv = true;
            }
            WrapperApproval wa = new WrapperApproval();
            wa.idApproval = pi.Id;
            wa.caller = pi.CreatedBy.Name;
            wa.sinistreName = mapSinitre.get(idSinistre).Numero_sinistre__c;
            wa.sinistreId = idSinistre;
            wa.alertsOrInfos = mapSinitre.get(idSinistre).AlertText__c;
            String amontSinitre = String.valueOf(mapSinitre.get(idSinistre).Montant_sinistre__c);
            if(!String.isBlank(amontSinitre)){
                wa.montantSin = amontSinitre + ' €';
            }
            else{
                wa.montantSin = '0.00 €';
            }
            wa.nomClient = mapSinitre.get(idSinistre).Asset.Account.Name;
            wa.formule = mapSinitre.get(idSinistre).Asset.Formule__r.Name ;
            wa.isAlert = currentObjId.getSobjectType().getDescribe().getName() == 'Case';
            if(isMouv && mapCalculIndem != null){
                // Manage Description Mass Approval
                String strInfos = '';
                if(String.isNotBlank(mapCalculIndem.get(currentObjId).Libelle__c)){
                    strInfos = mapCalculIndem.get(currentObjId).Type_mouvement__c+'('+mapCalculIndem.get(currentObjId).Libelle__c+')'+' : '+mapCalculIndem.get(currentObjId).Montant__c + ' €';
                }
                else{
                    strInfos = mapCalculIndem.get(currentObjId).Type_mouvement__c+' : '+mapCalculIndem.get(currentObjId).Montant__c+ ' €';
                }
                wa.alertsOrInfos = strInfos;
                wa.approvalProcessName = pi.ProcessDefinition.DeveloperName;
            }
            else{
                wa.alertsOrInfos = mapSinitre.get(currentObjId).AlertText__c;
                wa.approvalProcessName = pi.ProcessDefinition.DeveloperName;
            }
            if(us !=null && us.Montant_approbation__c >= mapSinitre.get(idSinistre).Montant_sinistre__c){
                listWrapper.add(wa);
            }
        }

        return listWrapper;
    }

    private static String managedReturnApprovalRequest(Approval.ProcessResult[] listResultApproval, String currentResult, Boolean processType, String validationReason, String userId){
        String result = currentResult;
        // Manage result approval process
        List<String> listSinistreIdGood = new List<String>();
        List<String> listCalculIndemGood = new List<String>();
        for(Approval.ProcessResult resultApproval : listResultApproval){
            // Success
            if(!resultApproval.isSuccess()){
                String errorMessage = '';
                List< Database.Error> lstError = new List<Database.Error>(resultApproval.getErrors());
                for(Database.Error error : lstError){
                    errorMessage += error.getMessage();
                }
                result = 'ERROR Approval : '+ errorMessage;
            }
            else {
                if(resultApproval.getInstanceStatus() == 'Approved'){
                    Id currentIdApproved = resultApproval.getEntityId();
                    if(currentIdApproved.getSobjectType().getDescribe().getName() == 'Case'){
                        listSinistreIdGood.add(currentIdApproved);
                    }
                    else if(currentIdApproved.getSobjectType().getDescribe().getName() == 'Mouvements_financiers__c'){
                        listCalculIndemGood.add(currentIdApproved);
                    }
                }
            }
        }
        if(!result.contains('ERROR')){
            result = 'Success';

            List<Id> sinistreGood = new List<Id>();
            List<Case> caseToRunPaiement = new List<Case>();
            sinistreGood.addAll(listSinistreIdGood);
            System.debug('TUTU' + sinistreGood);
            
            if(listCalculIndemGood.size()>0){
                List<Mouvements_financiers__c> lstMouvFi = [SELECT Case__c FROM Mouvements_financiers__c WHERE Id IN :listCalculIndemGood];
                for(Mouvements_financiers__c mv : lstMouvFi){
                    sinistreGood.add(mv.Case__c);
                }
            }
            if(listSinistreIdGood.size()>0){
                UtilityClassHelper.updateAlertNoFuture(listSinistreIdGood,processType, validationReason, userId);
            }
            
            List<Case> listCase = [SELECT Id,TECH_NumberIndemToProcess__c,TECH_NumberAlertWaiting__c,Numero_sinistre__c,TECH_CheckChoixClientValidate__c FROM Case WHERE Id IN:sinistreGood];
            for(Case c : listCase){
                if(c.TECH_NumberIndemToProcess__c == 0 && c.TECH_NumberAlertWaiting__c == 0){
                    caseToRunPaiement.add(c);
                }
            }
            System.debug('POPO' + sinistreGood);
            if(caseToRunPaiement.size()>0){
                Flow.Interview flow = new Flow.Interview.CASE_Manage_PaiementVersement(new map<String,Object> 
                                            {'VAR_ListCase' => caseToRunPaiement});     
                flow.start();  
            }          
        }
        return result;
    }

    public class WrapperApproval {
        @AuraEnabled
        public String idApproval {get;set;}
        @AuraEnabled
        public String approvalProcessName {get;set;}
        @AuraEnabled
        public String caller {get;set;}
        @AuraEnabled
        public String sinistreName {get;set;}
        @AuraEnabled
        public String sinistreId {get;set;}
        @AuraEnabled
        public String alertsOrInfos {get;set;}
        @AuraEnabled
        public String formule {get;set;}
        @AuraEnabled
        public String nomClient {get;set;}
        @AuraEnabled
        public Boolean isAlert {get; set;}
        @AuraEnabled
        public String montantSin {get; set;}
    }
}