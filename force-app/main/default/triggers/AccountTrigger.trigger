trigger AccountTrigger on Account (after insert) {
    AccountTriggerHandler.onAfterInsert(Trigger.new);
}
