global class ScheduledBatch_BatchAssetCalculator implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        
        // run batchcalculator 
        database.executebatch(new BatchAssetCalculator());
    }
}