public class IntegrationService {

    public class IntegrationResult {
        public Integer statusCode;
        public String  responseBody;
        public Boolean isSuccess;
    }

    @TestVisible
    private static String endpointBaseOverride;

    private static String getWebhookUrl() {
        if (endpointBaseOverride != null) {
            return endpointBaseOverride;
        }
        Integration_Config__mdt config = [
            SELECT Endpoint_URL__c
            FROM Integration_Config__mdt
            WHERE DeveloperName = 'JsonPlaceholder'
            LIMIT 1
        ];
        return config.Endpoint_URL__c;
    }

    public static IntegrationResult postAccount(Map<String, Object> payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getWebhookUrl());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);

        IntegrationResult result  = new IntegrationResult();
        result.statusCode   = res.getStatusCode();
        result.responseBody = res.getBody();
        result.isSuccess    = (res.getStatusCode() >= 200 && res.getStatusCode() < 300);
        return result;
    }
}
