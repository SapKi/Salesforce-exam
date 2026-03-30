public class AccountTriggerHandler {
    public static void onAfterInsert(List<Account> newAccounts) {
        Set<Id> accountIds = new Map<Id, Account>(newAccounts).keySet();
        System.enqueueJob(new AccountSyncQueueable(accountIds));
    }
}
