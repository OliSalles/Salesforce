import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import xlsxLib from '@salesforce/resourceUrl/xlsxResource'; // Certifique-se de que o recurso está corretamente carregado
import createLeads from '@salesforce/apex/LeadUploaderController.createLeads';
import downloadCSVLead from '@salesforce/apex/LeadUploaderController.downloadCSVLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadUploader extends LightningElement {
    @track successMessage;
    @track errorMessage;
    @track selectedFileName;
    @track disableUploadButton = true;
    @track isLoading = false;

    renderedCallback() {
        if (this.xlsxInitialized) {
            return;
        }
        this.xlsxInitialized = true;

        loadScript(this, xlsxLib)
            .then(() => {
                console.log('Biblioteca XLSX carregada com sucesso.');
            })
            .catch(error => {
                console.error('Erro ao carregar a biblioteca XLSX', error);
                this.showErrorToast('Erro ao carregar biblioteca', error.message);
            });
    }

    handleDownloadExcel() {
        this.isLoading = true;

        downloadCSVLead()
            .then(result => {
                if (result && result.length > 0) {
                    const worksheet = XLSX.utils.json_to_sheet(result);
                    const workbook = XLSX.utils.book_new();
                    XLSX.utils.book_append_sheet(workbook, worksheet, 'Leads');
                    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
                    this.downloadFile(excelBuffer, `Modelo de importação de Leads.xlsx`, 'application/octet-stream');
                    this.showSuccessToast('Exportação Completa', 'O arquivo Excel foi exportado com sucesso.');
                } else {
                    this.showInfoToast('Nenhum arquivo Encontrado', ' ');
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                let errorMessage = error.body?.message || error.message || JSON.stringify(error);
                this.showErrorToast('Erro no download', errorMessage);
            });
    }

    downloadFile(content, filename, mimeType) {
        const blob = new Blob([content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.setAttribute('download', filename);
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    handleFileUpload(event) {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            this.isLoading = true;
            const reader = new FileReader();
            reader.onload = (e) => {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: 'array' });
                const sheetName = workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                const json = XLSX.utils.sheet_to_json(sheet);
                this.processExcelData(json);
            };
            reader.readAsArrayBuffer(file);
        }
    }

    processExcelData(data) {
        createLeads({ leadList: data })
            .then(() => {
                this.showSuccessToast('Sucesso', 'Leads criados com sucesso');
            })
            .catch(error => {
                this.showErrorToast('Erro ao criar leads', error.body?.message || error.message);
            })
            .finally(() => {
                this.clearFileInput();
                this.isLoading = false;
            });
    }

    clearFileInput() {
        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = null;
        }
        this.selectedFileName = null;
    }

    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant: 'success',
            mode: 'dismissable',
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant: 'error',
            mode: 'dismissable',
        });
        this.dispatchEvent(evt);
    }

    showInfoToast(title, message) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant: 'info',
            mode: 'dismissable',
        });
        this.dispatchEvent(evt);
    }
}
