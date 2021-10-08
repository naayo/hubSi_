@isTest
private class testAdjustAuthorisation {
	@isTest static  void testPostCallout201() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resAdjustResponse');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        AdjustParams params = new AdjustParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<AdjustParams> paramsList = new List<AdjustParams>();
        paramsList.add(params);
        
        
        List<String> psp201 = AdjustAuthorisation.makePostCallout(paramsList);
        
        //
        System.assertEquals('863621241703154G',psp201[0],'the adjustment hasnt been received by Adyen');
    }
    
    @isTest static  void testPostCallout200() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resAdjustResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        AdjustParams params = new AdjustParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<AdjustParams> paramsList = new List<AdjustParams>();
        paramsList.add(params);
        
        
        List<String> psp200 = AdjustAuthorisation.makePostCallout(paramsList);
        
        //
        System.assertEquals('863621241703154G',psp200[0],'the adjustment hasnt been received by Adyen');
    }
    
	@isTest static  void testPostCallout401() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resAdjustResponse_AccessUnauthorized');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        AdjustParams params = new AdjustParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.pspReference = '883620809830331K';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<AdjustParams> paramsList = new List<AdjustParams>();
        paramsList.add(params);
		
        List<String> psp401 = AdjustAuthorisation.makePostCallout(paramsList);
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