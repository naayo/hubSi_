public class PaymentLinkParams {
    public PaymentLinkParams(){
        
    }
    @AuraEnabled @InvocableVariable public Double value;
    @AuraEnabled @InvocableVariable public String currency_x;
    @AuraEnabled @InvocableVariable public String reference;
    @AuraEnabled @InvocableVariable public String shopperReference;
    @AuraEnabled @InvocableVariable public String shopperEmail;
    @AuraEnabled @InvocableVariable public String merchantAccount; 
    @AuraEnabled @InvocableVariable public DateTime expirationDate;
}