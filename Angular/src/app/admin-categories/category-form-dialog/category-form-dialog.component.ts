import { Component, inject, signal, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CategoriesService } from '../../services/categories.service';
import { TranslationService } from '../../services/translation.service';
import { ErrorService } from '../../services/error.service';
import { AvailabilityService } from '../../services/availability.service';
import { AvailabilityListComponent } from '../../shared/availability-list/availability-list.component';
import { Category, AvailabilityEntry } from '../../menu/menu.models';

export interface CategoryFormDialogData {
  category: Category | null;
  nextPosition: number;
}

export interface CategoryFormDialogResult {
  categories: Category[];
}

@Component({
  selector: 'app-category-form-dialog',
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
    AvailabilityListComponent
  ],
  templateUrl: './category-form-dialog.component.html',
  styleUrls: ['./category-form-dialog.component.css']
})
export class CategoryFormDialogComponent {
  private dialogRef = inject(MatDialogRef<CategoryFormDialogComponent, CategoryFormDialogResult>);
  data = inject<CategoryFormDialogData>(MAT_DIALOG_DATA);
  private categoriesService = inject(CategoriesService);
  ts = inject(TranslationService);
  private errorService = inject(ErrorService);
  private availabilityService = inject(AvailabilityService);

  isCreating: boolean;

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(100), Validators.pattern(/.*\S.*/)])
  });

  error = signal('');
  loading = signal(false);

  @ViewChild(AvailabilityListComponent) availabilityList?: AvailabilityListComponent;
  availabilities = signal<AvailabilityEntry[]>([]);
  private originalAvailabilities: AvailabilityEntry[] = [];

  constructor() {
    const data = this.data;
    this.isCreating = data.category === null;

    if (data.category) {
      this.form.patchValue({
        name: data.category.name
      });

      this.availabilityService.getAvailabilities('categories', data.category.id).subscribe({
        next: (entries) => {
          this.originalAvailabilities = entries;
          this.availabilities.set(entries);
        }
      });
    } else {
      this.form.reset({
        name: ''
      });
    }
  }

  save(): void {
    Object.values(this.form.controls).forEach(c => c.markAsDirty());
    this.availabilityList?.markAllDirty();

    if (this.form.invalid || !(this.availabilityList?.isValid ?? true)) return;

    this.loading.set(true);
    this.error.set('');

    const request$ = this.isCreating
      ? this.categoriesService.createCategory({ name: this.form.value.name!, position: this.data.nextPosition })
      : this.categoriesService.updateCategory(this.data.category!.id, { name: this.form.value.name! });

    request$.subscribe({
      next: (res) => {
        if (res.data) {
          const categoryId = this.isCreating
            ? res.data[res.data.length - 1].id
            : this.data.category!.id;

          this.syncAvailabilities(categoryId).subscribe({
            next: () => {
              this.categoriesService.getCategories().subscribe({
                next: (refreshed) => {
                  this.loading.set(false);
                  this.dialogRef.close({ categories: refreshed.data ?? res.data! });
                },
                error: () => {
                  this.loading.set(false);
                  this.dialogRef.close({ categories: res.data! });
                }
              });
            },
            error: (err) => {
              this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
              this.loading.set(false);
            }
          });
        } else {
          const msg = (res.errors ?? []).join(', ');
          this.form.controls.name.setErrors({ serverError: msg });
          this.form.controls.name.markAsDirty();
          this.loading.set(false);
        }
      },
      error: (err) => {
        const msg = this.errorService.format(this.errorService.fromApiError(err));
        this.form.controls.name.setErrors({ serverError: msg });
        this.form.controls.name.markAsDirty();
        this.loading.set(false);
      }
    });
  }

  private syncAvailabilities(categoryId: number) {
    return this.availabilityService.syncAvailabilities(
      this.availabilities(), this.originalAvailabilities,
      entry => this.availabilityService.createAvailability('categories', categoryId, entry),
      (id, entry) => this.availabilityService.updateAvailability('categories', categoryId, id, entry),
      id => this.availabilityService.deleteAvailability('categories', categoryId, id)
    );
  }
}
