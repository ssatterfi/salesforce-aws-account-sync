trigger AccountAWSSyncTrigger on Account (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountAWSSyncHandler.handleAccounts(Trigger.new);
        } else {
            AccountAWSSyncHandler.handleAccounts(Trigger.new, Trigger.oldMap);
        }
    }
}