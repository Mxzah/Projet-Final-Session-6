import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../services/api.service';
import QRCodeStyling from 'styled-qr-code';

interface TableInfo {
    id: number;
    number: number;
    capacity: number;
    status: string;
    qr_token: string;
}

@Component({
    selector: 'app-admin-tables',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './admin-tables.component.html',
    styleUrls: ['./admin-tables.component.css']
})
export class AdminTablesComponent implements OnInit {
    tables: TableInfo[] = [];
    isLoading = true;
    copiedToken: string | null = null;

    // New table form
    newTableNumber: number | null = null;
    newTableCapacity: number = 4;
    isCreating = false;
    errorMessage: string | null = null;

    // Edit table
    editingTableId: number | null = null;
    editNumber: number | null = null;
    editCapacity: number | null = null;
    isUpdating = false;
    editErrorMessage: string | null = null;

    // Delete
    deletingTableId: number | null = null;
    confirmDeleteId: number | null = null;

    baseUrl: string = window.location.origin;

    // QR Style options
    qrDotType: string = 'rounded';
    qrDotColor: string = '#8a3f24';
    qrBgColor: string = '#fbf8f2';
    qrCornerSquareType: string = 'extra-rounded';
    qrCornerDotType: string = 'dot';
    qrCornerColor: string = '#1b1a17';
    qrSize: number = 250;

    dotTypes = ['square', 'dots', 'rounded', 'classy', 'classy-rounded', 'extra-rounded'];
    cornerSquareTypes = ['square', 'dot', 'extra-rounded'];
    cornerDotTypes = ['square', 'dot'];

    private qrInstances: Map<string, QRCodeStyling> = new Map();

    constructor(
        private apiService: ApiService,
        private cdr: ChangeDetectorRef,
        private ngZone: NgZone
    ) { }

    ngOnInit(): void {
        this.loadTables();
    }

    loadTables(): void {
        this.isLoading = true;
        this.apiService.get<TableInfo[]>('/api/tables').subscribe({
            next: (response) => {
                this.ngZone.run(() => {
                    if (response.success && response.data) {
                        this.tables = response.data;
                        this.isLoading = false;
                        this.cdr.detectChanges();
                        setTimeout(() => {
                            this.generateAllQrCodes();
                            this.cdr.detectChanges();
                        }, 100);
                    } else {
                        this.isLoading = false;
                        this.cdr.detectChanges();
                    }
                });
            },
            error: () => {
                this.ngZone.run(() => {
                    this.isLoading = false;
                    this.cdr.detectChanges();
                });
            }
        });
    }

    getTableUrl(table: TableInfo): string {
        const base = this.baseUrl.replace(/\/+$/, '');
        return `${base}/table/${table.qr_token}`;
    }

    onBaseUrlChange(): void {
        this.generateAllQrCodes();
    }

    generateAllQrCodes(): void {
        this.qrInstances.clear();
        this.tables.forEach(table => this.generateQrCode(table));
    }

    generateQrCode(table: TableInfo): void {
        const container = document.getElementById(`qr-${table.qr_token}`);
        if (!container) return;

        container.innerHTML = '';

        const qrCode = new QRCodeStyling({
            width: this.qrSize,
            height: this.qrSize,
            type: 'canvas',
            data: this.getTableUrl(table),
            margin: 8,
            dotsOptions: {
                color: this.qrDotColor,
                type: this.qrDotType as any,
            },
            backgroundOptions: {
                color: this.qrBgColor,
            },
            cornersSquareOptions: {
                type: this.qrCornerSquareType as any,
                color: this.qrCornerColor,
            },
            cornersDotOptions: {
                type: this.qrCornerDotType as any,
                color: this.qrCornerColor,
            },
            qrOptions: {
                errorCorrectionLevel: 'M',
            },
        });

        qrCode.append(container);
        this.qrInstances.set(table.qr_token, qrCode);
    }

    onStyleChange(): void {
        setTimeout(() => this.generateAllQrCodes(), 50);
    }

    downloadQr(table: TableInfo, format: 'svg' | 'png'): void {
        const qr = this.qrInstances.get(table.qr_token);
        if (!qr) return;

        const fileName = `restoqr-table-${table.number}.${format}`;

        if (format === 'svg') {
            const container = document.getElementById(`qr-${table.qr_token}`);
            const svgEl = container?.querySelector('svg');
            if (svgEl) {
                const svgData = new XMLSerializer().serializeToString(svgEl);
                const blob = new Blob([svgData], { type: 'image/svg+xml' });
                this.triggerDownload(blob, fileName);
            }
        } else {
            qr.getRawData('png').then((blob: Blob | null) => {
                if (blob) {
                    this.triggerDownload(blob, fileName);
                }
            });
        }
    }

    private triggerDownload(blob: Blob, fileName: string): void {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    copyUrl(table: TableInfo): void {
        const url = this.getTableUrl(table);
        navigator.clipboard.writeText(url).then(() => {
            this.copiedToken = table.qr_token;
            setTimeout(() => { this.copiedToken = null; }, 2000);
        });
    }

    createTable(): void {
        if (!this.newTableNumber) return;

        this.isCreating = true;
        this.errorMessage = null;

        this.apiService.post<TableInfo>('/api/tables', {
            table: {
                number: this.newTableNumber,
                nb_seats: this.newTableCapacity
            }
        }).subscribe({
            next: (response) => {
                this.isCreating = false;
                if (response.success) {
                    this.newTableNumber = null;
                    this.newTableCapacity = 4;
                    this.loadTables();
                }
            },
            error: (error) => {
                this.isCreating = false;
                this.errorMessage = error?.errors?.[0] || 'Erreur lors de la création.';
            }
        });
    }

    // Edit
    startEdit(table: TableInfo): void {
        this.editingTableId = table.id;
        this.editNumber = table.number;
        this.editCapacity = table.capacity;
        this.editErrorMessage = null;
    }

    cancelEdit(): void {
        this.editingTableId = null;
        this.editNumber = null;
        this.editCapacity = null;
        this.editErrorMessage = null;
    }

    saveEdit(): void {
        if (!this.editingTableId || !this.editNumber || !this.editCapacity) return;

        this.isUpdating = true;
        this.editErrorMessage = null;

        this.apiService.put<TableInfo>(`/api/tables/${this.editingTableId}`, {
            table: {
                number: this.editNumber,
                nb_seats: this.editCapacity
            }
        }).subscribe({
            next: (response) => {
                this.isUpdating = false;
                if (response.success) {
                    this.cancelEdit();
                    this.loadTables();
                }
            },
            error: (error) => {
                this.isUpdating = false;
                this.editErrorMessage = error?.errors?.[0] || 'Erreur lors de la modification.';
            }
        });
    }

    // Delete
    askDelete(table: TableInfo): void {
        this.confirmDeleteId = table.id;
    }

    cancelDelete(): void {
        this.confirmDeleteId = null;
    }

    confirmDelete(table: TableInfo): void {
        this.deletingTableId = table.id;

        this.apiService.delete<any>(`/api/tables/${table.id}`).subscribe({
            next: () => {
                this.deletingTableId = null;
                this.confirmDeleteId = null;
                this.loadTables();
            },
            error: (error) => {
                this.deletingTableId = null;
                this.confirmDeleteId = null;
                alert(error?.errors?.[0] || 'Erreur lors de la suppression.');
            }
        });
    }

}
