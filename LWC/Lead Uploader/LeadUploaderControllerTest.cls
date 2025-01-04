@IsTest
public class LeadUploaderControllerTest {

    @TestSetup
    static void setupTestData() {
        // Cria dados de teste se necessário, como Leads ou outros objetos relacionados
    }

    @IsTest
    static void testUploadLeadsSuccess() {
        // Simula os dados do Lead a serem carregados
        List<Map<String, String>> leadData = new List<Map<String, String>>();
        
        Map<String, String> lead1 = new Map<String, String>();
        lead1.put('FirstName', 'Test');
        lead1.put('LastName', 'Lead');
        lead1.put('Email', 'testlead@example.com');
        leadData.add(lead1);

        Map<String, String> lead2 = new Map<String, String>();
        lead2.put('FirstName', 'Another');
        lead2.put('LastName', 'Lead');
        lead2.put('Email', 'anotherlead@example.com');
        leadData.add(lead2);

        // Chama o método de uploadLeads
        Test.startTest();
        String result = LeadUploaderController.uploadLeads(leadData);
        Test.stopTest(); 
    }

    @IsTest
    static void testUploadLeadsWithException() {
        // Simula dados incompletos para gerar uma exceção
        List<Map<String, String>> leadData = new List<Map<String, String>>();
        
        Map<String, String> invalidLead = new Map<String, String>();
        invalidLead.put('FirstName', 'Invalid');
        invalidLead.put('LastName', 'Lead');
        // Email está faltando propositalmente para gerar um erro
        leadData.add(invalidLead); 
    }
}