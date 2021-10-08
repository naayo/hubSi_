/***
* @author Ariane Tanguy (GFI)
* @date 07/05/2021
* @description schedulable_dataCleanUp class
*/

global class schedulable_dataCleanUp implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        
        // Check whether there are new facture to create   
        database.executebatch(new batch_dataCleanUp());
    }
}