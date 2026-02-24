import { Component, Inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ItemsService } from '../services/items.service';
import { Item, Category } from '../menu/menu.models';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';

export interface ItemFormDialogData {
  item: Item | null;       // null = création, Item = modification
  categories: Category[];
}

export interface ItemFormDialogResult {
  created?: Item;
  updated?: Item;
}


@Component({
  selector: 'app-item-form-dialog',
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
  templateUrl: './item-form-dialog.component.html',
  styleUrls: ['./item-form-dialog.component.css']
})
export class ItemFormDialogComponent {
  isCreating: boolean;
  categories: Category[];

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(100), Validators.pattern(/.*\S.*/)]),
    description: new FormControl('', [Validators.maxLength(255), Validators.pattern(/.*\S.*/)]),
    price: new FormControl<number>(0, [Validators.required, Validators.min(0), Validators.max(9999.99)]),
    category_id: new FormControl<number>(0, [Validators.required])
  });

  image: File | null = null;
  imagePreview = signal<string | null>(null);
  imageError = signal('');
  error = signal('');
  loading = signal(false);

  constructor(
    private dialogRef: MatDialogRef<ItemFormDialogComponent, ItemFormDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: ItemFormDialogData,
    private itemsService: ItemsService,
    public ts: TranslationService,
    private errorService: ErrorService
  ) {
    this.isCreating = data.item === null;
    this.categories = data.categories;

    if (data.item) {
      this.form.patchValue({
        name: data.item.name,
        description: data.item.description,
        price: data.item.price,
        category_id: data.item.category_id
      });
      this.imagePreview.set(data.item.image_url || null);
    } else {
      this.form.reset({
        name: '',
        description: '',
        price: 0,
        category_id: data.categories[0]?.id ?? 0
      });
    }
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const validTypes = ['image/jpeg', 'image/png'];
    if (!validTypes.includes(file.type)) {
      this.imageError.set(this.errorService.format(this.errorService.imageError('format', this.ts)));
      input.value = '';
      return;
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      this.imageError.set(this.errorService.format(this.errorService.imageError('size', this.ts)));
      input.value = '';
      return;
    }

    this.imageError.set('');
    this.image = file;

    const reader = new FileReader();
    reader.onload = () => this.imagePreview.set(reader.result as string);
    reader.readAsDataURL(file);
  }

  save(): void {
    Object.values(this.form.controls).forEach(c => c.markAsDirty());

    if (this.isCreating && !this.image && !this.imageError()) {
      this.imageError.set(this.errorService.format(this.errorService.imageError('required', this.ts)));
    }

    if (this.form.invalid || this.imageError()) return;

    this.loading.set(true);
    this.error.set('');

    const v = this.form.value;

    if (this.isCreating) {
      const createData: { name: string; description?: string; price: number; category_id: number; image?: File } = {
        name: v.name!,
        description: v.description ?? '',
        price: v.price!,
        category_id: v.category_id!
      };
      if (this.image) createData.image = this.image;

      this.itemsService.createItem(createData).subscribe({
        next: (created) => {
          this.loading.set(false);
          this.dialogRef.close({ created });
        },
        error: (err: any) => {
          this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.loading.set(false);
        }
      });
    } else {
      const updateData: { name: string; description: string; price: number; category_id: number; image?: File } = {
        name: v.name!,
        description: v.description ?? '',
        price: v.price!,
        category_id: v.category_id!
      };
      if (this.image) updateData.image = this.image;

      this.itemsService.updateItem(this.data.item!.id, updateData).subscribe({
        next: (updated) => {
          this.loading.set(false);
          this.dialogRef.close({ updated });
        },
        error: (err: any) => {
          this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.loading.set(false);
        }
      });
    }
  }
}
