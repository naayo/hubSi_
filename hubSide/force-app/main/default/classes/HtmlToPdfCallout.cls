/***
* @author Nicolas Brancato (GFI)
* @date 26/02/2021
* @description Callout class for outbound call with HtmlToPdf services (SFAM Application to convert html to pdf)
*/

public class HtmlToPdfCallout {
    
    
    static final String EXTERNALSYSTEM_HTMLTOPDF = 'htmltopdf';
    static final String ENDPOINTNAME_CONVERT = 'convert';
    static final Integer STATUSCODE_200 = 200;
    static final Integer STATUSCODE_400 = 400;
    static final Integer STATUSCODE_401 = 401;
    static final Integer STATUSCODE_403 = 403;
    static final Integer STATUSCODE_500 = 500;
    
    /***
    * @description Trigger conversion from html to pdf
    * @param string htmlTemplate string encode in base64 that contains the html template
    * @param string fileName string contains the output filename
    * @return pdf
    */
    //@future(callout=true)
    public static Blob convertHtmlToPdf (string htmlTemplate, string fileName) {
        
        FlowConfiguration__mdt flowConfig = [SELECT Endpoint__c, Username__c
                                      FROM FlowConfiguration__mdt
                                      WHERE Label =: EXTERNALSYSTEM_HTMLTOPDF
                                      LIMIT 1];
        
        // fileName is the name of the output file
        System.debug('-- filename ' + filename);
        // htmlTemplate must be encoded in base 64
        System.debug('-- htmlTemplate ' + htmlTemplate);
        string body = '{"to":"pdf","filename":"' + fileName + '","data":"' + htmlTemplate + '"}';
        System.debug('-- body ' + body);
        
        blob pdfReturn;
		HTTPResponse res = new HTTPResponse();      
        try {
            // htmltopdf conversion request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(flowConfig.Endpoint__c + '/v1/' + ENDPOINTNAME_CONVERT);
            req.setMethod('POST');
            req.setTimeout(2 * 60 * 1000);
            req.setHeader('X-AUTH-TOKEN', flowConfig.Username__c);
            req.setBody(body);
            Http http = new Http();
            res = http.send(req);
            System.debug('-- answer convert ' + res.getBody());
            Integer AnswerStatus = res.getStatusCode();
            if(AnswerStatus == STATUSCODE_200){
                pdfReturn = res.getBodyAsBlob();
                System.debug('-- pdfReturn ' + pdfReturn);
                LogCallout.logSuccess(EXTERNALSYSTEM_HTMLTOPDF + ' ' + ENDPOINTNAME_CONVERT, null, null, null, '', res);
            }else if (AnswerStatus == STATUSCODE_400 || AnswerStatus == STATUSCODE_401 || AnswerStatus == STATUSCODE_403 || AnswerStatus == STATUSCODE_500){
            	LogCallout.logError(EXTERNALSYSTEM_HTMLTOPDF + ' ' + ENDPOINTNAME_CONVERT, null, null, null, '', res, null);
            }
            
        } catch (Exception e) {
            system.debug('exception conversion request' + String.valueOf(e));
            LogCallout.logError(EXTERNALSYSTEM_HTMLTOPDF + ' ' + ENDPOINTNAME_CONVERT, null, null, null, '', res, String.valueOf(e));
        }
        system.debug('-- pdfReturn ' + pdfReturn);
        return pdfReturn;
    }
}