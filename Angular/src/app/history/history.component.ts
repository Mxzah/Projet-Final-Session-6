import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSliderModule } from '@angular/material/slider';
import { MatDividerModule } from '@angular/material/divider';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { OrderService, OrderData } from '../services/order.service';
import { ReviewService, ReviewData } from '../services/review.service';
import { TranslationService } from '../services/translation.service';
import { ReviewFormDialogComponent, ReviewFormDialogData, ReviewFormDialogResult } from '../reviews/review-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-history',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSliderModule,
    MatDividerModule,
    MatDialogModule,
    HeaderComponent
  ],
  templateUrl: './history.component.html',
  styleUrls: ['./history.component.css']
})
export class HistoryComponent implements OnInit {
  orders = signal<OrderData[]>([]);
  reviews = signal<ReviewData[]>([]);
  isLoading = signal(true);

  // SSF state
  searchQuery = signal('');
  sortOrder = signal('newest');
  sliderMin = signal(0);
  sliderMax = signal(9999);
  computedMaxTotal = signal(9999);
  totalMin = signal<number | null>(null);
  totalMax = signal<number | null>(null);

  private searchTimer: any = null;
  private maxTotalInitialized = false;

  constructor(
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private reviewService: ReviewService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.orderService.getOrders({ closed: true }).subscribe({
      next: (res) => {
        const allOrders = (res.data || []).filter(o => o.ended_at);
        const maxTotal = Math.ceil(Math.max(...allOrders.map(o => o.adjusted_total), 0));
        this.computedMaxTotal.set(maxTotal);
        this.maxTotalInitialized = true;

        const params = this.route.snapshot.queryParams;
        if (params['search']) this.searchQuery.set(params['search']);
        if (params['sort']) this.sortOrder.set(params['sort']);
        if (params['min']) {
          const min = +params['min'];
          this.sliderMin.set(min);
          this.totalMin.set(min > 0 ? min : null);
        }
        if (params['max']) {
          const max = +params['max'];
          this.sliderMax.set(max);
          this.totalMax.set(max < maxTotal ? max : null);
        } else {
          this.sliderMax.set(maxTotal);
        }

        this.loadData();
      },
      error: () => {
        this.loadData();
      }
    });
  }

  loadData(): void {
    this.isLoading.set(true);
    this.orderService.getOrders({
      closed: true,
      sort: this.sortOrder() === 'newest' ? undefined : this.sortOrder(),
      total_min: this.totalMin(),
      total_max: this.totalMax()
    }).subscribe({
      next: (res) => {
        let allOrders = (res.data || []).filter(o => o.ended_at);
        // Client-side full-text search across all fields
        const query = this.searchQuery().trim();
        if (query) {
          allOrders = allOrders.filter(o => this.matchesSearch(o, query));
        }
        if (this.totalMin() != null) {
          allOrders = allOrders.filter(o => o.adjusted_total >= this.totalMin()!);
        }
        if (this.totalMax() != null) {
          allOrders = allOrders.filter(o => o.adjusted_total <= this.totalMax()!);
        }
        if (this.sortOrder() === 'total_asc') {
          allOrders.sort((a, b) => a.adjusted_total - b.adjusted_total);
        } else if (this.sortOrder() === 'total_desc') {
          allOrders.sort((a, b) => b.adjusted_total - a.adjusted_total);
        }
        this.orders.set(allOrders);
        this.loadReviews();
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  private loadReviews(): void {
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

  private matchesSearch(order: OrderData, query: string): boolean {
    const q = query.toLowerCase().trim();
    // Table number — support "3", "table 3", "table3"
    if (String(order.table_number).includes(q)) return true;
    const tableQ = q.replace(/^table\s*/i, '');
    if (tableQ && String(order.table_number) === tableQ) return true;
    // Server name
    if (order.server_name && order.server_name.toLowerCase().includes(q)) return true;
    // Vibe name
    if (order.vibe_name && order.vibe_name.toLowerCase().includes(q)) return true;
    // Order note
    if (order.note && order.note.toLowerCase().includes(q)) return true;
    // Total, tip, adjusted_total as strings
    if (order.adjusted_total.toFixed(2).includes(q)) return true;
    if (order.total.toFixed(2).includes(q)) return true;
    if (order.tip > 0 && order.tip.toFixed(2).includes(q)) return true;
    // Date
    if (this.formatDate(order.created_at).toLowerCase().includes(q)) return true;
    // Order lines
    for (const line of order.order_lines) {
      if (line.orderable_name.toLowerCase().includes(q)) return true;
      if (line.note && line.note.toLowerCase().includes(q)) return true;
      if (line.unit_price.toFixed(2).includes(q)) return true;
      if ((line.unit_price * line.quantity).toFixed(2).includes(q)) return true;
    }
    return false;
  }

  private updateQueryParams(): void {
    const queryParams: any = {};
    if (this.searchQuery()) queryParams.search = this.searchQuery();
    if (this.sortOrder() !== 'newest') queryParams.sort = this.sortOrder();
    if (this.totalMin() !== null) queryParams.min = this.totalMin();
    if (this.totalMax() !== null) queryParams.max = this.totalMax();
    this.router.navigate([], { queryParams, replaceUrl: true });
  }

  onSearchInput(event: Event): void {
    this.searchQuery.set((event.target as HTMLInputElement).value);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => {
      this.loadData();
      this.updateQueryParams();
    }, 350);
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  onSliderMinChange(value: number): void {
    this.sliderMin.set(value);
    this.totalMin.set(value > 0 ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadData(); this.updateQueryParams(); }, 300);
  }

  onSliderMaxChange(value: number): void {
    this.sliderMax.set(value);
    this.totalMax.set(value < this.computedMaxTotal() ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadData(); this.updateQueryParams(); }, 300);
  }

  onInputMinChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, 0), this.sliderMax());
    input.value = String(clamped);
    this.onSliderMinChange(clamped);
  }

  onInputMaxChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, this.sliderMin()), this.computedMaxTotal());
    input.value = String(clamped);
    this.onSliderMaxChange(clamped);
  }

  getImageUrl(path: string): string {
    return `${environment.apiUrl}${path}`;
  }

  getReviewForItem(orderableType: string, orderableId: number): ReviewData | null {
    return this.reviews().find(r =>
      r.reviewable_type === orderableType && r.reviewable_id === orderableId
    ) || null;
  }

  getReviewForServer(serverId: number): ReviewData | null {
    return this.reviews().find(r =>
      r.reviewable_type === 'User' && r.reviewable_id === serverId
    ) || null;
  }

  renderStars(rating: number): string {
    return '\u2605'.repeat(rating) + '\u2606'.repeat(5 - rating);
  }

  openReviewDialog(reviewableType: string, reviewableId: number, reviewableName: string, existingReview?: ReviewData): void {
    const data: ReviewFormDialogData = {
      mode: existingReview ? 'edit' : 'create',
      reviewableName,
      rating: existingReview?.rating,
      comment: existingReview?.comment
    };

    const ref = this.dialog.open(ReviewFormDialogComponent, {
      data,
      width: '440px',
      maxHeight: '90vh'
    });

    ref.afterClosed().subscribe((result: ReviewFormDialogResult | undefined) => {
      if (!result) return;

      if (existingReview) {
        this.reviewService.updateReview(existingReview.id, {
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
      } else {
        this.reviewService.createReview({
          rating: result.rating,
          comment: result.comment,
          reviewable_type: reviewableType,
          reviewable_id: reviewableId
        }, result.images).subscribe({
          next: (res) => {
            if (res.success) {
              this.snackBar.open(this.ts.t('reviews.created'), '', { duration: 3000 });
              this.loadReviews();
            } else {
              this.snackBar.open((res.errors as string[])?.join(', ') || 'Error', '', { duration: 5000 });
            }
          }
        });
      }
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
