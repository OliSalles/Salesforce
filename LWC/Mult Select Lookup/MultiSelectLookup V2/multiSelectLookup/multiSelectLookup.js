import { LightningElement, api, track } from 'lwc';
import retriveSearchData from '@salesforce/apex/MultiSelectLookupCtrl.retriveSearchData';

export default class MultiSelectLookup extends LightningElement {
    @api objectname;  
    @api fieldnames = ' Id, Name ';
    @api Label;
    @track searchRecords = [];
    @track selectedRecords = [];
    @api iconName = 'standard:user'
    @track messageFlag = false;
    @track isSearchLoading = false;
    @api placeholder = 'Procurando..';
    @track searchKey;
    @track searchKeyToSearch; 
    @api ismultiselect;
    @api isResultsVisible = false;
    @api recordTypeName; 
    @api condition;
    delayTimeout;

    connectedCallback() {
        // Converta o parâmetro para booleano no connectedCallback
        if(this.ismultiselect === false || this.ismultiselect === 'false')
            this.ismultiselect = false; 

        this.searchKeyToSearch = 'Last modified';

        this.searchField();
    }

    handleLookupClick() {
        this.isResultsVisible = true;
    }

    searchField() {
        var selectedRecordIds = [];

        this.selectedRecords.forEach(ele=>{
            selectedRecordIds.push(ele.Id);
        })  

        console.log('this.recordTypeName ===> ' + this.recordTypeName);

        retriveSearchData({ ObjectName: this.objectname, fieldName: ' Id, Name ', value: this.searchKeyToSearch, selectedRecId: selectedRecordIds, recordTypeName: this.recordTypeName, condition: this.condition }) 
            .then(result => {
                this.searchRecords = result;
                this.isSearchLoading = false;
                const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
                const clsList = lookupInputContainer.classList;
                clsList.add('slds-is-open');

                if (this.searchKeyToSearch.length > 0 && result.length == 0) {
                    this.messageFlag = true;
                } else {
                    this.messageFlag = false;
                }
            }).catch(error => {
                console.log(error);
            });
    }

    handleKeyChange(event) {
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKeyToSearch = searchKey;
            this.searchField();
        }, 300);
    }

    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');

        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                this.searchField();
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    setSelectedRecord(event) {
        var recId = event.target.dataset.id;
        let newsObject = this.searchRecords.find(data => data.Id === recId);
        
        if ( this.ismultiselect ) {
            this.selectedRecords.push(newsObject);

        } else {
            this.selectedRecords = [newsObject]; // Substitui os registros selecionados
        }

        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        let selRecords = this.selectedRecords;
        this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });

        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        this.dispatchEvent(selectedEvent);
    }

    removeRecord(event) {
        let selectRecId = [];
        for (let i = 0; i < this.selectedRecords.length; i++) {
            if (event.detail.name !== this.selectedRecords[i].Id)
                selectRecId.push(this.selectedRecords[i]);
        }

        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        this.dispatchEvent(selectedEvent);
    }
}