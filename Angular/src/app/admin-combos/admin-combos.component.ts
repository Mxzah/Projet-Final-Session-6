import { Component, OnInit, OnDestroy, NgZone, signal, computed, inject, input, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDialog } from '@angular/material/dialog';
import { CombosService, Combo } from '../services/combos.service';
import { ComboItemsService, ComboItem } from '../services/combo-items.service';
import { ItemsService } from '../services/items.service';
import { Item } from '../menu/menu.models';
import { ErrorService } from '../services/error.service';
import { TranslationService } from '../services/translation.service';
import { ComboFormDialogComponent, ComboFormDialogResult } from './combo-form-dialog/combo-form-dialog.component';
import { AddItemDialogComponent, AddItemDialogResult } from './add-item-dialog/add-item-dialog.component';
import { SsfBarComponent } from '../shared/ssf-bar/ssf-bar.component';

@Component({
    selector: 'app-admin-combos',
    standalone: true,
    imports: [
        CommonModule,
        MatCardModule,
        MatButtonModule,
        MatIconModule,
        MatProgressSpinnerModule,
        MatTooltipModule,
        SsfBarComponent
    ],
    templateUrl: './admin-combos.component.html',
    styleUrls: ['./admin-combos.component.css']
})
export class AdminCombosComponent implements OnInit, OnDestroy {
    combos = signal<Combo[]>([]);

    // Selected combo for detail view
    selectedCombo = signal<Combo | null>(null);
    comboItems = signal<ComboItem[]>([]);
    items = signal<Item[]>([]);
    isLoadingItems = signal(false);

    private now = signal(Date.now());
    private nowInterval?: ReturnType<typeof setInterval>;

    unavailableIds = computed(() => {
        const now = this.now();
        return new Set(
            this.combos()
                .filter(combo => {
                    if (!combo.availabilities || combo.availabilities.length === 0) return true;
                    return !combo.availabilities.some(a => {
                        const start = new Date(a.start_at).getTime();
                        const end = a.end_at ? new Date(a.end_at).getTime() : Infinity;
                        return start <= now && now < end;
                    });
                })
                .map(combo => combo.id)
        );
    });

    // Filtered combo items for the selected combo
    selectedComboItems = computed(() => {
        const combo = this.selectedCombo();
        if (!combo) return [];
        return this.comboItems().filter(ci => ci.combo_id === combo.id);
    });

    // Total value of items in the selected combo (sum of individual item prices * quantity)
    itemsTotalValue = computed(() => {
        const comboItems = this.selectedComboItems();
        const itemsMap = new Map(this.items().map(item => [item.id, item.price]));
        return comboItems.reduce((total, ci) => {
            const itemPrice = itemsMap.get(ci.item_id) ?? 0;
            return total + (itemPrice * ci.quantity);
        }, 0);
    });

    // Savings when buying combo vs buying items individually
    comboSavings = computed(() => {
        const itemsTotal = this.itemsTotalValue();
        const comboPrice = this.selectedCombo()?.price ?? 0;
        return itemsTotal - comboPrice;
    });

    // Unavailable item IDs (items without valid availability)
    unavailableItemIds = computed(() => {
        const now = this.now();
        return new Set(
            this.items()
                .filter(item => {
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
    isLoading = signal(true);
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
    private searchTimer: any = null;
    private maxPriceInitialized = false;
    private filtersReady = false;
    private router = inject(Router);

    // Query params bound via withComponentInputBinding()
    search = input<string>('');
    sort = input<string>('');
    min = input<string>('');
    max = input<string>('');

    constructor(
        private combosService: CombosService,
        private comboItemsService: ComboItemsService,
        private itemsService: ItemsService,
        private errorService: ErrorService,
        private dialog: MatDialog,
        private ngZone: NgZone,
        public ts: TranslationService
    ) {
        this.ngZone.runOutsideAngular(() => {
            this.nowInterval = setInterval(() => {
                this.ngZone.run(() => this.now.set(Date.now()));
            }, 60_000);
        });

        // Effect: reload data when filters change
        effect(() => {
            void this.searchQuery();
            void this.sortOrder();
            void this.priceMin();
            void this.priceMax();

            if (!this.filtersReady) return;

            if (this.searchTimer) clearTimeout(this.searchTimer);
            this.searchTimer = setTimeout(() => {
                this.loadCombos();
                this.updateQueryParams();
            }, 300);
        });
    }

    ngOnInit(): void {
        this.isLoading.set(true);
        // First load without filters to compute the real max price
        this.combosService.getCombos({ admin: true, include_deleted: true }).subscribe({
            next: (combos) => {
                this.ngZone.run(() => {
                    const maxPrice = Math.ceil(Math.max(...combos.map(c => c.price), 0));
                    this.computedMaxPrice.set(maxPrice);
                    this.maxPriceInitialized = true;

                    // Read query params via input signals
                    if (this.search()) this.searchQuery.set(this.search());
                    if (this.sort() && this.sort() !== 'none') this.sortOrder.set(this.sort());
                    if (this.min()) {
                        const min = +this.min();
                        this.sliderMin.set(min);
                        this.priceMin.set(min > 0 ? min : null);
                    }
                    if (this.max()) {
                        const max = +this.max();
                        this.sliderMax.set(max);
                        this.priceMax.set(max < maxPrice ? max : null);
                    } else {
                        this.sliderMax.set(maxPrice);
                    }

                    this.filtersReady = true;
                    this.loadCombos();
                });
            },
            error: () => {
                this.filtersReady = true;
                this.loadCombos();
            }
        });
    }

    loadCombos(): void {
        this.isLoading.set(true);
        this.loadError.set('');

        this.combosService.getCombos({
            admin: true,
            include_deleted: true,
            search: this.searchQuery(),
            sort: this.sortOrder(),
            price_min: this.priceMin(),
            price_max: this.priceMax()
        }).subscribe({
            next: (combos) => {
                this.combos.set(combos);
                this.isLoading.set(false);
            },
            error: (err) => {
                this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.isLoading.set(false);
            }
        });
    }

    // ── Combo Detail View ──
    selectCombo(combo: Combo): void {
        this.selectedCombo.set(combo);
        this.actionError.set('');
        this.loadComboItemsAndItems();
    }

    backToList(): void {
        this.selectedCombo.set(null);
        this.comboItems.set([]);
        this.actionError.set('');
    }

    private loadComboItemsAndItems(): void {
        this.isLoadingItems.set(true);

        let remaining = 2;
        const finish = () => {
            remaining -= 1;
            if (remaining === 0) {
                this.isLoadingItems.set(false);
            }
        };

        this.comboItemsService.getComboItems(true).subscribe({
            next: (data) => {
                this.comboItems.set(data);
                finish();
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
                finish();
            }
        });

        this.itemsService.getItems({ admin: true }).subscribe({
            next: (data) => {
                this.items.set(data.filter(item => !item.deleted_at));
                finish();
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
                finish();
            }
        });
    }

    // ── Create Combo (mat-dialog) ──
    openCreate(): void {
        const dialogRef = this.dialog.open(ComboFormDialogComponent, {
            width: '520px',
            data: { combo: null }
        });

        dialogRef.afterClosed().subscribe((result?: ComboFormDialogResult) => {
            if (result?.created) {
                this.combos.update(list => [result.created!, ...list]);
            }
        });
    }

    // ── Add Item to Combo (mat-dialog) ──
    openAddItem(): void {
        const combo = this.selectedCombo();
        if (!combo) return;

        const dialogRef = this.dialog.open(AddItemDialogComponent, {
            width: '440px',
            data: {
                comboId: combo.id,
                items: this.items(),
                unavailableItemIds: this.unavailableItemIds()
            }
        });

        dialogRef.afterClosed().subscribe((result?: AddItemDialogResult) => {
            if (result?.created) {
                this.comboItems.update(list => [result.created!, ...list]);
            }
        });
    }

    deleteComboItem(comboItem: ComboItem): void {
        this.comboItemsService.deleteComboItem(comboItem.id).subscribe({
            next: () => {
                // Reload to get the item with deleted_at set
                this.comboItemsService.getComboItems(true).subscribe({
                    next: (data) => this.comboItems.set(data),
                    error: () => { }
                });
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
            }
        });
    }

    trackByComboId(_: number, combo: Combo): number {
        return combo.id;
    }

    trackByComboItemId(_: number, comboItem: ComboItem): number {
        return comboItem.id;
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
    }

    onSortChange(value: string): void {
        this.sortOrder.set(value);
    }

    onSliderMinChange(value: number): void {
        this.sliderMin.set(value);
        this.priceMin.set(value > 0 ? value : null);
    }

    onSliderMaxChange(value: number): void {
        this.sliderMax.set(value);
        this.priceMax.set(value < this.computedMaxPrice() ? value : null);
    }

    onInputMinChange(value: number): void {
        this.onSliderMinChange(value);
    }

    onInputMaxChange(value: number): void {
        this.onSliderMaxChange(value);
    }
}
