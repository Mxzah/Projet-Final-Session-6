import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { from, of, concat } from 'rxjs';
import { concatMap, toArray, catchError } from 'rxjs/operators';
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
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { OrderReviewDialogComponent, OrderReviewDialogData, OrderReviewDialogResult, ReviewableItem } from './order-review-dialog.component';
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
  reviewFilter = signal('all');
  sliderMin = signal(0);
  sliderMax = signal(9999);
  computedMaxTotal = signal(9999);
  totalMin = signal<number | null>(null);
  totalMax = signal<number | null>(null);

  // Filtered orders (applies review filter on top of search/sort/price)
  filteredOrders = computed(() => {
    const all = this.orders();
    const filter = this.reviewFilter();
    if (filter === 'all') return all;
    return all.filter(o => {
      const hasReviews = this.orderHasReviews(o);
      return filter === 'reviewed' ? hasReviews : !hasReviews;
    });
  });

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
        if (params['review']) this.reviewFilter.set(params['review']);
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

  // ── Review helpers ──

  orderHasReviews(order: OrderData): boolean {
    return this.getOrderReviewCount(order) > 0;
  }

  getOrderReviewCount(order: OrderData): number {
    const revs = this.reviews().filter(r => r.order_id === order.id);
    return revs.length;
  }

  orderAllModerated(order: OrderData): boolean {
    const orderRevs = this.reviews().filter(r => r.order_id === order.id);
    return orderRevs.length > 0 && orderRevs.every(r => !!r.deleted_at);
  }

  openOrderReviewDialog(order: OrderData): void {
    const revs = this.reviews().filter(r => r.order_id === order.id);

    // Build reviewable items: server first, then order lines (deduplicated)
    const items: ReviewableItem[] = [];
    if (order.server_id && order.server_name) {
      const existing = revs.find(r => r.reviewable_type === 'User' && r.reviewable_id === order.server_id);
      items.push({
        type: 'User',
        id: order.server_id,
        name: order.server_name,
        existingReviewId: existing?.id,
        existingRating: existing?.rating,
        existingComment: existing?.comment,
        existingImageUrls: existing?.image_urls,
        deletedAt: existing?.deleted_at || undefined,
        deletionReason: existing?.deletion_reason || undefined
      });
    }

    // Deduplicate lines by orderable_type + orderable_id
    const seen = new Set<string>();
    for (const line of order.order_lines) {
      const key = `${line.orderable_type}:${line.orderable_id}`;
      if (seen.has(key)) continue;
      seen.add(key);
      const existing = revs.find(r => r.reviewable_type === line.orderable_type && r.reviewable_id === line.orderable_id);
      items.push({
        type: line.orderable_type,
        id: line.orderable_id,
        name: line.orderable_name,
        imageUrl: line.image?.url ? this.getImageUrl(line.image.url) : undefined,
        existingReviewId: existing?.id,
        existingRating: existing?.rating,
        existingComment: existing?.comment,
        existingImageUrls: existing?.image_urls,
        deletedAt: existing?.deleted_at || undefined,
        deletionReason: existing?.deletion_reason || undefined
      });
    }

    const data: OrderReviewDialogData = {
      orderId: order.id,
      orderTableNumber: order.table_number,
      orderDate: this.formatDate(order.created_at),
      items
    };

    const ref = this.dialog.open(OrderReviewDialogComponent, {
      data,
      width: '520px',
      maxHeight: '90vh'
    });

    ref.afterClosed().subscribe((result: OrderReviewDialogResult | undefined) => {
      if (!result || result.reviews.length === 0) return;

      const ops = result.reviews.map(r => {
        const op$ = r.existingReviewId
          ? this.reviewService.updateReview(r.existingReviewId, {
              rating: r.rating,
              comment: r.comment
            }, r.images)
          : this.reviewService.createReview({
              rating: r.rating,
              comment: r.comment,
              reviewable_type: r.reviewableType,
              reviewable_id: r.reviewableId,
              order_id: r.orderId
            }, r.images);
        return op$.pipe(catchError(() => of(null)));
      });

      from(ops).pipe(
        concatMap(op$ => op$),
        toArray()
      ).subscribe(results => {
        const saved = results.filter(r => r !== null).length;
        if (saved > 0) {
          this.snackBar.open(this.ts.t('reviews.reviewsSaved'), '', { duration: 3000 });
        } else {
          this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
        }
        this.loadReviews();
      });
    });
  }

  // ── Search/filter/sort ──

  private matchesSearch(order: OrderData, query: string): boolean {
    const q = query.toLowerCase().trim();
    if (String(order.table_number).includes(q)) return true;
    const tableQ = q.replace(/^table\s*/i, '');
    if (tableQ && String(order.table_number) === tableQ) return true;
    if (order.server_name && order.server_name.toLowerCase().includes(q)) return true;
    if (order.vibe_name && order.vibe_name.toLowerCase().includes(q)) return true;
    if (order.note && order.note.toLowerCase().includes(q)) return true;
    if (order.adjusted_total.toFixed(2).includes(q)) return true;
    if (order.total.toFixed(2).includes(q)) return true;
    if (order.tip > 0 && order.tip.toFixed(2).includes(q)) return true;
    if (this.formatDate(order.created_at).toLowerCase().includes(q)) return true;
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
    if (this.reviewFilter() !== 'all') queryParams.review = this.reviewFilter();
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

  onReviewFilterChange(value: string): void {
    this.reviewFilter.set(value);
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
