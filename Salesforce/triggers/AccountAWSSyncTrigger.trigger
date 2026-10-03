trigger AccountAWSSyncTrigger on Account (after insert, after update) {
    if (Trigger.isAfter) {
        AccountAWSSyncHandler.handleAccounts(Trigger.new);
    }
}