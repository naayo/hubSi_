/***
* @author Nicolas Brancato (GFI)
* @date 10/02/2021
* @description Mock class for chronopost callout
*/
@isTest
global class recherchePointChronopostInterCalloutMock implements WebServiceMock {
    
    
    public Integer errorCode;
	public String errorMessage;
    
    global recherchePointChronopostInterCalloutMock(final Integer errorCode, final String errorMessage){
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }
    
    global void doInvoke(
        Object stub,
        Object request_x,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
            
            cxfRecherchebtSoapChronopostFr.recherchePointChronopostInterResponse response_x = new cxfRecherchebtSoapChronopostFr.recherchePointChronopostInterResponse();
            
            cxfRecherchebtSoapChronopostFr.pointCHRResult fakepointCHRResult = new cxfRecherchebtSoapChronopostFr.pointCHRResult();
            fakepointCHRResult.errorCode = errorCode;
            fakepointCHRResult.errorMessage = errorMessage; 
            response_x.return_x = fakepointCHRResult; 
            response.put('response_x', response_x); 
        }
}