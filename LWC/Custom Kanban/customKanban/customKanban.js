import { LightningElement, wire, track } from 'lwc';
import getStatusPicklistValues from '@salesforce/apex/CustomKanbanController.getStatusPicklistValues';
import getManutencaoCountByStatus from '@salesforce/apex/CustomKanbanController.getManutencaoCountByStatus';
import getManutencoesByStatus from '@salesforce/apex/CustomKanbanController.getManutencoesByStatus';
import updateManutencaoStatus from '@salesforce/apex/CustomKanbanController.updateManutencaoStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class CustomKanban extends LightningElement {
    @track columns = [];
    statuses = [];
    statusCountMap = {};
    isLoading = false;

    // Variável para armazenar o resultado do wire da contagem, para usar com refreshApex
    wiredManutencaoCountResult;

    @wire(getStatusPicklistValues)
    wiredStatusValues({ data, error }) {
        if (data) {
            this.statuses = data;
            this.updateColumns();
        } else if (error) {
            this.handleError(error, 'Erro ao carregar os status');
        }
    }

    @wire(getManutencaoCountByStatus)
    wiredManutencaoCount(result) {
        const { data, error } = result;
        this.wiredManutencaoCountResult = result; // Armazena o result para refresh
        if (data) {
            this.statusCountMap = data;
            this.updateColumns();
        } else if (error) {
            this.handleError(error, 'Erro ao carregar contagem total de manutenções');
        }
    }

    updateColumns() {
        if (this.statuses && this.statuses.length > 0 && this.statusCountMap) {
            this.createColumns();
        }
    }

    createColumns() {
        const statusClasses = {
            'Parceiro Ativo': 'status-parceiro-ativo',
            'Recuperar Parceiro': 'status-recuperar-parceiro',
            'Manter Parceiro': 'status-manter-parceiro',
            'Potencializar Parceiro': 'status-potencializar-parceiro',
            'Inativar Parceiro': 'status-inativar-parceiro',
        };

        this.columns = this.statuses.map(status => {
            const className  = 'column ' + (statusClasses[status] || 'status-default');
            const totalCount = this.statusCountMap[status] ? this.statusCountMap[status] : 0;
            return {
                status: status,
                className: className,
                manutencoes: [],
                totalCount: totalCount,
                currentPage: 1,
                pageSize: 20
            };
        });

        // Carregar dados para cada coluna
        this.columns.forEach(column => {
            this.loadColumnData(column);
        });
    }

    loadColumnData(column) {
        const offset = (column.currentPage - 1) * column.pageSize;
        getManutencoesByStatus({ status: column.status, limitSize: column.pageSize, offsetSize: offset })
            .then(data => {
                column.manutencoes = data;
                // Força atualização do array columns para re-renderizar
                this.columns = [...this.columns];
            })
            .catch(error => {
                this.handleError(error, 'Erro ao carregar manutenções para o status ' + column.status);
            });
    }

    allowDrop(event) {
        event.preventDefault();
    }

    handleDragStart(event) {
        event.dataTransfer.setData('manutencaoId', event.currentTarget.dataset.id);
    }

    handleDrop(event) {
        event.preventDefault();
        const manutencaoId = event.dataTransfer.getData('manutencaoId');
        const newStatus = event.currentTarget.dataset.status;
        this.updateStatus(manutencaoId, newStatus);
    }

    updateStatus(manutencaoId, newStatus) {
        updateManutencaoStatus({ manutencaoId: manutencaoId, newStatus: newStatus })
            .then(() => {
                this.showToast('Sucesso', 'Status atualizado com sucesso', 'success');
                // Após atualizar, é preciso atualizar a contagem total e recarregar os dados
                return refreshApex(this.wiredManutencaoCountResult);
            })
            .then(() => {
                // Recria as colunas com a contagem atualizada e recarrega as páginas
                this.createColumns();
            })
            .catch(error => {
                this.handleError(error, 'Erro ao atualizar status');
            });
    }

    handleNextPageForColumn(event) {
        const status = event.currentTarget.dataset.status;
        const columnIndex = this.columns.findIndex(col => col.status === status);
        if (columnIndex >= 0) {
            const column = this.columns[columnIndex];
            if (column.currentPage * column.pageSize < column.totalCount) {
                column.currentPage++;
                this.loadColumnData(column);
            }
        }
    }

    handlePreviousPageForColumn(event) {
        const status = event.currentTarget.dataset.status;
        const columnIndex = this.columns.findIndex(col => col.status === status);
        if (columnIndex >= 0) {
            const column = this.columns[columnIndex];
            if (column.currentPage > 1) {
                column.currentPage--;
                this.loadColumnData(column);
            }
        }
    }

    handleError(error, defaultMessage) {
        let message = defaultMessage;
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.showToast('Erro', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    updateColumnState(column) {
        column.isFirstPage = (column.currentPage === 1);
        column.isLastPage = (column.currentPage * column.pageSize >= column.totalCount);
    } 
}
