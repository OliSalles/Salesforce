public with sharing class AccountCreation {
    @future(callout=true)
    public static void getAdvice(String accountsJson) {
        List<Account> accounts = (List<Account>) JSON.deserialize(accountsJson, List<Account>.class);

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://api.adviceslip.com/advice');

        Http http = new Http();
        HTTPResponse response = http.send(request);

        String jsonResponse = response.getBody();

        AccountCreationSchema jsonParse = (AccountCreationSchema) JSON.deserialize(jsonResponse, AccountCreationSchema.class);

        for(Account accountRecord : accounts) {
            accountRecord.Conselho__c = jsonParse.slip.advice;
        }

        update accounts;

        System.debug(jsonParse);
    }
}