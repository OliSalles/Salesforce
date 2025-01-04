import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processPriceItems from '@salesforce/apex/PriceItemImportController.processPriceItems';

import xlsxLib from '@salesforce/resourceUrl/xlsx_full_min_js';
import { loadScript } from 'lightning/platformResourceLoader';

export default class PriceItemImport extends LightningElement {
    isLoading = false; // Variável para controlar o estado de carregamento
    xlsxInitialized  = false; // Flag para garantir que a biblioteca XLSX seja carregada apenas uma vez

    @api recordId;

    renderedCallback() {
        // Garantindo que a biblioteca seja carregada apenas uma vez
        if (this.xlsxInitialized) {
            return;
        }
        this.xlsxInitialized = true;

        // Carregando a biblioteca XLSX
        loadScript(this, xlsxLib)
            .then(() => {
                console.log('Biblioteca XLSX carregada com sucesso');
            })
            .catch(error => {
                console.error('Erro ao carregar a biblioteca XLSX', error);
                this.sendToast('Erro', 'Erro ao carregar a biblioteca XLSX.', 'error');
            });
    }

    handleFileUpload(event) {
        console.log('Upload de arquivo iniciado.');

        // Verificando se há arquivos selecionados
        if (event.target.files.length > 0) {
            this.isLoading = true; // Ativando o estado de carregamento
            console.log('Arquivo selecionado:', event.target.files[0].name);

            const file = event.target.files[0];
            if (file) {
                const fileName = file.name;
                const fileExtension = fileName.split('.').pop().toLowerCase();
                console.log('Extensão do arquivo:', fileExtension);

                // Verificando o tipo de arquivo
                if (fileExtension === 'csv') {
                    console.log('Processando arquivo CSV...');
                    this.parseCsv(file);
                
                } else if (fileExtension === 'xlsx' || fileExtension === 'xls') {
                    console.log('Processando arquivo Excel...');
                    this.parseXlsx(file);
                
                } else {
                    console.warn('Formato de arquivo não suportado:', fileExtension);
                    this.showErrorToast('Erro', 'Formato de arquivo não suportado.');
                    this.isLoading = false; // Desativando o estado de carregamento
                }
            } else {
                console.error('Nenhum arquivo foi selecionado.');
                this.showErrorToast('Erro', 'Nenhum arquivo foi selecionado.');
                this.isLoading = false; // Desativando o estado de carregamento
            }
        } else {
            console.error('Nenhum arquivo foi selecionado.');
            this.showErrorToast('Erro', 'Nenhum arquivo foi selecionado.');
            this.isLoading = false; // Desativando o estado de carregamento
        }
    }

    parseCsv(file) {
        console.log('Iniciando leitura do arquivo CSV...');
        const reader = new FileReader();
        reader.onload = () => {
            console.log('Leitura do arquivo CSV concluída.');
            const csv = reader.result;
            const allTextLines = csv.split(/\r\n|\n/);
            const headers = allTextLines[0].split(',');
            const lines = [];

            console.log('Cabeçalhos CSV:', headers);

            for (let i = 1; i < allTextLines.length; i++) {
                const data = allTextLines[i].split(',');
                if (data.length === headers.length) {
                    const tarr = {};
                    for (let j = 0; j < headers.length; j++) {
                        tarr[headers[j].trim()] = data[j].trim();
                    }
                    lines.push(tarr);
                }
            }
            console.log('Dados processados do CSV:', lines);
            this.processData(lines);
        };
        reader.onerror = () => {
            console.error('Erro ao ler o arquivo CSV.');
            this.showErrorToast('Erro', 'Erro ao ler o arquivo CSV.');
            this.isLoading = false; // Desativando o estado de carregamento
        };
        reader.readAsText(file);
    }

    parseXlsx(file) {
        console.log('Iniciando leitura do arquivo Excel...');
        const reader = new FileReader();
        reader.onload = (e) => {
            console.log('Leitura do arquivo Excel concluída.');
            const data = new Uint8Array(e.target.result);
            const workbook = XLSX.read(data, { type: 'array' });
            const sheetName = workbook.SheetNames[0];
            const sheet = workbook.Sheets[sheetName];
            const json = XLSX.utils.sheet_to_json(sheet);

            console.log('Dados processados do Excel:', json);
            this.processData(json);
        };
        reader.onerror = () => {
            console.error('Erro ao ler o arquivo Excel.');
            this.showErrorToast('Erro', 'Erro ao ler o arquivo Excel.');
            this.isLoading = false; // Desativando o estado de carregamento
        };
        reader.readAsArrayBuffer(file);
    }

    processData(data) { 
        console.log('RecordId:', this.recordId);

        // Adicionar duas colunas vazias a cada linha
        const updatedData = data.map(row => {
            return {
                RecordTypeId: '', 
                priceItemId: '',   
                ...row            // Restante dos dados originais
            };
        });

        console.log('Dados com colunas adicionais:', updatedData);

        // Normalização dos dados
        const normalizedData = data.map(row => {
            const normalizedRow = {};
            for (const key in row) {
                if (row.hasOwnProperty(key)) {
                    let value = row[key];

                    // Remover espaços no início e no final de todas as strings
                    if (typeof value === 'string') {
                        value = value.trim();
                    }

                    // Verifica se o valor é um campo numérico que precisa de normalização
                    if (this.isNumericField(key)) {
                        value = this.normalizeNumber(value);
                    } 
                    normalizedRow[key] = value;
                }
            }
            return normalizedRow;
        });

        console.log('Dados normalizados:', normalizedData);

        const jsonData = JSON.stringify(normalizedData); 
        console.log('Dados convertidos para JSON:', jsonData);

        // Chamada ao método Apex
        processPriceItems({ recordId: this.recordId, dataList: jsonData })
            .then(result => { 
                    console.log('Batch agendado com sucesso. ', result);
                    this.sendToast('Sucesso', result, 'success'); 
            })
            .catch((error) => {
                // Tratar erro e exibir mensagem
                console.error('Erro ao processar os Price Items:', error);
                let errorMessage = error.body && error.body.message ? error.body.message : 'Erro desconhecido.';
                this.sendToast('Erro', errorMessage, 'error');
            })
            .finally(() => {
                this.clearFileInput();
                this.isLoading = false; // Desativando o estado de carregamento
            });
    }

    isNumericField(fieldName) {
        // Lista dos campos que precisam de normalização numérica
        const numericFields = [
            'commercialCapacity',
            'pricePerUnit',
            'spotLenght',
            'totalQuantity',
            'minCommercialCapacity',
            'discount'
        ];
        return numericFields.includes(fieldName);
    }

    normalizeNumber(value) {
        if (value == null) return null;
        // Remove espaços em branco
        value = value.toString().trim();
        // Remove separadores de milhares (pontos e vírgulas, exceto o último)
        value = value.replace(/[.,](?=[\d.,]*[.,])/g, '');
        // Substitui a vírgula restante pelo ponto como separador decimal
        value = value.replace(',', '.');
        return value;
    }

    clearFileInput() {
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            console.log('Limpando o campo de upload de arquivo.');
            fileInput.value = null;
        }
    }

    sendToast(title, message, variant) {
        const event = new CustomEvent('sendtoast', {
            detail: { title, message, variant },
        });
        this.dispatchEvent(event);
    }
}