global class PriceItemImportBatch implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    
    global String recordId;
    global String dataListJson;
    global String codExecucao;
    global List<String> errorMessages = new List<String>();
    private static List<Bundle__c> listBundleToUpdate = new List<Bundle__c>();
    global Set<Id> priceItemsId = new Set<Id>();

    // Contadores para Price Items
    global Integer successCountPriceItems = 0;
    global Integer errorCountPriceItems = 0;
    global Integer retryCountPriceItems = 0;

    // Contadores para Relacionamentos
    global Integer successCountRelations = 0;
    global Integer errorCountRelations = 0;
    global Integer retryCountRelations = 0;

    global String recordTypeId = '';
    global String priceItemId  = '';

    // Modo de Execução: 'Initial' ou 'Retry'
    global String executionMode;

    global List<JSON_Event_Log__c> pendingLogs       = new List<JSON_Event_Log__c>(); 
    global List<JSON_Event_Log__c> listRecordsToRtry = new List<JSON_Event_Log__c>();
 
    global PriceItemImportBatch(String recordId, String dataListJson, String codExecucao, String recordTypeId, String priceItemId) {
        this.recordId = recordId;
        this.dataListJson = dataListJson;
        this.codExecucao = codExecucao;
        this.recordTypeId = recordTypeId;
        this.executionMode = 'Initial';
    }
 
    global PriceItemImportBatch(String codExecucao) {
        this.codExecucao = codExecucao;
        this.executionMode = 'Retry';
    }

    global Iterable<Object> start(Database.BatchableContext BC) {
 
        if (executionMode == 'Initial') {
            List<PriceItemWrapper> items = (List<PriceItemWrapper>) JSON.deserialize(dataListJson, List<PriceItemWrapper>.class);
            return items;
        
        } else {
            // Reprocessamento: Buscar registros pendentes em JSON_Event_Log__c
            pendingLogs = [
                SELECT Id, JSON_object__c, Tipo__c, Status_Message__c, Record_Id__c, Cod_Execucao__c
                FROM JSON_Event_Log__c
                WHERE ( Tipo__c = 'Retry PriceItem' OR Tipo__c = 'Retry Relation' ) AND Cod_Execucao__c = :this.codExecucao
            ];

            List<Object> objectsToProcess = new List<Object>();
            for (JSON_Event_Log__c log : pendingLogs) {
                try {
                    if (log.Tipo__c == 'Retry PriceItem') {
                        PriceItemWrapper wrapper = (PriceItemWrapper) JSON.deserialize(log.JSON_object__c, PriceItemWrapper.class);
                        // Recriar o PriceItem a partir do wrapper
                        PriceItem__c priceItem = new PriceItem__c();
                        //Mapeamento dos campos do wrapper para o priceItem
                        priceItem.Bundle__c                  = recordId;
                        priceItem.RecordTypeId               = wrapper.recordTypeId;
                        priceItem.Catalog_Item__c            = wrapper.priceItemId;
                        priceItem.Commercial_Capacity__c     = wrapper.commercialCapacity;
                        priceItem.Price_Per_Unit__c          = wrapper.pricePerUnit;
                        priceItem.Unit__c                    = wrapper.unit;
                        priceItem.AMAP_Media_Type__c         = wrapper.aMAPMediaType;
                        priceItem.Description__c             = wrapper.description;
                        priceItem.Frequency__c               = wrapper.frequency;
                        priceItem.Location__c                = wrapper.locationId;
                        priceItem.Tipo_de_Formato__c         = wrapper.tipoDeFormato;
                        priceItem.Total_Quantity__c          = wrapper.totalQuantity;
                        priceItem.Min_Commercial_Capacity__c = wrapper.minCommercialCapacity;
                        priceItem.Faixa_Horaria__c           = wrapper.faixaHoraria;
                        priceItem.Dias_da_semana__c          = wrapper.diasDaSemana;
                        priceItem.Discount__c                = wrapper.discount;
                        priceItem.Spot_Lenght__c             = wrapper.spotLenght;
                        priceItem.Executed_by_batch__c       = true;  
                        objectsToProcess.add(priceItem);

                    } else if (log.Tipo__c == 'Retry Relation') {
                        PriceItem_Program_Group__c relation = (PriceItem_Program_Group__c) JSON.deserialize(log.JSON_object__c, PriceItem_Program_Group__c.class);
                        relation.Id = log.Record_Id__c; // Define o ID, se necessário para update em vez de insert
                        objectsToProcess.add(relation);
                    }
                } catch(Exception e){
                    errorMessages.add('Erro ao desserializar ou preparar registro para reprocessamento: ' + e.getMessage() + ' Log Id: ' + log.Id);
                }
            }
            return objectsToProcess;
        }
    }

    global void execute(Database.BatchableContext BC, List<Object> scope) {
        if (executionMode == 'Initial') {
            // Lógica para processamento inicial de PriceItemWrapper
            List<PriceItemWrapper> priceItemWrappers = (List<PriceItemWrapper>) scope;
            try {
                Map<Id, List<Id>> mapProgramGroupsByPriceItem = createPriceItems(priceItemWrappers, recordId);
                relatePriceItemsWithProgramGroups(mapProgramGroupsByPriceItem);
            } catch (Exception e) {
                System.debug('Erro durante o processamento no batch: ' + e.getMessage());
                errorMessages.add('Erro durante o processamento no batch: ' + e.getMessage());
            }
        } else {
            // Lógica para reprocessamento de PriceItem__c e PriceItem_Program_Group__c
            List<PriceItem__c> priceItemsToRetry = new List<PriceItem__c>();
            List<PriceItem_Program_Group__c> relationsToRetry = new List<PriceItem_Program_Group__c>();

            for (Object obj : scope) {
                if (obj instanceof PriceItem__c) {
                    priceItemsToRetry.add((PriceItem__c) obj);
                
                } else if (obj instanceof PriceItem_Program_Group__c) {
                    relationsToRetry.add((PriceItem_Program_Group__c) obj);
                }
            }

            // Reprocessar PriceItems
            if (!priceItemsToRetry.isEmpty()) {
                List<Database.UpsertResult> priceItemResults = Database.upsert(priceItemsToRetry, false);  
                for(Integer i = 0; i < priceItemResults.size(); i++){
                    Database.UpsertResult result = priceItemResults[i];
                    if (result.isSuccess()) {
                        successCountPriceItems++;
                    } else {
                        errorCountPriceItems++;
                        for (Database.Error err : result.getErrors()) {
                            if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                                // Registrar para re-tentativa
                                PriceItem__c priceItemToRetry = priceItemsToRetry[i];
                                listRecordsToRtry.add( createJsonEventLogForRetry(priceItemToRetry, 'Retry PriceItem' ) );
                                retryCountPriceItems++;
                            } else {
                                errorMessages.add('Erro ao reprocessar PriceItem: ' + err.getMessage());
                            }
                        }
                    }
                }
            }

            // Reprocessar Relacionamentos
            if (!relationsToRetry.isEmpty()) {
                List<Database.UpsertResult> relationResults = Database.upsert(relationsToRetry, false);  
                for(Integer i = 0; i < relationResults.size(); i++){
                    Database.UpsertResult result = relationResults[i];
                    if (result.isSuccess()) {
                        successCountRelations++;
                    } else {
                        errorCountRelations++;
                        for (Database.Error err : result.getErrors()) {
                            if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                                // Registrar para re-tentativa
                                PriceItem_Program_Group__c relationToRetry = relationsToRetry[i];
                                listRecordsToRtry.add( createJsonEventLogForRetry(relationToRetry, 'Retry Relation' ) );
                                retryCountRelations++;
                            } else {
                                errorMessages.add('Erro ao reprocessar relação: ' + err.getMessage());
                            }
                        }
                    }
                }
            } 

            if (!pendingLogs.isEmpty()) {
                //delete pendingLogs;
            } 
        }
    }

    global void finish(Database.BatchableContext BC) {
        populateBundleDataAfter(priceItemsId);

        if(!Test.isRunningTest())
            PRODMNG_ProductApiController.publishingConfiguracaoProduto(listBundleToUpdate);

        // Atualiza o registro JSON_Event_Log__c referente a esta execução
        updateEventLog();

        // Inicia o reprocessamento se houver registros pendentes e se o modo atual for 'Initial'
        if ( ( retryCountPriceItems > 0 || retryCountRelations > 0 ) && !Test.isRunningTest()) {
            PriceItemImportBatch retryBatch = new PriceItemImportBatch(codExecucao);
            Database.executeBatch(retryBatch);
        }
    }

    private Map<Id, List<Id>> createPriceItems(List<PriceItemWrapper> listPriceItemWrapper, String recordId) {
        Set<String> allProgramGroupNames = new Set<String>();
        for (PriceItemWrapper row : listPriceItemWrapper) {
            if (row.Grupo_de_Programas_Canais_1 != null) allProgramGroupNames.add(row.Grupo_de_Programas_Canais_1);
            if (row.Grupo_de_Programas_Canais_2 != null) allProgramGroupNames.add(row.Grupo_de_Programas_Canais_2);
            if (row.Grupo_de_Programas_Canais_3 != null) allProgramGroupNames.add(row.Grupo_de_Programas_Canais_3);
            if (row.Grupo_de_Programas_Canais_4 != null) allProgramGroupNames.add(row.Grupo_de_Programas_Canais_4);
        }
    
        Map<String, Id> programGroupNameToIdMap = new Map<String, Id>();
        if (!allProgramGroupNames.isEmpty()) {
            for (Program_Group__c pg : [
                SELECT Id, Name FROM Program_Group__c 
                WHERE Name IN :allProgramGroupNames
            ]) {
                programGroupNameToIdMap.put(pg.Name, pg.Id);
            }
        }
    
        List<PriceItem__c> newPriceItems = new List<PriceItem__c>();
        Map<Integer, PriceItemWrapper> indexToWrapperMap = new Map<Integer, PriceItemWrapper>();
    
        // Campos que esperamos do PriceItemWrapper (assumindo que todos são obrigatórios)
        // se algum campo puder ser nulo, remova da lista ou trate separadamente.
        List<String> requiredFields = new List<String>{
            'commercialCapacity', 'pricePerUnit', 'unit', 'aMAPMediaType', 'description', 
            'frequency', 'location', 'tipoDeFormato', 'totalQuantity', 
            'minCommercialCapacity', 'faixaHoraria', 'diasDaSemana', 'discount', 'spotLenght'
        }; 
    
        for (Integer i = 0; i < listPriceItemWrapper.size(); i++) {
            PriceItemWrapper row = listPriceItemWrapper[i];

            Map<String, Object> fieldsMap = new Map<String, Object>{ 
                'commercialCapacity' => row.commercialCapacity,
                'pricePerUnit' => row.pricePerUnit,
                'unit' => row.unit,
                'aMAPMediaType' => row.aMAPMediaType,
                'description' => row.description,
                'frequency' => row.frequency,
                'location' => row.location,
                'tipoDeFormato' => row.tipoDeFormato,
                'totalQuantity' => row.totalQuantity,
                'minCommercialCapacity' => row.minCommercialCapacity,
                'faixaHoraria' => row.faixaHoraria,
                'diasDaSemana' => row.diasDaSemana,
                'discount' => row.discount,
                'spotLenght' => row.spotLenght
            };
    
            // Verifica se todos os campos necessários estão presentes e não nulos
            Boolean hasError = false;
            String errorMessagePrefix = 'Erro ao inserir PriceItem [índice: ' + i + ']: ';
    
            // 1. Validação de campos nulos ou colunas ausentes
            for (String f : requiredFields) {
                Object val = fieldsMap.get(f);
                
                if (val == null || String.valueOf(val).trim() == '') {
                    hasError = true;
                    errorMessages.add(errorMessagePrefix + 'Falta ou valor nulo para o campo: ' + f + '. Verifique se as colunas estão corretas e sem valores vazios.');
                    errorCountPriceItems++;
                    break; 
                }
            }
            if(hasError) {
                continue; // Não adicionar este registro na lista de inserção
            }
    
            // Converte os campos numéricos e valida valores
            Decimal totalQuantity = row.totalQuantity;
            Decimal commercialCapacity = row.commercialCapacity;
            Decimal minCommercialCapacity = row.minCommercialCapacity;
            Decimal discount = row.discount;
            Decimal pricePerUnit = row.pricePerUnit;
            Decimal spotLenght = row.spotLenght;
    
            // 2. Validar não negatividade
            if (totalQuantity < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Total_Quantity não pode ser negativo.');
                errorCountPriceItems++;
            }
            if (commercialCapacity < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Commercial_Capacity não pode ser negativo.');
                errorCountPriceItems++;
            }
            if (minCommercialCapacity < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Min_Commercial_Capacity não pode ser negativo.');
                errorCountPriceItems++;
            }
            if (pricePerUnit < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Price_Per_Unit não pode ser negativo.');
                errorCountPriceItems++;
            }
            if (discount < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Discount não pode ser negativo.');
                errorCountPriceItems++;
            }
            if (spotLenght < 0) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'SpotLenght não pode ser negativo.');
                errorCountPriceItems++;
            }
    
            // 3. Validar Min_Commercial_Capacity ≤ Total_Quantity
            if (minCommercialCapacity > totalQuantity) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Min_Commercial_Capacity não pode ser maior que Total_Quantity.');
                errorCountPriceItems++;
            }
    
            // 4. Validar Discount ≤ 1 (100%)
            if (discount > 1) {
                hasError = true;
                errorMessages.add(errorMessagePrefix + 'Discount não pode ser maior que 1 (100%).');
                errorCountPriceItems++;
            }
    
            if (hasError) {
                // Houve algum erro, não adiciona o PriceItem
                continue;
            }

            row.recordTypeId = this.recordTypeId;
            row.priceItemId  = this.priceItemId;
    
            // Se chegou até aqui, passa nas validações
            PriceItem__c priceItem = new PriceItem__c();
            priceItem.Bundle__c                  = recordId;
            priceItem.RecordTypeId               = row.recordTypeId;
            priceItem.Catalog_Item__c            = row.priceItemId;
            priceItem.Commercial_Capacity__c     = commercialCapacity;
            priceItem.Price_Per_Unit__c          = pricePerUnit;
            priceItem.Unit__c                    = row.unit;
            priceItem.AMAP_Media_Type__c         = row.aMAPMediaType;
            priceItem.Description__c             = row.description;
            priceItem.Frequency__c               = row.frequency;
            priceItem.Location__c                = row.locationId;
            priceItem.Tipo_de_Formato__c         = row.tipoDeFormato;
            priceItem.Total_Quantity__c          = totalQuantity;
            priceItem.Min_Commercial_Capacity__c = minCommercialCapacity;
            priceItem.Faixa_Horaria__c           = row.faixaHoraria;
            priceItem.Dias_da_semana__c          = row.diasDaSemana;
            priceItem.Discount__c                = discount;
            priceItem.Spot_Lenght__c             = row.spotLenght;
            priceItem.Executed_by_batch__c       = true; 
    
            newPriceItems.add(priceItem);
            indexToWrapperMap.put(i, row);
        }
    
        if (!newPriceItems.isEmpty()) {
            try {
                Database.SaveResult[] saveResults = Database.insert(newPriceItems, false);
    
                Map<Id, PriceItemWrapper> priceItemIdToWrapperMap = new Map<Id, PriceItemWrapper>(); 
                Set<String> uniqueErrors = new Set<String>();
    
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        PriceItem__c insertedPriceItem = newPriceItems[i];
                        PriceItemWrapper correspondingWrapper = indexToWrapperMap.get(i);
                        priceItemIdToWrapperMap.put(insertedPriceItem.Id, correspondingWrapper);
    
                        // Incrementa contagem de sucessos de PriceItems
                        successCountPriceItems++;
                    } else {
                        // Houve um erro ao inserir o registro de PriceItem
                        for (Database.Error err : saveResults[i].getErrors()) {
                            String errMsg = 'Erro ao inserir PriceItem ' + err.getMessage();
                            
                            System.debug('errMsg ===> ' + errMsg);

                            if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                                // Registrar para re-tentativa
                                PriceItemWrapper wrapperToRetry = indexToWrapperMap.get(i);
                                listRecordsToRtry.add( createJsonEventLogForRetry(wrapperToRetry, 'Retry PriceItem' ));
                                retryCountPriceItems++;
                            } else {

                                if (!uniqueErrors.contains(errMsg)) {
                                    uniqueErrors.add(errMsg);
                                    errorMessages.add(errMsg);
                                    errorCountPriceItems++;
                                }
                            }
                        }
                    }
                } 
                priceItemsId = priceItemIdToWrapperMap.keySet();
    
                Map<Id, List<Id>> mapProgramGroupsByPriceItem = new Map<Id, List<Id>>();
    
                for (Id priceItemId : priceItemIdToWrapperMap.keySet()) {
                    PriceItemWrapper row = priceItemIdToWrapperMap.get(priceItemId);
                    List<Id> programGroupIds = new List<Id>();
    
                    if (row.Grupo_de_Programas_Canais_1 != null && programGroupNameToIdMap.containsKey(row.Grupo_de_Programas_Canais_1)) {
                        programGroupIds.add(programGroupNameToIdMap.get(row.Grupo_de_Programas_Canais_1));
                    }
                    if (row.Grupo_de_Programas_Canais_2 != null && programGroupNameToIdMap.containsKey(row.Grupo_de_Programas_Canais_2)) {
                        programGroupIds.add(programGroupNameToIdMap.get(row.Grupo_de_Programas_Canais_2));
                    }
                    if (row.Grupo_de_Programas_Canais_3 != null && programGroupNameToIdMap.containsKey(row.Grupo_de_Programas_Canais_3)) {
                        programGroupIds.add(programGroupNameToIdMap.get(row.Grupo_de_Programas_Canais_3));
                    }
                    if (row.Grupo_de_Programas_Canais_4 != null && programGroupNameToIdMap.containsKey(row.Grupo_de_Programas_Canais_4)) {
                        programGroupIds.add(programGroupNameToIdMap.get(row.Grupo_de_Programas_Canais_4));
                    }
                    mapProgramGroupsByPriceItem.put(priceItemId, programGroupIds);
                }
    
                return mapProgramGroupsByPriceItem;
    
            } catch (Exception e) {
                System.debug('Erro inesperado ao inserir PriceItems no batch: ' + e.getMessage());
                errorMessages.add('Erro inesperado ao inserir PriceItems: ' + e.getMessage());
                return new Map<Id, List<Id>>();
            }
        } else {
            System.debug('Nenhum PriceItem a ser inserido devido a erros de validação.');
            return new Map<Id, List<Id>>();
        }
    } 

    public static void populateBundleDataAfter(Set<Id> priceItemsId) {  
        List<PriceItem__c> listPriceItems = [
            SELECT id, Discount__c, Price_Gross__c, bonus__c, Total_Price__c, Optional__c, Net_Price__c, 
                   Catalog_Item__r.Media_Types__c, Catalog_Item__r.AMAP_Media_Type__c, Modulo__c, Bundle__c, 
                   bundle__r.Net_Price__c, bundle__r.Discount__c, bundle__r.Total_Price_No_Optional__c, 
                   bundle__r.Total_Price_Optional__c, bundle__r.Total_Price__c, bundle__r.Valor_Digital__c, 
                   bundle__r.Valor_TV__c, Executed_by_batch__c
            FROM PriceItem__c 
            WHERE bundle__c IN :priceItemsId
        ];

        listBundleToUpdate = AMAP_PriceItemTriggerHelper.populateBundleData(listPriceItems); 
    }

    private void relatePriceItemsWithProgramGroups(Map<Id, List<Id>> mapProgramGroupsByPriceItem) {
        System.debug('Iniciando criação de relações entre PriceItems e Program Groups no batch.');

        List<PriceItem_Program_Group__c> newJunctionRecords = new List<PriceItem_Program_Group__c>();

        for (Id priceItemId : mapProgramGroupsByPriceItem.keySet()) {
            List<Id> programGroupIds = mapProgramGroupsByPriceItem.get(priceItemId);

            for (Id programGroupId : programGroupIds) {
                if (programGroupId != null) {
                    newJunctionRecords.add(new PriceItem_Program_Group__c(
                        Item_de_Preco__c = priceItemId,
                        Grupo_de_Programas_Canais__c = programGroupId
                    ));
                }
            }
        }

        System.debug('Número de novas relações a serem inseridas no batch: ' + newJunctionRecords.size());

        if (!newJunctionRecords.isEmpty()) { 
            Database.SaveResult[] srList = Database.insert(newJunctionRecords, false); 

            Integer index = 0;
            Integer successRelationsThisBatch = 0;
            Integer failedRelationsThisBatch = 0;

            Set<String> uniqueErrors = new Set<String>();

            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    successRelationsThisBatch++;
                
                } else {
                    for (Database.Error err : sr.getErrors()) { 
                        
                        if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                            // Em caso de lock row registrar para re-tentativa
                            PriceItem_Program_Group__c junctionToRetry = newJunctionRecords[index];
                            listRecordsToRtry.add(createJsonEventLogForRetry(junctionToRetry, 'Retry Relation' ));
                            retryCountRelations++;
                            
                        } else {
                            String errMsg = 'Erro ao inserir relação ' + err.getMessage(); 
                            if (!uniqueErrors.contains(errMsg)) {
                                uniqueErrors.add(errMsg);
                                errorMessages.add(errMsg);
                                errorCountRelations++;
                            }
                            failedRelationsThisBatch++;
                        }
                    }
                }
                index++;
            }

            successCountRelations += successRelationsThisBatch; // Soma ao contador global
            // failedRelationsThisBatch já incrementou errorCountRelations

            if (failedRelationsThisBatch == 0) {
                System.debug('Relações criadas com sucesso. Inseridas: ' + successRelationsThisBatch);
            } else {
                System.debug('Algumas relações falharam. Sucesso: ' + successRelationsThisBatch + ', Falhas: ' + failedRelationsThisBatch);
            }
        } else {
            System.debug('Nenhuma relação a ser inserida no batch.');
        }
    }
 
    private JSON_Event_Log__c createJsonEventLogForRetry(Object objectToRetry, String type) {
        JSON_Event_Log__c retryLog  = new JSON_Event_Log__c();
        retryLog.Event_status__c    = 'Not Published';
        retryLog.Cod_Execucao__c    = codExecucao;
        retryLog.Status_Message__c  = 'Registros para Retry';
        retryLog.JSON_object__c     = JSON.serialize(objectToRetry);
        retryLog.Tipo__c            = type; 
        retryLog.Record_Id__c       = recordId; 

        return retryLog;
    } 

    private void updateEventLog() {
        JSON_Event_Log__c logRecord = [
            SELECT Id, Cod_Execucao__c, JSON_object__c, Event_status__c, Status_Message__c, Record_Id__c
            FROM JSON_Event_Log__c
            WHERE Cod_Execucao__c = :codExecucao
            LIMIT 1 FOR UPDATE
        ];

        Map<String,Object> jsonMap = new Map<String,Object>();
        if (String.isNotBlank(logRecord.JSON_object__c)) {
            try {
                jsonMap = (Map<String,Object>)JSON.deserializeUntyped(logRecord.JSON_object__c);
            } catch(Exception e) {
                jsonMap = new Map<String,Object>();
            }
        }

        // Recupera listas e contagens atuais
        List<Object> currentErrorsObj = (List<Object>)jsonMap.get('errors');
        List<String> currentErrors = new List<String>(); 
        if (currentErrorsObj != null) {
            for (Object obj : currentErrorsObj) {
                currentErrors.add((String)obj); 
            }
        }

        // Soma as novas mensagens de erro
        currentErrors.addAll(errorMessages);

        // Atualiza contagens separadas
        Integer prevSuccessPriceItems = (jsonMap.containsKey('successCountPriceItems')) ? (Integer)jsonMap.get('successCountPriceItems') : 0;
        Integer prevErrorPriceItems   = (jsonMap.containsKey('errorCountPriceItems')) ? (Integer)jsonMap.get('errorCountPriceItems') : 0;

        Integer prevSuccessRelations  = (jsonMap.containsKey('successCountRelations')) ? (Integer)jsonMap.get('successCountRelations') : 0;
        Integer prevErrorRelations    = (jsonMap.containsKey('errorCountRelations')) ? (Integer)jsonMap.get('errorCountRelations') : 0;

        // Atualiza com as contagens deste batch
        prevSuccessPriceItems += successCountPriceItems;
        prevErrorPriceItems   += errorCountPriceItems;
        prevSuccessRelations  += successCountRelations;
        prevErrorRelations    += errorCountRelations;

        // Armazena de volta no JSON
        jsonMap.put('successCountPriceItems', prevSuccessPriceItems);
        jsonMap.put('errorCountPriceItems', prevErrorPriceItems);
        jsonMap.put('successCountRelations', prevSuccessRelations);
        jsonMap.put('errorCountRelations', prevErrorRelations);
        jsonMap.put('errors', currentErrors);

        // Determinar status
        // Se houver qualquer erro (price items ou relações), podemos considerar Not Published
        if (prevErrorPriceItems > 0 || prevErrorRelations > 0) {
            logRecord.Event_status__c = 'Not Published';
            logRecord.Status_Message__c = 'Erros foram encontrados durante o processamento.';

        } else {
            logRecord.Event_status__c = 'Published'; 
            logRecord.Status_Message__c = 'Processamento concluído ou em andamento sem erros.';
        }

        logRecord.Record_Id__c = this.recordId;
        logRecord.JSON_object__c = JSON.serialize(jsonMap);
        logRecord.Tipo__c = 'Criação de price items via LWC';

        update logRecord;

        if(listRecordsToRtry.size() > 0)
            insert listRecordsToRtry;
    }
}