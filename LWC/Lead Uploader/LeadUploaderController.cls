/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-26-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LeadUploaderController {
    
    /*
    @AuraEnabled(cacheable=true)
    public static String uploadLeads(List<Map<String, String>> leadData) {
        try {
            List<Lead> leadsToInsertOrUpdate = new List<Lead>();

            // Iterar sobre os dados do Lead do arquivo Excel
            for (Map<String, String> row : leadData) {
                // Mapear os dados do Lead
                Lead lead = new Lead();
                lead.FirstName = row.get('FirstName');
                lead.LastName = row.get('LastName');
                lead.Email = row.get('Email');
                // Adicione outros campos conforme necessário

                leadsToInsertOrUpdate.add(lead);
            }

            // Verificar se há registros para processar
            if (!leadsToInsertOrUpdate.isEmpty()) {
                // Utilize upsert para criar ou atualizar registros com base no e-mail
                Database.upsert(leadsToInsertOrUpdate, Lead.Email, true);
            }

            return 'Leads carregados com sucesso!';
        } catch (Exception e) {
            // Log de erro ou lógica de tratamento de exceção conforme necessário
            return 'Erro ao processar o arquivo Excel: ' + e.getMessage();
        }
    }
    */

    public static String uploadLeads(List<Map<String, String>> leadData) {
        return null;
    }

    @AuraEnabled
    public static void createLeads(List<Map<String, String>> leadList) {

        Id RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('GAC Lideres').getRecordTypeId();

        List<Lead> leadsToInsert = new List<Lead>();

        for (Map<String, String> leadData : leadList) {
            Lead lead = new Lead();
            for (String fieldApiName : leadData.keySet()) {
                try {
                    if(fieldApiName == 'Name'){
                        lead.put('LastName', leadData.get(fieldApiName));

                    }else if(fieldApiName == 'email'){
                        lead.put(fieldApiName, leadData.get(fieldApiName)); 

                    }else{
                        lead.put(fieldApiName + '__c', leadData.get(fieldApiName)); 
                    }
                } catch (Exception e) {
                    // Log de erro se o campo não existir ou não for acessível
                    System.debug('Campo inválido: ' + fieldApiName);
                }
            }
            lead.Status = 'Novo Parceiro';
            lead.OwnerId = userinfo.getuserid();
            lead.recordTypeId = RecordTypeId;

            leadsToInsert.add(lead);
        }

        if (!leadsToInsert.isEmpty()) {
            insert leadsToInsert;
        }
    }

        public class LeadData {
        @AuraEnabled public String Name                      { get; set; }
        @AuraEnabled public String TelefoneRelacionamento    { get; set; }
        @AuraEnabled public String Telefone_2                { get; set; }
        @AuraEnabled public String Email                     { get; set; }
        @AuraEnabled public String Tipo                      { get; set; }
        @AuraEnabled public String CPF                       { get; set; }
        @AuraEnabled public String CNPJ                      { get; set; }
        @AuraEnabled public String Numero_Proposta           { get; set; }
        @AuraEnabled public Decimal RendaMensal              { get; set; }
        @AuraEnabled public Decimal Valor_Total_Contribuicao { get; set; }
        @AuraEnabled public String Logradouro                { get; set; }
        @AuraEnabled public String NumeroResidencia          { get; set; }
        @AuraEnabled public String UF                        { get; set; }
        @AuraEnabled public String Cidade                    { get; set; }
        @AuraEnabled public String CEP                       { get; set; }
        @AuraEnabled public String Complemento               { get; set; }
        
        // Construtor
        public LeadData() {
            this.Name                     = '-';
            this.TelefoneRelacionamento   = '-';
            this.Telefone_2               = '-';
            this.Email                    = '-';
            this.Tipo                     = '-';
            this.CPF                      = '-';
            this.CNPJ                     = '-';
            this.Numero_Proposta          = '-';
            this.RendaMensal              = 0.0;
            this.Valor_Total_Contribuicao = 0.0;
            this.Logradouro               = '-';
            this.NumeroResidencia         = '-';
            this.UF                       = '-';
            this.Cidade                   = '-';
            this.CEP                      = '-';
            this.Complemento              = '-';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LeadData> downloadCSVLead() {

        List<LeadData> listLead = new List<LeadData>();
        
        listLead.add(new LeadData());

        return listLead;
    }
}