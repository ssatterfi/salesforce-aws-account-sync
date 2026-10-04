public class AccountAWSSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> accountIds;

    public AccountAWSSyncQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        AccountAWSSyncHandler.doCalloutAndUpdate(accountIds);
    }
}
