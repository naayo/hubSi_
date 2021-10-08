/***
* @author Pierre-Mickael Barral (Inetum)
* @date 19/01/2021
* @description Batch calculator test class
* DATE          DEV         DESCRIPTION
* 19/01/2021    PMB         init
*/
@isTest
public with sharing class BatchAssetCalculatorTest {
    @testSetup static void init() {
        // Create an asset
        Asset ast = TestFactory.createAssuranceAssetWithFormula();
        ast.Date_debut_contrat__c = System.today().addMonths(-12);
        update ast;
        Case cs = TestFactory.createSinistre(ast.AccountId,ast.Id);
        cs.Date_sinistre__c = System.today().addMonths(-12).addDays(-1);
        insert cs;
    }

    @isTest
    public static void batchTest(){
        Test.StartTest();
        BatchAssetCalculator batch = new BatchAssetCalculator();
        ID batchprocessid = Database.executeBatch(batch);
        Test.StopTest();
        Case c = [SELECT Id,Status,Asset.TECH_CalculatorIndicLastChange__c FROM Case LIMIT 1];
        system.assertEquals(c.Asset.TECH_CalculatorIndicLastChange__c, System.today().addMonths(12).addDays(-1), 
        'Batch is not run');
    }
}