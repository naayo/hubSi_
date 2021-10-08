/***
* @author Pierre-Mickael BARRAL (INETUM)
* @date 10/11/2020
* @description GED CLWC Controller
* DATE          DEV         DESCRIPTION
* 12/07/2021    PMB         Inital version
*/
public with sharing class LWC_PJManageStatus {
    @AuraEnabled(cacheable=true)
    public static List<WrapperManageStatus> getPJ(Id fileId){
        //Use Wrapper class to manage element to send to lwc component
        List<WrapperManageStatus> listWrapper = new List<WrapperManageStatus>();
        //Get Id sinistre
        Document__c doc = [SELECT Related_sinistre__c FROM Document__c WHERE Id=:fileId];

        //Get all Piece
        if(doc != null && doc.Related_sinistre__c != null){
            List<Piece_justificative_Sinistre__c> listPJ = [SELECT Id,Name,Commentaire__c,Document__r.Name,Validite_document__c FROM Piece_justificative_Sinistre__c WHERE Case__c =:doc.Related_sinistre__c];
       
            listWrapper = LWC_PJManageStatus.populateWrapper(listPJ);
        }
       
        return listWrapper;
    }

    public static List<WrapperManageStatus> populateWrapper(List<Piece_justificative_Sinistre__c> listPJ){
        List<WrapperManageStatus> listWrapper = new List<WrapperManageStatus>();

        for(Piece_justificative_Sinistre__c pj : listPJ){
            WrapperManageStatus wrm = new WrapperManageStatus();
            wrm.Id = pj.Id;
            wrm.namePJ = pj.Name;
            wrm.documentLink = pj.Document__r.Name;
            wrm.status = pj.Validite_document__c;
            wrm.commentaire = pj.Commentaire__c == null ? '' : pj.Commentaire__c;
            wrm.documentLinkId = pj.Document__c == null ? '' : pj.Document__c; 
            listWrapper.add(wrm);
        }
        return listWrapper;
    }

    @AuraEnabled
    public static String updatePJ(List<WrapperManageStatus> listPJUpdated, String IdDocument){
        String result = '';

        List<Piece_justificative_Sinistre__c> listPjToUpdated = new List<Piece_justificative_Sinistre__c>();

        for(WrapperManageStatus pjUpdated : listPJUpdated){
            Piece_justificative_Sinistre__c pj = new Piece_justificative_Sinistre__c();
            pj.Id = pjUpdated.Id;
            pj.Validite_document__c = pjUpdated.status;
            pj.Commentaire__c = pjUpdated.commentaire;
            pj.Document__c = null;
            pj.ValidationDate__c = null;
            pj.Valideur__c= null;
            if(pjUpdated.status == 'Valid' || pjUpdated.status == 'Received'){
                pj.Document__c = String.isEmpty(pjUpdated.documentLinkId) ? null : pjUpdated.documentLinkId;
                if(pjUpdated.status == 'Valid'){
                    pj.ValidationDate__c = System.today();
                    pj.Valideur__c= UserInfo.getUserId();
                }
            }
            listPjToUpdated.add(pj);
        }
        try{
            update listPjToUpdated;
            result = 'OK';
        }
        catch(Exception ex){
            result = 'error :' + ex.getMessage();
        }
        return result;
    }

    public class WrapperManageStatus {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String namePJ {get;set;}
        @AuraEnabled
        public String documentLink {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public String commentaire {get;set;}
        @AuraEnabled
        public String documentLinkId {get;set;}
    }
}