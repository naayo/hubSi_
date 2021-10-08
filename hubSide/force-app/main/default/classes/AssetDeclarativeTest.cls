/***
* @author Ariane Tanguy (GFI)
* @date 07/05/2020
* @description Asset (contrat location) declarative rules test class
* @Object Contract
*/

@isTest
public class AssetDeclarativeTest {
    
    /***
	* @description On contract location creation, there should be : 
	* a facture created, some contract fields updated, the client's contract updated
	* @PB Creation_contrat
	*/
    @isTest
    public static void onLocationContractCreationPBTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Check whether the facture was created
        List<Facture__c> factureList = [SELECT id, Date_debut_periode__c
                                        FROM Facture__c
                                        WHERE Contrat__c =: c.id];
        
        system.assertEquals(1, factureList.size(), 
                            'The contract creation should have triggered the Facture creation - This is wrong');
        
        system.assertEquals(c.Date_debut_contrat__c, factureList[0].Date_debut_periode__c, 
                            'The Facture should have been updated with contract info - This is wrong');
        
        // Check whether the contract has been updated
        c = [SELECT Date_debut_contrat__c, Date_fin_contrat__c FROM Asset 
             WHERE id =: c.id];
        
        system.assertEquals(c.Date_debut_contrat__c.addMonths(12), c.Date_fin_contrat__c, 
                            'The contract creation should have triggered contract fields update - This is wrong');
        
        // Check whether the Formule et Option souscrite was created
        List<vlocity_ins__AssetCoverage__c> formuleList = [SELECT id, vlocity_ins__StartDate__c
                                        FROM vlocity_ins__AssetCoverage__c
                                        WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        
        system.assertEquals(1, formuleList.size(), 
                            'The contract creation should have triggered the Facture creation - This is wrong');
        
        // Last bit : check whether the client status has changed
        
    }
    
    /***
	* @description On facture creation, check whether the contract is updated
	* @PB Creation_contrat
	*/
    @isTest
    public static void onFactureCreationPBTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        insert c;
        
        // Check whether the facture was created
        List<Facture__c> factureList = [SELECT id FROM Facture__c
                                        WHERE Contrat__c =: c.id];
        // And updated on the contract
        c = [SELECT id, Facture__c FROM Asset LIMIT 1];
        
        system.assertEquals(factureList[0].id, c.Facture__c, 
                            'The facture creation should have triggered an update on the contract - This is wrong');
        
    }
    
}