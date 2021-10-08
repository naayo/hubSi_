@isTest
private class Flow_ColisRattacheSendSMSTest {
    
    static final String EXTERNALSYSTEM_ORANGE = 'Orange';
    static final String ENDPOINTNAME_AUTHORANGE = 'Oauth';
    static final String ENDPOINTNAME_SMSORANGE = 'Diffusion-requests';
    static final String COLIS_STATUT = 'Rattaché';
    public static final String PROFILE_TC = 'SFAM Reparation';
    public static User RepUser;
    public static Case s;
    
    /***
    * @description Static method to initialize all the data for the test methods
    */
    static{
       
        Id profileTCId = [Select Id From Profile  
                             Where name =: PROFILE_TC
                            ].Id;
        
        RepUser = TestFactory.createUser();
        RepUser.ProfileId = profileTCId;
        insert RepUser;
    
        s = TestFactory.createSinistre();
        s.ContactPhone__c = '0600000000';
        s.Typologie_Sinistre__c = 'Broken';
        s.Email_Contact__c ='test@test.fr.invalid';
        insert s;
        
        // Create 1 colis
        List<Colis__c> colisList = TestFactory.createColis(1);
        insert colisList;
    }
    
    
    /***
    * @description Test method for the flow ColisAfterUpdate and the sendSMS method in OrangeCallout class. 
    * This test method mocks a fake response with a success for the authentication callout in return.
    */
    @isTest
    static void test_sendSMS200() {
        
        String fakeBody = '{"access_token":"123","token_type":"bearer","scope":"api","ttl":3600}';
        HttpMockFactory mock = new HttpMockFactory(200,'', fakeBody, new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Colis__c cl;
        Test.startTest();
        System.runAs(RepUser){
            Case sin =  [SELECT Id FROM Case limit 1];
            cl = [SELECT Id FROM Colis__c limit 1];
            cl.Sinistre__c = sin.Id;
            cl.Statut__c = COLIS_STATUT;
            update cl;
                      
        }
        Test.stopTest();
        system.assertEquals(null, [SELECT id, CalloutErrorMessage__c 
                                   FROM CalloutErrorsManagement__c
                                   WHERE CaseRecord__c =: cl.Sinistre__c 
                                   AND Name =: EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE].CalloutErrorMessage__c);
        system.assertEquals(200, Integer.valueOf([SELECT id, CalloutStatusCode__c 
                                                  FROM CalloutErrorsManagement__c 
                                                  WHERE CaseRecord__c =: cl.Sinistre__c 
                                                  AND Name =: EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE].CalloutStatusCode__c));
    }
    
    
    /***
    * @description Test method for the flow ColisAfterUpdate and the sendSMS method in OrangeCallout class. 
    * This test method mocks a fake response with a 401 error for the authentication callout in return.
    */
    @isTest
    static void test_sendSMS401() {
        
        HttpMockFactory mock = new HttpMockFactory(401,'Unauthorized', '', new Map<String,String>{'Keep-Alive' => 'yes'});
        Test.setMock(HttpCalloutMock.class, mock);
        Colis__c cl;
        Test.startTest();
        System.runAs(RepUser){
            Case sin =  [SELECT Id FROM Case limit 1];
            cl = [SELECT Id FROM Colis__c limit 1];
            cl.Sinistre__c = sin.Id;
            cl.Statut__c = COLIS_STATUT;
            update cl;
        }
        Test.stopTest();
        List <CalloutErrorsManagement__c> Call = [SELECT id, CalloutErrorMessage__c 
        FROM CalloutErrorsManagement__c 
        WHERE CaseRecord__c =: cl.Sinistre__c
        AND Name =: EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE];
        System.debug(Call);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE CaseRecord__c =: cl.Sinistre__c
                       AND Name =: EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE].CalloutErrorMessage__c.contains('Unauthorized'));
        system.assertEquals(401, Integer.valueOf([SELECT id, CalloutStatusCode__c 
            FROM CalloutErrorsManagement__c 
            WHERE CaseRecord__c =: cl.Sinistre__c 
            AND Name =: EXTERNALSYSTEM_ORANGE + ' ' + ENDPOINTNAME_AUTHORANGE].CalloutStatusCode__c));
    }
}