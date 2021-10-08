public class CancelParams {
    public CancelParams(){
        
    }
    @AuraEnabled @InvocableVariable public String pspReference;
    @AuraEnabled @InvocableVariable public String merchantAccount;
}