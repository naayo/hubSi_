@isTest
private class testCapturePayment {
	@isTest static  void testPostCallout201() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCaptureResponse');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CaptureParams params = new CaptureParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CaptureParams> paramsList = new List<CaptureParams>();
        paramsList.add(params);
        
        
        List<String> psp201 = CapturePayment.makePostCallout(paramsList);
        
        //
        System.assertEquals('883620812624219A',psp201[0],'the capture hasnt been received by Adyen');
    }
    
    @isTest static  void testPostCallout200() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCaptureResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CaptureParams params = new CaptureParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CaptureParams> paramsList = new List<CaptureParams>();
        paramsList.add(params);
        
        
        List<String> psp200 = CapturePayment.makePostCallout(paramsList);
        
        //
        System.assertEquals('883620812624219A',psp200[0],'the capture hasnt been received by Adyen');
    }
    
	@isTest static  void testPostCallout401() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resCaptureResponse_AccessUnauthorized');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        CaptureParams params = new CaptureParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<CaptureParams> paramsList = new List<CaptureParams>();
        paramsList.add(params);
		
        List<String> psp401 = CapturePayment.makePostCallout(paramsList);
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