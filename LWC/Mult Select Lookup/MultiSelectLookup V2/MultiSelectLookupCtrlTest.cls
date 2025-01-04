@isTest
public class MultiSelectLookupCtrlTest {
    
    @testSetup
    static void setupTestData() {
        Id recordTypeAccountProdutor = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Produtor').getRecordTypeId();

        // Criação de registros para o teste
        Account acc1 = new Account(Name = 'Test Account 1', RecordTypeId = recordTypeAccountProdutor);
        Account acc2 = new Account(Name = 'Test Account 2', RecordTypeId = recordTypeAccountProdutor); 
        insert new List<Account>{acc1, acc2};

        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', 'Test', new List<String>{}, '', ''); 
        System.debug('Contas Criadas => ' + result.size());
    }
    
    @isTest
    static void testRetriveSearchDataWithValue() {
        // Cenário com valor
        List<String> selectedIds = new List<String>{};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', 'Test', selectedIds, '', ''); 

        // Verificação do resultado esperado
        System.assertEquals(2, result.size(), 'O número de resultados esperados deveria ser 2.');
    }
    
    @isTest
    static void testRetriveSearchDataWithoutValue() {
        // Cenário sem valor
        List<String> selectedIds = new List<String>{};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', '', selectedIds, '', ''); 

        // Verificação do resultado esperado
        System.assertEquals(0, result.size(), 'O número de resultados esperados deveria ser 0.');
    }

    @isTest
    static void testRetriveSearchDataWithSelectedIds() {
        // Teste com IDs selecionados
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> selectedIds = new List<String>{acc1.Id};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', 'Test', selectedIds, '', ''); 

        // Verificação do resultado esperado
        System.assertEquals(1, result.size(), 'O número de resultados esperados deveria ser 1.');
    }

    @isTest
    static void testRetriveSearchDataWithValueAndRT() { 
        List<String> selectedIds = new List<String>{};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', 'Test', selectedIds, 'Produtor', ''); 

        // Verificação do resultado esperado
        System.assertEquals(2, result.size(), 'O número de resultados esperados deveria ser 2.'); 
    } 
/*
    @isTest
    static void testRetriveSearchDataWithRecordType() {
        // Cenário com RecordType
        List<String> selectedIds = new List<String>{};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', '', selectedIds, 'Produtor', ''); 

        // Verificação do resultado esperado
        System.assertEquals(2, result.size(), 'O número de resultados esperados deveria ser 2.');
    }  
*/  

    @isTest
    static void testRetriveSearchDataWithCondition() {
        // Cenário com RecordType e uma condição
        List<String> selectedIds = new List<String>{};
        List<SObject> result = MultiSelectLookupCtrl.retriveSearchData('Account', 'Name', 'Last modified', selectedIds, 'Produtor', ' Name != null '); 

        // Verificação do resultado esperado
        System.assertEquals(2, result.size(), 'O número de resultados esperados deveria ser 2.');
    }  
}