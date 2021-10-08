global class batch_updateClientEmail implements Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Get all factures which last day was today
        return Database.getQueryLocator(
            'SELECT id, ' +
            'PersonEmail, ' +
            'address__c, ' +
            'BillingStreet, BillingCity, BillingPostalCode, ' +
            'PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, ' +
            'Phone ' +
            'FROM Account ' +
            'WHERE PersonEmail != \'%@yopmail.com\' ' + 
            'AND PersonEmail != \'%@sfam.eu\' ' + 
            'AND PersonEmail != \'%@smartphonerecycle.fr\' ' + 
            'AND Record_Type_Name__c = \'Client_SFAM\''
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accToUpdate){
        
        for(Account a : accToUpdate){
            a.PersonEmail = 'sinistre.salesforce@yopmail.com';
            a.BillingStreet = a.PersonMailingStreet = '1 r Camille Claudel';
            a.BillingCity = a.PersonMailingCity = 'ROMANS SUR ISÈRE';
            a.BillingPostalCode = a.PersonMailingPostalCode = '26100';
            a.address__c = '1 r Camille Claudel, 26100 ROMANS SUR ISÈRE';
            a.Phone = '0101010101';
        }
        system.debug('-- accToUpdate ' + accToUpdate.size());
        update accToUpdate;
        
    }
    
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
    }    
}