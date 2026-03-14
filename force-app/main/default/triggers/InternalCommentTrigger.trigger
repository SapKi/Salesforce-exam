trigger InternalCommentTrigger on Internal_Comment__c (before insert, before update) {
    InternalCommentTriggerHandler.handleBeforeUpsert(Trigger.new);
}
