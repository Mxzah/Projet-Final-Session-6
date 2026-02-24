import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CombosService, Combo } from '../services/combos.service';
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
        MatProgressSpinnerModule
    ],
    templateUrl: './admin-combos.component.html',
    styleUrls: ['./admin-combos.component.css']
})
export class AdminCombosComponent implements OnInit {
    combos = signal<Combo[]>([]);
    isLoading = signal(true);
    loadError = signal('');
    actionError = signal('');

    isCreating = signal(false);
    isSaving = signal(false);

    createForm = new FormGroup({
        name: new FormControl('', [Validators.required, Validators.maxLength(100), notOnlyWhitespace]),
        description: new FormControl('', [Validators.maxLength(500)]),
        price: new FormControl<number | null>(null, [Validators.required, Validators.min(0.01)])
    });

    constructor(
        private combosService: CombosService,
        private errorService: ErrorService,
        public ts: TranslationService
    ) { }

    ngOnInit(): void {
        this.loadCombos();
    }

    loadCombos(): void {
        this.isLoading.set(true);
        this.loadError.set('');

        this.combosService.getCombos().subscribe({
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

    openCreate(): void {
        this.actionError.set('');
        this.isCreating.set(true);
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

        this.combosService.createCombo({ name, description, price }).subscribe({
            next: (created) => {
                this.combos.update(list => [created, ...list]);
                this.isSaving.set(false);
                this.isCreating.set(false);
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
}
