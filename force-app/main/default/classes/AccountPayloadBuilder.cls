public class AccountPayloadBuilder {

    public static Map<String, Object> buildSlackPayload(Account acc) {
        String accountUrl = URL.getOrgDomainUrl().toExternalForm()
            + '/' + acc.Id;

        List<Object> fields = new List<Object>{
            new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*Name:*\n' + acc.Name
            },
            new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*Industry:*\n' + (acc.Industry != null ? acc.Industry : '—')
            },
            new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*Phone:*\n' + (acc.Phone != null ? acc.Phone : '—')
            },
            new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => '*Website:*\n' + (acc.Website != null ? acc.Website : '—')
            }
        };

        List<Object> blocks = new List<Object>{
            new Map<String, Object>{
                'type' => 'header',
                'text' => new Map<String, Object>{
                    'type' => 'plain_text',
                    'text' => 'New Salesforce Account Created'
                }
            },
            new Map<String, Object>{
                'type' => 'section',
                'fields' => fields
            },
            new Map<String, Object>{
                'type' => 'section',
                'text' => new Map<String, Object>{
                    'type' => 'mrkdwn',
                    'text' => '<' + accountUrl + '|View in Salesforce>'
                }
            },
            new Map<String, Object>{
                'type' => 'divider'
            }
        };

        return new Map<String, Object>{ 'blocks' => blocks };
    }
}
