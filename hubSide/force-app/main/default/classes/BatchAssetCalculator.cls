public class BatchAssetCalculator implements Database.Batchable<sObject> {
    Date dateNow = System.now().date();
    public String query = 'SELECT Id, '+
        'AssetId, Date_sinistre__c, ' + 
        'IsDeleted, Montant_sinistre__c, ' +
        'Montant_geste_co__c, Status, ' +
        'Asset.Formule__r.Formule_options__r.NbMounthKPIContract__c, ' +
        'Asset.Plafond__c, '+
        'Asset.TECH_CalculatorIndicLastChange__c,' +
        'Asset.TECH_CalculatorIndicNextChange__c,' +
        'Asset.TECH_PreviousAmountIndem__c,' +
        'Asset.TECH_LastBirthDayContract__c,' +
        'Asset.Date_debut_contrat__c ' +
        'FROM Case '+
        'WHERE Record_Type_Name__c LIKE \'Sinistre%\' ' + 
        'AND Asset.TECH_CalculatorIndicLastChange__c =:dateNow ' + 
        'ORDER BY LastModifiedDate DESC ' + 
        'ALL ROWS';
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<Case> scope){
        UtilityClassHelper.assetKPICalculator(scope,null);
    }
  
    public void finish(Database.BatchableContext BC){
    }
 }