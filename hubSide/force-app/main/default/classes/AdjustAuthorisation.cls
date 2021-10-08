public class AdjustAuthorisation {

    @InvocableMethod
    public static List<String> makePostCallout(List<AdjustParams> inParameters){
      
		Double value = inParameters[0].value;
        String currency_x = inParameters[0].currency_x;
        String pspReference = inParameters[0].pspReference;
        String merchantAccount = inParameters[0].merchantAccount;
        
        //log category:
        string adyenlog = 'Adyen /adjustment';
        
        //ws infos
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Password__c
                                      FROM FlowConfiguration__mdt
                                      WHERE Label = 'AdyenPayment'
                                      LIMIT 1];
        string apiResource = 'adjustAuthorisation';
        
        //call info
        string body = '{"merchantAccount":"'+ merchantAccount +'","modificationAmount":{"value":'+ value +',"currency":"'+ currency_x +'"},"originalReference":"'+ pspReference +'"}';
        List<String> AdjustResponseList = new List<String>();   
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
                AdjustResponseObject AdjustResponse = (AdjustResponseObject)parser.readValueAs(AdjustResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                AdjustResponseList.add(AdjustResponse.pspReference);
                return AdjustResponseList;
          }
            if(response.getStatusCode() == 200){
                //parsing
                JSONParser parser = JSON.createParser(response.getBody());
                AdjustResponseObject AdjustResponse = (AdjustResponseObject)parser.readValueAs(AdjustResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                AdjustResponseList.add(AdjustResponse.pspReference);
                return AdjustResponseList;
              }
            else {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus()+ ' ' + response.getBody());
                LogCallout.logError(adyenlog, null, null, null, body, response, null);
                return AdjustResponseList;
            }    
        }
        catch (Exception e){
            system.debug('exception adjustAuthorisation' + String.valueOf(e));
            LogCallout.logError(adyenlog, null, null, null, body, null, String.valueOf(e));
            return AdjustResponseList;
        }
        
    }
    
    
    public class AdjustResponseObject {
        public String pspReference;
        public String response;
    }
}