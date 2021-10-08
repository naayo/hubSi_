/***
* @author Nicolas Brancato (GFI)
* @date 09/02/2021
* @description Controller class test for PickUpSearchController and ChronopostCallout apex class
*/
@isTest
public class PickUpSearchControllerTest {
    
    
    public static final String PROFILE_GS = 'SFAM GS';
    public static User GSUser;
    public static Account a;
    public static Asset c;
    public static Case s;
    public static Equipement_sinistre__c eqs;
    public static string res;
    public static cxfRecherchebtSoapChronopostFr.pointCHRResult calloutRes;
    
    /***
    * @description Static method to initialize all the datas for the test methods
    */
    static{
        
        Id profileGSId = [Select Id From Profile  
                          Where name =: PROFILE_GS
                         ].Id;
        
        GSUser = TestFactory.createUser();
        GSUser.ProfileId = profileGSId;
        GSUser.Email = 'guillaume.gs@yopmail.com';
        insert GSUser;
        
        // Create a new account as system admin because the account is sent by Bappli
        a = TestFactory.createClient();
        insert a;
        
        // Create a new contract as system admin because the contract is sent by Bappli
        c = new Asset();
        c.Name = '0220010102';
        c.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Contrat_assurance');
        c.AccountId = a.id;
        c.Date_debut_contrat__c = System.today();
        c.Id_externe__c = 'INS0220010102';
        c.Id_contrat_B_appli__c = '5343473';
        insert c;
        
        // Create a sinistre
        s = TestFactory.createSinistre(a.id, c.id);
        insert s;
        
        // Create a damaged equipement
        eqs = new Equipement_sinistre__c(Sinistre__c = s.id);
        insert eqs;          
    }
    
    
    /***
    * @description Test method for the searchPickUp method in the PickUpSearchController apex class. 
    * This test method mocks a fake response with a success in return, that is to say with an errorCode equal to 0.
    */
    @isTest
    public static void searchPickUpSuccessTest(){
        
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new recherchePointChronopostInterCalloutMock(0, null));
        
        Test.startTest();
        System.runAs(GSUser){
            calloutRes = PickUpSearchController.searchPickUp('test address','test zipCode','test city', s.id);
        }
        Test.stopTest();
        system.assertEquals(0, calloutRes.errorCode);
        system.assertEquals(null, [SELECT id, CalloutErrorMessage__c 
                                   FROM CalloutErrorsManagement__c 
                                   WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c);        
    }
    
    
    /***
    * @description Test method for the searchPickUp method in the PickUpSearchController apex class. 
    * This test method mocks a fake response with an error in return, that is to say with an errorCode equal to 601.
    */
    @isTest
    public static void searchPickUpErrorTest(){
        
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new recherchePointChronopostInterCalloutMock(601, 'Pas de points CHR trouvés'));
        
        Test.startTest();
        System.runAs(GSUser){
            calloutRes = PickUpSearchController.searchPickUp('test address','test zipCode','test city', s.id);
        }
        Test.stopTest();
        system.assertEquals(601, calloutRes.errorCode);
        system.assert([SELECT id, CalloutErrorMessage__c 
                       FROM CalloutErrorsManagement__c 
                       WHERE CaseRecord__c =: s.id].CalloutErrorMessage__c.contains('Pas de points CHR trouvés'));
    }
    
    
    /***
    * @description Test method for the savePickUpAddress method in the PickUpSearchController apex class. 
    * This test method tries a sucessful update of the Equipement_sinistre__c.
    */
    @isTest
    public static void savePickUpAddressTest(){
        
        string identifierTest = '1234';
        string addressTest = '7 Russell Street, Wanaka 9305, Nouvelle-Zélande';
        string IdExterneAndAddressTest = identifierTest + ' Address:' +  addressTest;
        Test.startTest();
        System.runAs(GSUser){
            res = PickUpSearchController.savePickUpAddress(eqs.id,IdExterneAndAddressTest);
        }
        Test.stopTest();
        system.assertEquals(null, res);
        system.assertEquals(addressTest, [Select id, Adresse_de_livraison__c From Equipement_sinistre__c where id =: eqs.id].Adresse_de_livraison__c);
        system.assertEquals(identifierTest, [Select id, RelayPointIdExterne__c From Equipement_sinistre__c where id =: eqs.id].RelayPointIdExterne__c);
        system.assertEquals('En point relais', [Select id, DeliveryMode__c From Equipement_sinistre__c where id =: eqs.id].DeliveryMode__c);
    }
    
    
    /***
    * @description Test method for the savePickUpAddress method in the PickUpSearchController apex class. This test method tries a failed update of the Equipement_sinistre__c.
    */
    @isTest
    public static void savePickUpAddressCatchTest(){
        
        string addressTest = 'address test';
        Test.startTest();
        System.runAs(GSUser){
            res = PickUpSearchController.savePickUpAddress(s.id,addressTest);  
        }
        Test.stopTest();
        system.assertNotEquals(null, res);
        system.assertNotEquals('address test', [Select id, Adresse_de_livraison__c From Equipement_sinistre__c where id =: eqs.id].Adresse_de_livraison__c);
        system.assertNotEquals('En point relais', [Select id, DeliveryMode__c From Equipement_sinistre__c where id =: eqs.id].DeliveryMode__c);
    }
}