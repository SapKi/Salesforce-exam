public class AccountPayloadBuilder {
    public static Map<String, Object> buildPayload(Account acc) {
        return new Map<String, Object>{
            'id'       => acc.Id,
            'name'     => acc.Name,
            'phone'    => acc.Phone,
            'website'  => acc.Website,
            'industry' => acc.Industry
        };
    }
}
