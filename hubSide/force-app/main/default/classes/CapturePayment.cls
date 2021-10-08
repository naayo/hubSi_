public class CapturePayment {
   @InvocableMethod
    public static List<String> makePostCallout(List<CaptureParams> inParameters){
        Double value = inParameters[0].value;
        String currency_x = inParameters[0].currency_x;
        String reference = inParameters[0].reference;
        String pspReference = inParameters[0].pspReference;
        String merchantAccount = inParameters[0].merchantAccount;
        
        //log category:
        string adyenlog = 'Adyen /capture';
        
        //ws infos
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Password__c
                                      FROM FlowConfiguration__mdt
                                      WHERE Label = 'AdyenPayment'
                                      LIMIT 1];
        string apiResource = 'capture';
       
        //call info
        string body =  '{"merchantAccount":"'+ merchantAccount +'","modificationAmount":{"value":'+ value +',"currency":"'+ currency_x +'"},"originalReference":"'+ pspReference +'","reference": "'+ reference +'"}';
        
        List<String> CaptureResponseList = new List<String>();   
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
                CaptureResponseObject CaptureResponse = (CaptureResponseObject)parser.readValueAs(CaptureResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                CaptureResponseList.add(CaptureResponse.pspReference);
                return CaptureResponseList;
          }
            if(response.getStatusCode() == 200){
                //parsing
                JSONParser parser = JSON.createParser(response.getBody());
                CaptureResponseObject CaptureResponse = (CaptureResponseObject)parser.readValueAs(CaptureResponseObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                CaptureResponseList.add(CaptureResponse.pspReference);
                return CaptureResponseList;
              }
            else {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus()+ ' ' + response.getBody());
                LogCallout.logError(adyenlog, null, null, null, body, response, null);
                return CaptureResponseList;
            }    
        }
        catch (Exception e){
            system.debug('exception capturePayment' + String.valueOf(e));
            LogCallout.logError(adyenlog, null, null, null, body, null, String.valueOf(e));
            return CaptureResponseList;
        }
	}  
            
            
   	public class CaptureResponseObject {
        public String pspReference;
        public String message;
    }
}