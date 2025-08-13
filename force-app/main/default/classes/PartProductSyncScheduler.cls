global class PartProductSyncScheduler implements Schedulable{
    public string CRON_EXP = '0 0 6 * * ?';
    global void execute(SchedulableContext SC){
        Database.executeBatch(new PartProductSyncBatch(),1);
        system.Schedule('Part Sync Batch',CRON_EXP, new PartProductSyncScheduler());
    }
}