public class AdjustParams {
    public AdjustParams(){
        
    }
    @AuraEnabled @InvocableVariable public Double value;
    @AuraEnabled @InvocableVariable public String currency_x;
    @AuraEnabled @InvocableVariable public String pspReference;
    @AuraEnabled @InvocableVariable public String merchantAccount;
}