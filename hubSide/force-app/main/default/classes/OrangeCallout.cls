/***
* @author Nicolas Brancato (GFI)
* @date 06/01/2021
* @description Callout class for outbound call with Orange Services
*/
public class OrangeCallout {
    
    
    static final String EXTERNALSYSTEM_ORANGE = 'Orange';
    static final String ENDPOINTNAME_AUTHORANGE = 'Oauth';
    static final String ENDPOINTNAME_SMSORANGE = 'Diffusion-requests';
    static final Integer STATUSCODE_200 = 200;
    static final Integer STATUSCODE_201 = 201;
    static final Integer STATUSCODE_400 = 400;
    static final Integer STATUSCODE_500 = 500;
    
    /***
	* @description Send SMS to contactPhone on case to acknowledge receipt of the document
	* @param string contactPhone on the case linked to the document__c
	* @return null
	*/
    @future(callout=true)
    public static void sendSMS (id caseId, id docId, string contactPhone, string SMSText) {
        
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c,Password__c,Username__c 
                                      FROM FlowConfiguration__mdt
                                      WHERE Label =: EXTERNALSYSTEM_ORANGE
                                      LIMIT 1];
        
        string bodyAuth = 'username='+flowConfig.Username__c+'&password='+flowConfig.Password__c;
		HTTPResponse resAuth = new HTTPResponse();
        
        try {
            // Authentification request to Orange
            HttpRequest req = new HttpRequest();
            req.setEndpoint(flowConfig.Endpoint__c + 'api/v1.2/oauth/token');
            req.setMethod('POST');
            req.setTimeout(2 * 60 * 1000);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/json');
            req.setBody(bodyAuth);  
            Http http = new Http();
            resAuth = http.send(req);
            System.debug('answer authentification' + resAuth.getBody());
            Integer AuthAnswerStatus = resAuth.getStatusCode();
            
            if(AuthAnswerStatus == STATUSCODE_200){
                                
                string bodySMS = '{"msisdns":["' + contactPhone + '"], "smsParam":{"encoding" : "GSM7", "body":"' + SMSText + '"}}';
                HTTPResponse resSMS = new HTTPResponse();
                
                try {
                    // Read answer and get Token
                    Map<String, String> valuesFromAnswer = (Map<String, String>) JSON.deserialize(resAuth.getBody(), Map<String, String>.class);            
                    String access_token = valuesFromAnswer.get('access_token');
                    System.debug('access_token' + access_token);
                    
                    // Send sms request
                    HttpRequest reqSMS = new HttpRequest();
                    reqSMS.setEndpoint(flowConfig.Endpoint__c + 'api/v1.2/groups/'+Label.GroupSFAMOrangeId+'/diffusion-requests');
                    reqSMS.setMethod('POST');
                    reqSMS.setHeader('Authorization', 'Bearer ' + access_token);
                    reqSMS.setHeader('Content-Type', 'application/json');
                    reqSMS.setBody(bodySMS);  
                    Http httpSMS = new Http();
                    resSMS = httpSMS.send(reqSMS);
                    System.debug('answer diffusion SMS' + resSMS.getBody());
                    LogCallout.logSuccess(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE, caseId, docId, null, bodyAuth, resAuth);
                    Integer SMSAnswerStatus = resSMS.getStatusCode();
                    
                    if(SMSAnswerStatus == STATUSCODE_200 || SMSAnswerStatus == STATUSCODE_201){
                		LogCallout.logSuccess(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_SMSORANGE, caseId, docId, null, bodySMS, resSMS);
                    }else if(SMSAnswerStatus != STATUSCODE_200 && SMSAnswerStatus != STATUSCODE_201){
                    	LogCallout.logError(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_SMSORANGE, caseId, docId, null, bodySMS, resSMS, null);    
                    }
                } catch (Exception e) {
                    LogCallout.logError(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_SMSORANGE, caseId, docId, null, bodySMS, resSMS, String.valueOf(e));
                }  
                
            }else if (AuthAnswerStatus != STATUSCODE_200){
                LogCallout.logError(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE, caseId, docId, null, bodyAuth, resAuth, null);
            }            
        } catch (Exception e) {
            LogCallout.logError(EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE, caseId, docId, null, bodyAuth, resAuth, String.valueOf(e));
        }         
    }
}