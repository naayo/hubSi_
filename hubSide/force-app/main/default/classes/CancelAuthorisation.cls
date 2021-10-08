public class CancelAuthorisation {
 
    @InvocableMethod
    public static List<String> makePostCallout(List<CancelParams> inParameters){
     
        String pspReference = inParameters[0].pspReference;
        String merchantAccount = inParameters[0].merchantAccount;
       
        //log category:
        string adyenlog = 'Adyen /cancelOrRefund';
         
        //ws infos
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Password__c
                                      FROM FlowConfiguration__mdt
                                      WHERE Label = 'AdyenPayment'
                                      LIMIT 1];
        string apiResource = 'cancelOrRefund';
        
        //call info
        string body = '{"merchantAccount":"'+ merchantAccount +'","originalReference":"'+ pspReference +'"}';
        List<String> CancelResponseList = new List<String>();   
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(flowConfig.Endpoint__c + apiResource);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('X-API-Key', flowConfig.Password__c);
         
        try {
            
            request.setBody(body);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() == 201) {
                //parsing
                JSONParser parser = JSON.createParser(response.getBody());
                CancelResponseObject CancelResponse = (CancelResponseObject)parser.readValueAs(CancelResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                CancelResponseList.add(CancelResponse.pspReference);
                return CancelResponseList;
          }
            if(response.getStatusCode() == 200){
                //parsing
                JSONParser parser = JSON.createParser(response.getBody());
                CancelResponseObject CancelResponse = (CancelResponseObject)parser.readValueAs(CancelResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                CancelResponseList.add(CancelResponse.pspReference);
                return CancelResponseList;
              }
            else {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus()+ ' ' + response.getBody());
                LogCallout.logError(adyenlog, null, null, null, body, response, null);
                return CancelResponseList;
            }    
        }
        catch (Exception e){
            system.debug('exception cancelAuthorisation' + String.valueOf(e));
            LogCallout.logError(adyenlog, null, null, null, body, null, String.valueOf(e));
            return CancelResponseList;
        
    	}
    }
    
    public class CancelResponseObject {
        public String pspReference;
        public String response;
    }
}