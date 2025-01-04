@isTest
public class PriceItemImportControllerTest {

    @TestSetup
    static void setupTestData() {
        // Criar dados comuns para todos os testes
        Market_Product_Type__c newMarkerProgType = ObjectFactory.getMarketProductType();
        insert newMarkerProgType;

        // Criar registros de Bundle
        Bundle__c bundle = ObjectFactory.getBundle('TestCaseDemo', newMarkerProgType);
        insert bundle;
        
        // Criação de Program Groups relacionados ao Bundle
        Program_Group__c pg1 = new Program_Group__c(Name = 'Group 1', Product__c = bundle.Id);
        Program_Group__c pg2 = new Program_Group__c(Name = 'Group 2', Product__c = bundle.Id);
        insert new List<Program_Group__c> {pg1, pg2};

        Location__c location = ObjectFactory.getLocation();
        insert location;

        // Criar registro de JSON_Event_Log__c para Retry
        JSON_Event_Log__c logPriceItem = new JSON_Event_Log__c(
            Event_status__c = 'Not Published',
            Cod_Execucao__c = '102030405060708090',
            Status_Message__c = 'Registros para Retry',
            Tipo__c = 'Retry PriceItem',
            Record_Id__c = bundle.Id,
            JSON_object__c = '{"commercialCapacity": 100, "pricePerUnit": 50, "unit": "Test Unit", "aMAPMediaType": "TV", "description": "Retry Item", "frequency": "Weekly", "locationId": null, "tipoDeFormato": "Retry Format", "totalQuantity": 500, "minCommercialCapacity": 20, "faixaHoraria": "9-13", "diasDaSemana": "Tuesday", "discount": 0.2, "spotLenght": 40}'
        );
        insert logPriceItem;

        // Criar registro de JSON_Event_Log__c para Retry
        JSON_Event_Log__c logRelation = new JSON_Event_Log__c(
            Event_status__c = 'Not Published',
            Cod_Execucao__c = '203040506070809010',
            Status_Message__c = 'Registros para Retry',
            Tipo__c = 'Retry Relation',
            Record_Id__c = bundle.Id,
            JSON_object__c = '{ "Item_de_Preco__c": "a37000000000001", "Grupo_de_Programas_Canais__c": "b48000000000002" }'
        );
        insert logRelation;

        JSON_Event_Log__c logPriceItemSuccess = new JSON_Event_Log__c(
            Event_status__c = 'Published',
            Cod_Execucao__c = '102030405060708090',
            Status_Message__c = 'Processamento concluído ou em andamento sem erros.',
            Tipo__c = 'Criação de price items via LWC',
            Record_Id__c = bundle.Id,
            JSON_object__c = '{"successCountPriceItems":10,"errorCountPriceItems":0,"successCountRelations":5,"errorCountRelations":0,"errors":[]}'
        );
        insert logPriceItemSuccess; 
    }

    @isTest
    static void testImportPriceItemsInitial() {
        // Recuperar dados do setup
        Bundle__c bundle = [SELECT Id FROM Bundle__c LIMIT 1];

        List<PriceItemWrapper> listPriceItemWrapper = new List<PriceItemWrapper>(); 

        getPriceItemWrapper();
         
        Test.startTest();
        // Invocar o método para importar Price Items
        String response = PriceItemImportController.processPriceItems(bundle.Id, JSON.S);
        Test.stopTest(); 
 	}
 
     @isTest
     static void testImportPriceItemsInitialValidacoes() {
        // Recuperar dados do setup
        Bundle__c bundle = [SELECT Id FROM Bundle__c LIMIT 1];

        // Criar JSON de entrada
        String dataListJson = '[{"recordTypeId":"","priceItemId":"","commercialCapacity":1,"pricePerUnit":12.37,"spotLenght":15,"unit":"CPM","aMAPMediaType":"Free to Air","description":"GI Std todos os dias","frequency":"Total","location":"Campinas","locationId":"","tipoDeFormato":"Avulso","totalQuantity":-1,"minCommercialCapacity":3000000,"faixaHoraria":"Manhã;Tarde;Madrugada","diasDaSemana":"Todos os dias","discount":0.35,"Grupo_de_Programas_Canais_1":"Group 1","Grupo_de_Programas_Canais_2":"Group 2","Grupo_de_Programas_Canais_3":"","Grupo_de_Programas_Canais_4":""},'
                             + '{"recordTypeId":"","priceItemId":"","commercialCapacity":-1,"pricePerUnit":12.37,"spotLenght":15,"unit":"CPM","aMAPMediaType":"Free to Air","description":"GI Std todos os dias","frequency":"Total","location":"Campinas","locationId":"","tipoDeFormato":"Avulso","totalQuantity":0,"minCommercialCapacity":3000000,"faixaHoraria":"Manhã;Tarde;Madrugada","diasDaSemana":"Todos os dias","discount":0.35,"Grupo_de_Programas_Canais_1":"Group 1","Grupo_de_Programas_Canais_2":"Group 2","Grupo_de_Programas_Canais_3":"","Grupo_de_Programas_Canais_4":""},'
                             + '{"recordTypeId":"","priceItemId":"","commercialCapacity":1,"pricePerUnit":12.37,"spotLenght":15,"unit":"CPM","aMAPMediaType":"Free to Air","description":"GI Std todos os dias","frequency":"Total","location":"Campinas","locationId":"","tipoDeFormato":"Avulso","totalQuantity":0,"minCommercialCapacity":-3000000,"faixaHoraria":"Manhã;Tarde;Madrugada","diasDaSemana":"Todos os dias","discount":0.35,"Grupo_de_Programas_Canais_1":"Group 1","Grupo_de_Programas_Canais_2":"Group 2","Grupo_de_Programas_Canais_3":"","Grupo_de_Programas_Canais_4":""},'
                             + '{"recordTypeId":"","priceItemId":"","commercialCapacity":1,"pricePerUnit":-12.3,"spotLenght":15,"unit":"CPM","aMAPMediaType":"Free to Air","description":"GI Std todos os dias","frequency":"Total","location":"Campinas","locationId":"","tipoDeFormato":"Avulso","totalQuantity":0,"minCommercialCapacity":3000000,"faixaHoraria":"Manhã;Tarde;Madrugada","diasDaSemana":"Todos os dias","discount":0.35,"Grupo_de_Programas_Canais_1":"Group 1","Grupo_de_Programas_Canais_2":"Group 2","Grupo_de_Programas_Canais_3":"","Grupo_de_Programas_Canais_4":""},'
                             + '{"recordTypeId":"","priceItemId":"","commercialCapacity":1,"pricePerUnit":12.3,"spotLenght":15,"unit":"CPM","aMAPMediaType":"Free to Air","description":"GI Std todos os dias","frequency":"Total","location":"Campinas","locationId":"","tipoDeFormato":"Avulso","totalQuantity":0,"minCommercialCapacity":3000000,"faixaHoraria":"Manhã;Tarde;Madrugada","diasDaSemana":"Todos os dias","discount":0.35,"Grupo_de_Programas_Canais_1":"Group 1","Grupo_de_Programas_Canais_2":"Group 2","Grupo_de_Programas_Canais_3":"","Grupo_de_Programas_Canais_4":""}]';

        Test.startTest();
        // Invocar o método para importar Price Items
        String response = PriceItemImportController.processPriceItems(bundle.Id, dataListJson);
        Test.stopTest(); 
    }  

    @isTest
    static void testImportPriceItemsRetryPriceItem() {
        // Recuperar dados do setup
        JSON_Event_Log__c log = [SELECT Cod_Execucao__c FROM JSON_Event_Log__c WHERE Cod_Execucao__c = '102030405060708090' LIMIT 1];

        Test.startTest();
        // Invocar o batch para Retry
        PriceItemImportBatch retryBatch = new PriceItemImportBatch(log.Cod_Execucao__c);
        Database.executeBatch(retryBatch, 1);
        Test.stopTest();
 	}

     @isTest
     static void testImportPriceItemsRetryRelation() {
         // Recuperar dados do setup
         JSON_Event_Log__c log = [SELECT Cod_Execucao__c FROM JSON_Event_Log__c WHERE Cod_Execucao__c = '203040506070809010' LIMIT 1];
 
         Test.startTest();
         // Invocar o batch para Retry
         PriceItemImportBatch retryBatch = new PriceItemImportBatch(log.Cod_Execucao__c);
         Database.executeBatch(retryBatch, 1);
         Test.stopTest();
      }

    @isTest
    static void testImportPriceItemsInvalidJson() {
        // Criar um JSON inválido
        String invalidJson = '[{"commercialCapacity": 100, "pricePerUnit": }';

        Test.startTest();
        try {
            // Tentar importar com JSON inválido
            PriceItemImportController.processPriceItems('someBundleId', invalidJson);
            //System.assert(false, 'O método deve lançar uma exceção para JSON inválido.');
        } catch (Exception e) {
            //System.assert(e.getMessage().contains('Unexpected token'), 'A mensagem da exceção deve indicar problema no JSON.');
        }
        Test.stopTest();
    }

    static PriceItemWrapper getPriceItemWrapper(){

        PriceItemWrapper priceItemWP = new PriceItemWrapper();

        priceItemWP.recordTypeId          = '';
        priceItemWP.priceItemId           = '';
        priceItemWP.commercialCapacity    = 143000000;
        priceItemWP.pricePerUnit          = 12.37;
        priceItemWP.spotLenght            = 15;
        priceItemWP.unit                  = 'CPM';
        priceItemWP.aMAPMediaType         = 'Free to Air';
        priceItemWP.description           = 'GI Std todos os dias';
        priceItemWP.frequency             = 'Total';
        priceItemWP.location              = 'Campinas';
        priceItemWP.locationId            = '';
        priceItemWP.tipoDeFormato         = 'Avulso';
        priceItemWP.totalQuantity         = 143000000;
        priceItemWP.minCommercialCapacity = 3000000;
        priceItemWP.faixaHoraria          = 'Manhã;Tarde;Madrugada';
        priceItemWP.diasDaSemana          = 'Todos os dias';
        priceItemWP.discount              = 0.35;
        priceItemWP.Grupo_de_Programas_Canais_1 = 'Group 1';
        priceItemWP.Grupo_de_Programas_Canais_2 = 'Group 2';
        priceItemWP.Grupo_de_Programas_Canais_3 = '';
        priceItemWP.Grupo_de_Programas_Canais_4 = '';

        return priceItemWP;
    } 
}