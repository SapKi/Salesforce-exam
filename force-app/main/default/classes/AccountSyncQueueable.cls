public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public AccountSyncQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [
            SELECT Id, Name, Phone, Website, Industry
            FROM Account
            WHERE Id IN :accountIds
        ];

        List<Account> toUpdate = new List<Account>();

        for (Account acc : accounts) {
            Map<String, Object> payload = AccountPayloadBuilder.buildSlackPayload(acc);
            Account updatedAcc = new Account(Id = acc.Id, Last_Sync_DateTime__c = Datetime.now());

            try {
                IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
                updatedAcc.Last_Sync_Status__c      = result.isSuccess ? 'Success' : 'Failed';
                updatedAcc.Last_Response_Code__c    = result.statusCode;
                updatedAcc.Last_Response_Message__c = result.responseBody != null
                    ? result.responseBody.abbreviate(255)
                    : '';
            } catch (Exception e) {
                updatedAcc.Last_Sync_Status__c      = 'Failed';
                updatedAcc.Last_Response_Code__c    = 0;
                updatedAcc.Last_Response_Message__c = e.getMessage().abbreviate(255);
            }

            toUpdate.add(updatedAcc);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
