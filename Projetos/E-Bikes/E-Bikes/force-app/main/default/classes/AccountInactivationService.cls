public with sharing class AccountInactivationService {
    AccountInactivation accountInactivation = new AccountInactivation();
    AccountInactivationRepository repository = new AccountInactivationRepository();

    public void checkAccountInactivation(List<Account> accounts, Map<Id, SObject> accountOldById) {
        Set<Id> inactivatedAccountIds = accountInactivation.filterInativatedAccountIds(accounts, accountOldById);
        List<Opportunity> accountOpportunities = repository.getOpenOpoportunitiesByAccountIds(inactivatedAccountIds);

        for(Opportunity opportunityToClose : accountOpportunities) {
            opportunityToClose.StageName = 'Closed Lost';
            update opportunityToClose;
        }
    }
}