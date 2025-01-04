import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { updateRecord, getRecordUi } from 'lightning/uiRecordApi';
import getManutencaoStatus from '@salesforce/apex/CustomPathController.getManutencaoStatus';
import saveManutencaoStatus from '@salesforce/apex/CustomPathController.saveManutencaoStatus';
import USER_ID from '@salesforce/user/Id';
import {
    ScenarioState,
    ScenarioLayout,
    MarkAsCompleteScenario,
    MarkAsCurrentScenario,
    SelectClosedScenario,
    ChangeClosedScenario,
    Step,
    getMasterRecordTypeId,
    getRecordTypeId
} from './utils'; 

// value to assign to the last step when user has to select a proper closed step
const OPEN_MODAL_TO_SELECT_CLOSED_STEP = 'pathAssistant_selectAClosedStepValue';

import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CustomPath extends LightningElement {
    userId = USER_ID; // Adicionado para obter o ID do usuário logado
    @api gacProject;
    @api objectApiName;
    @api recordId;
    @api picklistField;
    @api closedOk;
    @api closedKo;
    @api lastStepLabel;
    @api hideUpdateButton;
    @track spinner = false;
    @track openModal = false;
    @track objectInfo;
    @track record;
    @track errorMsg;
    @track possibleSteps;
    @track selectedStepValue;
    _recordTypeId;
    _currentScenario;
    _selectedClosedStepValue;
    _scenarios = [];
    filteredRecords;
    newStatus;

    connectedCallback() {
        console.log('Record ID:', this.recordId);
        console.log('User ID:', this.userId);

        if ( !this.gacProject ) { return }

        this.loadMaintenanceStatus();
    }

    loadMaintenanceStatus() {
        console.log('Iniciando consulta status', this.recordId, this.userId);
        getManutencaoStatus({ accountId: this.recordId, userId: this.userId })
            .then(result => {
                console.log('Status consultado....');

                if (this.gacProject) {
                    this.filteredRecords = result.Status__c;
                }
            })
            .catch(error => {
                console.error('Error fetching maintenance status', error);
            })
    } 

    constructor() {
        super();
        const token = '{0}';

        this._scenarios.push(
            new MarkAsCompleteScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Mark {0} as Complete',
                    token
                )
            )
        );

        this._scenarios.push(
            new MarkAsCurrentScenario(
                new ScenarioLayout('', 'Mark as Current {0}', token)
            )
        );

        this._scenarios.push(
            new SelectClosedScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Select Closed {0}',
                    token
                )
            )
        );

        this._scenarios.push(
            new ChangeClosedScenario(
                new ScenarioLayout(
                    'Select Closed {0}',
                    'Change Closed {0}',
                    token
                )
            )
        );
    }

    @wire(getRecordUi, {
        recordIds: '$recordId',
        layoutTypes: 'Full',
        modes: 'View'
    })
    wiredRecordUI({ error, data }) {
        if (error) {
            this.errorMsg = error.body.message;
        }

        if (data && data.records[this.recordId]) {
            this.record = data.records[this.recordId];
            this.objectInfo = data.objectInfos[this.objectApiName];
            const rtId = getRecordTypeId(this.record);
            this._recordTypeId = rtId
                ? rtId
                : getMasterRecordTypeId(this.objectInfo);
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectApiName',
        recordTypeId: '$_recordTypeId'
    })
    wiredPicklistValues({ error, data }) {
        if (!this._recordTypeId) {
            return;
        }

        if (error) {
            this.errorMsg = error.body.message;
        }

        if (data) {
            if (data.picklistFieldValues[this.picklistField]) {
                this.possibleSteps = data.picklistFieldValues[
                    this.picklistField
                ].values
                .filter(elem => elem.value !== 'NA')
                .map((elem, idx) => {
                    return new Step(elem.value, elem.label, idx);
                });

                this._validateSteps();
            } else {
                this.errorMsg = `Impossible to load ${
                    this.picklistField
                } values for record type ${this._recordTypeId}`;
            }
        }
    }

    _setCurrentScenario() {
        const state = new ScenarioState(
            this.isClosed,
            this.selectedStepValue,
            this.currentStep.value,
            OPEN_MODAL_TO_SELECT_CLOSED_STEP
        );

        for (let idx in this._scenarios) {
            if (this._scenarios[idx].appliesToState(state)) {
                this._currentScenario = this._scenarios[idx];
                break;
            }
        }
    }

    _validateSteps() {
        let isClosedOkAvailable = false;
        let isClosedKoAvailable = false;

        this.possibleSteps.forEach(step => {
            isClosedKoAvailable |= step.equals(this.closedKo);
            isClosedOkAvailable |= step.equals(this.closedOk);
        });

        if (!isClosedOkAvailable) {
            this.errorMsg = `${
                this.closedOk
            } value is not available for record type ${this._recordTypeId}`;
        }

        if (!isClosedKoAvailable) {
            this.errorMsg = `${
                this.closedKo
            } value is not available for record type ${this._recordTypeId}`;
        }

        if (this.possibleSteps.length < 3) {
            this.errorMsg = `Not enough picklist values are available for record type ${
                this._recordTypeId
            }.`;
        }
    }

    _getStepElementCssClass(step) {
        let classText = 'slds-path__item';

        if (step.equals(this.closedOk)) {
            classText += ' slds-is-won';
        }

        if (step.equals(this.closedKo)) {
            classText += ' slds-is-lost';
        }

        if (step.equals(this.selectedStepValue)) {
            classText += ' slds-is-active';
        }

        if (step.equals(this.currentStep)) {
            classText += ' slds-is-current';

            if (!this.selectedStepValue) {
                classText += ' slds-is-active';
            }
        } else if (step.isBefore(this.currentStep) && !this.isClosedKo) {
            classText += ' slds-is-complete';
        } else {
            classText += ' slds-is-incomplete';
        }

        return classText;
    }

    _resetComponentState() {
        this.record = undefined;
        this.selectedStepValue = undefined;
        this._selectedClosedStepValue = undefined;
        this._currentScenario = undefined;
    }

    _updateRecord(stepValue) {

        let toUpdate = {
            fields: {
                Id: this.recordId
            }
        };

        toUpdate.fields[this.picklistField] = stepValue;

        this.spinner = true;

        if (this.gacProject) {
            this.spinner = false;
            return;
        }

        updateRecord(toUpdate)
            .then(() => {
                this.spinner = false; 
                
                    getRecordNotifyChange([{recordId: this.recordId}]); 
            })
            .catch(error => {
                this.errorMsg = error.body.message;
                this.spinner = false;
            });

        this._resetComponentState();
    }

    get currentStep() {
        for (let idx in this.possibleSteps) {
            if (this.gacProject) {

                if (this.possibleSteps[idx].equals(this.filteredRecords)) {
                    return this.possibleSteps[idx];
                }else{

                }
            } else {
                if (this.possibleSteps[idx].equals(this.record.fields[this.picklistField].value)) {
                    return this.possibleSteps[idx];
                }
            }
        }
        return new Step();
    }

    get nextStep() {
        return this.possibleSteps[this.currentStep.index + 1];
    }

    get steps() {
        let closedOkElem;
        let closedKoElem;

        let res = this.possibleSteps
            .filter(step => {
                if (step.equals(this.closedOk)) {
                    closedOkElem = step;
                    return false;
                }

                if (step.equals(this.closedKo)) {
                    closedKoElem = step;
                    return false;
                }

                return true;
            })
            .map(step => {
                step.setClassText(this._getStepElementCssClass(step));
                return step;
            });

        let lastStep;

        if (this.isClosedOk) {
            lastStep = closedOkElem;
        } else if (this.isClosedKo) {
            lastStep = closedKoElem;
        } else {
            lastStep = new Step(
                OPEN_MODAL_TO_SELECT_CLOSED_STEP,
                this.lastStepLabel,
                Infinity
            );
        }

        lastStep.setClassText(this._getStepElementCssClass(lastStep));

        res.push(lastStep);

        return res;
    }

    get closedSteps() {
        return this.possibleSteps.filter(step => {
            return step.equals(this.closedKo) || step.equals(this.closedOk);
        });
    }

    get updateButtonText() {
        return this._currentScenario
            ? this._currentScenario.layout.getUpdateButtonText(
                  this.picklistFieldLabel
              )
            : '';
    }

    get modalHeader() {
        return this._currentScenario
            ? this._currentScenario.layout.getModalHeader(
                  this.picklistFieldLabel
              )
            : '';
    }

    get selectLabel() {
        return this.picklistFieldLabel;
    }

    get picklistFieldLabel() {
        return this.objectInfo.fields[this.picklistField].label;
    }

    get isClosed() {
        return this.isClosedKo || this.isClosedOk;
    }

    get isClosedOk() {
        return this.currentStep.equals(this.closedOk);
    }

    get isClosedKo() {
        return this.currentStep.equals(this.closedKo);
    }

    get isLoaded() {
        const res = this.record && this.objectInfo && this.possibleSteps;
        if (res && !this._currentScenario) {
            this._setCurrentScenario();
        }
        return res;
    }
    

    get isUpdateButtonDisabled() {
        return !this.currentStep.hasValue() && !this.selectedStepValue;
    }

    get hasToShowSpinner() {
        return this.spinner || !this.isLoaded;
    }

    get genericErrorMessage() {
        return 'An unexpected error occurred. Please contact your System Administrator.';
    }

    closeModal() {
        this.openModal = false;
    }

    setClosedStep(event) {
        this._selectedClosedStepValue = event.target.value;
    }

    handleStepSelected(event) {
        this.selectedStepValue = event.currentTarget.getAttribute('data-value');
        this._setCurrentScenario();
    }

    handleUpdateButtonClick() {
        this.handleSave();

        switch (this._currentScenario.constructor) {
            case MarkAsCompleteScenario:
                if (
                    this.nextStep.equals(this.closedKo) ||
                    this.nextStep.equals(this.closedOk)
                ) {
                    this.openModal = true;
                } else {
                    this._updateRecord(this.nextStep.value);
                }
                break;
            case MarkAsCurrentScenario:
                this._updateRecord(this.selectedStepValue);
                break;
            case SelectClosedScenario:
            case ChangeClosedScenario:
                this.openModal = true;
                break;
            default:
                break;
        }
    }

    handleSave() {  
        if ( !this.gacProject ) { return }

        let StepValue = '';

        if(this.selectedStepValue == 'pathAssistant_selectAClosedStepValue')
            StepValue = this.closedKo; 
        else
            StepValue = this.selectedStepValue;

        
        console.log('StepValue ===> ', StepValue);
        console.log('this.recordId ===> ', this.recordId);

        saveManutencaoStatus({ accountId: this.recordId, userId: this.userId, newStatus: StepValue })
            .then(result => {
                console.log('Status updated successfully', result);  
                this.loadMaintenanceStatus();
            })
            .catch(error => {
                console.error('Error updating status', error);
            });
    }

    handleSaveButtonClick() {
        if (!this._selectedClosedStepValue) {
            return;
        }

        if(!this.gacProject)
            this._updateRecord(this._selectedClosedStepValue);
        
        this.openModal = false;
    }
}