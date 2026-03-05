import { Component, OnInit, OnDestroy, NgZone, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
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

@Component({
    selector: 'app-admin-combos',
    standalone: true,
    imports: [
        CommonModule,
        MatCardModule,
        MatButtonModule,
        MatIconModule,
        MatProgressSpinnerModule,
        MatTooltipModule
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
    }
    isLoading = signal(true);
    loadError = signal('');
    actionError = signal('');

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
    }

    ngOnInit(): void {
        this.loadCombos();
    }

    loadCombos(): void {
        this.isLoading.set(true);
        this.loadError.set('');

        this.combosService.getCombos({ admin: true, include_deleted: true }).subscribe({
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
}
