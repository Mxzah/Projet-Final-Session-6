import { Component, Inject, signal } from '@angular/core';
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
import { Category } from '../../menu/menu.models';

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
    MatProgressSpinnerModule
  ],
  templateUrl: './category-form-dialog.component.html',
  styleUrls: ['./category-form-dialog.component.css']
})
export class CategoryFormDialogComponent {
  isCreating: boolean;

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(100), Validators.pattern(/.*\S.*/)])
  });

  error = signal('');
  loading = signal(false);

  constructor(
    private dialogRef: MatDialogRef<CategoryFormDialogComponent, CategoryFormDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: CategoryFormDialogData,
    private categoriesService: CategoriesService,
    public ts: TranslationService,
    private errorService: ErrorService
  ) {
    this.isCreating = data.category === null;

    if (data.category) {
      this.form.patchValue({
        name: data.category.name
      });
    } else {
      this.form.reset({
        name: ''
      });
    }
  }

  save(): void {
    Object.values(this.form.controls).forEach(c => c.markAsDirty());
    if (this.form.invalid) return;

    this.loading.set(true);
    this.error.set('');

    const request$ = this.isCreating
      ? this.categoriesService.createCategory({ name: this.form.value.name!, position: this.data.nextPosition })
      : this.categoriesService.updateCategory(this.data.category!.id, { name: this.form.value.name! });

    request$.subscribe({
      next: (res) => {
        this.loading.set(false);
        if (res.data) {
          this.dialogRef.close({ categories: res.data });
        } else {
          this.error.set((res.errors ?? []).join(', '));
        }
      },
      error: (err) => {
        this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.loading.set(false);
      }
    });
  }
}
