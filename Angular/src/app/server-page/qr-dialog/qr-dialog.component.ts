import { Component, Inject, AfterViewInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { TranslationService } from '../../services/translation.service';
import QRCodeStyling from 'styled-qr-code';

export interface QrDialogData {
    tableNumber: number;
    qrUrl: string;
    scanInstruction: string;
}

@Component({
    selector: 'app-qr-dialog',
    standalone: true,
    imports: [MatDialogModule, MatButtonModule, MatIconModule],
    templateUrl: './qr-dialog.component.html',
    styleUrls: ['./qr-dialog.component.css']
})
export class QrDialogComponent implements AfterViewInit {
    constructor(
        public dialogRef: MatDialogRef<QrDialogComponent>,
        @Inject(MAT_DIALOG_DATA) public data: QrDialogData,
        public ts: TranslationService
    ) { }

    ngAfterViewInit(): void {
        this.renderQr();
    }

    private renderQr(): void {
        const container = document.getElementById('dialog-qr-container');
        if (!container) return;

        container.innerHTML = '';
        const qrCode = new QRCodeStyling({
            width: 250,
            height: 250,
            type: 'canvas',
            data: this.data.qrUrl,
            margin: 8,
            dotsOptions: { color: '#8a3f24', type: 'rounded' as any },
            backgroundOptions: { color: '#fbf8f2' },
            cornersSquareOptions: { type: 'extra-rounded' as any, color: '#1b1a17' },
            cornersDotOptions: { type: 'dot' as any, color: '#1b1a17' },
            qrOptions: { errorCorrectionLevel: 'M' }
        });
        qrCode.append(container);
    }
}
