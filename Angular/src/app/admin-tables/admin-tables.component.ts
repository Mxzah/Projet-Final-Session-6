import { Component, OnInit, AfterViewChecked, ChangeDetectorRef, NgZone, signal, computed, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatChipsModule } from '@angular/material/chips';
import { ApiService } from '../services/api.service';
import { TranslationService } from '../services/translation.service';
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
    imports: [
        CommonModule, FormsModule,
        MatCardModule, MatButtonModule, MatIconModule,
        MatFormFieldModule, MatInputModule, MatSelectModule,
        MatProgressSpinnerModule, MatTooltipModule, MatChipsModule
    ],
    templateUrl: './admin-tables.component.html',
    styleUrls: ['./admin-tables.component.css']
})
export class AdminTablesComponent implements OnInit, AfterViewChecked {
    tables = signal<TableInfo[]>([]);
    isLoading = signal(true);
    copiedToken = signal<string | null>(null);

    // New table form
    isCreateModalOpen = signal(false);
    newTableNumber = signal<number | null>(null);
    newTableCapacity = signal(4);
    isCreating = signal(false);
    errorMessage = signal<string | null>(null);

    // Edit table
    editingTableId = signal<number | null>(null);
    editNumber = signal<number | null>(null);
    editCapacity = signal<number | null>(null);
    isUpdating = signal(false);
    editErrorMessage = signal<string | null>(null);

    // Delete
    deletingTableId = signal<number | null>(null);
    confirmDeleteId = signal<number | null>(null);
    cleaningTableId = signal<number | null>(null);

    // QR Style options
    qrDotType = signal('rounded');
    qrDotColor = signal('#8a3f24');
    qrBgColor = signal('#fbf8f2');
    qrCornerSquareType = signal('extra-rounded');
    qrCornerDotType = signal('dot');
    qrCornerColor = signal('#1b1a17');
    qrSize: number = 250;

    dotTypes = ['square', 'dots', 'rounded', 'classy', 'classy-rounded', 'extra-rounded'];
    cornerSquareTypes = ['square', 'dot', 'extra-rounded'];
    cornerDotTypes = ['square', 'dot'];

    previewUrl = computed(() => {
        const firstTable = this.tables()[0];
        return firstTable ? this.getTableUrl(firstTable) : '';
    });

    private previewVersion = signal(0);
    private lastRenderedPreviewVersion = -1;

    constructor(
        private apiService: ApiService,
        private cdr: ChangeDetectorRef,
        private ngZone: NgZone,
        public ts: TranslationService
    ) { }

    private readonly previewEffect = effect(() => {
        this.previewUrl();
        this.qrDotType();
        this.qrDotColor();
        this.qrBgColor();
        this.qrCornerSquareType();
        this.qrCornerDotType();
        this.qrCornerColor();
        this.previewVersion.update(v => v + 1);
    }, { allowSignalWrites: true });

    ngOnInit(): void {
        this.loadTables();
    }

    ngAfterViewChecked(): void {
        const version = this.previewVersion();
        if (version === this.lastRenderedPreviewVersion) return;
        const rendered = this.renderPreviewQr();
        if (rendered) this.lastRenderedPreviewVersion = version;
    }

    loadTables(): void {
        this.isLoading.set(true);
        this.apiService.get<TableInfo[]>('/api/tables').subscribe({
            next: (response) => {
                this.ngZone.run(() => {
                    if (response.success && response.data) {
                        this.tables.set(response.data);
                        this.isLoading.set(false);
                        this.cdr.detectChanges();
                    } else {
                        this.isLoading.set(false);
                        this.cdr.detectChanges();
                    }
                });
            },
            error: () => {
                this.ngZone.run(() => {
                    this.isLoading.set(false);
                    this.cdr.detectChanges();
                });
            }
        });
    }

    getTableUrl(table: TableInfo): string {
        const base = window.location.origin.replace(/\/+$/, '');
        return `${base}/table/${table.qr_token}`;
    }

    getPreviewUrl(): string {
        return this.previewUrl();
    }

    private createQrCode(data: string): QRCodeStyling {
        return new QRCodeStyling({
            width: this.qrSize,
            height: this.qrSize,
            type: 'canvas',
            data,
            margin: 8,
            dotsOptions: {
                color: this.qrDotColor(),
                type: this.qrDotType() as any,
            },
            backgroundOptions: {
                color: this.qrBgColor(),
            },
            cornersSquareOptions: {
                type: this.qrCornerSquareType() as any,
                color: this.qrCornerColor(),
            },
            cornersDotOptions: {
                type: this.qrCornerDotType() as any,
                color: this.qrCornerColor(),
            },
            qrOptions: {
                errorCorrectionLevel: 'M',
            },
        });
    }

    renderPreviewQr(): boolean {
        const container = document.getElementById('qr-preview');
        if (!container) return false;

        container.innerHTML = '';
        const previewUrl = this.getPreviewUrl();
        if (!previewUrl) return false;

        const qrCode = this.createQrCode(previewUrl);
        qrCode.append(container);
        return true;
    }

    onStyleDropdownToggle(event: Event): void {
        const details = event.target as HTMLDetailsElement;
        if (details.open) {
            this.previewVersion.update(v => v + 1);
        }
    }

    downloadQr(table: TableInfo, format: 'svg' | 'png'): void {
        const fileName = `restoqr-table-${table.number}.${format}`;
        const qr = this.createQrCode(this.getTableUrl(table));

        qr.getRawData(format).then((blob: Blob | null) => {
            if (blob) {
                this.triggerDownload(blob, fileName);
            }
        });
    }

    markCleaned(table: TableInfo): void {
        this.cleaningTableId.set(table.id);

        this.apiService.put<TableInfo>(`/api/tables/${table.id}/mark_cleaned`, {
            cleaned_at: new Date().toISOString()
        }).subscribe({
            next: (response) => {
                this.cleaningTableId.set(null);
                if (!response.success || !response.data) {
                    alert(response.errors?.[0] || 'Erreur lors du nettoyage de la table.');
                    return;
                }

                this.tables.update(list =>
                    list.map(current => current.id === table.id ? response.data as TableInfo : current)
                );
            },
            error: (error) => {
                this.cleaningTableId.set(null);
                alert(error?.errors?.[0] || 'Erreur lors du nettoyage de la table.');
            }
        });
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
            this.copiedToken.set(table.qr_token);
            setTimeout(() => { this.copiedToken.set(null); }, 2000);
        });
    }

    createTable(): void {
        const newNumber = this.newTableNumber();
        if (newNumber == null) return;

        this.isCreating.set(true);
        this.errorMessage.set(null);

        this.apiService.post<TableInfo>('/api/tables', {
            table: {
                number: newNumber,
                nb_seats: this.newTableCapacity()
            }
        }).subscribe({
            next: (response) => {
                this.isCreating.set(false);
                if (response.success) {
                    this.cancelCreate();
                    this.loadTables();
                }
            },
            error: (error) => {
                this.isCreating.set(false);
                this.errorMessage.set(error?.errors?.[0] || this.ts.t('tables.createError'));
            }
        });
    }

    openCreate(): void {
        this.isCreateModalOpen.set(true);
        this.newTableNumber.set(null);
        this.newTableCapacity.set(4);
        this.errorMessage.set(null);
    }

    cancelCreate(): void {
        this.isCreateModalOpen.set(false);
        this.newTableNumber.set(null);
        this.newTableCapacity.set(4);
        this.errorMessage.set(null);
    }

    // Edit
    startEdit(table: TableInfo): void {
        this.editingTableId.set(table.id);
        this.editNumber.set(table.number);
        this.editCapacity.set(table.capacity);
        this.editErrorMessage.set(null);
    }

    cancelEdit(): void {
        this.editingTableId.set(null);
        this.editNumber.set(null);
        this.editCapacity.set(null);
        this.editErrorMessage.set(null);
    }

    saveEdit(): void {
        const editingId = this.editingTableId();
        const editNumber = this.editNumber();
        const editCapacity = this.editCapacity();
        if (editingId == null || editNumber == null || editCapacity == null) return;

        this.isUpdating.set(true);
        this.editErrorMessage.set(null);

        this.apiService.put<TableInfo>(`/api/tables/${editingId}`, {
            table: {
                number: editNumber,
                nb_seats: editCapacity
            }
        }).subscribe({
            next: (response) => {
                this.isUpdating.set(false);
                if (response.success) {
                    this.cancelEdit();
                    this.loadTables();
                }
            },
            error: (error) => {
                this.isUpdating.set(false);
                this.editErrorMessage.set(error?.errors?.[0] || this.ts.t('tables.editError'));
            }
        });
    }

    // Delete
    askDelete(table: TableInfo): void {
        this.confirmDeleteId.set(table.id);
    }

    cancelDelete(): void {
        this.confirmDeleteId.set(null);
    }

    confirmDelete(table: TableInfo): void {
        this.deletingTableId.set(table.id);

        this.apiService.delete<any>(`/api/tables/${table.id}`).subscribe({
            next: () => {
                this.deletingTableId.set(null);
                this.confirmDeleteId.set(null);
                this.loadTables();
            },
            error: (error) => {
                this.deletingTableId.set(null);
                this.confirmDeleteId.set(null);
                alert(error?.errors?.[0] || this.ts.t('tables.deleteError'));
            }
        });
    }

    getTableNumberById(id: number): number {
        const table = this.tables().find(t => t.id === id);
        return table ? table.number : 0;
    }

    confirmDeleteAction(): void {
        const confirmDeleteId = this.confirmDeleteId();
        if (confirmDeleteId == null) return;
        const table = this.tables().find(t => t.id === confirmDeleteId);
        if (table) {
            this.confirmDelete(table);
        }
    }

}
