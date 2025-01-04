public with sharing class CustomKanbanController {
    @AuraEnabled(cacheable=true)
    public static List<Manutencao__c> getManutencoes(Integer limitSize, Integer offsetSize) {
        return [
            SELECT Id, Name, Status__c
            FROM Manutencao__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY LastModifiedDate DESC
            LIMIT :limitSize OFFSET :offsetSize
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        // Obter os valores do picklist para Status__c
        List<String> statusValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Manutencao__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            statusValues.add(pickListVal.getLabel());
        }
        return statusValues;
    }

    @AuraEnabled
    public static void updateManutencaoStatus(Id manutencaoId, String newStatus) {
        Manutencao__c manutencao = [SELECT Id, Status__c FROM Manutencao__c WHERE Id = :manutencaoId];
        manutencao.Status__c = newStatus;
        update manutencao;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getManutencaoCountByStatus() {
        Map<String,Integer> statusCountMap = new Map<String,Integer>();

        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) total
            FROM Manutencao__c
            WHERE OwnerId = :UserInfo.getUserId()
            GROUP BY Status__c
        ];

        for(AggregateResult ar : results) {
            String status = (String)ar.get('Status__c');
            Integer count = (Integer)ar.get('total');
            statusCountMap.put(status, count);
        } 
        return statusCountMap;
    } 

    @AuraEnabled(cacheable=true)
    public static List<Manutencao__c> getManutencoesByStatus(String status, Integer limitSize, Integer offsetSize) {
        return [
            SELECT Id, Name, Status__c
            FROM Manutencao__c
            WHERE OwnerId = :UserInfo.getUserId() 
                AND Status__c = :status
            ORDER BY LastModifiedDate DESC
            LIMIT :limitSize OFFSET :offsetSize
        ];
    }
} 
