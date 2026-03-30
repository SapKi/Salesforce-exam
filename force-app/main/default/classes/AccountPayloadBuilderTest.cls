@isTest
private class AccountPayloadBuilderTest {

    @isTest
    static void buildPayload_mapsAllFields() {
        Account acc = new Account(
            Name     = 'Acme Corp',
            Phone    = '555-0100',
            Website  = 'https://acme.com',
            Industry = 'Technology'
        );
        insert acc;
        acc = [SELECT Id, Name, Phone, Website, Industry FROM Account WHERE Id = :acc.Id];

        Map<String, Object> payload = AccountPayloadBuilder.buildPayload(acc);

        System.assertEquals(acc.Id,            payload.get('id'),       'id mismatch');
        System.assertEquals('Acme Corp',        payload.get('name'),     'name mismatch');
        System.assertEquals('555-0100',         payload.get('phone'),    'phone mismatch');
        System.assertEquals('https://acme.com', payload.get('website'),  'website mismatch');
        System.assertEquals('Technology',       payload.get('industry'), 'industry mismatch');
    }

    @isTest
    static void buildPayload_handlesNullOptionalFields() {
        Account acc = new Account(Name = 'Minimal Account');
        insert acc;
        acc = [SELECT Id, Name, Phone, Website, Industry FROM Account WHERE Id = :acc.Id];

        Map<String, Object> payload = AccountPayloadBuilder.buildPayload(acc);

        System.assertEquals(acc.Id,             payload.get('id'));
        System.assertEquals('Minimal Account',  payload.get('name'));
        System.assertNotEquals(null, payload, 'payload should not be null');
    }
}
