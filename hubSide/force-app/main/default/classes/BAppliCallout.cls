/***
* @author Nicolas Brancato (GFI)
* @date 07/01/2021
* @description Callout class for outbound call with BAppli services
*/
public class BAppliCallout {
    
    static final String EXTERNALSYSTEM_BAPPLI = 'BAppli';
    static final String ENDPOINTNAME_PAYMENT = 'payment';
    static final String ENDPOINTNAME_STOCK = 'getFromStock';
    static final Integer STATUSCODE_200 = 200;
    static final Integer STATUSCODE_400 = 400;
    static final Integer STATUSCODE_404 = 404;
    static final Integer STATUSCODE_500 = 500;
    public static final String DAMAGEDEQUIPMENTSTATUS_DESTOCK = 'En destockage';
    public static final String DAMAGEDEQUIPMENTSTATUS_ORDER = 'En commmande';
    public static final String ASSOCIATEDCOSTOBJECT_EQUIPMENTEXCHANGE = 'Equipement Echangé';
    static final String BAPPLISTOCKNAME_SFAM = 'SFAM';
    
    /***
    * @description Trigger payment to BAppli when a Paiement_Versement__c record is created with status "Demande Versement"
    * @param id caseId Case id linked to the Paiement_Versement__c
    * @param id payId Paiement_Versement__c id
    * @param string BAppliContractId Value of the BAppli Contract Id stored in the field Id_contrat_B_appli__c in the linked asset
    * @param decimal amount Amount stored in the field Montant__c in the Paiement_Versement__c
    * @return null
    */
    @future(callout=true)
    public static void sendPayment (id caseId, id payId, string BAppliContractId, decimal amount) {
        
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Username__c
                                             FROM FlowConfiguration__mdt
                                             WHERE Label =: EXTERNALSYSTEM_BAPPLI
                                             LIMIT 1];
        
        string body = '{"type":"claim_bonus","contractNumber":"' + BAppliContractId + 
            '","amount":' + amount + 
            ',"userId":"' + UserInfo.getUserEmail() + 
            '"}';
        HTTPResponse res = new HTTPResponse();
        
        try {
            
            // payment request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(flowConfig.Endpoint__c + 'admin/api/claim/' + ENDPOINTNAME_PAYMENT);
            req.setMethod('POST');
            req.setTimeout(2 * 60 * 1000);
            String authorizationHeader = 'Bearer ' + flowConfig.Username__c;
            req.setHeader('Authorization', authorizationHeader);
            req.setBody(body);
            
            system.debug('body >> ' + body);
            
            Http http = new Http();
            res = http.send(req);
            
            System.debug('answer payment' + res.getBody());
                        
            switch on res.getStatusCode() {
                when 200 {
                    Paiement_Versement__c payToUpdate = new Paiement_Versement__c(id = payId,BAppliEventId__c = res.getBody());
                    update payToUpdate;
                    System.debug('payToUpdate' + payToUpdate);
                    LogCallout.logSuccess(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_PAYMENT, caseId, null, payId, body, res);
                }
                when else {
                    LogCallout.logError(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_PAYMENT, caseId, null, payId, body, res, null);
                }
            }
            
        } catch (Exception e) {
            system.debug('exception sendPayment' + String.valueOf(e));
            LogCallout.logError(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_PAYMENT, caseId, null, payId, body, res, String.valueOf(e));
        } 
    }
    
    /***
    * @description Trigger destock to BAppli
    * @param string stockName Constante value to reach the appropriate stock
    * @param string IdExterneBAppliEquipementEchange External id of the exchange equipment
    * @param string grade Grade of the chosen equipment
    * @param string operator Operator of the damaged equipment
    * @param id eqsId id of the Equipement_sinistre__c
    * @param id caseId id of linked case
    * @return null
    */
    @future(callout=true)
    public static void getFromStock (string stockName, string IdExterneBAppliEquipementEchange, string grade, string operator, id eqsId, id caseId) {
        
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Username__c
                                             FROM FlowConfiguration__mdt
                                             WHERE Label =: EXTERNALSYSTEM_BAPPLI
                                             LIMIT 1];
        
        string operatorSent = 'Tout opérateur';
        if(operator != null && operator != ''){
            operatorSent = operator;    
        } 
        
         Case caseObject = [SELECT Subject
            FROM Case
            WHERE id =: caseId
            LIMIT 1];
        
        // Pending us rework to change Grade__c api name to set BAppli value
        string body = '{"stockName":"' + stockName + 
            '","modelCode":"' + IdExterneBAppliEquipementEchange + 
            '","grade":"' + grade + 
            '","operator":"' + operatorSent + 
            '","comment":"' + caseObject.Subject + 
            '"}';
        
        system.debug('-- bodysent ' +body);
        HTTPResponse res = new HTTPResponse();
        try {
            // destock request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(flowConfig.Endpoint__c + 'admin/api/claim/' + ENDPOINTNAME_STOCK);
            req.setMethod('POST');
            req.setTimeout(2 * 60 * 1000);
            String authorizationHeader = 'Bearer ' + flowConfig.Username__c;
            req.setHeader('Authorization', authorizationHeader);
            req.setBody(body);
            Http http = new Http();
            MockToDev mock = new MockToDev(200, '', 
                        '{"imei":"355328086961253","stockFluctuationRef":"NUM_99999999","cost":"100"}', 
                        new Map<String,String>{'Keep-Alive' => 'yes'});
           
            //if dev2 environnnement get Mock
            if(URL.getSalesforceBaseUrl().toExternalForm().contains('dev2') && !System.test.isRunningTest()){              
                res = mock.respond();
            } else{
                res = http.send(req);
            }
            
            System.debug('-- answer destock ' + res.getBody());
            Integer AnswerStatus = res.getStatusCode();
            
            if(AnswerStatus == STATUSCODE_200){
                
                Map<String, object> answerAsMap = (Map<String, object>)JSON.deserializeUntyped(res.getBody());
                
                System.debug('-- answer imei ' + answerAsMap.get('imei'));
                System.debug('-- answer stockFluctuationRef ' + answerAsMap.get('stockFluctuationRef'));
                
                Equipement_sinistre__c eqsToUpdate = new Equipement_sinistre__c(id = eqsId, 
                                                                                Statut_equipement__c = DAMAGEDEQUIPMENTSTATUS_DESTOCK, 
                                                                                SerieNumberEC__c = string.valueOf(answerAsMap.get('imei')), 
                                                                                BAppliStockFluctuationRef__c = string.valueOf(answerAsMap.get('stockFluctuationRef')));
                
                if(string.valueOf(answerAsMap.get('cost')) != null || 
                   string.valueOf(answerAsMap.get('cost')) != ''){
                       
                       AssociatedCost__c assCostToInsert = new AssociatedCost__c(Name = ASSOCIATEDCOSTOBJECT_EQUIPMENTEXCHANGE, 
                                                                                 UnitCost__c = decimal.valueOf(string.valueOf(answerAsMap.get('cost'))), 
                                                                                 DamagedEquipment__c = eqsId);
                       insert assCostToInsert;
                       
                       decimal realCost = [SELECT RealCost__c 
                                           FROM Equipement_sinistre__c 
                                           WHERE id =: eqsId].RealCost__c;
                       
                       eqsToUpdate.RealCost__c = realCost <> null ? 
                           realCost + decimal.valueOf(string.valueOf(answerAsMap.get('cost'))) : decimal.valueOf(string.valueOf(answerAsMap.get('cost')));
                       eqsToUpdate.EquipmentAmount__c = eqsToUpdate.RealCost__c;                       
                       
                       if(eqsToUpdate.RealCost__c != null){
                           List<Mouvements_financiers__c> calIndemExchange = [SELECT id, Montant__c 
                                                                              FROM Mouvements_financiers__c 
                                                                              WHERE Case__c =: caseId 
                                                                              AND Type_mouvement__c =: CalculIndemnisationTriggerHandler.COSTTYPE_INTERNCOSTEXCHANGE];
                           
                           if(calIndemExchange.size() > 0){
                               /*if(eqsToUpdate.RealCost__c < calIndemExchange[0].Montant__c){*/
                               
                               calIndemExchange[0].Montant__c = eqsToUpdate.RealCost__c;
                               update calIndemExchange[0];
                               
                               system.debug('-- calIndemExchange[0] ' + calIndemExchange[0]);
                               //}
                           }
                       }
                   }
                
                system.debug('-- eqsToUpdate ' + eqsToUpdate);
                update eqsToUpdate;
                
                LogCallout.logSuccess(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_STOCK, caseId, null, null, body, res);
                
            } else if (AnswerStatus == STATUSCODE_404){
                
                Equipement_sinistre__c eqsToUpdate = new Equipement_sinistre__c(id = eqsId);
                
                if(stockName == BAPPLISTOCKNAME_SFAM){
                    eqsToUpdate.Statut_equipement__c = DAMAGEDEQUIPMENTSTATUS_ORDER;
                    eqsToUpdate.OrderDate__c = Datetime.now();                     
                }
                
                eqsToUpdate.SerieNumberEC__c = 'Déstockage Ko le ' + string.valueOf(Datetime.now());
                update eqsToUpdate; 
                LogCallout.logError(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_STOCK, caseId, null, null, body, res, null);
                
            } else if (AnswerStatus == STATUSCODE_500){
                LogCallout.logError(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_STOCK, caseId, null, null, body, res, null);
            }
        } catch (Exception e) {
            system.debug('-- exception getFromStock' + String.valueOf(e));
            LogCallout.logError(EXTERNALSYSTEM_BAPPLI + ' ' + ENDPOINTNAME_STOCK, caseId, null, null, body, res, String.valueOf(e));
        }  
    }

    public class MockToDev {
        protected Integer code {get;set;}
        protected String status {get;set;}
        protected String body {get;set;}
        protected Map<String, String> responseHeaders {get;set;}

        public MockToDev(Integer code, String status, String body, Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;
            this.body = body;
            this.responseHeaders = responseHeaders;
        }

        public HTTPResponse respond() {
            HttpResponse res = new HttpResponse();
            for (String key : this.responseHeaders.keySet()) {
                res.setHeader(key, this.responseHeaders.get(key));
            }
            res.setBody(this.body);
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            return res;
        }
    }
}