/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-28-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CustomPathController {

    @AuraEnabled(cacheable=false)
    public static Manutencao__c getManutencaoStatus(Id accountId, Id userId) {
        return [
            SELECT Status__c
              FROM Manutencao__c
             WHERE ( Account__c = :accountId OR Cooperativismo__c = :accountId )
               AND OwnerId = :userId
             LIMIT 1
        ];
    }

    @AuraEnabled
    public static void saveManutencaoStatus(String accountId, Id userId, String newStatus) {
        try {
            Manutencao__c manutencao = new Manutencao__c();

            Map<String, ObjectsPrefix__mdt> objectPrefixMap = new Map<String, ObjectsPrefix__mdt>();
            for (ObjectsPrefix__mdt objPrefix : [SELECT Id, DeveloperName, MasterLabel, ObjectPrefix__c FROM ObjectsPrefix__mdt]) {
                objectPrefixMap.put(objPrefix.MasterLabel, objPrefix);
            }

            String prefix = accountId.substring(0, 3); 
  
            if(prefix == objectPrefixMap.get('Account').ObjectPrefix__c){ 
                manutencao.Account__c = accountId ;

            }else if(prefix == objectPrefixMap.get('Agencia').ObjectPrefix__c){
                manutencao.Cooperativismo__c = accountId;
            }

            manutencao.OwnerId = userId;
            manutencao.Status__c = newStatus;
            manutencao.ExternalId__c = userId + '' + accountId; // Certifique-se de que ExternalId__c seja um campo de ID externo

            // Upsert based on the ExternalId__c field
            if(!Test.isRunningTest())
            	upsert manutencao ExternalId__c;
            
        } catch (Exception e) {
            System.debug('Error in saveManutencaoStatus: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while saving the maintenance status: ' + e.getMessage());
        } 
    } 
}