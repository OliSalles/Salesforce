public with sharing class OrderTriggerHandler implements TriggerHandler{
    OrderCreationService orderCreationService = new OrderCreationService();

    public void beforeInsert(List<Order__c> newOrders) {
    }

    public void beforeUpdate(List<Order__c> oldOrders, List<Order__c> newOrders, Map<ID, SObject> oldOrderMap, Map<ID, SObject> newOrderMap) {
    }

    public void beforeDelete(List<Order__c> oldOrders, Map<ID, SObject> oldOrderMap) {
    }

    public void afterInsert(List<Order__c> newOrders, Map<ID, SObject> newOrderMap) {
        orderCreationService.incrementAccountOrderQuantity(newOrders);
    }

    public void afterUpdate(List<Order__c> oldOrders, List<Order__c> newOrders, Map<ID, SObject> oldOrderMap, Map<ID, SObject> newOrderMap) {
        orderCreationService.checkStatus(newOrders, oldOrderMap);
    }

    public void afterDelete(List<Order__c> oldOrders, Map<ID, SObject> oldOrderMap) {
    }

    public void afterUndelete(List<Order__c> newOrders, Map<ID, SObject> newOrderMap) {
    }
}