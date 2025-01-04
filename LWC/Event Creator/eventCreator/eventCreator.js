import { api, LightningElement, wire, track } from 'lwc';
import { getObjectInfo }     from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent }    from "lightning/platformShowToastEvent";

import EVENT_OBJECT     from '@salesforce/schema/Event';
import createEvent      from '@salesforce/apex/EventCreatorController.createEvent';
import getRecordTypeId  from '@salesforce/apex/EventCreatorController.getRecordTypeId';
import getObjPrefix     from '@salesforce/apex/EventCreatorController.getObjPrefix';

import LEVEL0NE_FIELD   from '@salesforce/schema/Event.Nivel_1__c'; 
import LEVELTOW_FIELD   from '@salesforce/schema/Event.Nivel_2__c'; 
import LEVELTHREE_FIELD from '@salesforce/schema/Event.Nivel_3__c'; 
import LEVELFOUR_FIELD  from '@salesforce/schema/Event.Nivel_4__c'; 

import EVENTTYPE_FIELD  from '@salesforce/schema/Event.TipoVisita__c'; 

export default class eventCreator extends LightningElement {
    @track eventId;
    @track error;

    @track selectedParticipants = [];
    @api participants = [];   
    @api objectApiName;

    @wire(getObjectInfo, { objectApiName: EVENT_OBJECT })
    eventInfo;  

    @track tituloEvento = '';
    
    @track levelOneOptions;
    @track levelTwoOptions; 
    @track levelThreeOptions; 
    @track levelFourOptions;

    @api   levelOne; 
    @track levelTwo; 
    @track levelThree; 
    @track levelFour; 

    @track eventTypeOptions; 
    @track eventType; 
    
    @track startDateTime = new Date().toISOString();
    @track endDateTime   = new Date(new Date().getTime() + 15 * 60000).toISOString();

    @track showTituloError      = false;
    @track showLevelOneError    = false;
    @track showLevelTwoError    = false;
    @track showLevelThreeError  = false;
    @track showLevelFourError   = false;
    @track showStartDateError   = false;
    @track showEndDateError     = false; 
    @track showParticipantError = true;

    @track isLoading = false; 
 
    @api enableLayout = false;
    @api recordTypeId;
    @api ismobile = false;
    @api disabledlevelone = false;

    @track EventLead = false;
    @track EventAccount = false;
    @track EventUsers = false;

    lvlOnePromise;
    lvlTwoPromise;
    lvlThreePromise;
    lvlFourPromise;
    eventTypePromise;

    recurrence = false;
    recurrenceType;
    dateToEndRecurrence;
    recurrenceTypeOptions = [{label: 'Diário', value: "Diário"}, {label: 'Semanal', value: "Semanal"}, {label: 'Mensal', value: "Mensal"}];

    createPromise() {
        let resolve;
        let reject;

        const promise = new Promise((res, rej) => {
            resolve = res;
            reject = rej;
        });

        return { promise, resolve, reject };
    }

    createPromises() {
        this.lvlOnePromise = null;
        this.lvlTwoPromise = null;
        this.lvlThreePromise = null;
        this.lvlFourPromise = null;
        this.eventTypePromise = null;
    };

    resolvePromise(promiseObj) {
        if (promiseObj && promiseObj.resolve) {
            promiseObj.resolve();
        }
    }

    executePromisesWhenReady() {
        const promises = [];

        if (this.lvlOnePromise) promises.push(this.lvlOnePromise.promise);
        if (this.lvlTwoPromise) promises.push(this.lvlTwoPromise.promise);
        if (this.lvlThreePromise) promises.push(this.lvlThreePromise.promise);
        if (this.lvlFourPromise) promises.push(this.lvlFourPromise.promise);
        if (this.eventTypePromise) promises.push(this.eventTypePromise.promise);
    
        Promise.all(promises).then(() => {
            this.processLevelOne();
        }).catch(error => {
            console.error('Erro ao resolver todas as promessas: ', error);
        }).finally(() => {
            console.log('Fechando loading!!!');
            this.isLoading = false;
        });
    }

    connectedCallback() { 
        this.isLoading = true; 

        this.loadRecordTypeId();
        this.createPromises();

        console.log('participants ===> ', JSON.stringify( this.participants ) );
    } 

    async loadRecordTypeId() {
        try {
            // Obtenha o Record Type ID
            const recordTypeId = await getRecordTypeId({ objectApiName: 'Event', recordTypeName: this.levelOne });
            this.recordTypeId = recordTypeId;
 
        } catch (error) {
            console.error('Erro ao carregar os valores dos picklists:', error);
        }
    }

    checkPromisesReady() {
        if (this.lvlOnePromise && this.lvlTwoPromise && this.lvlThreePromise &&
            this.lvlFourPromise && this.eventTypePromise) {
            this.executePromisesWhenReady();
        }
    }

    processLevelOne() {
        console.log('Processando Level 1', this.levelOneFieldData);
        if (!this.levelOneFieldData) {
            return;
        }

        this.levelOneOptions = this.levelOneFieldData;
        this.setLevelOneFromParticipants(); 

        console.log('Opções carregadas',this.levelOneOptions);
        console.log('Level One do PAI', this.levelOne);
        if(this.levelOne){

            this.handleLevelOneChange({ target: { value: this.levelOne } });
            
            if (this.levelTwoFieldData) {
                let key = this.levelTwoFieldData.controllerValues[ this.levelOne ];
                this.levelTwoOptions = this.levelTwoFieldData.values.filter(opt => opt.validFor.includes(key));
            }

            this.disabledlevelone = true;
        } 
    }

    get isLevelFourDisabled() {
        return !this.levelFourOptions || this.levelFourOptions.length === 0;
    }
    
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: EVENTTYPE_FIELD })
    eventTypeFieldInfo({ data, error }) {
        if (!this.eventTypePromise) {
            this.eventTypePromise = this.createPromise();
        }

        if (data) {
            this.eventTypeOptions = data.values; 
            this.resolvePromise(this.eventTypePromise);
            console.log('Executado promise eventType!');
        } else if (error) {
            this.eventTypePromise.reject(error);
        } 
        this.checkPromisesReady()
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: LEVELFOUR_FIELD })
    levelFourFieldInfo({ data, error }) {
        if (!this.lvlFourPromise) {
            this.lvlFourPromise = this.createPromise();
        }

        if (data) {
            this.levelFourFieldData = data; 
            this.resolvePromise(this.lvlFourPromise);
            console.log('Executado promise level four!');
        } else if (error) {
            this.lvlFourPromise.reject(error);
        }

        this.checkPromisesReady()
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: LEVELTHREE_FIELD })
    levelThreeFieldInfo({ data, error }) {
        if (!this.lvlThreePromise) {
            this.lvlThreePromise = this.createPromise();
        }

        if (data) {
            this.levelThreeFieldData = data; 
            this.resolvePromise(this.lvlThreePromise);
            console.log('Executado promise level three!');
        } else if (error) {
            this.lvlThreePromise.reject(error);
        }

        this.checkPromisesReady()
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: LEVELTOW_FIELD })
    levelTwoFieldInfo({ data, error }) {
        if (!this.lvlTwoPromise) {
            this.lvlTwoPromise = this.createPromise();
        }

        if (data) {
            this.levelTwoFieldData = data; 
            this.resolvePromise(this.lvlTwoPromise);
            console.log('Executado promise level two!');
        } else if (error) {
            this.lvlTwoPromise.reject(error);
        }

        this.checkPromisesReady()
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: LEVEL0NE_FIELD })
    levelOneFieldInfo({ data, error }) {
        if (!this.lvlOnePromise) {
            this.lvlOnePromise = this.createPromise();
        }
    
        if (data) {
            this.levelOneFieldData = data.values;
            this.resolvePromise(this.lvlOnePromise);
            console.log('Executado promise level one!');
        } else if (error) {
            this.lvlOnePromise.reject(error);
        }

        this.checkPromisesReady()
    } 

    handleCancel() {
        // Reset all tracked properties to their initial state
        this.tituloEvento  = '';
        this.startDateTime = new Date().toISOString();
        this.endDateTime   = new Date(new Date().getTime() + 15 * 60000).toISOString();
        this.levelOne      = '';
        this.levelTwo      = '';
        this.levelThree    = '';
        this.levelFour     = '';
         
        this.eventType     = '';
        this.participants  = [];
        this.selectedParticipants = [];

        // Reset error states
        this.showTituloError     = false;
        this.showLevelOneError   = false;
        this.showLevelTwoError   = false;
        this.showLevelThreeError = false;
        this.showLevelFourError  = false;
        this.showStartDateError  = false;
        this.showEndDateError    = false; 

        // Hide modal if applicable
        this.showModal = false;

        // Dispatch cancel event if needed
        const event = new CustomEvent('cancel');
        this.dispatchEvent(event);
    }

    handleTituloChange(event) {
        this.tituloEvento = event.target.value;
        if (this.tituloEvento) {
            this.showTituloError = false;
        }
    }

    setLevelOneFromParticipants() {
        if (this.participants && this.participants.length > 0) {
            getObjPrefix()
                .then(result => {
                    if (result) {
                        // Acessando o prefixo do objeto Lead
                        const leadPrefix    = result['Lead'].ObjectPrefix__c;     
                        const accountPrefix = result['Account'].ObjectPrefix__c;  
                        const agenciaPrefix = result['Agencia'].ObjectPrefix__c;

                        if (this.participants[0].startsWith(leadPrefix)) {
                            this.levelOne = 'Prospecção de Novos Parceiros';
                        
                        } else if (this.participants[0].startsWith(accountPrefix) || this.participants[0].startsWith(agenciaPrefix)) {
                            this.levelOne = 'Manutenção de Parceiros'; 
                        }
                    } 
                })
                .catch(error => {
                    console.error('Erro ao buscar o valor do custom metadata:', error);
                    // Lidar com o erro, como exibir uma mensagem de erro
                });
        }
    }
    
    handleLevelOneChange(event) {
        this.levelOne = event.target.value;
        console.log('Level one selected!!!', this.levelOne);
        this.showLevelOneError = false;

        if (this.levelTwoFieldData) {
            let key = this.levelTwoFieldData.controllerValues[event.target.value];
            this.levelTwoOptions = this.levelTwoFieldData.values.filter(opt => opt.validFor.includes(key));
        } 
        console.log(' objectApiName ===> ', this.objectApiName);

        if (!this.objectApiName){
            if (this.levelOne == 'Prospecção de Novos Parceiros' && this.disabledlevelone == false) {
                this.EventLead = true;
                this.EventAccount = false;
                this.EventUsers = false;
            
            } else if (this.levelOne == 'Manutenção de Parceiros' && this.disabledlevelone == false) {
                this.EventLead = false;
                this.EventAccount = true;
                this.EventUsers = false;
            
            } else if (this.levelOne == 'Modulo Administrativo (Atividades Internas)') {
                this.EventLead = false;
                this.EventAccount = false;
                this.EventUsers = true;
            }
        }
    }

    handlelevelTwoChange(event){
        this.levelTwo = event.target.value;

        this.showLevelTwoError = false;

        let key = this.levelThreeFieldData.controllerValues[event.target.value];
        this.levelThreeOptions = this.levelThreeFieldData.values.filter(opt => opt.validFor.includes(key));
    }

    handlelevelThreeChange(event){
        this.levelThree = event.target.value;
        this.showLevelThreeError = false;

        let key = this.levelFourFieldData.controllerValues[event.target.value];
        this.levelFourOptions = this.levelFourFieldData.values.filter(opt => opt.validFor.includes(key));
    }  

    handlelevelFourChange(event){
        this.levelFour = event.target.value;
        this.showLevelFourError = false;
    }  

    handleOwnerSelection(event) {
        this.selectedParticipants = event.detail;
        console.log(this.selectedParticipants);
        this.participants = this.selectedParticipants.map(users => users.Id);   
        console.log(this.participants);
    }  

    handleStartDateTimeChange(event) {

        const newDate = new Date(event.target.value);

        this.startDateTime = newDate.toISOString();
        this.showStartDateError = false;

        this.endDateTime = new Date(newDate.getTime() + 15 * 60000).toISOString();
    }

    handleEndDateTimeChange(event) {
        this.endDateTime = event.target.value;
        this.showEndDateError = false;
    }

    handleEventTypeChange(event) {
        this.eventType = event.target.value; 
    }

    handleSave() {  

        this.showTituloError      = !this.tituloEvento;
        this.showLevelOneError    = !this.levelOne;
        this.showLevelTwoError    = !this.levelTwo;
        this.showLevelThreeError  = !this.levelThree;
        this.showLevelFourError   = !this.levelFour;
        this.showStartDateError   = !this.startDateTime;
        this.showEndDateError     = !this.endDateTime;  
        this.showParticipantError = this.EventUsers ? true : this.participants.length > 0;

        console.log('this.showParticipantError ===> ', this.showParticipantError);

        if (this.tituloEvento && 
            this.levelOne && 
            this.levelTwo && 
            this.levelThree && 
            this.startDateTime && 
            this.endDateTime &&
            this.showParticipantError ) { 

            this.isLoading = true; 

            let descricaoEvento = this.template.querySelector('[data-id="descricaoEvento"]').value; 

            createEvent({
                title: this.tituloEvento,
                description: descricaoEvento,
                startDateTime: this.startDateTime,
                endDateTime: this.endDateTime,
                levelOne: this.levelOne,
                levelTwo: this.levelTwo,
                levelThree: this.levelThree,
                levelFour: this.levelFour,
                eventType: this.eventType,
                recordTypeIdStr: this.recordTypeId,
                participants: this.participants,
                recurrence: this.recurrence,
                recurrenceType: this.recurrenceType,
                recurrenceEndDate: this.dateToEndRecurrence
            })
            .then(result => {
                
                this.showModal = false;
                this.isLoading = false; // Hide loading spinner

                this.reloadComponent(); // Reload the component
                this.showNotification('Sucesso', 'Atividade criada com sucesso!', 'success');

                const event = new CustomEvent('submit');
                this.dispatchEvent(event);
                const activityCreation = new CustomEvent("createactivity",{
                    detail: {
                        activityId: result
                    }
                });
                this.dispatchEvent(activityCreation);
            })
            .catch(error => {
                console.error('Erro ao criar o evento: ' + error);
                this.isLoading = false; // Hide loading spinner
                this.showNotification('Erro', 'Erro ao criar o evento: ' + error.body.message, 'error');
            });
        } 
    } 

    reloadComponent() {
        // Reset all tracked properties to their initial state
        this.tituloEvento  = '';
        this.startDateTime = new Date().toISOString();
        this.endDateTime   = new Date(new Date().getTime() + 15 * 60000).toISOString();
        //this.levelOne    = '';
        this.levelTwo      = '';
        this.levelThree    = '';
        this.levelFour     = '';
        this.eventType     = '';
        this.participants  = [];
        this.selectedParticipants = [];

        // Reset error states
        this.showTituloError     = false;
        this.showLevelOneError   = false;
        this.showLevelTwoError   = false;
        this.showLevelThreeError = false;
        this.showLevelFourError  = false;
        this.showStartDateError  = false;
        this.showEndDateError    = false; 
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleRecurrenceChange(event){
        this.recurrence = event.detail.checked;
    }

    handleRecurrenceTypeChange(event){
        this.recurrenceType = event.detail.value;
    }

    handleRecurrenceDateChange(event){
        this.dateToEndRecurrence = event.detail.value;
    }
}