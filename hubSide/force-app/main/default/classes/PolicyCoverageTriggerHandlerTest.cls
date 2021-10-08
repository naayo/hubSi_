/***
* @author Ariane Tanguy (GFI)
* @date 11/06/2020
* @description PolicyCoverage test class
* @Object vlocity_ins__AssetCoverage__c
*/

@isTest
public class PolicyCoverageTriggerHandlerTest {
    
    /***
    * @description Check whether there is a previous open formula
    * @see checkPreviousFormuleOnCreation
    */
    @isTest
    public static void checkPreviousFormuleOnCreationTest(){
        
        // see handleFormuleUpgradeTest
    }
    
    /***
    * @description Update the record type on formule creation
    * @see updateFormuleOnCreation
    */
    @isTest
    public static void updateFormuleOnCreationTest(){
        
        id formuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year(), 
                                                   system.today().month(), 
                                                   system.today().day());
        insert c;
        
        // Query the formule
        vlocity_ins__AssetCoverage__c a = [SELECT id, Name, RecordTypeId
                                           FROM vlocity_ins__AssetCoverage__c
                                           WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        system.assertEquals(formuleLocationId, a.RecordTypeId, 
                            'The record type hasnt been updated - This is wrong');
        
        c = [SELECT Code_formule__r.Name FROM Asset WHERE id =: c.id];
        system.assertEquals(c.Code_formule__r.Name + ' - ' + system.today(), a.Name, 
                      'The name hasnt been updated - This is wrong');
    }
    
    /***
    * @description Update the formule name on update
    * @see updateFormuleOnUpdate
    */
    @isTest
    public static void updateFormuleOnUpdateTest(){
        
        id formuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year(), 
                                                   system.today().month(), 
                                                   system.today().day());
        insert c;
        
        // Query the formule
        vlocity_ins__AssetCoverage__c a = [SELECT id, Name
                                           FROM vlocity_ins__AssetCoverage__c
                                           WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        
        c = [SELECT Code_formule__r.Name FROM Asset WHERE id =: c.id];
        system.assertEquals(c.Code_formule__r.Name + ' - ' + system.today(), a.Name, 
                      'The name hasnt been updated - This is wrong');
        
        // Try updating the formule's name
        a.Name = 'any name from mulesoft';
        update a;
        
        a = [SELECT id, Name
             FROM vlocity_ins__AssetCoverage__c
             WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        system.assertEquals(c.Code_formule__r.Name + ' - ' + system.today(), a.Name, 
                      'The name hasnt been corrected - This is wrong');
    }
    
    /***
    * @description Combine the different forumule + option to update the policies at the asset level
    * @see updateRelatedAsset
    */
    @isTest
    public static void updateRelatedAssetOneOptionAtATimeTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createAssuranceAsset();
        insert c;
        
        // Create a formule and an option
        List<Product2> formuleOptionList = new List<Product2>();
        for(integer i = 0; i<2; i++){
            formuleOptionList.add(TestFactory.createFormuleInsurer());
        }
        
        // Update the option to actually an option
        formuleOptionList[1].vlocity_ins__Type__c = 'Option';
        formuleOptionList[1].Oxydation__c = TRUE;
        formuleOptionList[1].Plafond__c = 10;
        formuleOptionList[1].Nombre_produits_assures__c = '2';        
        insert formuleOptionList;
        
        // Create a formule
        vlocity_ins__AssetCoverage__c f = TestFactory.createFormuleOptionInsurer(formuleOptionList[0].id);
        f.vlocity_ins__PolicyAssetId__c = c.id;
        f.vlocity_ins__Type__c = 'Formula';
        f.Statut__c = 'open';
        insert f;
        
        // Query the required objects
        Product2 p = [SELECT id, Casse__c, Oxydation__c, Plafond__c, Nombre_produits_assures__c
                      FROM Product2
                      WHERE id =: formuleOptionList[0].id];
        c = [SELECT id, Casse__c, Plafond__c
             FROM Asset];
        f = [SELECT id, Casse__c, Plafond__c
             FROM vlocity_ins__AssetCoverage__c];
        
        // Check whether the asset's policies have been updated
        system.assertEquals(p.Casse__c, c.Casse__c, 'The casse policy hasnt been updated on the asset - This is wrong');
        system.assertEquals(p.Plafond__c, c.Plafond__c, 'The plafond hasnt been updated on the asset - This is wrong');
        
        // Check whether the policy has been updated
        system.assertEquals(p.Casse__c, f.Casse__c, 'The casse policy hasnt been updated on the policy - This is wrong');
        system.assertEquals(p.Plafond__c, f.Plafond__c, 'The plafond hasnt been updated on the policy - This is wrong');
        
        // Add an option
        vlocity_ins__AssetCoverage__c o = TestFactory.createFormuleOptionInsurer(formuleOptionList[1].id);
        o.vlocity_ins__PolicyAssetId__c = c.id;
        o.vlocity_ins__Type__c = 'Option';
        o.Statut__c = 'open';
        insert o;
        
        // Query the required objects
        Product2 p2 = [SELECT id, Oxydation__c, Plafond__c, Nombre_produits_assures__c
                       FROM Product2
                       WHERE id =: formuleOptionList[1].id];
        c = [SELECT id, Oxydation__c, Plafond__c, Nombre_produits_assures__c
             FROM Asset];
        
        // Check whether the asset's policies have been updated
        system.assertEquals(p.Oxydation__c | p2.Oxydation__c, c.Oxydation__c, 'The oxydation policy hasnt been updated on the asset - This is wrong');
        system.assertEquals(p.Plafond__c + p2.Plafond__c, c.Plafond__c, 'The plafond hasnt been updated on the asset - This is wrong');
        system.assertEquals('3', c.Nombre_produits_assures__c, 'The # of insured products hasnt been updated on the asset - This is wrong');
        
        // All considered, that option is not needed anymore, let's cancel it
        o.Statut__c = 'closed';
        o.Date_de_resiliation__c = system.today();
        update o;
        
        c = [SELECT id, Casse__c, Oxydation__c, Plafond__c
             FROM Asset];
        
        // Check whether the asset's policies have been updated
        system.assertEquals(p.Oxydation__c, c.Oxydation__c, 'The oxydation policy hasnt been updated on the asset - This is wrong');
        system.assertEquals(p.Plafond__c, c.Plafond__c, 'The plafond hasnt been updated on the asset - This is wrong');
    }
    
    /***
    * @description Combine the different forumule + option to update the policies at the asset level
    * @see updateRelatedAsset
    */
    @isTest
    public static void updateRelatedAssetMoreThanOneOptionTest(){
        
        // Create a new Contract
        Asset c = TestFactory.createAssuranceAsset();
        insert c;
        
        // Create a formule and an option
        List<Product2> formuleOptionList = new List<Product2>();
        for(integer i = 0; i<3; i++){
            formuleOptionList.add(TestFactory.createFormuleInsurer());
        }
        
        // Update the first option to an option
        formuleOptionList[1].vlocity_ins__Type__c = 'Option';
        formuleOptionList[1].Oxydation__c = TRUE;
        formuleOptionList[1].Plafond__c = 10;
        formuleOptionList[1].Nombre_produits_assures__c = '2';   
        
        // Same for the second option
        formuleOptionList[2].vlocity_ins__Type__c = 'Option';
        formuleOptionList[2].Oxydation__c = TRUE;
        formuleOptionList[2].Plafond__c = 0;
        formuleOptionList[2].Nombre_produits_assures__c = '0';        
        insert formuleOptionList;
        
        // Create a formule
        vlocity_ins__AssetCoverage__c f = TestFactory.createFormuleOptionInsurer(formuleOptionList[0].id);
        f.vlocity_ins__PolicyAssetId__c = c.id;
        f.vlocity_ins__Type__c = 'Formula';
        f.Statut__c = 'open';
        insert f;
        
        // Add both options
        vlocity_ins__AssetCoverage__c o = TestFactory.createFormuleOptionInsurer(formuleOptionList[1].id);
        o.vlocity_ins__PolicyAssetId__c = c.id;
        o.vlocity_ins__Type__c = 'Option';
        o.Statut__c = 'open';
        vlocity_ins__AssetCoverage__c o2 = TestFactory.createFormuleOptionInsurer(formuleOptionList[2].id);
        o2.vlocity_ins__PolicyAssetId__c = c.id;
        o2.vlocity_ins__Type__c = 'Option';
        o2.Statut__c = 'open';
        List<vlocity_ins__AssetCoverage__c> optionList = new List<vlocity_ins__AssetCoverage__c>{o, o2};
            
        insert optionList;
        
        // Query the required objects
        formuleOptionList = [SELECT id, Casse__c, Oxydation__c, Plafond__c, Nombre_produits_assures__c
                             FROM Product2
                             WHERE id IN: formuleOptionList];
        c = [SELECT id, Oxydation__c, Plafond__c, Nombre_produits_assures__c
             FROM Asset];
        
        // Check whether the asset's policies have been updated
        system.assertEquals(formuleOptionList[0].Oxydation__c | formuleOptionList[1].Oxydation__c | formuleOptionList[2].Oxydation__c, 
                            c.Oxydation__c, 
                            'The oxydation policy hasnt been updated on the asset - This is wrong');
        system.assertEquals(formuleOptionList[0].Plafond__c + formuleOptionList[1].Plafond__c + formuleOptionList[2].Plafond__c, c.Plafond__c, 
                            'The plafond hasnt been updated on the asset - This is wrong');
        system.assertEquals('3', c.Nombre_produits_assures__c, 'The # of insured products hasnt been updated on the asset - This is wrong');
    }
    
    /***
    * @description Update the previous formule + facture on new formule creation
    * @see handleFormuleResiliation
    */
    @isTest
    public static void handleFormuleUpgradeTest(){
        
        id formuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year(), 
                                                   system.today().month(), 
                                                   system.today().day());
        insert c;
        
        // Create another formule
        Product2 p = TestFactory.createFormule();
        p.Nombre_jours_inclus__c = 20;
        p.Name = 'Gamme 20 JOURS / MOIS';
        insert p;
        
        test.startTest();
        
        // Create another policy coverage
        vlocity_ins__AssetCoverage__c f = TestFactory.createFormuleOption();
        f.vlocity_ins__Type__c = 'Formula';
        f.vlocity_ins__PolicyAssetId__c = c.id;
        f.Formule_options__c = p.id;
        f.Date_souscription__c = system.today();
        
        // Let's try to insert it
        try{
            insert f;
            system.assert(false, 'This policy coverage shouldnt have been successfully inserted - This is wrong');
        } catch(Exception ex){
            system.assertEquals(TRUE, ex.getMessage().contains('an active contractItem'), ex.getMessage());
        }
        
        // Stop the previous formule
        vlocity_ins__AssetCoverage__c oldF = [SELECT id, Statut__c, Date_de_resiliation__c
                                              FROM vlocity_ins__AssetCoverage__c
                                              WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        oldF.Statut__c = 'closed';
        oldF.Date_de_resiliation__c = system.today();
        update oldF;
        
        // And insert the new one
        insert f;
        
        // Query the formule
        List<vlocity_ins__AssetCoverage__c> formuleList = [SELECT id, Date_souscription__c, Statut__c, Motif_de_resiliation__c
                                                           FROM vlocity_ins__AssetCoverage__c
                                                           WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        system.assertEquals(2, formuleList.size(), 
                            'There should be two formules now - This is wrong');
        
        vlocity_ins__AssetCoverage__c oldFormule = formuleList[0];
        vlocity_ins__AssetCoverage__c newFormule = formuleList[1];
        
        // Check whether the new formule is active, and the old one not anymore
        system.assertEquals('closed', oldFormule.Statut__c, 
                            'The old formule status should have been changed - This is wrong');
        system.assertEquals('open', newFormule.Statut__c, 
                            'The new formule status should have been changed - This is wrong');
        system.assertEquals('upgrade', oldFormule.Motif_de_resiliation__c, 
                            'The old formule status should have been changed - This is wrong');
        
        // Now check the facture
        Facture__c fac = [SELECT id, Nombre_jours_formule__c FROM Facture__c WHERE Contrat__c =: c.id];
        system.assertEquals(p.Nombre_jours_inclus__c, fac.Nombre_jours_formule__c, 
                            'The number of allowed days in the facture should have been updated - This is wrong');
        
        test.stopTest();
    }
    
    /***
    * @description Update the previous formule + facture on new formule creation
    * @see handleFormuleResiliation
    */
    @isTest
    public static void handleFormuleDowngradeTest(){
        
        id formuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year(), 
                                                   system.today().month(), 
                                                   system.today().day());
        insert c;
        
        // Create another formule
        Product2 p = TestFactory.createFormule();
        p.Nombre_jours_inclus__c = 2;
        p.Name = 'Gamme 2 JOURS / MOIS';
        insert p;
        
        test.startTest();
        
        // Stop the previous formule
        vlocity_ins__AssetCoverage__c oldF = [SELECT id, Statut__c, Date_de_resiliation__c
                                              FROM vlocity_ins__AssetCoverage__c
                                              WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        oldF.Statut__c = 'closed';
        oldF.Date_de_resiliation__c = system.today();
        update oldF;
        
        // Create another policy coverage
        vlocity_ins__AssetCoverage__c f = TestFactory.createFormuleOption();
        f.vlocity_ins__Type__c = 'Formula';
        f.vlocity_ins__PolicyAssetId__c = c.id;
        f.Formule_options__c = p.id;
        f.Date_souscription__c = system.today();
        insert f;
        
        // Query the formule
        List<vlocity_ins__AssetCoverage__c> formuleList = [SELECT id, Date_souscription__c, Statut__c, Motif_de_resiliation__c
                                                           FROM vlocity_ins__AssetCoverage__c
                                                           WHERE vlocity_ins__PolicyAssetId__c =: c.id];
        system.assertEquals(2, formuleList.size(), 
                            'There should be two formules now - This is wrong');
        
        vlocity_ins__AssetCoverage__c oldFormule = formuleList[0];
        vlocity_ins__AssetCoverage__c newFormule = formuleList[1];
        
        // Check whether the new formule is active, and the old one not anymore
        system.assertEquals('closed', oldFormule.Statut__c, 
                            'The old formule status should have been changed - This is wrong');
        system.assertEquals('open', newFormule.Statut__c, 
                            'The new formule status should have been changed - This is wrong');
        system.assertEquals('downgrade', oldFormule.Motif_de_resiliation__c, 
                            'The old formule status should have been changed - This is wrong');
        
        // Now check the facture
        Facture__c fac = [SELECT id, Nombre_jours_formule__c FROM Facture__c WHERE Contrat__c =: c.id];
        system.assertEquals(4, fac.Nombre_jours_formule__c, 
                            'The number of allowed days in the facture shouldnt have been updated - This is wrong');
        
        test.stopTest();
    }
    
    /***
    * @description Update the previous formule + facture on new formule creation
    * @see handleFormuleResiliation
    */
    @isTest
    public static void handleOptionResiliationTest(){
        
        id formuleLocationId = UtilityClassHelper.getCreatedRecordType('Formule_option_location');
        
        // Create a new Contract
        Asset c = TestFactory.createContract();
        c.Date_debut_contrat__c = Date.newInstance(system.today().year(), 
                                                   system.today().month(), 
                                                   system.today().day());
        insert c;
        
        // Create another formule
        Product2 p = TestFactory.createFormule();
        insert p;
        
        p.Nombre_jours_inclus__c = 20;
        p.Name = 'Gamme 20 JOURS / MOIS';
        update p;
        
        // Create an option
        vlocity_ins__AssetCoverage__c o = TestFactory.createFormuleOption();
        o.vlocity_ins__Type__c = 'Option';
        o.vlocity_ins__PolicyAssetId__c = c.id;
        o.Formule_options__c = p.id;
        o.Date_souscription__c = system.today();
        insert o;
        
        // And another
        vlocity_ins__AssetCoverage__c newO = TestFactory.createFormuleOption();
        newO.vlocity_ins__Type__c = 'Option';
        newO.vlocity_ins__PolicyAssetId__c = c.id;
        newO.Formule_options__c = p.id;
        newO.Date_souscription__c = system.today();
        
        test.startTest();
        
        // Let's try to insert it
        try{
            insert newO;
            system.assert(false, 'This policy coverage shouldnt have been successfully inserted - This is wrong');
        } catch(Exception ex){
            system.assertEquals(TRUE, ex.getMessage().contains('an active contractItem'), ex.getMessage());
        }
        
        // Stop the previous option
        o.Statut__c = 'closed';
        o.Date_de_resiliation__c = system.today();
        update o;
        
        // And insert the new one
        insert newO;
        
        // Query the formule
        List<vlocity_ins__AssetCoverage__c> optionList = [SELECT id, Date_souscription__c, Statut__c, Motif_de_resiliation__c
                                                          FROM vlocity_ins__AssetCoverage__c
                                                          WHERE vlocity_ins__PolicyAssetId__c =: c.id
                                                          AND vlocity_ins__Type__c = 'Option'];
        
        system.assertEquals(2, optionList.size(), 
                            'There should be two options now - This is wrong');
        
        vlocity_ins__AssetCoverage__c oldOption = optionList[0];
        vlocity_ins__AssetCoverage__c newOption = optionList[1];
        
        // Check whether the new formule is active, and the old one not anymore
        system.assertEquals('closed', oldOption.Statut__c, 
                            'The old formule status should have been changed - This is wrong');
        system.assertEquals('open', newOption.Statut__c, 
                            'The new formule status should have been changed - This is wrong');
        
        test.stopTest();
    }
    
    /***
    * @description Update the facture on formula update
    * @see updateRelatedFacture
    */
    @isTest
    public static void updateRelatedFactureTest(){
        
        // see handleFormuleResiliation
    }
    
}