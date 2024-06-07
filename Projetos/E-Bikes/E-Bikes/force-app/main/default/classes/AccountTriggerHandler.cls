public with sharing class AccountTriggerHandler implements TriggerHandler{
    AccountInactivationService accountInactivationService = new AccountInactivationService();
    AccountCreationService accountCreationService = new AccountCreationService();
    public void beforeInsert(List<Account> newAccounts) {
    }

    public void beforeUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
    }

    public void beforeDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {
    }

    public void afterInsert(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {
        accountCreationService.getAdvice(newAccounts);
    }

    public void afterUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
        accountInactivationService.checkAccountInactivation(newAccounts, oldAccountMap);
    }

    public void afterDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {
    }

    public void afterUndelete(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {
    }
}