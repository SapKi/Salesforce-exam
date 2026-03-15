@isTest
private class InternalCommentTriggerHandlerTest {

    // ─── Helpers ─────────────────────────────────────────────────────────────────

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    private static Boolean isWrapOn() {
        Comment_Config__mdt[] cfg = [
            SELECT Auto_Wrap__c FROM Comment_Config__mdt
            WHERE DeveloperName = 'Default' LIMIT 1
        ];
        return !cfg.isEmpty() && cfg[0].Auto_Wrap__c == true;
    }

    // ─── wrapBody unit tests ─────────────────────────────────────────────────────

    @isTest
    static void testWrapBody_shortLine_unchanged() {
        String result = InternalCommentTriggerHandler.wrapBody('Hello world', 40);
        System.assertEquals('Hello world', result, 'Short line should not change');
    }

    @isTest
    static void testWrapBody_lineAtExactLimit_unchanged() {
        String line = 'A'.repeat(40);
        String result = InternalCommentTriggerHandler.wrapBody(line, 40);
        System.assertEquals(line, result, 'Line at exact limit should not change');
    }

    @isTest
    static void testWrapBody_longLine_allLinesWithinLimit() {
        String body = 'It is a long established fact that a reader will be distracted by the readable.';
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        for (String line : result.split('\n', -1)) {
            System.assert(line.length() <= 40, 'Line exceeds limit: "' + line + '"');
        }
    }

    @isTest
    static void testWrapBody_longLine_doesNotBreakWords() {
        String body = 'It is a long established fact that a reader will be distracted by the readable.';
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        // All original words must still appear in the result
        for (String word : body.split(' ')) {
            System.assert(result.contains(word), 'Word broken or lost: "' + word + '"');
        }
    }

    @isTest
    static void testWrapBody_requirementExample_matchesExpected() {
        String body = 'hello\nIt is a long established fact that a reader will be distracted by the readable.\nbye';
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        List<String> lines = result.split('\n', -1);

        System.assertEquals('hello', lines[0], 'First line should be unchanged');
        System.assertEquals('It is a long established fact that a', lines[1]);
        System.assertEquals('reader will be distracted by the', lines[2]);
        System.assertEquals('readable.', lines[3]);
        System.assertEquals('bye', lines[4], 'Last line should be unchanged');
    }

    @isTest
    static void testWrapBody_emptyLines_removed() {
        String body = 'hello\n\nbye';
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        System.assertEquals('hello\nbye', result, 'Empty lines are removed by wrapLine');
    }

    @isTest
    static void testWrapBody_noSpaces_hardBreakAtLimit() {
        String body = 'A'.repeat(50);
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        List<String> lines = result.split('\n', -1);
        System.assertEquals('A'.repeat(40), lines[0], 'First chunk should be 40 chars');
        System.assertEquals('A'.repeat(10), lines[1], 'Remainder should be 10 chars');
    }

    @isTest
    static void testWrapBody_multipleShortLines_allUnchanged() {
        String body = 'line one\nline two\nline three';
        String result = InternalCommentTriggerHandler.wrapBody(body, 40);
        System.assertEquals(body, result, 'All short lines should be unchanged');
    }

    // ─── saveComment — success path ──────────────────────────────────────────────

    @isTest
    static void testSaveComment_shortBody_createsRecord() {
        Account acc = createAccount();

        Test.startTest();
        InternalCommentTriggerHandler.saveComment('Short comment', acc.Id);
        Test.stopTest();

        List<Internal_Comment__c> saved = [
            SELECT Body__c, Account__c FROM Internal_Comment__c WHERE Account__c = :acc.Id
        ];
        System.assertEquals(1, saved.size(), 'One record should be created');
        System.assertEquals('Short comment', saved[0].Body__c);
        System.assertEquals(acc.Id, saved[0].Account__c);
    }

    // ─── saveComment — wrap enabled ───────────────────────────────────────────────

    @isTest
    static void testSaveComment_wrapEnabled_longBodyIsSavedWrapped() {
        if (!isWrapOn()) return;
        Account acc = createAccount();
        String longBody = 'It is a long established fact that a reader will be distracted by the readable.';

        Test.startTest();
        InternalCommentTriggerHandler.saveComment(longBody, acc.Id);
        Test.stopTest();

        Internal_Comment__c saved = [SELECT Body__c FROM Internal_Comment__c WHERE Account__c = :acc.Id LIMIT 1];
        for (String line : saved.Body__c.split('\n', -1)) {
            System.assert(line.length() <= InternalCommentTriggerHandler.getMaxLineLength(),
                'Saved line exceeds limit: "' + line + '"');
        }
    }

    // ─── saveComment — wrap disabled (Req 2 error path) ─────────────────────────

    @isTest
    static void testSaveComment_wrapDisabled_longLineThrowsAuraException() {
        if (isWrapOn()) return;
        Account acc = createAccount();
        String longBody = 'This line is definitely longer than forty characters and must fail';

        Test.startTest();
        try {
            InternalCommentTriggerHandler.saveComment(longBody, acc.Id);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException correctly thrown');
        }
        Test.stopTest();

        System.assertEquals(0,
            [SELECT Id FROM Internal_Comment__c WHERE Account__c = :acc.Id].size(),
            'No record should be inserted on validation failure');
    }

    // ─── Trigger — before insert ─────────────────────────────────────────────────

    @isTest
    static void testTrigger_insert_wrapDisabled_longLineAddsDmlError() {
        if (isWrapOn()) return;
        Account acc = createAccount();

        Test.startTest();
        try {
            insert new Internal_Comment__c(
                Body__c = 'This line is definitely longer than forty characters',
                Account__c = acc.Id
            );
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Row out of boundary'),
                'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testTrigger_insert_wrapEnabled_longLineIsWrapped() {
        if (!isWrapOn()) return;
        Account acc = createAccount();
        Internal_Comment__c rec = new Internal_Comment__c(
            Body__c = 'It is a long established fact that a reader will be distracted by the readable.',
            Account__c = acc.Id
        );

        Test.startTest();
        insert rec;
        Test.stopTest();

        Internal_Comment__c saved = [SELECT Body__c FROM Internal_Comment__c WHERE Id = :rec.Id];
        for (String line : saved.Body__c.split('\n', -1)) {
            System.assert(line.length() <= InternalCommentTriggerHandler.getMaxLineLength(),
                'Line exceeds limit after trigger: "' + line + '"');
        }
    }

    @isTest
    static void testTrigger_update_wrapDisabled_longLineAddsDmlError() {
        if (isWrapOn()) return;
        Account acc = createAccount();
        Internal_Comment__c rec = new Internal_Comment__c(
            Body__c = 'Short body',
            Account__c = acc.Id
        );
        insert rec;

        Test.startTest();
        try {
            rec.Body__c = 'This updated line is definitely longer than forty characters';
            update rec;
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Row out of boundary'),
                'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testTrigger_nullBody_noError() {
        Account acc = createAccount();
        Internal_Comment__c rec = new Internal_Comment__c(
            Body__c = null,
            Account__c = acc.Id
        );

        Test.startTest();
        insert rec;
        Test.stopTest();

        System.assertEquals(1,
            [SELECT Id FROM Internal_Comment__c WHERE Account__c = :acc.Id].size(),
            'Null body should be allowed');
    }
}
