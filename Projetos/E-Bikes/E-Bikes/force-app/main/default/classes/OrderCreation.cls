public with sharing class OrderCreation {
    OrderCreationRepository repository = new OrderCreationRepository();

    public void incrementAccountOrderQuantity(List<Order__c> orders) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Account> accounts = repository.getAccounts();

        for(Order__c orderRecord : orders) {
            for(Account accountRecord : accounts) {
                if(orderRecord.Account__c == accountRecord.Id) {
                    Decimal numberOfOrders = accountRecord.QuantidadePedidos__c;

                    if(numberOfOrders == null) {
                        numberOfOrders = 0;
                    }

                    numberOfOrders += 1;
                    accountRecord.QuantidadePedidos__c = numberOfOrders;
                    accountsToUpdate.add(accountRecord);
                }
            }
        }

        if(!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public class TooManyRowsException extends Exception {}
}