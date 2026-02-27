import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { TranslationService } from '../services/translation.service';

export interface ConfirmDeleteDialogData {
  userName: string;
}

@Component({
  selector: 'app-confirm-delete-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title class="dialog-title">{{ ts.t('admin.users.deleteTitle') }}</h2>

    <mat-dialog-content>
      <p class="dialog-text">{{ ts.t('admin.users.deleteConfirm') }} <strong>{{ data.userName }}</strong> ?</p>
    </mat-dialog-content>

    <mat-dialog-actions align="end">
      <button mat-stroked-button class="btn-cancel" (click)="onCancel()">{{ ts.t('admin.cancel') }}</button>
      <button mat-flat-button class="btn-danger" (click)="onConfirm()">{{ ts.t('admin.delete') }}</button>
    </mat-dialog-actions>
  `,
  styles: [`
    :host {
      display: block;
      font-family: "Space Grotesk", "Segoe UI", sans-serif;
    }

    .dialog-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.25rem;
      color: #1b1a17;
    }

    .dialog-text {
      margin: 0 0 0.5rem 0;
      font-size: 0.9rem;
      color: rgba(27, 26, 23, 0.7);
    }

    .btn-cancel {
      border-radius: 10px !important;
      color: #1b1a17 !important;
      border-color: rgba(27, 26, 23, 0.15) !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }

    .btn-cancel:hover {
      background: rgba(27, 26, 23, 0.04) !important;
    }

    .btn-danger {
      border-radius: 10px !important;
      background: #8a3f24 !important;
      color: #fff !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }

    .btn-danger:hover {
      opacity: 0.9;
    }

    ::ng-deep .mat-mdc-dialog-actions {
      padding: 0.75rem 1.5rem 1rem !important;
    }
  `]
})
export class ConfirmDeleteDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<ConfirmDeleteDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ConfirmDeleteDialogData,
    public ts: TranslationService
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
