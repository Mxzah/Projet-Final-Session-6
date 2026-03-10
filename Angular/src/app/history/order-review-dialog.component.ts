import { Component, Inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDividerModule } from '@angular/material/divider';
import { TranslationService } from '../services/translation.service';
import { environment } from '../../environments/environment';

export interface ReviewableItem {
  type: string;         // 'Item', 'Combo', or 'User'
  id: number;
  name: string;
  imageUrl?: string;
  existingReviewId?: number;
  existingRating?: number;
  existingComment?: string;
  existingImageUrls?: string[];
  existingImageSignedIds?: string[];
  deletedAt?: string;
  deletionReason?: string;
}

export interface OrderReviewDialogData {
  orderId: number;
  orderTableNumber: number;
  orderDate: string;
  items: ReviewableItem[];
}

export interface SingleReviewResult {
  reviewableType: string;
  reviewableId: number;
  orderId: number;
  rating: number;
  comment: string;
  images?: File[];
  removeImageIds?: string[];
  existingReviewId?: number;
}

export interface OrderReviewDialogResult {
  reviews: SingleReviewResult[];
}

interface ReviewEntry {
  item: ReviewableItem;
  rating: number;
  comment: string;
  images: File[];
  imagePreviews: string[];
  existingImageUrls: string[];
  existingImageSignedIds: string[];
  removedImageIds: string[];
  imageError: string;
  expanded: boolean;
}

@Component({
  selector: 'app-order-review-dialog',
  standalone: true,
  imports: [
    CommonModule, FormsModule, MatDialogModule, MatFormFieldModule,
    MatInputModule, MatButtonModule, MatIconModule, MatDividerModule
  ],
  template: `
    <div class="dialog-wrap">
      <div class="dialog-header">
        <h2 class="dialog-title">{{ ts.t('reviews.orderReviewTitle') }}</h2>
        <p class="dialog-subtitle">{{ ts.t('cuisine.table') }} {{ data.orderTableNumber }} — {{ data.orderDate }}</p>
      </div>

      <div class="dialog-body">
        @for (entry of entries; track entry.item.id + entry.item.type) {
          <div class="review-section" [class.has-review]="entry.rating > 0" [class.moderated]="!!entry.item.deletedAt">
            <button type="button" class="section-toggle" (click)="entry.expanded = !entry.expanded">
              <div class="section-left">
                <mat-icon class="section-icon">{{ entry.item.type === 'User' ? 'person' : 'restaurant' }}</mat-icon>
                <div class="section-info">
                  <span class="section-name">{{ entry.item.name }}</span>
                  @if (entry.item.type === 'User') {
                    <span class="section-type">{{ ts.t('reviews.typeServer') }}</span>
                  }
                </div>
              </div>
              <div class="section-right">
                @if (entry.item.deletedAt) {
                  <span class="moderated-badge">{{ ts.t('reviews.moderatedBadge') }}</span>
                } @else if (entry.rating > 0) {
                  <span class="mini-stars">{{ renderStars(entry.rating) }}</span>
                }
                <mat-icon class="toggle-icon">{{ entry.expanded ? 'expand_less' : 'expand_more' }}</mat-icon>
              </div>
            </button>

            @if (entry.expanded) {
              @if (entry.item.deletedAt) {
                <div class="section-body moderated-body">
                  <div class="moderated-banner">
                    <mat-icon>gavel</mat-icon>
                    <span>{{ ts.t('reviews.moderated') }}</span>
                  </div>
                  @if (entry.item.deletionReason) {
                    <p class="moderated-reason">{{ ts.t('reviews.moderatedReason') }} {{ entry.item.deletionReason }}</p>
                  }
                  <p class="moderated-date">{{ ts.t('admin.reviews.deletedOn') }} {{ entry.item.deletedAt | date:'medium' }}</p>
                  <div class="star-rating">
                    <span class="star-label">{{ ts.t('reviews.rating') }}</span>
                    <div class="stars">
                      @for (star of [1,2,3,4,5]; track star) {
                        <mat-icon class="star" [class.filled]="star <= entry.rating" style="cursor: default;">
                          {{ star <= entry.rating ? 'star' : 'star_border' }}
                        </mat-icon>
                      }
                    </div>
                  </div>
                  @if (entry.comment) {
                    <p class="moderated-comment">{{ entry.comment }}</p>
                  }
                </div>
              } @else {
                <div class="section-body">
                  <div class="star-rating">
                    <span class="star-label">{{ ts.t('reviews.rating') }}</span>
                    <div class="stars">
                      @for (star of [1,2,3,4,5]; track star) {
                        <mat-icon
                          class="star"
                          [class.filled]="star <= entry.rating"
                          (click)="entry.rating = star">
                          {{ star <= entry.rating ? 'star' : 'star_border' }}
                        </mat-icon>
                      }
                    </div>
                  </div>

                  <mat-form-field class="comment-field" appearance="outline">
                    <mat-label>{{ ts.t('reviews.comment') }}</mat-label>
                    <textarea matInput
                              [(ngModel)]="entry.comment"
                              maxlength="500"
                              rows="3"
                              [placeholder]="ts.t('reviews.comment')"></textarea>
                    <mat-hint align="end">{{ entry.comment.length }}/500</mat-hint>
                  </mat-form-field>

                  <div class="photo-section">
                    <label class="photo-label">{{ ts.t('reviews.photos') }}</label>
                    <div class="photo-previews">
                      @for (url of entry.existingImageUrls; track url) {
                        <div class="photo-thumb existing">
                          <img [src]="getImageUrl(url)" alt="existing" />
                          <button type="button" class="remove-photo" (click)="removeExistingImage(entry, $index)">×</button>
                        </div>
                      }
                      @for (preview of entry.imagePreviews; track preview) {
                        <div class="photo-thumb">
                          <img [src]="preview" alt="preview" />
                          <button type="button" class="remove-photo" (click)="removeImage(entry, $index)">×</button>
                        </div>
                      }
                      @if (entry.existingImageUrls.length + entry.images.length < 3) {
                        <button type="button" class="add-photo-btn" (click)="triggerFileInput(entry)">
                          <mat-icon>add_a_photo</mat-icon>
                        </button>
                      }
                    </div>
                    @if (entry.imageError) {
                      <span class="photo-error">{{ entry.imageError }}</span>
                    }
                  </div>
                </div>
              }
            }
          </div>
        }
      </div>

      <input #fileInput type="file" accept="image/jpeg,image/png" multiple hidden (change)="onFilesSelected($event)" />

      <div class="dialog-footer">
        <span class="review-count">{{ getCompletedCount() }} / {{ getEditableCount() }} {{ ts.t('reviews.itemsReviewed') }}</span>
        <div class="dialog-actions">
          <button mat-stroked-button (click)="dialogRef.close()" class="btn-cancel">
            {{ ts.t('admin.cancel') }}
          </button>
          <button mat-flat-button (click)="onSubmit()" [disabled]="getCompletedCount() === 0" class="btn-save">
            {{ ts.t('reviews.saveReviews') }}
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dialog-wrap {
      display: flex;
      flex-direction: column;
      max-height: 85vh;
      font-family: "Space Grotesk", "Segoe UI", sans-serif;
    }
    .dialog-header {
      padding: 1.5rem 1.5rem 0.75rem;
    }
    .dialog-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.25rem;
      margin: 0 0 0.25rem;
      color: #1b1a17;
    }
    .dialog-subtitle {
      font-size: 0.85rem;
      color: rgba(27,26,23,0.55);
      margin: 0;
    }
    .dialog-body {
      flex: 1;
      overflow-y: auto;
      padding: 0.5rem 1.5rem;
    }

    /* ── Section toggle (accordion) ── */
    .review-section {
      border: 1px solid rgba(27,26,23,0.1);
      border-radius: 12px;
      margin-bottom: 0.6rem;
      overflow: hidden;
      transition: border-color 0.15s;
    }
    .review-section.has-review {
      border-color: rgba(200,109,63,0.35);
      background: rgba(200,109,63,0.03);
    }
    .section-toggle {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 0.75rem 1rem;
      background: transparent;
      border: none;
      cursor: pointer;
      gap: 0.5rem;
    }
    .section-toggle:hover { background: rgba(27,26,23,0.03); }
    .section-left {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      min-width: 0;
    }
    .section-icon {
      color: rgba(27,26,23,0.45);
      font-size: 1.2rem;
      width: 1.2rem;
      height: 1.2rem;
      flex-shrink: 0;
    }
    .section-info { display: flex; flex-direction: column; align-items: flex-start; min-width: 0; }
    .section-name {
      font-weight: 600;
      font-size: 0.92rem;
      color: #1b1a17;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 220px;
    }
    .section-type {
      font-size: 0.72rem;
      color: rgba(27,26,23,0.5);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .section-right {
      display: flex;
      align-items: center;
      gap: 0.35rem;
      flex-shrink: 0;
    }
    .mini-stars {
      font-size: 0.82rem;
      color: #C86D3F;
      letter-spacing: 0.05em;
    }
    .toggle-icon {
      color: rgba(27,26,23,0.4);
      font-size: 1.3rem;
      width: 1.3rem;
      height: 1.3rem;
    }

    /* ── Section body (review form) ── */
    .section-body {
      padding: 0 1rem 1rem;
    }
    .star-rating { margin-bottom: 0.75rem; }
    .star-label {
      font-size: 0.82rem;
      color: rgba(27,26,23,0.55);
      display: block;
      margin-bottom: 0.3rem;
    }
    .stars { display: flex; gap: 0.2rem; }
    .star {
      cursor: pointer;
      font-size: 1.6rem;
      width: 1.6rem;
      height: 1.6rem;
      color: rgba(27,26,23,0.2);
      transition: color 0.12s;
    }
    .star.filled { color: #C86D3F; }
    .star:hover { color: #C86D3F; }
    .comment-field { width: 100%; }
    .photo-section { margin-bottom: 0.25rem; }
    .photo-label { font-size: 0.82rem; color: rgba(27,26,23,0.55); display: block; margin-bottom: 0.3rem; }
    .photo-previews { display: flex; gap: 0.4rem; flex-wrap: wrap; }
    .photo-thumb { position: relative; width: 60px; height: 60px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(27,26,23,0.12); }
    .photo-thumb img { width: 100%; height: 100%; object-fit: cover; }
    .remove-photo { position: absolute; top: 2px; right: 2px; width: 18px; height: 18px; border-radius: 50%; border: none; background: rgba(0,0,0,0.55); color: #fff; font-size: 12px; line-height: 1; cursor: pointer; display: flex; align-items: center; justify-content: center; }
    .add-photo-btn { width: 60px; height: 60px; border-radius: 8px; border: 2px dashed rgba(27,26,23,0.18); background: transparent; cursor: pointer; display: flex; align-items: center; justify-content: center; color: rgba(27,26,23,0.3); }
    .add-photo-btn:hover { border-color: #C86D3F; color: #C86D3F; }
    .photo-thumb.existing { opacity: 0.85; border-color: rgba(200,109,63,0.3); }
    .photo-error { font-size: 0.72rem; color: #d32f2f; display: block; margin-top: 0.2rem; }

    /* ── Moderated review ── */
    .review-section.moderated {
      border-color: rgba(180, 60, 30, 0.2);
      background: rgba(180, 60, 30, 0.03);
      opacity: 0.75;
    }
    .moderated-badge {
      font-size: 0.68rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      background: rgba(180, 60, 30, 0.12);
      color: #b43c1e;
      padding: 0.12rem 0.45rem;
      border-radius: 999px;
      font-weight: 600;
    }
    .moderated-body { opacity: 0.85; }
    .moderated-banner {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(180, 60, 30, 0.08);
      border-radius: 8px;
      padding: 0.6rem 0.8rem;
      margin-bottom: 0.6rem;
      color: #b43c1e;
      font-size: 0.85rem;
      font-weight: 500;
    }
    .moderated-banner mat-icon {
      font-size: 1.1rem;
      width: 1.1rem;
      height: 1.1rem;
    }
    .moderated-reason {
      font-size: 0.82rem;
      color: rgba(27,26,23,0.6);
      font-style: italic;
      margin: 0 0 0.3rem;
    }
    .moderated-date {
      font-size: 0.75rem;
      color: rgba(27,26,23,0.4);
      margin: 0 0 0.5rem;
    }
    .moderated-comment {
      font-size: 0.85rem;
      color: rgba(27,26,23,0.5);
      margin: 0.3rem 0 0;
    }

    /* ── Footer ── */
    .dialog-footer {
      padding: 0.75rem 1.5rem 1.25rem;
      border-top: 1px solid rgba(27,26,23,0.08);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 0.75rem;
      flex-wrap: wrap;
    }
    .review-count {
      font-size: 0.82rem;
      color: rgba(27,26,23,0.5);
    }
    .dialog-actions {
      display: flex;
      gap: 0.6rem;
    }
    .btn-cancel {
      border-radius: 10px !important;
      color: #1b1a17 !important;
      border-color: rgba(27,26,23,0.15) !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }
    .btn-save {
      border-radius: 10px !important;
      background: linear-gradient(120deg, #C86D3F, #A0522D) !important;
      color: #fff !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }
    .btn-save:disabled {
      opacity: 0.5 !important;
    }
  `]
})
export class OrderReviewDialogComponent {
  entries: ReviewEntry[] = [];
  private activeEntry: ReviewEntry | null = null;

  getCompletedCount(): number {
    return this.entries.filter(e => e.rating > 0 && !e.item.deletedAt).length;
  }

  getEditableCount(): number {
    return this.entries.filter(e => !e.item.deletedAt).length;
  }

  constructor(
    public dialogRef: MatDialogRef<OrderReviewDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: OrderReviewDialogData,
    public ts: TranslationService,
    private cdr: ChangeDetectorRef
  ) {
    // Build entries: server first (if present), then items
    this.entries = data.items.map((item, i) => ({
      item,
      rating: item.existingRating || 0,
      comment: item.existingComment || '',
      images: [],
      imagePreviews: [],
      existingImageUrls: item.existingImageUrls || [],
      existingImageSignedIds: item.existingImageSignedIds || [],
      removedImageIds: [],
      imageError: '',
      expanded: i === 0 // expand first item by default
    }));
  }

  renderStars(rating: number): string {
    return '\u2605'.repeat(rating) + '\u2606'.repeat(5 - rating);
  }

  triggerFileInput(entry: ReviewEntry): void {
    this.activeEntry = entry;
    const input = document.querySelector('input[type="file"][hidden]') as HTMLInputElement;
    if (input) input.click();
  }

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || !this.activeEntry) return;
    const entry = this.activeEntry;
    const newFiles = Array.from(input.files);
    const toAdd = newFiles.slice(0, 3 - entry.existingImageUrls.length - entry.images.length);

    for (const file of toAdd) {
      if (!['image/jpeg', 'image/png'].includes(file.type)) {
        entry.imageError = this.ts.t('reviews.photosFormatError');
        input.value = '';
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        entry.imageError = this.ts.t('reviews.photosSizeError');
        input.value = '';
        return;
      }
    }

    entry.imageError = '';
    entry.images = [...entry.images, ...toAdd];
    entry.imagePreviews = [...entry.imagePreviews, ...toAdd.map(f => URL.createObjectURL(f))];
    input.value = '';
    this.cdr.detectChanges();
  }

  removeExistingImage(entry: ReviewEntry, index: number): void {
    const signedId = entry.existingImageSignedIds[index];
    if (signedId) entry.removedImageIds.push(signedId);
    entry.existingImageUrls = entry.existingImageUrls.filter((_, i) => i !== index);
    entry.existingImageSignedIds = entry.existingImageSignedIds.filter((_, i) => i !== index);
  }

  removeImage(entry: ReviewEntry, index: number): void {
    URL.revokeObjectURL(entry.imagePreviews[index]);
    entry.images = entry.images.filter((_, i) => i !== index);
    entry.imagePreviews = entry.imagePreviews.filter((_, i) => i !== index);
  }

  getImageUrl(path: string): string {
    return `${environment.apiUrl}${path}`;
  }

  onSubmit(): void {
    const reviews: SingleReviewResult[] = this.entries
      .filter(e => e.rating > 0 && !e.item.deletedAt)
      .map(e => ({
        reviewableType: e.item.type,
        reviewableId: e.item.id,
        orderId: this.data.orderId,
        rating: e.rating,
        comment: e.comment.trim(),
        images: e.images.length > 0 ? e.images : undefined,
        removeImageIds: e.removedImageIds.length > 0 ? e.removedImageIds : undefined,
        existingReviewId: e.item.existingReviewId
      }));

    this.dialogRef.close({ reviews } as OrderReviewDialogResult);
  }
}
