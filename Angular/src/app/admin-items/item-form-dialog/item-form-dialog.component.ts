import { Component, Inject, signal, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ItemsService } from '../../services/items.service';
import { Item, Category, AvailabilityEntry } from '../../menu/menu.models';
import { TranslationService } from '../../services/translation.service';
import { ErrorService } from '../../services/error.service';
import { AvailabilityService } from '../../services/availability.service';
import { AvailabilityListComponent } from '../../shared/availability-list/availability-list.component';
import { ImageUploadComponent, ImageValidationResult } from '../../shared/image-upload/image-upload.component';

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
    MatProgressSpinnerModule,
    AvailabilityListComponent,
    ImageUploadComponent
  ],
  templateUrl: './item-form-dialog.component.html',
  styleUrls: ['./item-form-dialog.component.css']
})
export class ItemFormDialogComponent {
  isCreating: boolean;
  categories: Category[];

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(100), Validators.pattern(/.*\S.*/)]),
    description: new FormControl('', [Validators.maxLength(255)]),
    price: new FormControl<number>(0, [Validators.required, Validators.min(0), Validators.max(9999.99)]),
    category_id: new FormControl<number>(0, [Validators.required])
  });

  image: File | null = null;
  imagePreviews = signal<string[]>([]);
  error = signal('');
  loading = signal(false);

  @ViewChild(AvailabilityListComponent) availabilityList?: AvailabilityListComponent;
  @ViewChild(ImageUploadComponent) imageUpload?: ImageUploadComponent;

  availabilities = signal<AvailabilityEntry[]>([]);
  private originalAvailabilities: AvailabilityEntry[] = [];

  constructor(
    private dialogRef: MatDialogRef<ItemFormDialogComponent, ItemFormDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: ItemFormDialogData,
    private itemsService: ItemsService,
    public ts: TranslationService,
    private errorService: ErrorService,
    private availabilityService: AvailabilityService
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
      if (data.item.image_url) {
        this.imagePreviews.set([data.item.image_url]);
      }

      this.availabilityService.getAvailabilities('items', data.item.id).subscribe({
        next: (entries) => {
          this.originalAvailabilities = entries;
          this.availabilities.set(entries);
        }
      });
    } else {
      this.form.reset({
        name: '',
        description: '',
        price: 0,
        category_id: data.categories[0]?.id ?? 0
      });
    }
  }

  onImagesSelected(results: ImageValidationResult[]): void {
    this.image = results[0].file;
    this.imagePreviews.set([results[0].preview]);
  }

  save(): void {
    Object.values(this.form.controls).forEach(c => c.markAsDirty());
    this.availabilityList?.markAllDirty();

    if (this.isCreating && !this.image && !this.imageUpload?.hasError()) {
      this.imageUpload?.setError(this.errorService.format(this.errorService.imageError('required', this.ts)));
    }

    if (this.form.invalid || this.imageUpload?.hasError() || !(this.availabilityList?.isValid ?? true)) return;

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
          this.syncAvailabilities(created.id).subscribe({
            next: () => {
              this.itemsService.getItem(created.id).subscribe({
                next: (fresh) => {
                  this.loading.set(false);
                  this.dialogRef.close({ created: fresh });
                },
                error: () => {
                  this.loading.set(false);
                  this.dialogRef.close({ created });
                }
              });
            },
            error: (err: any) => {
              this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
              this.loading.set(false);
            }
          });
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
          this.syncAvailabilities(updated.id).subscribe({
            next: () => {
              this.itemsService.getItem(updated.id).subscribe({
                next: (fresh) => {
                  this.loading.set(false);
                  this.dialogRef.close({ updated: fresh });
                },
                error: () => {
                  this.loading.set(false);
                  this.dialogRef.close({ updated });
                }
              });
            },
            error: (err: any) => {
              this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
              this.loading.set(false);
            }
          });
        },
        error: (err: any) => {
          this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.loading.set(false);
        }
      });
    }
  }

  private syncAvailabilities(itemId: number) {
    return this.availabilityService.syncAvailabilities(
      this.availabilities(), this.originalAvailabilities,
      entry => this.availabilityService.createAvailability('items', itemId, entry),
      (id, entry) => this.availabilityService.updateAvailability('items', itemId, id, entry),
      id => this.availabilityService.deleteAvailability('items', itemId, id)
    );
  }
}
