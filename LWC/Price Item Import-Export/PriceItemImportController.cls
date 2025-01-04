public with sharing class PriceItemImportController {
    
    private static Boolean deletionsDone = false; 
    private static List<Bundle__c> listBundleToDelete = new List<Bundle__c>(); 
    private static List<PriceItem__c> deletedPrices = new List<PriceItem__c> ();
    private static List<Id> bundleIdlist = new List<Id>();

    @AuraEnabled
    public static String processPriceItems(String recordId, String dataList) {

        System.debug('Iniciando processamento de Price Items para o Bundle: ' + recordId);

        List<RecordType> listRecordTypeId = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Preco_Base'];

        List<Catalog_Item__c> listCatalogItem = [SELECT Id, Catalog_Display_Name__c FROM Catalog_Item__c WHERE Catalog_Display_Name__c = 'Giro'];

        if(listRecordTypeId.size() == 0){
            throw new AuraHandledException('Erro: RecordType do Price Item não encontrada para o nome: Preco Base');
        
        }else if(listCatalogItem.size() == 0){
            throw new AuraHandledException('Erro: Catalog Item não encontrada para o nome: Giro');
        }

        // Desserializar todos os itens
        List<PriceItemWrapper> allItems = (List<PriceItemWrapper>)JSON.deserialize(dataList, List<PriceItemWrapper>.class);

        System.debug('allItems size ===>' + allItems.size());

        // Converter nomes de Location para IDs
        Map<String, Id> locationMap = fetchLocationMap(allItems);

        System.debug('locationMap size ===>' + locationMap.size());
 
        // Atribuir IDs correspondentes aos nomes
        for (PriceItemWrapper item : allItems) {
            if (locationMap.containsKey(item.location)) {
                item.locationId = locationMap.get(item.location);
            
            } else {
                throw new AuraHandledException('Erro: Localização não encontrada para o nome: ' + item.location);
            }
        }

        System.debug('Passou pela validação dos locations ===>' + allItems.size());

        // Realiza as deleções apenas uma vez
        if (!deletionsDone) {
            deletePriceItemProgramGroups(recordId);
            deletePriceItems(recordId);
            deletionsDone = true;
        }  
        
        if (deletionsDone) { 
            try {   
                if(!Test.isRunningTest())
                    PRODMNG_ProductApiController.publishingConfiguracaoProduto(listBundleToDelete);

                // Tenta obter um log existente para esse recordId
                JSON_Event_Log__c existingLog = getEventLogForRecord(recordId);

                // Gera um novo código de execução 
                String newCodExecucao = recordId + String.valueOf(Datetime.now().getTime()); 
 
                Map<String,Object> jsonMap = new Map<String,Object>{
                    'successCountPriceItems' => 0,
                    'errorCountPriceItems' => 0,
                    'successCountRelations' => 0,
                    'errorCountRelations' => 0,
                    'errors' => new List<String>()
                };

                if (existingLog == null) { 
                    // Nenhum log existente, cria um novo
                    existingLog = new JSON_Event_Log__c(
                        Record_Id__c = recordId,
                        cod_execucao__c = newCodExecucao,
                        Event_status__c = 'Not Published',
                        Status_Message__c = 'Processamento iniciado...',
                        JSON_object__c = JSON.serialize(jsonMap),
                        Tipo__c = 'Criação de price items via LWC'
                    );
                    insert existingLog;
                } else {
                    // Log já existe. Atualizar cod_execucao, zerar contagens
                    // Caso o log já tenha JSON, preservar a estrutura, 
                    // mas de qualquer forma zerar os valores.
                    Map<String,Object> oldJsonMap = new Map<String,Object>();
                    if (String.isNotBlank(existingLog.JSON_object__c)) {
                        try {
                            oldJsonMap = (Map<String,Object>)JSON.deserializeUntyped(existingLog.JSON_object__c);
                        
                        } catch(Exception e) {
                            // Caso de erro no parse, não há problema, sobrescrever com valores zerados
                            oldJsonMap = new Map<String,Object>();
                        }
                    }

                    // Sobrescrevendo os valores com zero
                    oldJsonMap.put('successCountPriceItems', 0);
                    oldJsonMap.put('errorCountPriceItems', 0);
                    oldJsonMap.put('successCountRelations', 0);
                    oldJsonMap.put('errorCountRelations', 0);
                    oldJsonMap.put('errors', new List<String>());

                    existingLog.cod_execucao__c = newCodExecucao;
                    existingLog.Event_status__c = 'Not Published';
                    existingLog.Status_Message__c = 'Processamento iniciado...';
                    existingLog.JSON_object__c = JSON.serialize(oldJsonMap);

                    update existingLog;
                }  
                
                // Definir o tamanho de cada lote (chunk)
                Integer chunkSize = 50; 

                // Dividir a lista em sublistas
                List<List<PriceItemWrapper>> subLists = splitListIntoChunks(allItems, chunkSize);

                // Executar um batch para cada sublista
                for (List<PriceItemWrapper> chunk : subLists) {
                    // Re-serializar somente o chunk atual
                    String chunkJson = JSON.serialize(chunk);

                    PriceItemImportBatch batchJob = new PriceItemImportBatch(recordId, chunkJson, existingLog.cod_execucao__c, listRecordTypeId[0].Id, listCatalogItem[0].Id);
                    Id batchprocessId = Database.executeBatch(batchJob);

                    System.debug('Batch enfileirado com sucesso para um chunk. Id do processo: ' + batchprocessId);
                }

                return 'Processamento em lotes iniciado com sucesso. Verifique os registros em breve.';
            
            } catch (Exception e) {
                System.debug('Erro durante o processamento: ' + e.getMessage());
                throw new AuraHandledException('Erro durante o processamento dos Price Items: ' + e.getMessage()); 
            }
        }
        return null;
    }

    // Busca IDs de Location com base nos nomes fornecidos
    private static Map<String, Id> fetchLocationMap(List<PriceItemWrapper> items) {
        
        Set<String> locationNames = new Set<String>();
        
        for (PriceItemWrapper item : items) {
            if( String.isNotBlank(item.location))
                locationNames.add(item.location);
        }

        System.debug('locationNames size ===>' + locationNames.size());
 
        List<Location__c> locations = [
            SELECT Id, Name 
            FROM Location__c 
            WHERE Name IN :locationNames
        ];

        System.debug('locations size ===> ' + locations.size());
        
        Map<String, Id> locationMap = new Map<String, Id>();

        for (Location__c loc : locations) {
            locationMap.put(loc.Name, loc.Id);
        } 
        return locationMap;
    }

    private static JSON_Event_Log__c getEventLogForRecord(Id recordId) {
        List<JSON_Event_Log__c> logs = [
            SELECT Id, Record_Id__c, cod_execucao__c, Event_status__c, Status_Message__c, JSON_object__c
              FROM JSON_Event_Log__c
             WHERE Record_Id__c = :recordId
               AND Tipo__c = 'Criação de price items via LWC'
          ORDER BY CreatedDate DESC
             LIMIT 1
        ];
        return logs.isEmpty() ? null : logs[0];
    }

    private static List<List<PriceItemWrapper>> splitListIntoChunks(List<PriceItemWrapper> originalList, Integer chunkSize) {
        List<List<PriceItemWrapper>> chunks = new List<List<PriceItemWrapper>>();
       
        for (Integer i = 0; i < originalList.size(); i += chunkSize) {
            Integer count = i + chunkSize;
            if (count > originalList.size()) {
                count = originalList.size();
            }

            // Criar sublista manualmente
            List<PriceItemWrapper> subPart = new List<PriceItemWrapper>();
            for (Integer x = i; x < count; x++) {
                subPart.add(originalList[x]);
            }

            chunks.add(subPart);
        }
        return chunks;
    }
 
    private static void deletePriceItemProgramGroups(String recordId) {
        System.debug('Deletando relações existentes entre PriceItems e Program Groups para o Bundle: ' + recordId);

        List<PriceItem_Program_Group__c> junctionRecords = [
            SELECT Id 
            FROM PriceItem_Program_Group__c 
            WHERE Item_de_Preco__r.Bundle__c = :recordId
        ];

        System.debug('Número de relações a serem deletadas: ' + junctionRecords.size());

        if (!junctionRecords.isEmpty()) {
            delete junctionRecords;
            System.debug('Relações deletadas com sucesso.');
        
        } else {
            System.debug('Nenhuma relação encontrada para deletar.');
        }
    }

    private static void deletePriceItems(String recordId) {
        System.debug('Deletando PriceItems existentes para o Bundle: ' + recordId);

        List<PriceItem__c> priceItems = [
            SELECT Id, Executed_by_batch__c
            FROM PriceItem__c 
            WHERE Bundle__c = :recordId
        ];

        for (PriceItem__c row : priceItems) {
            row.Executed_by_batch__c = true;
        }

        update priceItems;

        populateBundleDataBefore(priceItems);

        System.debug('Número de PriceItems a serem deletados: ' + priceItems.size());

        if (!priceItems.isEmpty()) {
            delete priceItems;
            System.debug('PriceItems deletados com sucesso.');
        } else {
            System.debug('Nenhum PriceItem encontrado para deletar.');
        }
    } 

    public static void populateBundleDataBefore(List<PriceItem__c> priceItemList) {
        deletedPrices = [SELECT Id, Bundle__c, Executed_by_batch__c 
                           FROM PriceItem__c 
                          WHERE Id IN :priceItemList];
		
        List<Id> priceIdsToDelete = new List<Id> ();
		
        for (PriceItem__c p : deletedPrices) {
            if (p.Bundle__c != null) {
                bundleIdList.add(p.Bundle__c);
            }
            priceIdsToDelete.add(p.Id);
        }
		
        if (bundleIdList.size() > 0) {
            List<PriceItem__c> listPriceItems = [SELECT id, Discount__c, Price_Gross__c, bonus__c, Total_Price__c, Optional__c, Net_Price__c, Catalog_Item__r.Media_Types__c, 
                                                        Catalog_Item__r.AMAP_Media_Type__c, Modulo__c, Bundle__c, bundle__r.Net_Price__c, bundle__r.Discount__c, bundle__r.Total_Price_No_Optional__c, 
                                                        bundle__r.Total_Price_Optional__c, bundle__r.Total_Price__c, bundle__r.Valor_Digital__c, bundle__r.Valor_TV__c, Executed_by_batch__c
                                                   FROM PriceItem__c 
                                                  WHERE bundle__c IN :bundleIdList
                                                    AND Id NOT IN :priceIdsToDelete];

            listBundleToDelete = AMAP_PriceItemTriggerHelper.populateBundleData(listPriceItems);
        }  
    }
}