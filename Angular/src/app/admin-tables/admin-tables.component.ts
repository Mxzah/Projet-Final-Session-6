import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ApiService } from '../services/api.service';
import { AuthService } from '../services/auth.service';
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
        private authService: AuthService,
        private router: Router
    ) { }

    ngOnInit(): void {
        this.loadTables();
    }

    loadTables(): void {
        this.isLoading = true;
        this.apiService.get<TableInfo[]>('/api/tables').subscribe({
            next: (response) => {
                if (response.success && response.data) {
                    this.tables = response.data;
                    setTimeout(() => this.generateAllQrCodes(), 100);
                }
                this.isLoading = false;
            },
            error: () => {
                this.isLoading = false;
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
                capacity: this.newTableCapacity
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

    logout(): void {
        this.authService.logout().subscribe({
            next: () => this.router.navigate(['/login']),
            error: () => this.router.navigate(['/login'])
        });
    }
}
