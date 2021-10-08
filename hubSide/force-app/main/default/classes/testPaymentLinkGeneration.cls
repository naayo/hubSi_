@isTest
private class testPaymentLinkGeneration {
	@isTest static  void testPostCallout201() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resPaymentLink');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        PaymentLinkParams params = new PaymentLinkParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.shopperReference = 'SHOPPER_REF';
        params.shopperEmail = 'shopper@email.ext';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        params.expirationDate = DateTime.now() + 10;
        
        
        List<PaymentLinkParams> paramsList = new List<PaymentLinkParams>();
        paramsList.add(params);
        
        
        List<String> url201 = PaymentLinkGeneration.makePostCallout(paramsList);
        
        //
        System.assertEquals('https://test.adyen.link/PLE4428699423F5045',url201[0],'the url hasn\'t been generated');
    }
    
    @isTest static  void testPostCallout200() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resPaymentLink');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        PaymentLinkParams params = new PaymentLinkParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.shopperReference = 'SHOPPER_REF';
        params.shopperEmail = 'shopper@email.ext';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<PaymentLinkParams> paramsList = new List<PaymentLinkParams>();
        paramsList.add(params);
        
        
        List<String> url200 = PaymentLinkGeneration.makePostCallout(paramsList);
        
        //
        System.assertEquals('https://test.adyen.link/PLE4428699423F5045',url200[0],'the url hasn\'t been generated');
    }
    
	@isTest static  void testPostCallout401() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('resPaymentLink_AccessForbidden');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        PaymentLinkParams params = new PaymentLinkParams();
        params.value = 5000;
        params.currency_x = 'EUR';
        params.reference = 'TEST_REF';
        params.shopperReference = 'SHOPPER_REF';
        params.shopperEmail = 'shopper@email.ext';
        params.merchantAccount = 'MERCHANT_ACCOUNT';
        
        
        List<PaymentLinkParams> paramsList = new List<PaymentLinkParams>();
        paramsList.add(params);
		
        List<String> url401 = PaymentLinkGeneration.makePostCallout(paramsList);
        String url; 
        try{
            url = url401[0];
        }
        catch (Exception err){     
        }
        
        //
        System.assertEquals(null,url,'no URL expected');
    }
    
    
}