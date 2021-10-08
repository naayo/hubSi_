global class batch_createNewFacture implements Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Get all factures which last day was today
        return Database.getQueryLocator(
            'SELECT id, ' +
            'Contrat__c, ' +
            'Contrat__r.Code_formule__r.Nombre_jours_inclus__c, ' +
            'Contrat__r.Code_formule__r.Report_maximum__c, ' +
            'Contrat__r.Date_cloture__c, ' +
            'Date_debut_periode__c, ' +
            'Date_fin_periode__c, ' +
            'Montant_facture__c, ' +
            'Nombre_jours_consommes__c, ' +
            'Nombre_jours_depassement__c, ' +
            'Nombre_jours_reportes__c, ' + 
            'Nombre_jours_restants__c ' +
            'FROM Facture__c ' +
            'WHERE Date_fin_periode__c = TODAY ' + 
            'AND Contrat_actif__c = TRUE'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Facture__c> factureToRenewList){
        
        // Query all current emprunt existing on the facture
        List<Emprunt__c> currentEmpruntList = [SELECT id, Date_Sortie__c, Date_retour_prevu__c, 
                                               Facture__c, Nombre_jours_depassement__c
                                               FROM Emprunt__c 
                                               WHERE Facture__c IN: factureToRenewList
                                               AND Date_retour_prevu__c > TODAY
                                               AND Status__c = 'Sortie'];
        
        // Map the emprunt to their current facture
        Map<id, Emprunt__c> factureIdEmpruntMap = new Map<id, Emprunt__c>();
        for(Emprunt__c e : currentEmpruntList){
            factureIdEmpruntMap.put(e.Facture__c, e);
        }
        
        List<Facture__c> factureToUpsertList = new List<Facture__c>();
        for(Facture__c f : factureToRenewList){            
            
            // Create the new Facture
            Facture__c newFacture = new Facture__c();
            newFacture.Contrat__c = f.Contrat__c;
            newFacture.Date_debut_periode__c = f.Date_fin_periode__c.addDays(1);
            newFacture.Nombre_jours_formule__c = f.Contrat__r.Code_formule__r.Nombre_jours_inclus__c;
            
            // Handle the contract resiliation if there was one
            if(f.Contrat__r.Date_cloture__c < f.Date_debut_periode__c.addMonths(1) - 1){
                newFacture.Date_fin_periode__c = f.Contrat__r.Date_cloture__c;
            } else {
                newFacture.Date_fin_periode__c = newFacture.Date_debut_periode__c.addMonths(1) - 1;
            }
            
            newFacture.Nombre_jours_reportes__c = f.Nombre_jours_restants__c <= f.Contrat__r.Code_formule__r.Report_maximum__c ?
                f.Nombre_jours_restants__c : f.Contrat__r.Code_formule__r.Report_maximum__c;
            
            // Check whether there is an already running emprunt
            if(factureIdEmpruntMap.keySet().contains(f.id)){
                
                // Remove the number of days on the current facture, and compensate the new one.
                Integer daysNewFacture = system.today().daysBetween(factureIdEmpruntMap.get(f.id).Date_retour_prevu__c);
                Integer daysPreviousFacture = factureIdEmpruntMap.get(f.id).Date_Sortie__c.daysBetween(system.today());
                
                system.debug('-- here daysPreviousFacture ' + daysPreviousFacture);
                system.debug('-- here daysNewFacture ' + daysNewFacture);
                
                f.Nombre_jours_consommes__c -= daysNewFacture;
                
                Decimal nombreJoursRestants = f.Contrat__r.Code_formule__r.Nombre_jours_inclus__c + f.Nombre_jours_reportes__c - f.Nombre_jours_consommes__c;
                nombreJoursRestants = nombreJoursRestants > 0 ? nombreJoursRestants : 0;
                newFacture.Nombre_jours_reportes__c = nombreJoursRestants <= f.Contrat__r.Code_formule__r.Report_maximum__c ?
                    nombreJoursRestants : f.Contrat__r.Code_formule__r.Report_maximum__c;
                
                newFacture.Nombre_jours_consommes__c = daysNewFacture;
                
                system.debug('-- here f.Nombre_jours_consommes__c ' + f.Nombre_jours_consommes__c);
                system.debug('-- here newFacture.Nombre_jours_reportes__c ' + newFacture.Nombre_jours_reportes__c);
                system.debug('-- here newFacture.Nombre_jours_consommes__c ' + newFacture.Nombre_jours_consommes__c);
                
                // If the emprunt was short on days, remove some days on the next facture
                if(f.Nombre_jours_depassement__c - daysNewFacture > 0){
                    f.Nombre_jours_consommes__c -= (f.Nombre_jours_depassement__c - daysNewFacture);
                    f.Nombre_jours_depassement__c = 0;
                    f.Montant_facture__c = 0;
                    newFacture.Nombre_jours_reportes__c -= factureIdEmpruntMap.get(f.id).Nombre_jours_depassement__c;
                    //newFacture.Nombre_jours_consommes__c += factureIdEmpruntMap.get(f.id).Nombre_jours_depassement__c;
                }
                
                factureToUpsertList.add(f);
            }
            
            factureToUpsertList.add(newFacture);
        }
        
        if(factureToUpsertList.size() > 0 ){
            upsert factureToUpsertList;
        }
    }
    
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
    }    
}