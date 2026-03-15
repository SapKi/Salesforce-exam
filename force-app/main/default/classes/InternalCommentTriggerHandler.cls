public class InternalCommentTriggerHandler {

    private static final Integer DEFAULT_MAX_LEN = 40;

    // ─── Entry point ────────────────────────────────────────────────────────────

    public static void handleBeforeUpsert(List<Internal_Comment__c> records) {
        Integer maxLen = getMaxLineLength();

        for (Internal_Comment__c rec : records) {
            if (rec.Body__c == null) continue;

            // Requirement 2 (base): validate every line – fail if any line > limit
            // Bonus Requirement 2: wrap lines instead of erroring (limit is configurable)
            if (isWrapEnabled()) {
                rec.Body__c = wrapBody(rec.Body__c, maxLen);
            } else {
                validateBody(rec, maxLen);
            }
        }
    }

    // ─── Requirement 2: validate and throw error ────────────────────────────────

    private static void validateBody(Internal_Comment__c rec, Integer maxLen) {
        for (String line : rec.Body__c.split('\n', -1)) {
            if (line.length() > maxLen) {
                rec.addError('Row out of boundary of ' + maxLen + ' character');
                return;
            }
        }
    }

    // ─── Bonus Requirement 2: word-wrap ─────────────────────────────────────────

    @TestVisible
    static String wrapBody(String body, Integer maxLen) {
        List<String> outputLines = new List<String>();
        for (String line : body.split('\n', -1)) {
            outputLines.addAll(wrapLine(line, maxLen));
        }
        return String.join(outputLines, '\n');
    }

    private static List<String> wrapLine(String line, Integer maxLen) {
        List<String> result = new List<String>();
        while (line.length() > maxLen) {
            String chunk = line.substring(0, maxLen);
            Integer lastSpace = chunk.lastIndexOf(' ');
            if (lastSpace <= 0) {
                // No space found – hard break at limit
                result.add(chunk);
                line = line.substring(maxLen);
            } else {
                result.add(line.substring(0, lastSpace));
                line = line.substring(lastSpace + 1);
            }
        }
        if (line.length() > 0) {
            result.add(line);
        }
        return result;
    }

    // ─── AuraEnabled method called from LWC ─────────────────────────────────────

    @AuraEnabled
    public static void saveComment(String body, Id accountId) {
        Integer maxLen = getMaxLineLength();

        if (isWrapEnabled()) {
            body = wrapBody(body, maxLen);
        } else {
            for (String line : body.split('\n', -1)) {
                if (line.length() > maxLen) {
                    throw new AuraHandledException(
                        'Row out of boundary of ' + maxLen + ' character'
                    );
                }
            }
        }

        insert new Internal_Comment__c(
            Body__c = body,
            Account__c = accountId
        );
    }

    // ─── Custom Metadata helpers ─────────────────────────────────────────────────

    @TestVisible
    static Integer getMaxLineLength() {
        Comment_Config__mdt[] cfg = [
            SELECT Max_Line_Length__c
            FROM Comment_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return (!cfg.isEmpty() && cfg[0].Max_Line_Length__c != null)
            ? Integer.valueOf(cfg[0].Max_Line_Length__c)
            : DEFAULT_MAX_LEN;
    }

    @TestVisible
    static Boolean isWrapEnabled() {
        Comment_Config__mdt[] cfg = [
            SELECT Auto_Wrap__c
            FROM Comment_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return !cfg.isEmpty() && cfg[0].Auto_Wrap__c == true;
    }
}
