@isTest
public class testCancelAuthorisation {
	@isTest static  void testPostCallout201() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCancelResponse');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CancelParams params = new CancelParams();
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CancelParams> paramsList = new List<CancelParams>();
        paramsList.add(params);
        
        
        List<String> psp201 = CancelAuthorisation.makePostCallout(paramsList);
        
        //
        System.assertEquals('863621241703154G',psp201[0],'the cancellation hasnt been received by Adyen');
    }
    
    @isTest static  void testPostCallout200() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCancelResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CancelParams params = new CancelParams();
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CancelParams> paramsList = new List<CancelParams>();
        paramsList.add(params);
        
        
        List<String> psp200 = CancelAuthorisation.makePostCallout(paramsList);
        
        //
        System.assertEquals('863621241703154G',psp200[0],'the cancellation hasnt been received by Adyen');
    }
    
	@isTest static  void testPostCallout401() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCancelResponse_AccessUnauthorized');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CancelParams params = new CancelParams();
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CancelParams> paramsList = new List<CancelParams>();
        paramsList.add(params);
		
        List<String> psp401 = CancelAuthorisation.makePostCallout(paramsList);
        String psp; 
        try{
            psp = psp401[0];
        }
        catch (Exception err){     
        }
        
        //
        System.assertEquals(null,psp,'no psp expected');
    }
    
    
}