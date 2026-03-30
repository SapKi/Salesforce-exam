public with sharing class AccountSyncButtonController {
    @AuraEnabled
    public static void syncAccount(Id accountId) {
        System.enqueueJob(new AccountSyncQueueable(new Set<Id>{ accountId }));
    }
}
