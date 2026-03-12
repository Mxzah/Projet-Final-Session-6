import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { TranslationService } from '../../services/translation.service';

export interface ThankYouDialogData {
  title: string;
  message: string;
  reviewLabel: string;
  quitLabel: string;
}

/** Result: 'review' or 'quit' */
export type ThankYouDialogResult = 'review' | 'quit';

@Component({
  selector: 'app-thank-you-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule, MatIconModule],
  template: `
    <div class="thank-you-dialog">
      <mat-icon class="thank-you-icon">check_circle</mat-icon>
      <h2 mat-dialog-title class="thank-you-title">{{ data.title }}</h2>
      <mat-dialog-content class="thank-you-msg">
        {{ data.message }}
      </mat-dialog-content>
      <mat-dialog-actions class="thank-you-actions" align="center">
        <button mat-raised-button color="primary" class="review-btn" (click)="choose('review')">
          <mat-icon>star</mat-icon>
          {{ data.reviewLabel }}
        </button>
        <button mat-button class="quit-btn" (click)="choose('quit')">
          {{ data.quitLabel }}
        </button>
      </mat-dialog-actions>
    </div>
  `,
  styles: [`
    .thank-you-dialog {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      padding: 1.5rem 1rem 0.5rem;
    }
    .thank-you-icon {
      font-size: 4rem;
      width: 4rem;
      height: 4rem;
      color: #2e7d32;
      margin-bottom: 0.5rem;
    }
    .thank-you-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.4rem;
      margin: 0 0 0.25rem;
      color: #1b1a17;
    }
    .thank-you-msg {
      font-size: 0.9rem;
      color: rgba(27, 26, 23, 0.55);
      margin-bottom: 1rem;
      max-height: none !important;
      overflow: visible !important;
    }
    .thank-you-actions {
      display: flex !important;
      flex-direction: column;
      gap: 0.5rem;
      width: 100%;
      padding: 0.5rem 0 !important;
    }
    .review-btn {
      width: 100%;
      padding: 0.85rem 1.5rem !important;
      font-size: 1rem !important;
      border-radius: 12px !important;
      background: linear-gradient(120deg, #C87941, #A0522D) !important;
      color: white !important;
    }
    .quit-btn {
      width: 100%;
      border-radius: 12px !important;
      font-size: 0.9rem !important;
      color: rgba(27, 26, 23, 0.55) !important;
    }
  `]
})
export class ThankYouDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<ThankYouDialogComponent, ThankYouDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: ThankYouDialogData,
    public ts: TranslationService
  ) {}

  choose(action: ThankYouDialogResult): void {
    this.dialogRef.close(action);
  }
}
