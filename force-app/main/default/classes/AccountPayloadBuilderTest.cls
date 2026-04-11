@isTest
private class AccountPayloadBuilderTest {

    @isTest
    static void buildSlackPayload_containsBlocks() {
        Account acc = new Account(
            Name     = 'Acme Corp',
            Phone    = '555-0100',
            Website  = 'https://acme.com',
            Industry = 'Technology'
        );
        insert acc;
        acc = [SELECT Id, Name, Phone, Website, Industry FROM Account WHERE Id = :acc.Id];

        Map<String, Object> payload = AccountPayloadBuilder.buildSlackPayload(acc);

        System.assert(payload.containsKey('blocks'), 'payload must have blocks');
        List<Object> blocks = (List<Object>) payload.get('blocks');
        System.assert(blocks.size() > 0, 'blocks must not be empty');
    }

    @isTest
    static void buildSlackPayload_headerContainsNewAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        acc = [SELECT Id, Name, Phone, Website, Industry FROM Account WHERE Id = :acc.Id];

        Map<String, Object> payload = AccountPayloadBuilder.buildSlackPayload(acc);
        String serialized = JSON.serialize(payload);

        System.assert(serialized.contains('New Salesforce Account Created'), 'header text missing');
        System.assert(serialized.contains('Test Account'), 'account name missing');
    }

    @isTest
    static void buildSlackPayload_handlesNullOptionalFields() {
        Account acc = new Account(Name = 'Minimal Account');
        insert acc;
        acc = [SELECT Id, Name, Phone, Website, Industry FROM Account WHERE Id = :acc.Id];

        Map<String, Object> payload = AccountPayloadBuilder.buildSlackPayload(acc);
        String serialized = JSON.serialize(payload);

        System.assert(serialized.contains('—'), 'null fields should show dash');
    }
}
