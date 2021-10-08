/***
* @author Sakthes T. (Inetum)
* @date 08/07/2021
* @description Used by the Flow ColisAfterUpdate Callout class for the class OrangeCallout outbound call with Orange Services
*/
public class Flow_ColisRattacheSendSMS {
 
    @InvocableMethod(label='Send SMS' description='Call the Apex class OrangeCallout.sendSMS to the specified inParameters' category='Colis__c')
    public static List<String> makePostCallout(List<Flow_ColisRattacheSendSMSParams> inParameters){
     
        Id caseId = inParameters[0].caseId;
        Id ObjId = inParameters[0].ObjId;
        String contactPhone = inParameters[0].contactPhone;
        String SMSText = inParameters[0].SMSText;
        OrangeCallout.sendSMS(caseId, ObjId, contactPhone, SMSText);
        Return new List<String>{'toto'};
    }

}