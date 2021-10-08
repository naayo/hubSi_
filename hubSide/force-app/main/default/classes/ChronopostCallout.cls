/***
* @author Nicolas Brancato (GFI)
* @date 04/02/2021
* @description Callout class for outbound call with Chronopost services
*/

public class ChronopostCallout {
    
    
    static final String EXTERNALSYSTEM_CHRONOPOST = 'Chronopost';
    static final String ENDPOINTNAME_RECHERCHEPOINT = 'recherchePointChronopostInter';
    
    /***
    * @description Method call from the apex controller PickUpSearchController. 
    * This method allows to call Chronopost External service pick up search.
    * @param string address Adress type by the user for searching
    * @param string zipCode ZipCode type by the user for searching
    * @param string city City type by the user for searching
    * @return cxfRecherchebtSoapChronopostFr.pointCHRResult res Result of the callout as a class object.
    */
    @AuraEnabled
    public static cxfRecherchebtSoapChronopostFr.pointCHRResult recherchePointChronopostInter(string address, string zipCode, string city, id caseId) {
    
        FlowConfiguration__mdt flowConfig = [SELECT Username__c, Password__c
                                             FROM FlowConfiguration__mdt
                                             WHERE Label =: EXTERNALSYSTEM_CHRONOPOST
                                             LIMIT 1];
        
        cxfRecherchebtSoapChronopostFr.PointRelaisServiceWSPort temp = new cxfRecherchebtSoapChronopostFr.PointRelaisServiceWSPort();
        cxfRecherchebtSoapChronopostFr.pointCHRResult res = temp.recherchePointChronopostInter(flowConfig.Username__c,
                                                                                               flowConfig.Password__c, 
                                                                                               address, zipCode, city, 
                                                                                               'FR', 'T', '86', 'T', '1', 
                                                                                               string.valueOf(Date.today().format()),
                                                                                               '5','10','1','FR','2.0');
        
        system.debug('-- errorCode   ' + res.errorCode);
        system.debug('-- errorMessage   ' + res.errorMessage);
        
        string bodySent = 'paramètres envoyés :' + '\r\n' + 
            flowConfig.Username__c + '\r\n' + 
            flowConfig.Password__c + '\r\n' + 
            address + '\r\n' + zipCode + '\r\n' + 
            city + '\r\n' + 'FR' + '\r\n' + 
            'T' + '\r\n' + '86' + '\r\n' + 
            'T' + '\r\n' + '1' + '\r\n' + 
            string.valueOf(Date.today().format()) + '\r\n' + 
            '5' + '\r\n' + '10' + '\r\n' + 
            '1' + '\r\n' + 'FR' + '\r\n' + '2.0';
        
        if(res.errorCode != 0){
            string error = res.errorCode + '\r\n' + res.errorMessage;
            LogCallout.logError(EXTERNALSYSTEM_CHRONOPOST + ' ' + ENDPOINTNAME_RECHERCHEPOINT, caseId, null, null, bodySent, null, error);   
        }else{
            LogCallout.logSuccess(EXTERNALSYSTEM_CHRONOPOST + ' ' + ENDPOINTNAME_RECHERCHEPOINT, caseId, null, null, bodySent, null);  
        }      
        return res;
    }
}