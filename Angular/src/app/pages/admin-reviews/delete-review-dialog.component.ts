import { Component, Inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { TranslationService } from '../../services/translation.service';

export interface DeleteReviewDialogData {
  reviewableName: string;
}

export interface DeleteReviewDialogResult {
  reason: string;
}

@Component({
  selector: 'app-delete-review-dialog',
  standalone: true,
  imports: [FormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  template: `
    <div class="dialog-wrap">
      <h2 mat-dialog-title class="dialog-title">{{ ts.t('reviews.deleteReview') }}</h2>
      <mat-dialog-content>
        <p class="dialog-target">{{ data.reviewableName }}</p>
        <mat-form-field appearance="outline" class="reason-field">
          <mat-label>{{ ts.t('admin.reviews.deleteReason') }}</mat-label>
          <textarea matInput [(ngModel)]="reason" rows="3" maxlength="500"></textarea>
          <mat-hint>{{ ts.t('admin.reviews.deleteReasonHint') }}</mat-hint>
        </mat-form-field>
      </mat-dialog-content>
      <mat-dialog-actions align="end">
        <button mat-stroked-button (click)="dialogRef.close()" class="btn-cancel">{{ ts.t('admin.cancel') }}</button>
        <button mat-flat-button (click)="confirm()" class="btn-delete">{{ ts.t('admin.delete') }}</button>
      </mat-dialog-actions>
    </div>
  `,
  styles: [`
    .dialog-wrap { font-family: "Space Grotesk", "Segoe UI", sans-serif; }
    .dialog-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.2rem;
      color: #1b1a17;
    }
    .dialog-target {
      font-weight: 600;
      margin: 0 0 1rem;
      color: #1b1a17;
    }
    .reason-field { width: 100%; }
    .btn-cancel {
      border-radius: 10px !important;
      color: #1b1a17 !important;
      border-color: rgba(27,26,23,0.15) !important;
    }
    .btn-delete {
      border-radius: 10px !important;
      background: linear-gradient(120deg, #b43c1e, #8b2010) !important;
      color: #fff !important;
    }
  `]
})
export class DeleteReviewDialogComponent {
  reason = '';

  constructor(
    public dialogRef: MatDialogRef<DeleteReviewDialogComponent, DeleteReviewDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: DeleteReviewDialogData,
    public ts: TranslationService
  ) {}

  confirm(): void {
    this.dialogRef.close({ reason: this.reason.trim() });
  }
}
