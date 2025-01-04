/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EventCreatorController {

    @AuraEnabled(cacheable=true)
    public static Id getRecordTypeId(String objectApiName, String recordTypeName) {
        
        try {
            Schema.DescribeSObjectResult sObjectResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Map<String,Schema.RecordTypeInfo> recordTypeInfos = sObjectResult.getRecordTypeInfosByName();
            Id recordTypeId = recordTypeInfos.get(recordTypeName).getRecordTypeId();
            return recordTypeId;
        
        } catch (Exception e) {
            throw new AuraHandledException('Erro ao buscar o ID do tipo de registro: ' + e.getMessage());
        }
    } 

    @AuraEnabled(cacheable=false)
    public static List<EventWrapper> getTodayEvents( Id recordId ) {
        Date today = Date.today();
        List<EventWrapper> eventList = new List<EventWrapper>();

        List<Event> listEvents = new List<Event>();

        if(recordId != null){
            listEvents = [ SELECT Id, WhatId, WhoId, Subject, StartDateTime, EndDateTime
                             FROM Event
                            WHERE OwnerId = :UserInfo.getUserId()
                              AND ActivityDate = :today
                              AND ( WhatId = :recordId OR WhoId = :recordId )
                         ORDER BY StartDateTime ASC
                    ];
        }else{
            listEvents = [ SELECT Id, WhatId, WhoId, Subject, StartDateTime, EndDateTime
                             FROM Event
                            WHERE OwnerId = :UserInfo.getUserId()
                              AND ActivityDate = :today 
                         ORDER BY StartDateTime ASC
                    ];
        }
        
        for (Event evt : listEvents) {
            // Formata apenas a hora de StartDateTime e adiciona à lista de eventos
            eventList.add(new EventWrapper(evt.Id, evt.WhatId, evt.WhoId, evt.Subject, evt.StartDateTime.format('HH:mm'), evt.StartDateTime.format('dd-MM-yy').replace('-', '/') ));
        }
        return eventList;
    } 

    @AuraEnabled(cacheable=false)
    public static List<EventWrapper> getEventsTimeLine( Id recordId ) {
        Date today = Date.today();
        List<EventWrapper> eventList = new List<EventWrapper>();

        List<Event> listEvents = new List<Event>();

        if(recordId != null){
            listEvents = [ SELECT Id, WhatId, WhoId, Subject, StartDateTime, EndDateTime
                             FROM Event
                            WHERE OwnerId = :UserInfo.getUserId()
                              AND ActivityDate != :today
                              AND ( WhatId = :recordId OR WhoId = :recordId )
                         ORDER BY StartDateTime ASC
                    ];
        } 

        System.debug('listEvents ===> ' + listEvents);
        
        for (Event evt : listEvents) {

            if( evt.Subject != null && evt.Subject.length() > 30){
                evt.Subject = evt.Subject.substring(0, 30); 
            }
                                  
            // Formata apenas a hora de StartDateTime e adiciona à lista de eventos
            eventList.add(new EventWrapper(evt.Id, evt.WhatId, evt.WhoId, evt.Subject, evt.StartDateTime.format('HH:mm'), evt.StartDateTime.format('dd-MM-yy').replace('-', '/') ));
        }
        return eventList;
    } 

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectName, String fieldName, String recordTypeId ) {
        List<String> picklistValues = new List<String>();
        
        // Obtenha a descrição do objeto
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        
        // Obtenha a descrição do campo
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldName).getDescribe();
        
        // Obtenha os valores do picklist baseado no Record Type
        if (recordTypeId == null) {
            recordTypeId = describeResult.getRecordTypeInfosByName().get('Prospecção de Novos Parceiros').getRecordTypeId();
        }
        
        List<Schema.RecordTypeInfo> recordTypeInfos = describeResult.getRecordTypeInfos();
        for (Schema.RecordTypeInfo recordTypeInfo : recordTypeInfos) {
            if (recordTypeInfo.getRecordTypeId() == recordTypeId) { 
                
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    if (entry.isActive()) {
                        picklistValues.add(entry.getValue());
                    }
                }
                break;
            }
        }
        return picklistValues;
    } 

    public class EventWrapper {
        @AuraEnabled public String eventId   { get; set; }
        @AuraEnabled public String whatId    { get; set; }
        @AuraEnabled public String whoId     { get; set; }
        @AuraEnabled public String subject   { get; set; }
        @AuraEnabled public String startTime { get; set; }
        @AuraEnabled public String startDate { get; set; }

        public EventWrapper(String eventId, String whatId, String whoId, String subject, String startTime, String startDate) {
            this.eventId    = eventId;
            this.whatId     = whatId;
            this.whoId      = whoId;
            this.subject    = subject;
            this.startTime  = startTime;
            this.startDate  = startDate;
        }
    }
 
    public static String createEvent(
        String title, 
        String description, 
        DateTime startDateTime, 
        DateTime endDateTime, 
        String levelOne, 
        String levelTwo, 
        String levelThree, 
        String levelFour,
        String eventType,
        String recordTypeIdStr,  
        List<String> participants){

            return createEvent( title, description, startDateTime, endDateTime, levelOne, levelTwo, levelThree, levelFour, eventType, recordTypeIdStr, participants, false, null, null);
    }

    @AuraEnabled
    public static String createEvent(
        String title, 
        String description, 
        DateTime startDateTime, 
        DateTime endDateTime, 
        String levelOne, 
        String levelTwo, 
        String levelThree, 
        String levelFour,
        String eventType,
        String recordTypeIdStr,  
        List<String> participants,
        Boolean recurrence,
        String recurrenceType,
        Date recurrenceEndDate ) {

        BusinessHours standardBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Id standardBusinessHoursId = standardBusinessHours.Id;
        
        List<Event> listEvents = new List<Event>();
        
        Event newEvent = new Event(
            Subject = title,
            Description = description,
            StartDateTime = startDateTime,
            EndDateTime = endDateTime,
            Nivel_1__c = levelOne,
            Nivel_2__c = levelTwo,
            Nivel_3__c = levelThree,
            Nivel_4__c = levelFour,
            TipoVisita__c = eventType != null? eventType : '',
            recordTypeId = recordTypeIdStr
        );

        if(participants.size() > 0){

            Map<String, ObjectsPrefix__mdt> objectPrefixMap = new Map<String, ObjectsPrefix__mdt>();
            for (ObjectsPrefix__mdt objPrefix : [SELECT Id, DeveloperName, MasterLabel, ObjectPrefix__c FROM ObjectsPrefix__mdt]) {
                objectPrefixMap.put(objPrefix.MasterLabel, objPrefix);
            }
            String prefix = participants[0].substring(0, 3); 

            if( prefix == objectPrefixMap.get('User').ObjectPrefix__c ){
                newEvent.OwnerId = UserInfo.getUserId(); 
                listEvents.add( newEvent );
                
                for(String participant : participants){

                    Event eventClone = newEvent.clone(); 
                
                    eventClone.OwnerId = participant;  

                    listEvents.add( eventClone );
                }    

            }else if(prefix == objectPrefixMap.get('Lead').ObjectPrefix__c){
                Integer taskCount = calculateRecurrence(recurrence, recurrenceType, recurrenceEndDate, Date.today());
                System.debug('taskCount ==>>' + taskCount);

                for(String participant : participants){
                    for(Integer i = 0; i < taskCount; i++){
                        Event eventClone = newEvent.clone();
                        DateTime startDate = newEvent.StartDateTime.addDays(i * (recurrenceType == 'Diário' ? 1 : (recurrenceType == 'Semanal' ? 7 : 30)));
                        DateTime endDate = newEvent.EndDateTime.addDays(i * (recurrenceType == 'Diário' ? 1 : (recurrenceType == 'Semanal' ? 7 : 30)));
                        
                        startDate = adjustToNextBusinessDay(startDate, standardBusinessHoursId);
                        endDate = adjustToNextBusinessDay(endDate, standardBusinessHoursId);
                        
                        Boolean alreadyExistsForDay = false;
                        for (Event existingEvent : listEvents) {
                            if(existingEvent.StartDateTime.date() == startDate.date() && existingEvent.WhoId == participant){
                                alreadyExistsForDay = true;
                                break;
                            }
                        }
                        
                        if(!alreadyExistsForDay){
                            eventClone.StartDateTime = startDate;
                            eventClone.EndDateTime = endDate;
                            eventClone.WhoId = participant;

                            listEvents.add(eventClone);
                        }
                    }
                }
                System.debug('listEvents ==>>' + listEvents); 

            }else if(prefix == objectPrefixMap.get('Account').ObjectPrefix__c || prefix == objectPrefixMap.get('Agencia').ObjectPrefix__c){
 
                for(String participant : participants){

                    Event eventClone = newEvent.clone(); 
                
                    eventClone.whatId = participant;  

                    listEvents.add( eventClone );
                }    

            }else if(prefix == objectPrefixMap.get('Manutencao').ObjectPrefix__c){ 

                Map<String, Manutencao__c> mapManutencao = new Map<String, Manutencao__c> ( [SELECT Id, Account__c, Cooperativismo__c 
                                                                                               FROM Manutencao__c 
                                                                                              WHERE Id IN : participants ] );

                for(String idParticipant : participants){

                    Event eventClone = newEvent.clone(); 

                    system.debug(mapManutencao);
                    Manutencao__c manutencao = mapManutencao.get( idParticipant );
                
                    eventClone.whatId = manutencao.Account__c != null ? manutencao.Account__c : manutencao.Cooperativismo__c;  

                    listEvents.add( eventClone );
                }    
            }  
        }else{
            newEvent.OwnerId = UserInfo.getUserId(); 
            listEvents.add( newEvent );
        }

        System.debug('listEvents ===> ' + listEvents);
        
        insert listEvents;
        
        return newEvent.Id;
    }

    private static Integer calculateRecurrence(Boolean recurrence, String recurrenceType, Date recurrenceEndDate, Date currentDate){
        if(recurrence){
            Integer taskCount = 0;
            
            if(recurrenceType == 'Diário'){
                Integer dayDifference = currentDate.daysBetween(recurrenceEndDate);
                taskCount = dayDifference + 1;
            
            }else if(recurrenceType == 'Semanal'){
                Integer weekDifference = currentDate.daysBetween(recurrenceEndDate) / 7;
                taskCount = weekDifference + 1;

            }else if(recurrenceType == 'Mensal'){
                Integer monthDifference = currentDate.monthsBetween(recurrenceEndDate);
                taskCount = monthDifference + 1;
            }
            
            return taskCount;
        } else{
            return 1;
        }
    }

    private static DateTime adjustToNextBusinessDay(DateTime eventDate, Id businessHoursId) {
        if (!BusinessHours.isWithin(businessHoursId, eventDate)) {
            while (!BusinessHours.isWithin(businessHoursId, eventDate)) {
                eventDate = eventDate.addDays(1);
            }
        }
        return eventDate;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, ObjectsPrefix__mdt> getObjPrefix() {
        try {
            Map<String, ObjectsPrefix__mdt> objectPrefixMap = new Map<String, ObjectsPrefix__mdt>();
            
            for (ObjectsPrefix__mdt objPrefix : [SELECT Id, DeveloperName, MasterLabel, ObjectPrefix__c FROM ObjectsPrefix__mdt]) {
                objectPrefixMap.put(objPrefix.MasterLabel, objPrefix);
            }

            // Retorna o valor do campo se o registro for encontrado
            if (!objectPrefixMap.isEmpty()) {
                return objectPrefixMap;
            } else {
                return null;
            }
        } catch (Exception e) {
            // Lidar com exceções, como registro não encontrado
            System.debug(e);
            return null;
        }
    }
}