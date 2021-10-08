/***
* @author Nicolas Brancato (GFI)
* @date 17/02/2021
* @description Controller class test for Flow_CustomPicklistObjectEquipmentCost apex class
*/

@isTest
public class Flow_CustomPicklistObjectEquipCostTest {
    
    
    public static final String PROFILE_GS = 'SFAM GS';
    public static User GSUser;
    public static Id EQUIPMENTCOSTTYPERTID_EXCHANGE;
    public static List<EquipmentCostType__c> equipCostTypeList;
    public static List<String> customListOfStrings;
    
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
        
        EQUIPMENTCOSTTYPERTID_EXCHANGE = [Select id from RecordType where DeveloperName =: 'Exchange'].id;
        
        equipCostTypeList = new list<EquipmentCostType__c>{new EquipmentCostType__c(RecordTypeId = EQUIPMENTCOSTTYPERTID_EXCHANGE, Object__c = 'Accessoire', ValueLevel__c = 'Basse Valeur', UnitCost__c = 10,ManpowerCost__c = 30, ChangeableCost__c = false),
            												new EquipmentCostType__c(RecordTypeId = EQUIPMENTCOSTTYPERTID_EXCHANGE, Object__c = 'Accessoire', ValueLevel__c = 'Haute Valeur', UnitCost__c = 45,ManpowerCost__c = 50, ChangeableCost__c = true),
            												new EquipmentCostType__c(RecordTypeId = EQUIPMENTCOSTTYPERTID_EXCHANGE, Object__c = 'Mode Livraison', ValueLevel__c = 'Haute Valeur', UnitCost__c = 120,ManpowerCost__c = 0, ChangeableCost__c = false)};
        insert equipCostTypeList;
    }
    
    
    /***
    * @description Test method for the createPicklist method in the Flow_CustomPicklistObjectEquipmentCost apex class.
    */
    @isTest
    public static void createPicklistTest(){
        
        
        Test.startTest();
        System.runAs(GSUser){
            customListOfStrings = Flow_CustomPicklistObjectEquipmentCost.createPicklist(EQUIPMENTCOSTTYPERTID_EXCHANGE);
        }
        Test.stopTest();
        system.assertNotEquals(null, customListOfStrings);
        system.assertEquals(new list<String>{'Accessoire','Mode Livraison'}, customListOfStrings);
    }
}