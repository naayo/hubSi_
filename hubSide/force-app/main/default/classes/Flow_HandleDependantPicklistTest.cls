/***
* @author Ariane Tanguy (GFI)
* @date 15/04/2021
* @description Flow_HandleDependantPicklist test class
* @Class Flow_HandleDependantPicklist
*/

@isTest
public class Flow_HandleDependantPicklistTest {
    
    @testSetup 
    public static void testSetup(){
        
        // Create a SFAMConfig
        SFAMConfig__c c = new SFAMConfig__c();
        c.Name = 'DirectionQualiteSinistre';
        c.UserBusinessProfile__c = 'DirectionQualiteSinistre';
        c.UserProfile__c = 'SFAM Stock';
        c.Equipement_sinistre_Statut_equipement__c = 'En Analyse;CustomerReception';
        c.Equipement_sinistre_Sous_statut__c = 'Retourné client;Repaired';
        insert c;
        
        // Create a user
        User u = TestFactory.createUser();
        u.LastName = 'MistaDirecta';
        u.businessProfile__c = 'DirectionQualiteSinistre';
        insert u;
    }
    
    /***
	* @description Get the current user's business profile
	* @LightningComponent Flow_HandleDependantPicklist
	*/
    @isTest
    public static void getUserBusinessProfileTest(){
        
        User u = [SELECT id, businessProfile__c 
                  FROM User
                  WHERE LastName = 'MistaDirecta'];
        
        String businessProfile;
        system.runAs(u){
            businessProfile = Flow_HandleDependantPicklist.getUserBusinessProfile();
        }
        
        // Check the result
        system.assertEquals(u.businessProfile__c, businessProfile, 
                           'The business profile doesnt match the users - This is wrong');
    }
    
    /***
	* @description Get the business profile filtered controlling picklist map
	* @LightningComponent Flow_HandleDependantPicklist
	*/
    @isTest
    public static void getBusinessProfileControllingPicklistFilteredTest(){
        
        User u = [SELECT id, businessProfile__c 
                  FROM User
                  WHERE LastName = 'MistaDirecta'];
        
        Map<String, String> ctrPkFiltered;
                
        // Play the flow
        system.runAs(u){
            ctrPkFiltered = Flow_HandleDependantPicklist.getControllingPicklistFiltered('Equipement_sinistre__c', 
                                                                                        'Statut_equipement__c', 
                                                                                        Flow_HandleDependantPicklist.getUserBusinessProfile(), 
                                                                                        NULL);
        }
        
        List<String> filteredStatusList = [SELECT Equipement_sinistre_Statut_equipement__c
                                           FROM SFAMConfig__c].Equipement_sinistre_Statut_equipement__c.split(';');
        
        for(String s : ctrPkFiltered.values()){
            system.assert(filteredStatusList.contains(s), 
                          'The value ' + s + ' is missing in the business profile controlling filtered picklist - This is wrong');
        }
    }
    
    /***
	* @description Get the RT filtered controlling picklist map
	* @LightningComponent Flow_HandleDependantPicklist
	*/
    @isTest
    public static void getRTControllingPicklistFilteredTest(){
        
        User u = [SELECT id, businessProfile__c 
                  FROM User
                  WHERE LastName = 'MistaDirecta'];
        
        // Create another SFAMConfig
        SFAMConfig__c c = new SFAMConfig__c();
        c.Name = 'Equipement_a_reparer';
        c.Equipement_sinistre_Statut_equipement__c = 'CustomerReception';
        insert c;
        
        Map<String, String> ctrPkFiltered;
                
        // Play the flow
        system.runAs(u){
            ctrPkFiltered = Flow_HandleDependantPicklist.getControllingPicklistFiltered('Equipement_sinistre__c', 
                                                                                        'Statut_equipement__c', 
                                                                                        Flow_HandleDependantPicklist.getUserBusinessProfile(), 
                                                                                        'Equipement_a_reparer');
        }
        
        List<String> filteredStatusList = [SELECT Equipement_sinistre_Statut_equipement__c
                                           FROM SFAMConfig__c
                                           WHERE Name = 'Equipement_a_reparer'].Equipement_sinistre_Statut_equipement__c.split(';');
        
        for(String s : ctrPkFiltered.values()){
            system.assert(filteredStatusList.contains(s), 
                          'The value ' + s + ' is missing in the RT controlling filtered picklist - This is wrong');
        }
        
        // Check whether the result stays the same with the business profile removed
        c = [SELECT id FROM SFAMConfig__c WHERE Name = 'DirectionQualiteSinistre'];
        delete c;
        
        // Play the flow
        system.runAs(u){
            ctrPkFiltered = Flow_HandleDependantPicklist.getControllingPicklistFiltered('Equipement_sinistre__c', 
                                                                                        'Statut_equipement__c', 
                                                                                        Flow_HandleDependantPicklist.getUserBusinessProfile(), 
                                                                                        'Equipement_a_reparer');
        }
        
        for(String s : ctrPkFiltered.values()){
            system.assert(filteredStatusList.contains(s), 
                          'The value ' + s + ' is missing in the RT controlling filtered picklist - This is wrong');
        }
    }
    
    /***
	* @description Get the dependant picklist map
	* @LightningComponent Flow_HandleDependantPicklist
	*/
    @isTest
    public static void getDependantPicklistFilteredTest(){
        
        User u = [SELECT id, businessProfile__c 
                  FROM User
                  WHERE LastName = 'MistaDirecta'];
        
        Map<String, String> dpdPkFiltered;
                
        // Play the flow
        system.runAs(u){
            dpdPkFiltered = Flow_HandleDependantPicklist.getDependantPicklistFiltered('Equipement_sinistre__c', 
                                                                                      'Statut_equipement__c', 
                                                                                      'Sous_statut__c', 
                                                                                      'CustomerReception',
                                                                                      Flow_HandleDependantPicklist.getUserBusinessProfile());
        }
        
        List<String> filteredStatusList = [SELECT Equipement_sinistre_Sous_statut__c
                                           FROM SFAMConfig__c].Equipement_sinistre_Sous_statut__c.split(';');
        
        for(String s : dpdPkFiltered.values()){
            system.assert(filteredStatusList.contains(s), 
                          'The value ' + s + ' is missing in the dependant filtered picklist - This is wrong');
        }
    }
}