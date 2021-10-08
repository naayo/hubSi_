/***
* @author Nicolas Brancato (GFI)
* @date 19/01/2021
* @description Log Callout class for outbound call
*/
public class LogCallout {
    
    /***
    * @description Log the answer of a callout as a success in the CalloutErrorsManagement__c object
    * @param string calloutName Concatenation of the name of the external system and the name of the external services called
    * @param id caseId Case id linked to the record that triggers the callout
    * @param id documentId Document__c id if the record that triggers the callout is a Document__c
    * @param id paiementVersementId Paiement_Versement__c id if the record that triggers the callout is a Paiement_Versement__c
    * @param string bodySent Body of the performed callout
    * @param httpResponse response Response of the performed callout
    * @return null
    */
    public static void logSuccess(string calloutName, id caseId, id documentId, id paiementVersementId, string bodySent, httpResponse response){
                
        CalloutErrorsManagement__c newCallSucLog = new CalloutErrorsManagement__c();
        newCallSucLog.Name = calloutName;
        newCallSucLog.CaseRecord__c = caseId;
        newCallSucLog.DocumentLink__c = documentId <> null ? documentId : null;
        newCallSucLog.PaiementVersementLink__c = paiementVersementId <> null ? paiementVersementId : null;
        newCallSucLog.JSONSOAPBodySent__c = response == NULL ? bodySent : bodySent + '\r\n' + 'response : ' + response.getBody();
        newCallSucLog.JSONSOAPBodySent__c = newCallSucLog.JSONSOAPBodySent__c.length() > 32768 ? newCallSucLog.JSONSOAPBodySent__c.left(32767) : newCallSucLog.JSONSOAPBodySent__c;
        newCallSucLog.CalloutStatusCode__c = string.valueOf(response?.getStatusCode());
        insert newCallSucLog; 
    }
    
    /***
    * @description Log the answer of a callout as an error in the CalloutErrorsManagement__c object. The message error is stored is the field CalloutErrorMessage__c
    * @param string calloutName Concatenation of the name of the external system and the name of the external services called
    * @param id caseId Case id linked to the record that triggers the callout
    * @param id documentId Document__c id if the record that triggers the callout is a Document__c
    * @param id paiementVersementId Paiement_Versement__c id if the record that triggers the callout is a Paiement_Versement__c
    * @param string bodySent Body of the performed callout
    * @param httpResponse response Response of the performed callout
    * @param string catchError Exception thrown by the try catch if the code is not entirely performed
    * @return null
    */
    public static void logError(string calloutName, id caseId, id documentId, id paiementVersementId, String bodySent, httpResponse response, string catchError){
        
        String resp = '';
        
        if(response != null){
            resp = response.getBody();
            if(resp == NULL){
                resp = 'No Response';
            }
        }
        
        CalloutErrorsManagement__c newCallErrLog = new CalloutErrorsManagement__c();
        newCallErrLog.Name = calloutName;
        newCallErrLog.CaseRecord__c = caseId;
        newCallErrLog.DocumentLink__c = documentId <> null ? documentId : null;
        newCallErrLog.PaiementVersementLink__c = paiementVersementId <> null ? paiementVersementId : null;
        newCallErrLog.JSONSOAPBodySent__c = bodySent;
        newCallErrLog.JSONSOAPBodySent__c = newCallErrLog.JSONSOAPBodySent__c.length() > 32768 ? newCallErrLog.JSONSOAPBodySent__c.left(32767) : newCallErrLog.JSONSOAPBodySent__c;
        newCallErrLog.CalloutStatusCode__c = string.valueOf(response?.getStatusCode());
        if(catchError == null){
            newCallErrLog.CalloutErrorMessage__c = response.getStatus() + '\r\n' + 'response : ' + resp;
        }else{
            newCallErrLog.CalloutErrorMessage__c = 'response : ' + resp + catchError;     
        }
        insert newCallErrLog; 
    }
}