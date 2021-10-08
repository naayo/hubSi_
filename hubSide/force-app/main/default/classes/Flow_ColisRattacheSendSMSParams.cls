/***
* @author Sakthes T. (Inetum)
* @date 08/07/2021
* @description Class variable used as an input parameter for the InvocableMethod Flow_ColisRattacheSendSMS
*/
public class Flow_ColisRattacheSendSMSParams {
    public Flow_ColisRattacheSendSMSParams(){
        
    }
    @AuraEnabled @InvocableVariable public Id caseId;
    @AuraEnabled @InvocableVariable public Id ObjId;
    @AuraEnabled @InvocableVariable public String SMSText;
    @AuraEnabled @InvocableVariable public String contactPhone;
}