import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import extractAllPriceItemFields from '@salesforce/apex/PriceItemExportController.extractAllPriceItemFields';
import { loadScript } from 'lightning/platformResourceLoader';
import xlsxLib from '@salesforce/resourceUrl/xlsx_full_min_js';
import getLastEventLog from '@salesforce/apex/PriceItemExportController.getLastEventLog'; // Import do novo Apex

export default class PriceItemExport extends LightningElement {
    isModalOpen = false;
    @api recordId;
    isLoading = false;
    xlsxInitialized = false;

    // Variáveis para armazenar o status do último carregamento
    @track lastEventStatus;
    @track statusMessage;

    // Novas variáveis para armazenar contadores separados
    @track successCountPriceItems;
    @track errorCountPriceItems;
    @track successCountRelations;
    @track errorCountRelations;

    renderedCallback() {
        if (this.xlsxInitialized) {
            return;
        }
        this.xlsxInitialized = true;

        this.isLoading = true;

        loadScript(this, xlsxLib)
            .then(() => {
                console.log('Biblioteca XLSX carregada com sucesso.');
                this.isLoading = false; 
            })
            .catch(error => {
                console.error('Erro ao carregar a biblioteca XLSX', error);
                this.showErrorToast('Erro ao carregar biblioteca', error.message);
                this.isLoading = false; 
            });
    }

    // Recupera o último log via @wire
    @wire(getLastEventLog, { recordId: '$recordId' })
    wiredEventLog({ error, data }) {
        if (data) {
            this.lastEventStatus = data.Event_status__c;
            

            if (data.JSON_object__c) {
                try {
                    const jsonObj = JSON.parse(data.JSON_object__c);
                    // Agora obtemos cada contador separadamente
                    this.successCountPriceItems = jsonObj.successCountPriceItems || 0;
                    this.errorCountPriceItems   = jsonObj.errorCountPriceItems || 0;
                    this.successCountRelations  = jsonObj.successCountRelations || 0;
                    this.errorCountRelations    = jsonObj.errorCountRelations || 0;
                    this.statusMessage          = jsonObj.errors;
                } catch (e) {
                    console.error('Erro ao parsear JSON_object__c:', e);
                }
            }
        } else if (error) {
            console.error('Erro ao obter o último log:', error);
        }
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    exportAsCSV() {
        this.isModalOpen = false;
        this.handleExportCSV();
    }

    exportAsExcel() {
        this.isModalOpen = false;
        this.handleExportExcel();
    }

    handleExportCSV() {
        this.isLoading = true; 
        extractAllPriceItemFields({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    const csv = this.convertToCSV(result);
                    this.downloadFile(csv, `PriceItems_${new Date().toISOString()}.csv`, 'text/plain');
                    this.showSuccessToast('Exportação Completa', 'Os dados CSV foram exportados com sucesso.');
                } else {
                    this.showInfoToast('Nenhum Dado Encontrado', 'Não foram encontrados Price Items para exportar.');
                }
                this.isLoading = false; 
            })
            .catch(error => {
                this.isLoading = false; 
                let errorMessage = this.extractErrorMessage(error);
                this.showErrorToast('Erro na Exportação', errorMessage);
                console.error('Erro ao exportar Price Items:', error);
            });
    }

    handleExportExcel() {
        if (typeof window.XLSX === 'undefined') {
            this.showErrorToast('Erro', 'A biblioteca XLSX não foi carregada corretamente.');
            return;
        }

        this.isLoading = true; 
        extractAllPriceItemFields({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    const worksheetData = this.prepareWorksheetData(result);
                    const workbook  = window.XLSX.utils.book_new();
                    const worksheet = window.XLSX.utils.json_to_sheet(worksheetData);

                    window.XLSX.utils.book_append_sheet(workbook, worksheet, 'Price Items');

                    const wbout = window.XLSX.write(workbook, { bookType: 'xlsx', type: 'binary' });
                    const buf = this.s2ab(wbout);
                    const blob = new Blob([buf], { type: 'application/octet-stream' });
                    this.downloadBlob(blob, `Modelo de importação de Price Items.xlsx`);
                    this.showSuccessToast('Exportação Completa', 'Os dados Excel foram exportados com sucesso.');
                } else {
                    this.showInfoToast('Nenhum Dado Encontrado', 'Não foram encontrados Price Items para exportar.');
                }
                this.isLoading = false; 
            })
            .catch(error => {
                this.isLoading = false; 
                let errorMessage = this.extractErrorMessage(error);
                this.showErrorToast('Erro na Exportação', errorMessage);
                console.error('Erro ao exportar Price Items:', error);
            });
    }

    s2ab(s) {
        const buf = new ArrayBuffer(s.length);
        const view = new Uint8Array(buf);
        for (let i = 0; i < s.length; i++) {
            view[i] = s.charCodeAt(i) & 0xFF;
        }
        return buf;
    }

    prepareWorksheetData(data) {
        if (!data || !data.length) {
            return [];
        }

        const headers = [
            'commercialCapacity', 'pricePerUnit', 'spotLenght', 'unit', 'aMAPMediaType', 
            'description', 'frequency', 'location','tipoDeFormato', 'totalQuantity', 
            'minCommercialCapacity', 'faixaHoraria', 'diasDaSemana', 'discount', 
            'Grupo_de_Programas_Canais_1', 'Grupo_de_Programas_Canais_2',
            'Grupo_de_Programas_Canais_3', 'Grupo_de_Programas_Canais_4'
        ];

        return data.map(record => {
            const rowData = {};
            headers.forEach(header => {
                rowData[header] = record[header] || '';
            });
            return rowData;
        });
    }

    convertToCSV(data) {
        if (!data || !data.length) {
            return '';
        }

        const headers = [
            'commercialCapacity', 'pricePerUnit', 'spotLenght', 'unit', 'aMAPMediaType', 
            'description', 'frequency', 'location', 'tipoDeFormato', 'totalQuantity', 
            'minCommercialCapacity', 'faixaHoraria', 'diasDaSemana', 'discount',
            'Grupo_de_Programas_Canais_1', 'Grupo_de_Programas_Canais_2',
            'Grupo_de_Programas_Canais_3', 'Grupo_de_Programas_Canais_4'
        ];

        const csvRows = [];
        csvRows.push(headers.join(','));

        data.forEach(record => {
            const values = headers.map(header => {
                let value = record[header];
                if (value === null || value === undefined) {
                    value = '';
                } else if (typeof value === 'string') {
                    value = `"${value.replace(/"/g, '""')}"`;
                }
                return value;
            });
            csvRows.push(values.join(','));
        });

        return csvRows.join('\n');
    }

    downloadFile(content, filename, mimeType) {
        const bom = '\uFEFF';
        const blob = new Blob([bom + content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.setAttribute('download', filename);
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    downloadBlob(blob, filename) {
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);

        link.href = url;
        link.setAttribute('download', filename);
        document.body.appendChild(link);
        link.click();

        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }

    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showInfoToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'info',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    extractErrorMessage(error) {
        let errorMessage = 'Ocorreu um erro desconhecido.';
        if (error) {
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            } else {
                errorMessage = JSON.stringify(error);
            }
        }
        return errorMessage;
    }

    handleToastEvent(event) {
        const { title, message, variant } = event.detail;
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(toastEvent);
    }
}