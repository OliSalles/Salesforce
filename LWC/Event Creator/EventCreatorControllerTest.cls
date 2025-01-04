@IsTest
public class EventCreatorControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Criação de um usuário de teste com permissões administrativas
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = 'System Administrator' 
                         OR Name = 'Administrador do sistema' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Criação de dados de teste com o usuário de teste
        System.runAs(testUser) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
        
            Lead testLead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company');
            insert testLead;
        
            Event testEvent = new Event(Subject = 'Test Event', StartDateTime = DateTime.now(), EndDateTime = DateTime.now().addHours(1), OwnerId = testUser.Id, WhatId = testAccount.Id);
            insert testEvent;
        }
    }

    @IsTest
    static void testGetRecordTypeId() {
        // Testar o método getRecordTypeId
        String objectApiName = 'Account';
        String recordTypeName = 'Produtor'; // Adapte de acordo com os record types disponíveis no seu ambiente
        Id recordTypeId = EventCreatorController.getRecordTypeId(objectApiName, recordTypeName);
   
    }

    @IsTest
    static void testGetTodayEvents() {
        // Testar o método getTodayEvents
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<EventCreatorController.EventWrapper> events = EventCreatorController.getTodayEvents(testAccount.Id);
    }

    @IsTest
    static void testGetEventsTimeLine() {
        // Testar o método getEventsTimeLine
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<EventCreatorController.EventWrapper> events = EventCreatorController.getEventsTimeLine(testAccount.Id);
 
    }

    @IsTest
    static void testGetPicklistValues() {
        // Testar o método getPicklistValues
        String objectName = 'Event';
        String fieldName  = 'TipoVisita__c'; 
        List<String> picklistValues = EventCreatorController.getPicklistValues(objectName, fieldName, null);
 
    } 

    @IsTest
    static void testCreateEventLead() {

        Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('GAC_Lideres_Prospeccao').getRecordTypeId();
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        // Testar o método createEvent
        String title = 'Test Event';
        String description = 'Description for test event';
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);
        String levelOne = 'Prospecção de Novos Parceiros';
        String levelTwo = 'Cadastrar Parceiro';
        String levelThree = 'Documentação Solicitada';
        String levelFour = '';
        String eventType = '';
        String recordTypeIdStr = recordTypeId;
        List<String> participants = new List<String>{lead.Id};
        Boolean recurrence = true;
        String recurrenceType = 'Diário';
        Date recurrenceEndDate = Date.today().addDays(7);
        
        Test.startTest();
        String eventId = EventCreatorController.createEvent(title, description, startDateTime, endDateTime, levelOne, levelTwo, levelThree, levelFour, eventType, recordTypeIdStr, participants, recurrence, recurrenceType, recurrenceEndDate);
        Test.stopTest(); 
    }

    @IsTest
    static void testCreateEventUser() {

        Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('GAC_Lideres_Prospeccao').getRecordTypeId();

        // Testar o método createEvent
        String title = 'Test Event';
        String description = 'Description for test event';
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);
        String levelOne = 'Prospecção de Novos Parceiros';
        String levelTwo = 'Cadastrar Parceiro';
        String levelThree = 'Documentação Solicitada';
        String levelFour = '';
        String eventType = '';
        String recordTypeIdStr = recordTypeId;
        List<String> participants = new List<String>{UserInfo.getUserId()};
        Boolean recurrence = false;
        
        Test.startTest();
        String eventId = EventCreatorController.createEvent(title, description, startDateTime, endDateTime, levelOne, levelTwo, levelThree, levelFour, eventType, recordTypeIdStr, participants, recurrence, null, null);
        Test.stopTest(); 
    }

    @IsTest
    public static void testEventWrapper() {
        // Valores de exemplo para teste
        String eventId = '00U0x0000001abc';
        String whatId = '0010x0000001xyz';
        String whoId = '0030x0000001lmn';
        String subject = 'Test Event';
        String startTime = '14:00';
        String startDate = '01/10/2024';
        
        // Instanciação do EventWrapper com os valores fornecidos
        EventCreatorController.EventWrapper eventWrapper = 
            new EventCreatorController.EventWrapper(eventId, whatId, whoId, subject, startTime, startDate);
 
    }
      
    
}