global class GenerateAccountRows implements Database.Batchable<sObject>, Database.Stateful {

	private Integer indice;

	global static void iniciar(Integer indice) {
		Database.executeBatch(new GenerateAccountRows(indice), 5000);
	}

	global GenerateAccountRows(Integer indice) {
		this.indice = indice;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([select id from account limit 1]);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<Account> lstContas = new List<Account>();
		for (Integer i=0; i<5000;i++) {
			lstContas.add(new Account(Name = 'Acc' + indice + i));
		}
		insert lstContas;
	}

	global void finish(Database.BatchableContext BC) {
		indice++;
		if (indice <= 11) {
			GenerateAccountRows.iniciar(indice);
		}
	}
}