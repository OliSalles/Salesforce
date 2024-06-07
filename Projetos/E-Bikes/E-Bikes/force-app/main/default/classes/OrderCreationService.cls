public with sharing class OrderCreationService {
    OrderCreation orderCreation = new OrderCreation();

    public void incrementAccountOrderQuantity(List<Order__c> orders) {
        orderCreation.incrementAccountOrderQuantity(orders);
    }

    public void checkStatus(List<Order__c> orders, Map<Id, SObject> mapOldOrdersById) {
        List<Order__c> ordersToProcess = new List<Order__c>();

        for(Order__c order : orders) {
            Order__c oldOrder = (Order__c) mapOldOrdersById.get(order.Id);

            if(order.Status__c == 'In Production' && oldOrder.Status__c != order.Status__c) {
                ordersToProcess.add(order);
            }
        }
    }
}