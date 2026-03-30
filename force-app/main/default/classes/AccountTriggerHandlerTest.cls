@isTest
private class AccountTriggerHandlerTest {

    private static void setEndpoint() {
        IntegrationService.endpointBaseOverride = 'https://jsonplaceholder.typicode.com';
    }

    @isTest
    static void trigger_enqueuesJob_andSyncsOnInsert() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(201, '{"id":1}'));

        Test.startTest();
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;
        Test.stopTest();

        Account updated = [
            SELECT Last_Sync_Status__c, Last_Response_Code__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals('Success', updated.Last_Sync_Status__c);
        System.assertEquals(201,       (Integer)updated.Last_Response_Code__c);
    }

    @isTest
    static void trigger_setsFailedStatus_onApiError() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(503, 'Service Unavailable'));

        Test.startTest();
        Account acc = new Account(Name = 'Trigger Fail Account');
        insert acc;
        Test.stopTest();

        Account updated = [SELECT Last_Sync_Status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed', updated.Last_Sync_Status__c);
    }

    @isTest
    static void trigger_handlesBulkInsert() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"id":1}'));

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i));
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> updated = [
            SELECT Last_Sync_Status__c FROM Account WHERE Id IN :accounts
        ];
        System.assertEquals(5, updated.size());
        for (Account a : updated) {
            System.assertEquals('Success', a.Last_Sync_Status__c);
        }
    }
}
