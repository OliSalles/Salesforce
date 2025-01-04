@isTest
public class CustomPathControllerTest {

    @testSetup
    static void setupData() { 
        // Criar uma conta de teste
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Criar um usuário de teste
        /*
        Profile p =            [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        */
        user testUser = [SELECT ID FROM USER WHERE EMAIL = 'laparecido@mag.com.br'];
        
        /*
        User testUser = new User(
            Username = 'testuser2319@test.com',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
        );
        insert testUser;
        */

        // Criar uma manutenção de teste
        Manutencao__c testManutencao = new Manutencao__c(
            Account__c = testAccount.Id,
            OwnerId = testUser.Id,
            Status__c = 'Parceiro Ativo',
            ExternalId__c = testUser.Id + '' + testAccount.Id
        );
        insert testManutencao;
    }

    @isTest
    static void testGetManutencaoStatus() {
        // Recuperar dados de configuração de teste
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'laparecido@mag.com.br' LIMIT 1];

        // Chamar o método getManutencaoStatus
        Test.startTest();
        CustomPathController.getManutencaoStatus(testAccount.Id, testUser.Id);
        Test.stopTest(); 
    }

    @isTest
    static void testSaveManutencaoStatus() {
        // Recuperar dados de configuração de teste
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'laparecido@mag.com.br' LIMIT 1];

        // Chamar o método saveManutencaoStatus para atualizar o status
        Test.startTest();
        CustomPathController.saveManutencaoStatus(testAccount.Id, testUser.Id, 'Parceiro Estacionado');
        Test.stopTest();
    } 
}