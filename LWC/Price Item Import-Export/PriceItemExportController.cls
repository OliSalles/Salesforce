public with sharing class PriceItemExportController {

    @AuraEnabled(cacheable=true)
    public static JSON_Event_Log__c getLastEventLog(Id recordId) {
        List<JSON_Event_Log__c> logs = [
            SELECT Event_status__c, CreatedDate, Tipo__c, OwnerId, Record_Id__c, Status_Message__c, Topic_Name__c, JSON_object__c
              FROM JSON_Event_Log__c
             WHERE Record_Id__c = :recordId
               AND Tipo__c = 'Criação de price items via LWC'
          ORDER BY CreatedDate DESC
             LIMIT 1
        ];
        if (!logs.isEmpty()) {
            return logs[0];
        } else {
            // Retorna um registro "falso" com valores padrão
            JSON_Event_Log__c noLog = new JSON_Event_Log__c();
            noLog.Event_status__c = 'Sem logs';
            noLog.Status_Message__c = 'Nenhum registro de log encontrado para este ID.';
            return noLog;
        }
    }

    /**
     * Método para extrair os campos especificados dos PriceItems relacionados a um Bundle 
     * @return Lista de PriceItemData contendo os campos extraídos
     */  
    @AuraEnabled(cacheable=false)
    public static List<PriceItemData> extractAllPriceItemFields(String recordId) {
        System.debug('recordId ===> ' + recordId);

        // Obter todos os grupos de programas para os PriceItems relacionados ao Bundle
        Map<Id, List<PriceItem_Program_Group__c>> mapProgramGroupByPriceItems = new Map<Id, List<PriceItem_Program_Group__c>>();
        List<PriceItem_Program_Group__c> listProgramGroup = [
            SELECT Id, Grupo_de_Programas_Canais__r.Name, Item_de_Preco__c
            FROM PriceItem_Program_Group__c
            WHERE Item_de_Preco__r.Bundle__c = :recordId
        ];
        for (PriceItem_Program_Group__c row : listProgramGroup) {
            if (!mapProgramGroupByPriceItems.containsKey(row.Item_de_Preco__c)) {
                mapProgramGroupByPriceItems.put(row.Item_de_Preco__c, new List<PriceItem_Program_Group__c>());
            }
            mapProgramGroupByPriceItems.get(row.Item_de_Preco__c).add(row);
        }

        // Consultar todos os PriceItems com os campos especificados, incluindo o Name de Location__c
        List<PriceItem__c> priceItems = [
            SELECT RecordTypeId, Bundle__c, Catalog_Item__c, Commercial_Capacity__c, Price_Per_Unit__c,
                   Spot_Lenght__c, Unit__c, AMAP_Media_Type__c, Description__c, Frequency__c,
                   Location__c, Location__r.Name, Optional__c, ByPass_Validation__c, Related_to_Bundle__c, Tipo_de_Formato__c,
                   Total_Quantity__c, Min_Commercial_Capacity__c, isUpdatedTableDate__c, Faixa_Horaria__c,
                   Dias_da_semana__c, Is_Editable__c, SalesProduct__c, Discount__c
            FROM PriceItem__c
            WHERE Bundle__c = :recordId
        ];

        System.debug('priceItems ===> ' + priceItems.size());

        // Converter os registros para a classe PriceItemData
        List<PriceItemData> extractedData = new List<PriceItemData>();
        for (PriceItem__c pi : priceItems) {
            PriceItemData priceItemData = new PriceItemData(pi);

            // Obter os grupos de programas para o Item de Preço atual e preencher os campos
            List<PriceItem_Program_Group__c> relatedProgramGroups = mapProgramGroupByPriceItems.get(pi.Id);
            if (relatedProgramGroups != null && !relatedProgramGroups.isEmpty()) {
                for (Integer i = 0; i < relatedProgramGroups.size(); i++) {
                    String groupName = relatedProgramGroups[i].Grupo_de_Programas_Canais__r.Name;
                    if (i == 0) {
                        priceItemData.Grupo_de_Programas_Canais_1 = groupName;
                    } else if (i == 1) {
                        priceItemData.Grupo_de_Programas_Canais_2 = groupName;
                    } else if (i == 2) {
                        priceItemData.Grupo_de_Programas_Canais_3 = groupName;
                    } else if (i == 3) {
                        priceItemData.Grupo_de_Programas_Canais_4 = groupName;
                    } else { 
                        break;
                    }
                }
            }
            extractedData.add(priceItemData);
        }

        return extractedData;
    }

    /**
     * Classe wrapper para armazenar os dados extraídos dos PriceItems
     */
    public class PriceItemData { 
        @AuraEnabled public Id      recordTypeId          { get; set; } 
        @AuraEnabled public Id      catalogItem           { get; set; }
        @AuraEnabled public Decimal commercialCapacity    { get; set; }
        @AuraEnabled public Decimal pricePerUnit          { get; set; }
        @AuraEnabled public Decimal spotLenght            { get; set; }
        @AuraEnabled public String  unit                  { get; set; }
        @AuraEnabled public String  aMAPMediaType         { get; set; }
        @AuraEnabled public String  description           { get; set; }
        @AuraEnabled public String  frequency             { get; set; }
        @AuraEnabled public String  location              { get; set; }  
        @AuraEnabled public String  tipoDeFormato         { get; set; }
        @AuraEnabled public Decimal totalQuantity         { get; set; }
        @AuraEnabled public Decimal minCommercialCapacity { get; set; } 
        @AuraEnabled public String  faixaHoraria          { get; set; }
        @AuraEnabled public String  diasDaSemana          { get; set; } 
        @AuraEnabled public Decimal discount              { get; set; }

        @AuraEnabled public String  Grupo_de_Programas_Canais_1 { get; set; }
        @AuraEnabled public String  Grupo_de_Programas_Canais_2 { get; set; }
        @AuraEnabled public String  Grupo_de_Programas_Canais_3 { get; set; }
        @AuraEnabled public String  Grupo_de_Programas_Canais_4 { get; set; }

        // Construtor
        public PriceItemData(PriceItem__c pi) { 
            this.recordTypeId          = pi.RecordTypeId; 
            this.catalogItem           = pi.Catalog_Item__c;
            this.commercialCapacity    = pi.Commercial_Capacity__c;
            this.pricePerUnit          = pi.Price_Per_Unit__c;
            this.spotLenght            = pi.Spot_Lenght__c;
            this.unit                  = pi.Unit__c;
            this.aMAPMediaType         = pi.AMAP_Media_Type__c;
            this.description           = pi.Description__c;
            this.frequency             = pi.Frequency__c;
            this.location              = pi.Location__r.Name; // Atualizado para usar o Name
            this.tipoDeFormato         = pi.Tipo_de_Formato__c;
            this.totalQuantity         = pi.Total_Quantity__c;
            this.minCommercialCapacity = pi.Min_Commercial_Capacity__c; 
            this.faixaHoraria          = pi.Faixa_Horaria__c;
            this.diasDaSemana          = pi.Dias_da_semana__c; 
            this.discount              = pi.Discount__c;
        }
    }
}
