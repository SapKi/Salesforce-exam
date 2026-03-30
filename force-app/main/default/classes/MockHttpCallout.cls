@isTest
public class MockHttpCallout implements HttpCalloutMock {
    private final Integer statusCode;
    private final String  body;

    public MockHttpCallout(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body       = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(body);
        return res;
    }
}
