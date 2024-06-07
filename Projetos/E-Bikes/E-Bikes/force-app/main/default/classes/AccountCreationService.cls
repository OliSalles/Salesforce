public with sharing class AccountCreationService {
    public void getAdvice(List<Account> accounts) {
        if (accounts.size() == 1) { // Skip when running data load via batch
            AccountCreation.getAdvice(JSON.serialize(accounts));
        }
    }
}