import { Component, OnInit, OnDestroy, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { ReviewService, ReviewData } from '../services/review.service';
import { TranslationService } from '../services/translation.service';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog.component';

@Component({
  selector: 'app-admin-reviews',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule, MatButtonModule, MatIconModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './admin-reviews.component.html',
  styleUrls: ['./admin-reviews.component.css']
})
export class AdminReviewsComponent implements OnInit, OnDestroy {
  reviews = signal<ReviewData[]>([]);
  isLoading = signal(true);

  searchTerm = signal('');
  filterType = signal('all');
  filterRating = signal('all');
  sortOrder = signal('newest');

  private searchSubject = new Subject<string>();
  private searchSubscription!: Subscription;

  reviewableTypes = [
    { value: 'Item', labelKey: 'admin.reviews.typeItem' },
    { value: 'Combo', labelKey: 'admin.reviews.typeCombo' },
    { value: 'User', labelKey: 'admin.reviews.typeServer' },
  ];
  ratings = [1, 2, 3, 4, 5];

  constructor(
    private reviewService: ReviewService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    public ts: TranslationService
  ) {}

  ngOnInit(): void {
    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => this.loadData());

    this.loadData();
  }

  ngOnDestroy(): void {
    this.searchSubscription?.unsubscribe();
  }

  loadData(): void {
    this.isLoading.set(true);
    const filters: Record<string, string> = {};
    if (this.searchTerm()) filters['search'] = this.searchTerm();
    if (this.filterType() !== 'all') filters['reviewable_type'] = this.filterType();
    if (this.filterRating() !== 'all') filters['rating'] = this.filterRating();
    filters['sort'] = this.sortOrder();

    this.reviewService.getReviews(filters).subscribe({
      next: (res) => {
        this.reviews.set(res.data || []);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  onSearchChange(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchTerm.set(value);
    this.searchSubject.next(value);
  }

  onFilterTypeChange(value: string): void {
    this.filterType.set(value);
    this.loadData();
  }

  onFilterRatingChange(value: string): void {
    this.filterRating.set(value);
    this.loadData();
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadData();
  }

  confirmDelete(review: ReviewData): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('reviews.deleteReview'),
      message: this.ts.t('admin.reviews.deleteConfirm'),
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
            this.snackBar.open(this.ts.t('admin.reviews.reviewDeleted'), '', { duration: 3000 });
            this.loadData();
          }
        }
      });
    });
  }

  renderStars(rating: number): string {
    return '\u2605'.repeat(rating) + '\u2606'.repeat(5 - rating);
  }
}
