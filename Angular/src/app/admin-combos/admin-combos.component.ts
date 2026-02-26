import { Component, OnInit, OnDestroy, NgZone, ViewChild, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { CombosService, Combo } from '../services/combos.service';
import { ComboItemsService, ComboItem } from '../services/combo-items.service';
import { ItemsService } from '../services/items.service';
import { Item } from '../menu/menu.models';
import { AvailabilityService } from '../services/availability.service';
import { AvailabilityEntry } from '../menu/menu.models';
import { AvailabilityListComponent } from '../shared/availability-list/availability-list.component';
import { ErrorService } from '../services/error.service';
import { TranslationService } from '../services/translation.service';

function notOnlyWhitespace(control: AbstractControl): ValidationErrors | null {
    if (control.value && /^\s*$/.test(control.value)) {
        return { whitespace: true };
    }
    return null;
}

@Component({
    selector: 'app-admin-combos',
    standalone: true,
    imports: [
        CommonModule,
        ReactiveFormsModule,
        MatCardModule,
        MatButtonModule,
        MatIconModule,
        MatFormFieldModule,
        MatInputModule,
        MatSelectModule,
        MatProgressSpinnerModule,
        MatSlideToggleModule,
        AvailabilityListComponent
    ],
    templateUrl: './admin-combos.component.html',
    styleUrls: ['./admin-combos.component.css']
})
export class AdminCombosComponent implements OnInit, OnDestroy {
    @ViewChild('createAvailList') createAvailList?: AvailabilityListComponent;

    combos = signal<Combo[]>([]);
    createAvailabilities = signal<AvailabilityEntry[]>([]);
    showDeleted = signal(false);

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

    isCreating = signal(false);
    isSaving = signal(false);

    // Image for create combo
    createImage: File | null = null;
    createImagePreview = signal<string | null>(null);
    createImageError = signal('');

    // Add item to combo form
    isAddingItem = signal(false);
    isSavingItem = signal(false);
    itemSearchTerm = signal('');

    // Filtered items based on search term
    filteredItems = computed(() => {
        const search = this.itemSearchTerm().toLowerCase().trim();
        if (!search) return this.items();
        return this.items().filter(item => item.name.toLowerCase().includes(search));
    });

    createForm = new FormGroup({
        name: new FormControl('', [Validators.required, Validators.maxLength(100), notOnlyWhitespace]),
        description: new FormControl('', [Validators.maxLength(255)]),
        price: new FormControl<number | null>(null, [Validators.required, Validators.min(0.01), Validators.max(9999.99)])
    });

    addItemForm = new FormGroup({
        item_id: new FormControl<number | null>(null, [Validators.required]),
        quantity: new FormControl<number | null>(1, [Validators.required, Validators.min(1), Validators.max(10)])
    });

    constructor(
        private combosService: CombosService,
        private comboItemsService: ComboItemsService,
        private itemsService: ItemsService,
        private availabilityService: AvailabilityService,
        private errorService: ErrorService,
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

        this.combosService.getCombos({ include_deleted: this.showDeleted() }).subscribe({
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

    toggleShowDeleted(): void {
        this.showDeleted.update(v => !v);
        this.loadCombos();
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
        this.isAddingItem.set(false);
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

        this.comboItemsService.getComboItems(this.showDeleted()).subscribe({
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

    // ── Add Item to Combo ──
    openAddItem(): void {
        this.actionError.set('');
        this.isAddingItem.set(true);
        this.itemSearchTerm.set('');
        this.addItemForm.reset({ item_id: null, quantity: 1 });
        this.addItemForm.markAsPristine();
        this.addItemForm.markAsUntouched();
    }

    onItemSearchInput(event: Event): void {
        const input = event.target as HTMLInputElement;
        this.itemSearchTerm.set(input.value);
    }

    onSelectOpened(): void {
        this.itemSearchTerm.set('');
    }

    cancelAddItem(): void {
        this.isAddingItem.set(false);
        this.isSavingItem.set(false);
        this.actionError.set('');
    }

    saveAddItem(): void {
        Object.values(this.addItemForm.controls).forEach(c => {
            c.markAsDirty();
            c.markAsTouched();
        });
        if (this.addItemForm.invalid || this.isSavingItem()) return;

        const combo = this.selectedCombo();
        if (!combo) return;

        const values = this.addItemForm.getRawValue();
        const item_id = Number(values.item_id);
        const quantity = Number(values.quantity);

        this.actionError.set('');
        this.isSavingItem.set(true);

        this.comboItemsService.createComboItem({ combo_id: combo.id, item_id, quantity }).subscribe({
            next: (created) => {
                this.comboItems.update(list => [created, ...list]);
                this.isSavingItem.set(false);
                this.isAddingItem.set(false);
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.isSavingItem.set(false);
            }
        });
    }

    deleteComboItem(comboItem: ComboItem): void {
        this.comboItemsService.deleteComboItem(comboItem.id).subscribe({
            next: () => {
                this.comboItems.update(list => list.filter(ci => ci.id !== comboItem.id));
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
            }
        });
    }

    // ── Create Combo ──
    openCreate(): void {
        this.actionError.set('');
        this.isCreating.set(true);
        this.createAvailabilities.set([]);
        this.createImage = null;
        this.createImagePreview.set(null);
        this.createImageError.set('');
        this.createForm.reset({
            name: '',
            description: '',
            price: null
        });
        this.createForm.markAsPristine();
        this.createForm.markAsUntouched();
    }

    cancelCreate(): void {
        this.isCreating.set(false);
        this.isSaving.set(false);
        this.actionError.set('');
        this.createAvailabilities.set([]);
        this.createImage = null;
        this.createImagePreview.set(null);
        this.createImageError.set('');
    }

    onImageSelected(event: Event): void {
        const input = event.target as HTMLInputElement;
        const file = input.files?.[0];
        if (!file) return;

        const validTypes = ['image/jpeg', 'image/png'];
        if (!validTypes.includes(file.type)) {
            this.createImageError.set(this.errorService.format(this.errorService.imageError('format', this.ts)));
            input.value = '';
            return;
        }

        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
            this.createImageError.set(this.errorService.format(this.errorService.imageError('size', this.ts)));
            input.value = '';
            return;
        }

        this.createImageError.set('');
        this.createImage = file;

        const reader = new FileReader();
        reader.onload = () => this.createImagePreview.set(reader.result as string);
        reader.readAsDataURL(file);
    }

    clampPrice(event: Event): void {
        const input = event.target as HTMLInputElement;
        const value = parseFloat(input.value);
        if (value > 9999.99) {
            input.value = '9999.99';
            this.createForm.controls.price.setValue(9999.99);
        } else if (value < 0) {
            input.value = '0';
            this.createForm.controls.price.setValue(0);
        }
    }

    clampQuantity(event: Event): void {
        const input = event.target as HTMLInputElement;
        const value = parseInt(input.value, 10);
        if (value > 10) {
            input.value = '10';
            this.addItemForm.controls.quantity.setValue(10);
        } else if (value < 1) {
            input.value = '1';
            this.addItemForm.controls.quantity.setValue(1);
        }
    }

    saveCreate(): void {
        Object.values(this.createForm.controls).forEach(control => control.markAsDirty());
        if (this.createForm.invalid || this.isSaving()) return;

        const values = this.createForm.getRawValue();
        const name = values.name?.trim() ?? '';
        const description = values.description?.trim() ?? '';
        const price = Number(values.price);

        this.actionError.set('');
        this.isSaving.set(true);

        const payload: { name: string; description?: string; price: number; image?: File } = { name, description, price };
        if (this.createImage) payload.image = this.createImage;

        this.combosService.createCombo(payload).subscribe({
            next: (created) => {
                this.combos.update(list => [created, ...list]);
                this.availabilityService.syncAvailabilities(
                    this.createAvailabilities(), [],
                    (e) => this.availabilityService.createAvailability('combos', created.id, e),
                    (id, e) => this.availabilityService.updateAvailability('combos', created.id, id, e),
                    (id) => this.availabilityService.deleteAvailability('combos', created.id, id)
                ).subscribe({
                    next: () => { this.isSaving.set(false); this.isCreating.set(false); },
                    error: () => { this.isSaving.set(false); this.isCreating.set(false); }
                });
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.isSaving.set(false);
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
