import { Component, Inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ComboItemsService, ComboItem } from '../../services/combo-items.service';
import { Item, AvailabilityEntry } from '../../models/menu.models';
import { TranslationService } from '../../services/translation.service';
import { ErrorService } from '../../services/error.service';

export interface AddItemDialogData {
    comboId: number;
    items: Item[];
    unavailableItemIds: Set<number>;
}

export interface AddItemDialogResult {
    created?: ComboItem;
}

@Component({
    selector: 'app-add-item-dialog',
    standalone: true,
    imports: [
        CommonModule,
        ReactiveFormsModule,
        MatDialogModule,
        MatButtonModule,
        MatIconModule,
        MatFormFieldModule,
        MatInputModule,
        MatSelectModule,
        MatProgressSpinnerModule
    ],
    templateUrl: './add-item-dialog.component.html',
    styleUrls: ['./add-item-dialog.component.css']
})
export class AddItemDialogComponent {
    items: Item[];
    unavailableItemIds: Set<number>;
    comboId: number;

    form = new FormGroup({
        item_id: new FormControl<number | null>(null, [Validators.required]),
        quantity: new FormControl<number | null>(1, [Validators.required, Validators.min(1), Validators.max(10)])
    });

    error = signal('');
    loading = signal(false);
    itemSearchTerm = signal('');

    filteredItems = computed(() => {
        const search = this.itemSearchTerm().toLowerCase().trim();
        if (!search) return this.items;
        return this.items.filter(item => item.name.toLowerCase().includes(search));
    });

    constructor(
        private dialogRef: MatDialogRef<AddItemDialogComponent, AddItemDialogResult>,
        @Inject(MAT_DIALOG_DATA) public data: AddItemDialogData,
        private comboItemsService: ComboItemsService,
        public ts: TranslationService,
        private errorService: ErrorService
    ) {
        this.items = data.items;
        this.unavailableItemIds = data.unavailableItemIds;
        this.comboId = data.comboId;
    }

    onItemSearchInput(event: Event): void {
        const input = event.target as HTMLInputElement;
        this.itemSearchTerm.set(input.value);
    }

    onSelectOpened(): void {
        this.itemSearchTerm.set('');
    }

    clampQuantity(event: Event): void {
        const input = event.target as HTMLInputElement;
        const value = parseInt(input.value, 10);
        if (value > 10) {
            input.value = '10';
            this.form.controls.quantity.setValue(10);
        } else if (value < 1) {
            input.value = '1';
            this.form.controls.quantity.setValue(1);
        }
    }

    save(): void {
        Object.values(this.form.controls).forEach(c => {
            c.markAsDirty();
            c.markAsTouched();
        });
        if (this.form.invalid || this.loading()) return;

        const values = this.form.getRawValue();
        const item_id = Number(values.item_id);
        const quantity = Number(values.quantity);

        this.error.set('');
        this.loading.set(true);

        this.comboItemsService.createComboItem({ combo_id: this.comboId, item_id, quantity }).subscribe({
            next: (created) => {
                this.loading.set(false);
                this.dialogRef.close({ created });
            },
            error: (err) => {
                this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.loading.set(false);
            }
        });
    }
}
