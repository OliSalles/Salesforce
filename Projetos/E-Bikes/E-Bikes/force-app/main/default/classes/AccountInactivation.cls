public with sharing class AccountInactivation {
    public Set<Id> filterInativatedAccountIds(List<Account> accounts, Map<Id, SObject> accountOldById) {
        Set<Id> inactivatedAccountIds = new Set<Id>();

        for(Account account : accounts) {
            Account oldAccount = (Account) accountOldById.get(account.Id);

            if(account.Status__c == 'Inactive' && account.Status__c != oldAccount.Status__c) {
                inactivatedAccountIds.add(account.Id);
            }
        }

        return inactivatedAccountIds;
    }
}