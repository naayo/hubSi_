/***
* @author Nicolas Brancato (GFI)
* @date 02/03/2021
* @description Callout class test for outbound call with HtmlToPdf services (SFAM Application to convert html to pdf)
*/
@isTest
public class HtmlToPdfCalloutTest {
    
    
    public static final String PROFILE_GS = 'SFAM GS';
    public static User GSUser;
    public static Blob result;
    
    /***
    * @description Static method to initialize all the data for the test methods
    */
    static{
       
        Id profileGSId = [Select Id From Profile  
                             Where name =: PROFILE_GS].Id;
        
        GSUser = TestFactory.createUser();
        GSUser.ProfileId = profileGSId;
        GSUser.Email = 'guillaume.gs@yopmail.co';
        insert GSUser;
    }
    
    
    /***
    * @description Test method for the convertHtmlToPdf method in HtmlToPdfCallout class. 
    * This test method mocks a fake response with a success in return.
    * The body returns a binary file which represents the pdf file
    */
    @isTest
    static void test_convertHtmlToPdf200() {
        
        HttpMockFactory mock = new HttpMockFactory(200,'','0x02457D5BECBC775C934BF72FFA2474A437430F1D420FBD7708480D1DD14D87[...]', 
                                                   new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        System.runAs(GSUser){
			string fileName = 'fichierTest.pdf';
            string htmlTemplate = 'PGEgaHJlZj0iZGF0YTp0ZXh0L2h0bWw7YmFzZTY0LFYyVnNZMjl0WlNCMGJ5QThZajVpWVhObE5qUXVaM1Z5ZFR3dllqNGgiPjwvYT4=';
            result = HtmlToPdfCallout.convertHtmlToPdf(htmlTemplate, fileName);
        }
        Test.stopTest();
        system.assertEquals(Blob.valueOf('0x02457D5BECBC775C934BF72FFA2474A437430F1D420FBD7708480D1DD14D87[...]'), result);
    }
    
    
    /***
    * @description Test method for the convertHtmlToPdf method in HtmlToPdfCallout class. 
    * This test method mocks a fake response with a failure in return.
    * The body returns an error 403 : "Username could not be found."
    */
    @isTest
    static void test_convertHtmlToPdf403() {
        
        HttpMockFactory mock = new HttpMockFactory(403,'','Username could not be found.', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        System.runAs(GSUser){
			string fileName = 'fichierTest.pdf';
            string htmlTemplate = 'PGEgaHJlZj0iZGF0YTp0ZXh0L2h0bWw7YmFzZTY0LFYyVnNZMjl0WlNCMGJ5QThZajVpWVhObE5qUXVaM1Z5ZFR3dllqNGgiPjwvYT4=';
            result = HtmlToPdfCallout.convertHtmlToPdf(htmlTemplate, fileName);
        }
        Test.stopTest();
        system.assertEquals(null, result);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c].CalloutErrorMessage__c.contains('Username could not be found.'));
        system.assertEquals(403, Integer.valueOf([Select id, CalloutStatusCode__c From CalloutErrorsManagement__c].CalloutStatusCode__c));
    }
}