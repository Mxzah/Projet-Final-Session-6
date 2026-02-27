import { Component, Inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { TranslationService } from '../services/translation.service';

export interface ReviewFormDialogData {
  mode: 'create' | 'edit';
  reviewableName: string;
  rating?: number;
  comment?: string;
}

export interface ReviewFormDialogResult {
  rating: number;
  comment: string;
  images?: File[];
}

@Component({
  selector: 'app-review-form-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatIconModule],
  template: `
    <div class="dialog-content">
      <h2 class="dialog-title">
        {{ data.mode === 'create' ? ts.t('reviews.leaveReview') : ts.t('reviews.editReview') }}
      </h2>
      <p class="dialog-item-name">{{ data.reviewableName }}</p>

      <div class="star-rating">
        <span class="star-label">{{ ts.t('reviews.rating') }}</span>
        <div class="stars">
          @for (star of [1,2,3,4,5]; track star) {
            <mat-icon
              class="star"
              [class.filled]="star <= rating()"
              (click)="rating.set(star)">
              {{ star <= rating() ? 'star' : 'star_border' }}
            </mat-icon>
          }
        </div>
      </div>

      <mat-form-field class="comment-field" appearance="outline">
        <mat-label>{{ ts.t('reviews.comment') }}</mat-label>
        <textarea matInput
                  [(ngModel)]="comment"
                  maxlength="500"
                  rows="4"
                  [placeholder]="ts.t('reviews.comment')"></textarea>
        <mat-hint align="end">{{ comment.length }}/500</mat-hint>
        @if (commentError()) {
          <mat-error>{{ commentError() }}</mat-error>
        }
      </mat-form-field>

      <div class="photo-section">
        <label class="photo-label">{{ ts.t('reviews.photos') }}</label>
        <div class="photo-previews">
          @for (preview of imagePreviews(); track preview) {
            <div class="photo-thumb">
              <img [src]="preview" alt="preview" />
              <button type="button" class="remove-photo" (click)="removeImage($index)">×</button>
            </div>
          }
          @if (selectedImages().length < 3) {
            <button type="button" class="add-photo-btn" (click)="fileInput.click()">
              <mat-icon>add_a_photo</mat-icon>
            </button>
          }
        </div>
        <input #fileInput type="file" accept="image/jpeg,image/png" multiple hidden (change)="onFilesSelected($event)" />
        @if (imageError()) {
          <span class="photo-error">{{ imageError() }}</span>
        }
      </div>

      <div class="dialog-actions">
        <button mat-stroked-button
                (click)="dialogRef.close()"
                style="border-radius: 10px; color: #1b1a17; border-color: rgba(27,26,23,0.15); font-family: 'Space Grotesk','Segoe UI',sans-serif;">
          {{ ts.t('admin.cancel') }}
        </button>
        <button mat-flat-button
                (click)="onSubmit()"
                [disabled]="!isValid()"
                style="border-radius: 10px; background: linear-gradient(120deg, #C86D3F, #A0522D); color: #fff; font-family: 'Space Grotesk','Segoe UI',sans-serif;">
          {{ ts.t('admin.save') }}
        </button>
      </div>
    </div>
  `,
  styles: [`
    .dialog-content {
      padding: 1.5rem;
      font-family: "Space Grotesk", "Segoe UI", sans-serif;
    }
    .dialog-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.25rem;
      margin: 0 0 0.25rem;
      color: #1b1a17;
    }
    .dialog-item-name {
      font-weight: 600;
      font-size: 1rem;
      color: #1b1a17;
      margin: 0 0 1rem;
    }
    .star-rating {
      margin-bottom: 1rem;
    }
    .star-label {
      font-size: 0.85rem;
      color: rgba(27,26,23,0.6);
      display: block;
      margin-bottom: 0.35rem;
    }
    .stars {
      display: flex;
      gap: 0.25rem;
    }
    .star {
      cursor: pointer;
      font-size: 2rem;
      width: 2rem;
      height: 2rem;
      color: rgba(27,26,23,0.25);
      transition: color 0.15s;
    }
    .star.filled {
      color: #C86D3F;
    }
    .star:hover {
      color: #C86D3F;
    }
    .comment-field {
      width: 100%;
    }
    .photo-section { margin-bottom: 0.75rem; }
    .photo-label { font-size: 0.85rem; color: rgba(27,26,23,0.6); display: block; margin-bottom: 0.35rem; }
    .photo-previews { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .photo-thumb { position: relative; width: 72px; height: 72px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(27,26,23,0.12); }
    .photo-thumb img { width: 100%; height: 100%; object-fit: cover; }
    .remove-photo { position: absolute; top: 2px; right: 2px; width: 20px; height: 20px; border-radius: 50%; border: none; background: rgba(0,0,0,0.55); color: #fff; font-size: 14px; line-height: 1; cursor: pointer; display: flex; align-items: center; justify-content: center; }
    .add-photo-btn { width: 72px; height: 72px; border-radius: 8px; border: 2px dashed rgba(27,26,23,0.2); background: transparent; cursor: pointer; display: flex; align-items: center; justify-content: center; color: rgba(27,26,23,0.35); transition: border-color 0.15s, color 0.15s; }
    .add-photo-btn:hover { border-color: #C86D3F; color: #C86D3F; }
    .photo-error { font-size: 0.75rem; color: #d32f2f; display: block; margin-top: 0.25rem; }
    .dialog-actions {
      display: flex;
      justify-content: flex-end;
      gap: 0.75rem;
      margin-top: 1rem;
    }
  `]
})
export class ReviewFormDialogComponent {
  rating = signal(0);
  comment = '';
  commentError = signal('');
  selectedImages = signal<File[]>([]);
  imagePreviews = signal<string[]>([]);
  imageError = signal('');

  constructor(
    public dialogRef: MatDialogRef<ReviewFormDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ReviewFormDialogData,
    public ts: TranslationService
  ) {
    this.rating.set(data.rating || 0);
    this.comment = data.comment || '';
  }

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files) return;
    const newFiles = Array.from(input.files);
    const current = this.selectedImages();
    const toAdd = newFiles.slice(0, 3 - current.length);
    for (const file of toAdd) {
      if (!['image/jpeg', 'image/png'].includes(file.type)) {
        this.imageError.set(this.ts.t('reviews.photosFormatError'));
        input.value = '';
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        this.imageError.set(this.ts.t('reviews.photosSizeError'));
        input.value = '';
        return;
      }
    }
    this.imageError.set('');
    const updatedFiles = [...current, ...toAdd];
    this.selectedImages.set(updatedFiles);
    const previews = [...this.imagePreviews()];
    toAdd.forEach(f => {
      const reader = new FileReader();
      reader.onload = () => {
        previews.push(reader.result as string);
        this.imagePreviews.set([...previews]);
      };
      reader.readAsDataURL(f);
    });
    input.value = '';
  }

  removeImage(index: number): void {
    const files = [...this.selectedImages()];
    const previews = [...this.imagePreviews()];
    files.splice(index, 1);
    previews.splice(index, 1);
    this.selectedImages.set(files);
    this.imagePreviews.set(previews);
  }

  isValid(): boolean {
    return this.rating() >= 1 && this.rating() <= 5 &&
           this.comment.trim().length > 0 && this.comment.length <= 500;
  }

  onSubmit(): void {
    if (!this.comment.trim()) {
      this.commentError.set(this.ts.t('reviews.commentRequired'));
      return;
    }
    if (this.comment.length > 500) {
      this.commentError.set(this.ts.t('reviews.commentMaxLength'));
      return;
    }
    if (this.rating() < 1) return;

    this.dialogRef.close({
      rating: this.rating(),
      comment: this.comment.trim(),
      images: this.selectedImages().length > 0 ? this.selectedImages() : undefined
    } as ReviewFormDialogResult);
  }
}
