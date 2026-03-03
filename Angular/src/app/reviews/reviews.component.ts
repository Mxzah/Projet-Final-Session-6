import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { ReviewService, ReviewData } from '../services/review.service';
import { TranslationService } from '../services/translation.service';
import { ReviewFormDialogComponent, ReviewFormDialogData, ReviewFormDialogResult } from './review-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-reviews',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatDialogModule,
    HeaderComponent
  ],
  templateUrl: './reviews.component.html',
  styleUrls: ['./reviews.component.css']
})
export class ReviewsComponent implements OnInit {
  reviews = signal<ReviewData[]>([]);
  isLoading = signal(true);

  constructor(
    public ts: TranslationService,
    private authService: AuthService,
    private reviewService: ReviewService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadReviews();
  }

  loadReviews(): void {
    this.isLoading.set(true);
    this.reviewService.getReviews().subscribe({
      next: (res) => {
        this.reviews.set(res.data || []);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  getReviewableTypeLabel(type: string): string {
    if (type === 'User') return this.ts.t('reviews.typeServer');
    if (type === 'Combo') return 'Combo';
    return 'Item';
  }

  openEditDialog(review: ReviewData): void {
    const data: ReviewFormDialogData = {
      mode: 'edit',
      reviewableName: review.reviewable_name,
      rating: review.rating,
      comment: review.comment
    };

    const ref = this.dialog.open(ReviewFormDialogComponent, {
      data,
      width: '440px',
      maxHeight: '90vh'
    });

    ref.afterClosed().subscribe((result: ReviewFormDialogResult | undefined) => {
      if (!result) return;
      this.reviewService.updateReview(review.id, {
        rating: result.rating,
        comment: result.comment
      }, result.images).subscribe({
        next: (res) => {
          if (res.success) {
            this.snackBar.open(this.ts.t('reviews.updated'), '', { duration: 3000 });
            this.loadReviews();
          } else {
            this.snackBar.open((res.errors as string[])?.join(', ') || 'Error', '', { duration: 5000 });
          }
        }
      });
    });
  }

  confirmDelete(review: ReviewData): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('reviews.deleteReview'),
      message: this.ts.t('reviews.deleteConfirm'),
      itemName: review.reviewable_name,
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open(ConfirmDialogComponent, { data, width: '440px' });
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.reviewService.deleteReview(review.id).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.snackBar.open(this.ts.t('reviews.deleted'), '', { duration: 3000 });
            this.loadReviews();
          }
        }
      });
    });
  }

  getImageUrl(path: string): string {
    return `${environment.apiUrl}${path}`;
  }

  renderStars(rating: number): string {
    return '\u2605'.repeat(rating) + '\u2606'.repeat(5 - rating);
  }

  formatDate(dateStr: string): string {
    const d = new Date(dateStr);
    return d.toLocaleDateString(this.ts.lang() === 'fr' ? 'fr-CA' : 'en-CA', {
      year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
    });
  }

  goToMenu(): void {
    this.router.navigate(['/menu']);
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
