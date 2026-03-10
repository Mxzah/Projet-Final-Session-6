import { Component, OnInit, OnDestroy, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
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
import { DeleteReviewDialogComponent, DeleteReviewDialogResult } from './delete-review-dialog.component';
import { environment } from '../../environments/environment';

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
  filterType = signal<string[]>([]);
  filterRating = signal<string[]>([]);
  filterStatus = signal('active');
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
    public ts: TranslationService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    const params = this.route.snapshot.queryParams;
    if (params['search']) this.searchTerm.set(params['search']);
    if (params['type']) this.filterType.set(params['type'].split(','));
    if (params['rating']) this.filterRating.set(params['rating'].split(','));
    if (params['status']) this.filterStatus.set(params['status']);
    if (params['sort']) this.sortOrder.set(params['sort']);

    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => { this.loadData(); this.updateQueryParams(); });

    this.loadData();
  }

  ngOnDestroy(): void {
    this.searchSubscription?.unsubscribe();
  }

  loadData(): void {
    this.isLoading.set(true);
    const filters: Record<string, string> = {};
    if (this.searchTerm()) filters['search'] = this.searchTerm();
    if (this.filterType().length > 0) filters['reviewable_type'] = this.filterType().join(',');
    if (this.filterRating().length > 0) filters['rating'] = this.filterRating().join(',');
    if (this.filterStatus()) filters['status'] = this.filterStatus();
    filters['sort'] = this.sortOrder();

    this.reviewService.getReviews(filters).subscribe({
      next: (res) => {
        const data = res.data || [];
        // Push archived/deleted reviews to the bottom
        data.sort((a, b) => {
          const aDeleted = a.deleted_at ? 1 : 0;
          const bDeleted = b.deleted_at ? 1 : 0;
          return aDeleted - bDeleted;
        });
        this.reviews.set(data);
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

  onFilterTypeChange(value: string[]): void {
    this.filterType.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  onFilterRatingChange(value: string[]): void {
    this.filterRating.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  onFilterStatusChange(value: string): void {
    this.filterStatus.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  private updateQueryParams(): void {
    const queryParams: any = {};
    if (this.searchTerm()) queryParams.search = this.searchTerm();
    if (this.filterType().length > 0) queryParams.type = this.filterType().join(',');
    if (this.filterRating().length > 0) queryParams.rating = this.filterRating().join(',');
    if (this.filterStatus() !== 'active') queryParams.status = this.filterStatus();
    if (this.sortOrder() !== 'newest') queryParams.sort = this.sortOrder();
    this.router.navigate([], { queryParams, replaceUrl: true });
  }

  confirmDelete(review: ReviewData): void {
    const ref = this.dialog.open(DeleteReviewDialogComponent, {
      data: { reviewableName: review.reviewable_name },
      width: '440px'
    });
    ref.afterClosed().subscribe((result: DeleteReviewDialogResult | undefined) => {
      if (!result) return;
      this.reviewService.deleteReview(review.id, result.reason || undefined).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.snackBar.open(this.ts.t('admin.reviews.reviewDeleted'), '', { duration: 3000 });
            this.loadData();
          }
        }
      });
    });
  }

  isDeleted(review: ReviewData): boolean {
    return !!review.deleted_at;
  }

  hasDeletedReviews(): boolean {
    return this.reviews().some(r => !!r.deleted_at);
  }

  hasActiveReviews(): boolean {
    return this.reviews().some(r => !r.deleted_at);
  }

  activeReviews(): ReviewData[] {
    return this.reviews().filter(r => !r.deleted_at);
  }

  deletedReviews(): ReviewData[] {
    return this.reviews().filter(r => !!r.deleted_at);
  }

  getImageUrl(path: string): string {
    return `${environment.apiUrl}${path}`;
  }

  renderStars(rating: number): string {
    return '\u2605'.repeat(rating) + '\u2606'.repeat(5 - rating);
  }
}
