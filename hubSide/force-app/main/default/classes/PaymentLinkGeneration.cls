public class PaymentLinkGeneration {
    @InvocableMethod
    public static List<String> makePostCallout(List<PaymentLinkParams> inParameters){
        Double value = inParameters[0].value;
        String currency_x = inParameters[0].currency_x;
        String reference = inParameters[0].reference;
        String shopperReference = inParameters[0].shopperReference;
        String shopperEmail = inParameters[0].shopperEmail;
        String merchantAccount = inParameters[0].merchantAccount;
        DateTime expirationDate = inParameters[0].expirationDate;
        
        
        //log category:
        string adyenlog = 'Adyen /paymentLink';
        
        //ws infos
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Password__c
                                      FROM FlowConfiguration__mdt
                                      WHERE Label = 'AdyenCheckout'
                                      LIMIT 1];
        string apiResource = 'paymentLinks';
        
        DateTime maxExpirationDate = DateTime.now() + 69;
        String finalExpirationDate;
        If (expirationDate >= maxExpirationDate){
            finalExpirationDate = expirationDate.format('yyyy-MM-dd') + 'T' + expirationDate.format('hh:mm:ss') + 'Z';
        }
        Else{
          	finalExpirationDate = maxExpirationDate.format('yyyy-MM-dd') + 'T' + maxExpirationDate.format('hh:mm:ss') + 'Z';
        }
        
        //call info
        string body = '{"reference": "'+ reference +'","amount": {"value": '+ value +',"currency": "'+ currency_x +'"},"countryCode": "FR","expiresAt":"'+ finalExpirationDate +'","merchantAccount": "'+ merchantAccount +'","shopperReference": "'+ shopperReference +'","shopperEmail": "'+ shopperEmail +'","shopperLocale": "fr-FR","billingAddress": {"street": "rue de paris","postalCode": "75001","city": "Paris","houseNumberOrName": "10","country": "FR","stateOrProvince": "IDF"},"deliveryAddress": {"street": "rue de paris","postalCode": "75001","city": "Paris","houseNumberOrName": "10","country": "FR","stateOrProvince": "IDF"}}';
        List<String> PaymentLinkList = new List<String>();   
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
                JSONParser parser = JSON.createParser(response.getBody().replace('"currency":', '"currency_x":'));
                PaymentLinkObject PaymentLink = (PaymentLinkObject)parser.readValueAs(PaymentLinkObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                PaymentLinkList.add(PaymentLink.url);
                return PaymentLinkList;
            }
            if(response.getStatusCode() == 200){
                //parsing
                JSONParser parser = JSON.createParser(response.getBody().replace('"currency":', '"currency_x":'));
                PaymentLinkObject PaymentLink = (PaymentLinkObject)parser.readValueAs(PaymentLinkObject.class);
                LogCallout.logSuccess(adyenlog, null, null, null, body, response);
                //valo output
                PaymentLinkList.add(PaymentLink.url);
                return PaymentLinkList;
            }
            else {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus()+ ' ' + response.getBody());
                LogCallout.logError(adyenlog, null, null, null, body, response, null);
                return PaymentLinkList;
            }    
        }
        catch (Exception e){
            system.debug('exception sendPayment' + String.valueOf(e));
            LogCallout.logError(adyenlog, null, null, null, body, null, String.valueOf(e));
            return PaymentLinkList;
        }
        
    } 
      
    
    public class PayLinkAmount{
        public String currency_x;
        public Double value;
    }
    
    public class PayLinkAddress{
        public String city;
        public String country;
        public String houseNumberOrName;
        public String postalCode;
        public String stateOrProvince;
        public String street;
    }
    
    public class PaymentLinkObject {
        public PayLinkAmount amount;
        public PayLinkAddress billingAddress;
        public String countryCode;
        public PayLinkAddress deliveryAddress;
        public DateTime expiresAt;
        public String id;
        public String merchantAccount;
        public String reference;
        public String shopperEmail;
        public String shopperLocale;
        public String shopperReference;
        public String status;
        public String url;
	}	
}