global class schedulable_createNewFacture implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        
        // Check whether there are new facture to create    
        database.executebatch(new batch_createNewFacture());
    }
}