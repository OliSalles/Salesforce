import { api, LightningElement, track } from 'lwc';
const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'E-mail', fieldName: 'Email'},
    { label: 'Telefone', fieldName: 'Phone'}
];
export default class multiSelectLookup extends LightningElement {
    @api objectname; // Agora é uma propriedade @api
    @api objectlabel;

    title;
    placeholder;

    @track selectedRecords = [];
    @track selectedRecordsLength; 
    columns = columns;

    connectedCallback() {
        this.title = "Buscar " + this.objectlabel;
        this.placeholder = "Digite o nome do " + this.objectlabel;
    }

    handleselectedCompanyRecords(event) {
        this.selectedRecords = [...event.detail.selRecords];
        this.selectedRecordsLength = this.selectedRecords.length;
        const enviaRegistros = new CustomEvent('registros', {detail: this.selectedRecords});
        this.dispatchEvent(enviaRegistros);
    };
}