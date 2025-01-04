@isTest
public class PriceItemExportControllerTest {
    
    @testSetup
    static void setupTestData() {

        // Criar dados comuns para todos os testes
        Market_Product_Type__c newMarkerProgType = ObjectFactory.getMarketProductType();
        insert newMarkerProgType;

        // Criar registros de Bundle
        Bundle__c bundle = ObjectFactory.getBundle('TestBundleDemo', newMarkerProgType);
        insert bundle;
        
        // Criação de Program Groups relacionados ao Bundle
        Program_Group__c pg1 = new Program_Group__c(Name = 'Group 1', Product__c = bundle.Id);
        Program_Group__c pg2 = new Program_Group__c(Name = 'Group 2', Product__c = bundle.Id);
        insert new List<Program_Group__c> {pg1, pg2};
        
        // Criação de PriceItems relacionados ao Bundle
        PriceItem__c pi1 = new PriceItem__c(Bundle__c = bundle.Id, Price_Per_Unit__c = 100);
        PriceItem__c pi2 = new PriceItem__c(Bundle__c = bundle.Id, Price_Per_Unit__c = 200);
        insert new List<PriceItem__c> {pi1, pi2};
        
        // Criação de registros de junção PriceItem_Program_Group
        PriceItem_Program_Group__c pgLink1 = new PriceItem_Program_Group__c(Item_de_Preco__c = pi1.Id, Grupo_de_Programas_Canais__c = pg1.Id);
        PriceItem_Program_Group__c pgLink2 = new PriceItem_Program_Group__c(Item_de_Preco__c = pi2.Id, Grupo_de_Programas_Canais__c = pg2.Id);
        insert new List<PriceItem_Program_Group__c> {pgLink1, pgLink2};
 
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
    static void testProcessPriceItems() { 

        Bundle__c bundle = [
            SELECT Id, Name 
              FROM Bundle__c  
             LIMIT 1
        ];

        // Chamar o método principal de processamento de PriceItems
        Test.startTest();
        PriceItemExportController.extractAllPriceItemFields(bundle.Id); 
        Test.stopTest(); 
    }

    @isTest
    static void testGetLastEventLog() { 

        Bundle__c bundle = [
            SELECT Id, Name 
              FROM Bundle__c  
             LIMIT 1
        ];

        // Chamar o método principal de processamento de PriceItems
        Test.startTest();
        PriceItemExportController.getLastEventLog(bundle.Id); 
        Test.stopTest(); 
    } 
} 