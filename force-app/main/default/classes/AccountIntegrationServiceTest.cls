@isTest
private class AccountIntegrationServiceTest {

    private static final String MOCK_WEBHOOK = 'https://hooks.slack.com/services/TEST/TEST/TEST';

    private static void setupEndpoint() {
        IntegrationService.endpointBaseOverride = MOCK_WEBHOOK;
    }

    @isTest
    static void postAccount_returnsSuccess_on2xx() {
        setupEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, 'ok'));

        Map<String, Object> payload = new Map<String, Object>{
            'blocks' => new List<Object>()
        };

        Test.startTest();
        IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
        Test.stopTest();

        System.assertEquals(200,  result.statusCode);
        System.assertEquals(true, result.isSuccess);
        System.assertEquals('ok', result.responseBody);
    }

    @isTest
    static void postAccount_returnsFailure_on5xx() {
        setupEndpoint();
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout(500, 'Internal Server Error'));

        Map<String, Object> payload = new Map<String, Object>{ 'blocks' => new List<Object>() };

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

        Map<String, Object> payload = new Map<String, Object>{ 'blocks' => new List<Object>() };

        Test.startTest();
        IntegrationService.IntegrationResult result = IntegrationService.postAccount(payload);
        Test.stopTest();

        System.assertEquals(404,   result.statusCode);
        System.assertEquals(false, result.isSuccess);
    }
}
