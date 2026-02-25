import { Component, OnInit, OnDestroy, NgZone, ViewChild, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CombosService, Combo } from '../services/combos.service';
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
        MatProgressSpinnerModule,
        AvailabilityListComponent
    ],
    templateUrl: './admin-combos.component.html',
    styleUrls: ['./admin-combos.component.css']
})
export class AdminCombosComponent implements OnInit, OnDestroy {
    @ViewChild('createAvailList') createAvailList?: AvailabilityListComponent;

    combos = signal<Combo[]>([]);
    createAvailabilities = signal<AvailabilityEntry[]>([]);

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

    ngOnDestroy(): void {
        clearInterval(this.nowInterval);
    }
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
        this.createAvailabilities.set([]);
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
}
