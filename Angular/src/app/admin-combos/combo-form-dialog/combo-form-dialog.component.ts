import { Component, Inject, signal, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CombosService, Combo } from '../../services/combos.service';
import { AvailabilityService } from '../../services/availability.service';
import { AvailabilityEntry } from '../../menu/menu.models';
import { AvailabilityListComponent } from '../../shared/availability-list/availability-list.component';
import { ImageUploadComponent, ImageValidationResult } from '../../shared/image-upload/image-upload.component';
import { TranslationService } from '../../services/translation.service';
import { ErrorService } from '../../services/error.service';

export interface ComboFormDialogData {
    combo: null; // null = création (pas d'édition pour l'instant)
}

export interface ComboFormDialogResult {
    created?: Combo;
}

@Component({
    selector: 'app-combo-form-dialog',
    standalone: true,
    imports: [
        CommonModule,
        ReactiveFormsModule,
        MatDialogModule,
        MatButtonModule,
        MatIconModule,
        MatFormFieldModule,
        MatInputModule,
        MatProgressSpinnerModule,
        AvailabilityListComponent,
        ImageUploadComponent
    ],
    templateUrl: './combo-form-dialog.component.html',
    styleUrls: ['./combo-form-dialog.component.css']
})
export class ComboFormDialogComponent {
    @ViewChild(AvailabilityListComponent) availabilityList?: AvailabilityListComponent;

    form = new FormGroup({
        name: new FormControl('', [Validators.required, Validators.maxLength(100), Validators.pattern(/.*\S.*/)]),
        description: new FormControl('', [Validators.maxLength(255)]),
        price: new FormControl<number | null>(null, [Validators.required, Validators.min(0.01), Validators.max(9999.99)])
    });

    image = signal<File | null>(null);
    imagePreviews = signal<string[]>([]);
    availabilities = signal<AvailabilityEntry[]>([]);
    error = signal('');
    loading = signal(false);

    constructor(
        private dialogRef: MatDialogRef<ComboFormDialogComponent, ComboFormDialogResult>,
        @Inject(MAT_DIALOG_DATA) public data: ComboFormDialogData,
        private combosService: CombosService,
        private availabilityService: AvailabilityService,
        public ts: TranslationService,
        private errorService: ErrorService
    ) { }

    onImagesSelected(results: ImageValidationResult[]): void {
        this.image.set(results[0].file);
        this.imagePreviews.set([results[0].preview]);
    }

    clampPrice(event: Event): void {
        const input = event.target as HTMLInputElement;
        const value = parseFloat(input.value);
        if (value > 9999.99) {
            input.value = '9999.99';
            this.form.controls.price.setValue(9999.99);
        } else if (value < 0) {
            input.value = '0';
            this.form.controls.price.setValue(0);
        }
    }

    save(): void {
        Object.values(this.form.controls).forEach(c => c.markAsDirty());
        if (this.form.invalid || this.loading()) return;

        const values = this.form.getRawValue();
        const name = values.name?.trim() ?? '';
        const description = values.description?.trim() ?? '';
        const price = Number(values.price);

        this.error.set('');
        this.loading.set(true);

        const payload: { name: string; description?: string; price: number; image?: File } = { name, description, price };
        const img = this.image();
        if (img) payload.image = img;

        this.combosService.createCombo(payload).subscribe({
            next: (created) => {
                this.availabilityService.syncAvailabilities(
                    this.availabilities(), [],
                    (e) => this.availabilityService.createAvailability('combos', created.id, e),
                    (id, e) => this.availabilityService.updateAvailability('combos', created.id, id, e),
                    (id) => this.availabilityService.deleteAvailability('combos', created.id, id)
                ).subscribe({
                    next: () => {
                        this.loading.set(false);
                        this.dialogRef.close({ created });
                    },
                    error: () => {
                        this.loading.set(false);
                        this.dialogRef.close({ created });
                    }
                });
            },
            error: (err) => {
                this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
                this.loading.set(false);
            }
        });
    }
}
