/***
* @author Ariane Tanguy (GFI)
* @date 07/05/2021
* @description batch_dataCleanUp class
*/

global class batch_dataCleanUp implements Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Get all factures which last day was today
        return Database.getQueryLocator(
            'SELECT id ' +
            'FROM Case ' +
            'WHERE vlocity_ins__Verified__c = TRUE ' + 
            'AND Record_type_name__c = \'Sinistre\' ' + 
            'AND Account.Compte_test__c = FALSE '
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Case> caseToDelete){
        
        // Delete those useless cases
        if(caseToDelete.size() > 0){
            delete caseToDelete;
        }
        
        // Check whether there are some homeless equipement sinistre
        List<Equipement_sinistre__c> equipSinToDelete = [SELECT id 
                                                        FROM Equipement_sinistre__c
                                                        WHERE Sinistre__c = NULL];
        delete equipSinToDelete;        
    }
    
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
    }    
}