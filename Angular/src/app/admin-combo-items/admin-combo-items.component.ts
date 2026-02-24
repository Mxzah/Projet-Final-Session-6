import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ComboItemsService, ComboItem } from '../services/combo-items.service';
import { CombosService, Combo } from '../services/combos.service';
import { ItemsService } from '../services/items.service';
import { Item } from '../menu/menu.models';
import { ErrorService } from '../services/error.service';
import { TranslationService } from '../services/translation.service';

@Component({
    selector: 'app-admin-combo-items',
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
        MatProgressSpinnerModule
    ],
    templateUrl: './admin-combo-items.component.html',
    styleUrls: ['./admin-combo-items.component.css']
})
export class AdminComboItemsComponent implements OnInit {
    comboItems = signal<ComboItem[]>([]);
    combos = signal<Combo[]>([]);
    items = signal<Item[]>([]);

    isLoading = signal(true);
    loadError = signal('');
    actionError = signal('');

    isCreating = signal(false);
    isSaving = signal(false);

    createForm = new FormGroup({
        combo_id: new FormControl<number | null>(null, [Validators.required]),
        item_id: new FormControl<number | null>(null, [Validators.required]),
        quantity: new FormControl<number | null>(1, [Validators.required, Validators.min(1)])
    });

    constructor(
        private comboItemsService: ComboItemsService,
        private combosService: CombosService,
        private itemsService: ItemsService,
        private errorService: ErrorService,
        public ts: TranslationService
    ) { }

    ngOnInit(): void {
        this.loadData();
    }

    private loadData(): void {
        this.isLoading.set(true);
        this.loadError.set('');

        let remaining = 3;
        const finish = () => {
            remaining -= 1;
            if (remaining === 0) {
                this.isLoading.set(false);
            }
        };

        this.comboItemsService.getComboItems().subscribe({
            next: (data) => {
                this.comboItems.set(data);
                finish();
            },
            error: (err) => {
                this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
                finish();
            }
        });

        this.combosService.getCombos().subscribe({
            next: (data) => {
                this.combos.set(data);
                finish();
            },
            error: (err) => {
                this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
                finish();
            }
        });

        this.itemsService.getItems({ admin: true }).subscribe({
            next: (data) => {
                this.items.set(data.filter(item => !item.deleted_at));
                finish();
            },
            error: (err) => {
                this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
                finish();
            }
        });
    }

    openCreate(): void {
        this.actionError.set('');
        this.isCreating.set(true);
        this.createForm.reset({
            combo_id: null,
            item_id: null,
            quantity: 1
        });
        this.createForm.markAsPristine();
        this.createForm.markAsUntouched();
    }

    cancelCreate(): void {
        this.isCreating.set(false);
        this.isSaving.set(false);
        this.actionError.set('');
    }

    saveCreate(): void {
        Object.values(this.createForm.controls).forEach(control => control.markAsDirty());
        if (this.createForm.invalid || this.isSaving()) return;

        const values = this.createForm.getRawValue();
        const combo_id = Number(values.combo_id);
        const item_id = Number(values.item_id);
        const quantity = Number(values.quantity);

        this.actionError.set('');
        this.isSaving.set(true);

        this.comboItemsService.createComboItem({ combo_id, item_id, quantity }).subscribe({
            next: (created) => {
                this.comboItems.update(list => [created, ...list]);
                this.isSaving.set(false);
                this.isCreating.set(false);
            },
            error: (err) => {
                this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.isSaving.set(false);
            }
        });
    }

    trackByComboItemId(_: number, comboItem: ComboItem): number {
        return comboItem.id;
    }
}
