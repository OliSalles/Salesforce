import { api, LightningElement, track } from 'lwc';
const columns = [
    { label: 'Name',   fieldName: 'Name' },
    { label: 'E-mail', fieldName: 'Email'} 
];
export default class MultiSelectLookupCpm extends LightningElement {
    @api objectname; // Agora é uma propriedade @api
    @api objectlabel;
    @api ismultiselect;
    @api recordTypeName;
    @api condition;
    @api enableLayout = false;

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

        if( this.ismultiselect == 'false' ){
            
            this.selectedRecords = [...event.detail.selRecords];

        }else{ 

            this.selectedRecords = [...event.detail.selRecords];
        }

        this.selectedRecordsLength = this.selectedRecords.length;
        const enviaRegistros = new CustomEvent('registros', { detail: this.selectedRecords });
        this.dispatchEvent(enviaRegistros);
    }
}