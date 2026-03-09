import { Component, OnInit, OnDestroy, NgZone, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { Location } from '@angular/common';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { ItemsService } from '../../services/items.service';
import { Item, Category } from '../../menu/menu.models';
import { ApiService } from '../../services/api.service';
import { TranslationService } from '../../services/translation.service';
import { ErrorService } from '../../services/error.service';
import { SsfSidebarComponent } from '../../shared/ssf-sidebar/ssf-sidebar.component';
import { SsfBarComponent } from '../../shared/ssf-bar/ssf-bar.component';
import { ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult } from '../item-form-dialog/item-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from '../confirm-dialog/confirm-dialog.component';
import { StatsReportDialogComponent } from '../../shared/stats-report-dialog/stats-report-dialog.component';

@Component({
  selector: 'app-admin-items',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatCardModule, MatButtonModule, MatIconModule,
    MatProgressSpinnerModule, MatTooltipModule,
    SsfSidebarComponent, SsfBarComponent
  ],
  templateUrl: './admin-items.component.html',
  styleUrls: ['./admin-items.component.css']
})
export class AdminItemsComponent implements OnInit, OnDestroy {
  items = signal<Item[]>([]);
  isLoading = signal(true);
  categories = signal<Category[]>([]);
  loadError = signal('');
  actionError = signal('');

  // SSF signals
  searchQuery = signal<string>('');
  sortOrder = signal<string>('none');
  priceMin = signal<number | null>(null);
  priceMax = signal<number | null>(null);
  sliderMin = signal<number>(0);
  sliderMax = signal<number>(9999);
  computedMaxPrice = signal<number>(9999);
  activeCategory = signal<number>(0);

  private now = signal(Date.now());
  private nowInterval?: ReturnType<typeof setInterval>;
  private searchTimer: any = null;
  private maxPriceInitialized = false;

  categoryNames = computed(() =>
    [...new Set(this.items().map(i => i.category_name ?? '—'))]
  );

  itemsByCategory = computed(() => {
    return this.categories().map(cat => {
      const items = this.items().filter(item => item.category_id === cat.id);
      return { ...cat, items };
    });
  });

  unavailableIds = computed(() => {
    const now = this.now();
    return new Set(
      this.items()
        .filter(item => {
          if (item.deleted_at) return false;
          if (!item.availabilities || item.availabilities.length === 0) return true;
          return !item.availabilities.some(a => {
            const start = new Date(a.start_at).getTime();
            const end = a.end_at ? new Date(a.end_at).getTime() : Infinity;
            return start <= now && now < end;
          });
        })
        .map(item => item.id)
    );
  });

  ngOnDestroy(): void {
    clearInterval(this.nowInterval);
    if (this.searchTimer) clearTimeout(this.searchTimer);
  }

  constructor(
    private itemsService: ItemsService,
    private apiService: ApiService,
    public ts: TranslationService,
    private dialog: MatDialog,
    private errorService: ErrorService,
    private ngZone: NgZone,
    private router: Router,
    private route: ActivatedRoute,
    private location: Location
  ) {
    this.ngZone.runOutsideAngular(() => {
      this.nowInterval = setInterval(() => {
        this.ngZone.run(() => this.now.set(Date.now()));
      }, 60_000);
    });
  }

  ngOnInit(): void {
    this.isLoading.set(true);
    // First load without filters to compute the real max price
    this.itemsService.getItems({ admin: true }).subscribe({
      next: (items) => {
        this.ngZone.run(() => {
          const maxPrice = Math.ceil(Math.max(...items.map(i => i.price), 0));
          this.computedMaxPrice.set(maxPrice);
          this.maxPriceInitialized = true;

          // Read query params and apply them
          const params = this.route.snapshot.queryParams;
          if (params['search']) this.searchQuery.set(params['search']);
          if (params['sort'] && params['sort'] !== 'none') this.sortOrder.set(params['sort']);
          if (params['min']) {
            const min = +params['min'];
            this.sliderMin.set(min);
            this.priceMin.set(min > 0 ? min : null);
          }
          if (params['max']) {
            const max = +params['max'];
            this.sliderMax.set(max);
            this.priceMax.set(max < maxPrice ? max : null);
          } else {
            this.sliderMax.set(maxPrice);
          }

          this.loadData();
        });
      },
      error: () => {
        this.loadData();
      }
    });
    this.loadCategories();
  }

  loadData(): void {
    this.isLoading.set(true);
    this.loadError.set('');
    this.itemsService.getItems({
      admin: true,
      search: this.searchQuery(),
      sort: this.sortOrder(),
      price_min: this.priceMin(),
      price_max: this.priceMax()
    }).subscribe({
      next: (items) => {
        this.ngZone.run(() => {
          this.items.set(items);
          this.isLoading.set(false);

          if (this.categories().length === 0) {
            this.extractCategoriesFromItems(items);
          }
        });
      },
      error: (err) => {
        this.ngZone.run(() => {
          this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.isLoading.set(false);
        });
      }
    });
  }

  loadCategories(): void {
    this.apiService.get<Category[]>('/api/categories').subscribe({
      next: (response) => {
        if (response.data) {
          this.categories.set(response.data);
          if (response.data.length > 0 && this.activeCategory() === 0) {
            this.activeCategory.set(response.data[0].id);
          }
        }
      },
      error: () => {
        if (this.items().length > 0) {
          this.extractCategoriesFromItems(this.items());
        }
      }
    });
  }

  private extractCategoriesFromItems(items: Item[]): void {
    const catMap = new Map<number, Category>();
    for (const item of items) {
      if (!catMap.has(item.category_id)) {
        catMap.set(item.category_id, {
          id: item.category_id,
          name: item.category_name ?? '—',
          position: catMap.size
        });
      }
    }
    this.categories.set([...catMap.values()]);
  }

  // ── SSF Handlers ──

  private updateQueryParams(): void {
    const queryParams: any = {};
    if (this.searchQuery()) queryParams.search = this.searchQuery();
    if (this.sortOrder() !== 'none') queryParams.sort = this.sortOrder();
    if (this.priceMin() !== null) queryParams.min = this.priceMin();
    if (this.priceMax() !== null) queryParams.max = this.priceMax();
    this.router.navigate([], { queryParams, replaceUrl: true });
  }

  onSearchInput(value: string): void {
    this.searchQuery.set(value);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadData(); this.updateQueryParams(); }, 300);
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadData();
    this.updateQueryParams();
  }

  onSliderMinChange(value: number): void {
    this.sliderMin.set(value);
    this.priceMin.set(value > 0 ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadData(); this.updateQueryParams(); }, 300);
  }

  onSliderMaxChange(value: number): void {
    this.sliderMax.set(value);
    this.priceMax.set(value < this.computedMaxPrice() ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadData(); this.updateQueryParams(); }, 300);
  }

  onInputMinChange(value: number): void {
    this.onSliderMinChange(value);
  }

  onInputMaxChange(value: number): void {
    this.onSliderMaxChange(value);
  }

  selectCategory(id: number): void {
    this.activeCategory.set(id);
    const el = document.getElementById('admin-category-' + id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  // ── Création ──

  openCreate(): void {
    const data: ItemFormDialogData = { item: null, categories: this.categories() };
    const ref = this.dialog.open<ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult>(
      ItemFormDialogComponent,
      { data, width: '720px', maxWidth: '95vw', maxHeight: '90vh', disableClose: false }
    );
    ref.afterClosed().subscribe({
      next: (result) => {
        if (result?.created) {
          this.ngZone.run(() => this.items.update(items => [...items, result.created!]));
        }
      }
    });
  }

  // ── Modification ──

  openEdit(item: Item): void {
    const data: ItemFormDialogData = { item, categories: this.categories() };
    const ref = this.dialog.open<ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult>(
      ItemFormDialogComponent,
      { data, width: '720px', maxWidth: '95vw', maxHeight: '90vh', disableClose: false }
    );
    ref.afterClosed().subscribe({
      next: (result) => {
        if (result?.updated) {
          this.ngZone.run(() => this.items.update(items =>
            items.map(i => i.id === item.id ? result.updated! : i)
          ));
        }
      }
    });
  }

  // ── Suppression / Archivage ──

  confirmDelete(item: Item): void {
    const data: ConfirmDialogData = item.in_use
      ? {
          title: this.ts.t('admin.archiveItem'),
          message: this.ts.t('admin.archiveConfirm'),
          itemName: item.name,
          warning: this.ts.t('admin.archiveWarning'),
          confirmLabel: this.ts.t('admin.archive'),
          confirmClass: 'btn-danger'
        }
      : {
          title: this.ts.t('admin.deleteItem'),
          message: this.ts.t('admin.deleteConfirm'),
          itemName: item.name,
          confirmLabel: this.ts.t('admin.delete'),
          confirmClass: 'btn-danger'
        };

    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );

    ref.afterClosed().subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.actionError.set('');
        if (item.in_use) {
          this.itemsService.softDeleteItem(item.id).subscribe({
            next: (response) => {
              if (response.data) {
                this.ngZone.run(() => this.items.update(items => items.map(i => i.id === item.id ? response.data! : i)));
              }
            },
            error: (err) => {
              this.ngZone.run(() => this.actionError.set(this.errorService.format(this.errorService.fromApiError(err))));
            }
          });
        } else {
          this.itemsService.hardDeleteItem(item.id).subscribe({
            next: () => {
              this.ngZone.run(() => this.items.update(items => items.filter(i => i.id !== item.id)));
            },
            error: (err) => {
              this.ngZone.run(() => this.actionError.set(this.errorService.format(this.errorService.fromApiError(err))));
            }
          });
        }
      }
    });
  }

  // ── Désarchivage ──

  confirmRestore(item: Item): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('admin.restoreItem'),
      message: this.ts.t('admin.restoreConfirm'),
      itemName: item.name,
      confirmLabel: this.ts.t('admin.restoreBtn'),
      confirmClass: 'btn-restore'
    };

    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );

    ref.afterClosed().subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.actionError.set('');
        this.itemsService.restoreItem(item.id).subscribe({
          next: (response) => {
            if (response.data) {
              this.ngZone.run(() => this.items.update(items => items.map(i => i.id === item.id ? response.data! : i)));
            }
          },
          error: (err) => {
            this.ngZone.run(() => this.actionError.set(this.errorService.format(this.errorService.fromApiError(err))));
          }
        });
      }
    });
  }

  getItemsByCategory(categoryName: string): Item[] {
    return this.items().filter(i => (i.category_name ?? '—') === categoryName);
  }

  openStats(): void {
    const previousUrl = this.location.path();
    this.location.replaceState('/admin/items/stats');

    const ref = this.dialog.open(StatsReportDialogComponent, {
      data: { endpoint: '/api/items/stats', dialogTitle: 'Rapport de statistiques — Items' },
      width: '900px', maxWidth: '95vw', maxHeight: '90vh'
    });

    ref.afterClosed().subscribe(() => {
      this.location.replaceState(previousUrl);
    });
  }
}
