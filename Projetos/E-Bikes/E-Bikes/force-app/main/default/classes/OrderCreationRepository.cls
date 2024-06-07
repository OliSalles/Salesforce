public with sharing class OrderCreationRepository {
    public List<Account> getAccounts() {
        return [
            SELECT
                Id,
                QuantidadePedidos__c
            FROM
                Account
        ];
    }
}