@isTest
private class AccountSyncButtonControllerTest {

    private static void setEndpoint() {
        IntegrationService.endpointBaseOverride = 'https://jsonplaceholder.typicode.com';
    }

    @isTest
    static void syncAccount_queuesJobSuccessfully() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(201, '{"id":1}'));

        Account acc = new Account(Name = 'Button Test Account');
        insert acc;

        Test.startTest();
        AccountSyncButtonController.syncAccount(acc.Id);
        Test.stopTest();

        Account updated = [
            SELECT Last_Sync_Status__c, Last_Response_Code__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals('Success', updated.Last_Sync_Status__c);
        System.assertEquals(201,       (Integer)updated.Last_Response_Code__c);
    }

    @isTest
    static void syncAccount_setsFailedStatus_onApiError() {
        setEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(500, 'Error'));

        Account acc = new Account(Name = 'Button Fail Account');
        insert acc;

        Test.startTest();
        AccountSyncButtonController.syncAccount(acc.Id);
        Test.stopTest();

        Account updated = [SELECT Last_Sync_Status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed', updated.Last_Sync_Status__c);
    }
}
