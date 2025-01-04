import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getTodayEvents from '@salesforce/apex/EventCreatorController.getTodayEvents';
import getEventsTimeLine from '@salesforce/apex/EventCreatorController.getEventsTimeLine'; 
import getObjPrefix from '@salesforce/apex/EventCreatorController.getObjPrefix';

export default class EventCreatorCMP extends NavigationMixin(LightningElement) {

    objectApiName;  
    
    @api recordId; 
    @api haveEventsToday;
    @api ShowTimeLine;

    @track eventsToday = [];
    @track eventsTodayLimited = [];
    @track allEventsToday = [];

    @track eventsTimeLine = [];
    @track eventsTimeLineLimited = [];
    @track allEventsTimeLine = [];

    leadPrefix    = '';
    accountPrefix = '';
    agenciaPrefix = '';
    
    haveEventsToday = false;
    haveEventsTimeLine = false;
    isModalOpen = false;
    selectedOption = '';
    selectedParticipant = [];

    showAllEventsTodayLabel    = 'Ver mais atividades';
    showAllEventsTimeLineLabel = 'Ver mais atividades';

    options = [
        { label: 'Prospecção de Novos Parceiros', value: 'Prospecção de Novos Parceiros' },
        { label: 'Manutenção de Parceiros', value: 'Manutenção de Parceiros' },
        { label: 'Módulo Administrativo (Atividades Internas)', value: 'Modulo Administrativo (Atividades Internas)' }
    ];

    @track showLevelOneModal = false;
    @track selectedLevelOne = '';
    @track showMainModal = false;

    @wire(CurrentPageReference) 
    getPageReferenceParameters(currentPageReference) { 
        if (currentPageReference) { 
            this.recordId = currentPageReference.attributes.recordId;    
            this.objectApiName = currentPageReference.attributes.objectApiName;
        }  
    } 

    connectedCallback() {   

        if (this.recordId) {
            this.selectedParticipant.push(this.recordId);
        }

        getObjPrefix()
            .then(result => {
                if (result) {
                    // Acessando o prefixo do objeto Lead
                    this.leadPrefix    = result['Lead'].ObjectPrefix__c;     
                    this.accountPrefix = result['Account'].ObjectPrefix__c;  
                    this.agenciaPrefix = result['Agencia'].ObjectPrefix__c; 
                } 
            })
            .catch(error => {
                console.error('Erro ao buscar o valor do custom metadata:', error);
                // Lidar com o erro, como exibir uma mensagem de erro
            });

        this.loadEvents();

        if(this.ShowTimeLine){
            this.loadEventsTimeLine();
        }
    } 

    loadEvents() {

        console.log( 'loadEvents ===> ' );

        getTodayEvents({ recordId: this.recordId })
            .then(data => {
                const updatedEvents = data.map(event => {
                    let cssClass = 'activity';
    
                    if (event.whatId && ( event.whatId.startsWith(this.accountPrefix) || event.whatId.startsWith(this.agenciaPrefix) ) ) {
                        cssClass += ' maintenance'; // Manutenção de Parceiros
                    
                    } else if (event.whoId && event.whoId.startsWith(this.leadPrefix)) {
                        cssClass += ' prospecting'; // Prospecção de Novos Parceiros
                    
                    } else {
                        cssClass += ' admin'; // Atividades Administrativas
                    }
                    return { ...event, cssClass };
                });
                this.allEventsToday = [...updatedEvents];  

                // Limita a lista inicial a 5 eventos
                if(this.allEventsToday.length > 5)
                    this.eventsTodayLimited = this.allEventsToday.slice(0, 5);
                else
                    this.eventsTodayLimited = this.allEventsToday;

                this.eventsToday = this.eventsTodayLimited;
    
                this.haveEventsToday = this.eventsToday.length > 0;
            })
            .catch(error => {
                console.error('Error retrieving events: ', error);
            });
    }

    loadEventsTimeLine() {

        console.log( 'loadEventsTimeLine ===> ' );

        getEventsTimeLine({ recordId: this.recordId })
            .then(data => {
                const updatedEvents = data.map(event => {
                    let cssClass = 'activity';
    
                    if (event.whatId && ( event.whatId.startsWith(this.accountPrefix) || event.whatId.startsWith(this.agenciaPrefix) ) ) {
                        cssClass += ' maintenance'; // Manutenção de Parceiros
                    
                    } else if (event.whoId && event.whoId.startsWith(this.leadPrefix)) {
                        cssClass += ' prospecting'; // Prospecção de Novos Parceiros
                    
                    } else {
                        cssClass += ' admin'; // Atividades Administrativas
                    }
                    return { ...event, cssClass };
                });
                this.allEventsTimeLine = [...updatedEvents];  

                // Limita a lista inicial a 5 eventos
                if(this.allEventsTimeLine.length > 5)
                    this.eventsTimeLineLimited = this.allEventsTimeLine.slice(0, 5);
                else
                this.eventsTimeLineLimited = this.allEventsTimeLine;

                this.eventsTimeLine = this.eventsTimeLineLimited;
    
                this.haveEventsTimeLine = this.eventsTimeLine.length > 0;
            })
            .catch(error => {
                console.error('Error retrieving events: ', error);
            });
    }

    handleEventClick(event) {
        const eventId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: eventId,
                objectApiName: 'Event',
                actionName: 'view',
            },
        });
    }

    handleOpenModal() {

        console.log('this.objectApiName ===> ', this.objectApiName);
        
        if(this.objectApiName === 'Account' || this.objectApiName === 'Agencia__c'){
            this.showMainModal = true;
            this.selectedLevelOne = 'Manutenção de Parceiros';
        
        } else if(this.objectApiName === 'Lead'){
            this.showMainModal = true;
            this.selectedLevelOne = 'Prospecção de Novos Parceiros';
        
        } else {
            this.isModalOpen = true;
        } 
    }

    handleCloseModal() {
        this.isModalOpen = false;

        this.loadEvents();

        this.loadEventsTimeLine();
    }

    handleOptionChange(event) {
        this.selectedLevelOne = event.detail.value;
    }

    handleConfirm() {
        this.isModalOpen = false;
        this.showMainModal = true;
    } 

    showAllEvents() {

        if( this.eventsToday.length == this.eventsTodayLimited.length){
            this.eventsToday = this.allEventsToday; 
            this.showAllEventsTodayLabel = 'Ver menos atividades';
        }else{
            this.eventsToday = this.eventsTodayLimited;
            this.showAllEventsTodayLabel = 'Ver mais atividades';
        }
    } 

    showAllEventsTimeLine() { 

        if( this.eventsTimeLine.length == this.eventsTimeLineLimited.length){
            this.eventsTimeLine = this.allEventsTimeLine; 
            this.showAllEventsTimeLineLabel = 'Ver menos atividades';
        }else{
            this.eventsTimeLine = this.eventsTimeLineLimited;
            this.showAllEventsTimeLineLabel = 'Ver mais atividades';
        }
    } 

    handleClick() {
        this.showMainModal = true;
    }

    handleClose() {
        this.showMainModal = false;
  
        this.loadEvents();

        this.loadEventsTimeLine();
    }
}