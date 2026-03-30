@isTest
private class AccountSyncQueueableTest {

    @TestSetup
    static void setup() {
        IntegrationService.endpointBaseOverride = 'https://jsonplaceholder.typicode.com';
    }

    private static void setEndpoint() {
        IntegrationService.endpointBaseOverride = 'https://jsonplaceholder.typicode.com';
    }

    @isTest
    static void execute_setsSuccessFields_on2xx() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(201, '{"id":101}'));

        Account acc = new Account(Name = 'Queueable Success');
        insert acc;

        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(new Set<Id>{ acc.Id }));
        Test.stopTest();

        Account updated = [
            SELECT Last_Sync_Status__c, Last_Response_Code__c,
                   Last_Response_Message__c, Last_Sync_DateTime__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals('Success', updated.Last_Sync_Status__c);
        System.assertEquals(201,       (Integer)updated.Last_Response_Code__c);
        System.assertNotEquals(null,   updated.Last_Sync_DateTime__c);
    }

    @isTest
    static void execute_setsFailedFields_on5xx() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(500, 'Server Error'));

        Account acc = new Account(Name = 'Queueable Failure');
        insert acc;

        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(new Set<Id>{ acc.Id }));
        Test.stopTest();

        Account updated = [
            SELECT Last_Sync_Status__c, Last_Response_Code__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals('Failed', updated.Last_Sync_Status__c);
        System.assertEquals(500,      (Integer)updated.Last_Response_Code__c);
    }

    @isTest
    static void execute_handlesMultipleAccounts() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"id":1}'));

        Account acc1 = new Account(Name = 'Multi Account 1');
        Account acc2 = new Account(Name = 'Multi Account 2');
        insert new List<Account>{ acc1, acc2 };

        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(new Set<Id>{ acc1.Id, acc2.Id }));
        Test.stopTest();

        List<Account> updated = [
            SELECT Last_Sync_Status__c FROM Account WHERE Id IN (:acc1.Id, :acc2.Id)
        ];
        for (Account a : updated) {
            System.assertEquals('Success', a.Last_Sync_Status__c);
        }
    }
}
