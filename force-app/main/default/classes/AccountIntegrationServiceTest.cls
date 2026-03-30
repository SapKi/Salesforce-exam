@isTest
private class AccountIntegrationServiceTest {

    private static void setupEndpoint() {
        IntegrationService.endpointBaseOverride = 'https://jsonplaceholder.typicode.com';
    }

    @isTest
    static void postAccount_returnsSuccess_on2xx() {
        setupEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(201, '{"id":101,"title":"test"}'));

        Map<String, Object> payload = new Map<String, Object>{
            'id'       => 'a00000000000001AAA',
            'name'     => 'Test Corp',
            'phone'    => '555-0199',
            'website'  => 'https://test.com',
            'industry' => 'Finance'
        };

        Test.startTest();
        IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
        Test.stopTest();

        System.assertEquals(201,                         result.statusCode,   'status code');
        System.assertEquals(true,                        result.isSuccess,    'isSuccess');
        System.assertEquals('{"id":101,"title":"test"}', result.responseBody, 'body');
    }

    @isTest
    static void postAccount_returnsFailure_on5xx() {
        setupEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(500, 'Internal Server Error'));

        Map<String, Object> payload = new Map<String, Object>{ 'id' => 'x', 'name' => 'X' };

        Test.startTest();
        IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
        Test.stopTest();

        System.assertEquals(500,   result.statusCode);
        System.assertEquals(false, result.isSuccess);
    }

    @isTest
    static void postAccount_returnsFailure_on4xx() {
        setupEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(404, 'Not Found'));

        Map<String, Object> payload = new Map<String, Object>{ 'id' => 'x', 'name' => 'X' };

        Test.startTest();
        IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
        Test.stopTest();

        System.assertEquals(404,   result.statusCode);
        System.assertEquals(false, result.isSuccess);
    }
}
