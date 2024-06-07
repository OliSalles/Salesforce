public with sharing class AccountInactivationRepository {
    public List<Opportunity> getOpenOpoportunitiesByAccountIds(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                StageName
            FROM 
                Opportunity
            WHERE 
                AccountId IN: accountIds
                AND
                StageName != 'Closed Won'
                AND
                StageName != 'Closed Lost'
        ];
    }
}