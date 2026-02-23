import { Component, OnInit, signal, computed, ChangeDetectorRef, Renderer2 } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ItemsService } from '../services/items.service';
import { Item, Category } from '../menu/menu.models';
import { ApiService } from '../services/api.service';
import { TranslationService } from '../services/translation.service';

function notOnlyWhitespace(control: AbstractControl): ValidationErrors | null {
  if (control.value && /^\s*$/.test(control.value)) {
    return { whitespace: true };
  }
  return null;
}

@Component({
  selector: 'app-admin-items',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule,
    MatCardModule, MatButtonModule, MatIconModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './admin-items.component.html',
  styleUrls: ['./admin-items.component.css']
})
export class AdminItemsComponent implements OnInit {
  items = signal<Item[]>([]);
  isLoading = signal(true);
  categories = signal<Category[]>([]);

  // Suppression
  itemToDelete = signal<Item | null>(null);

  // Désarchivage
  itemToRestore = signal<Item | null>(null);

  // Création
  isCreating = signal(false);

  // Modification
  editingItem = signal<Item | null>(null);
  editForm = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(100), notOnlyWhitespace]),
    description: new FormControl('', [Validators.maxLength(255), notOnlyWhitespace]),
    price: new FormControl<number>(0, [Validators.required, Validators.min(0), Validators.max(9999.99)]),
    category_id: new FormControl<number>(0, [Validators.required])
  });
  editImage: File | null = null;
  editImagePreview = signal<string | null>(null);
  editImageError = signal('');
  editError = signal('');
  editLoading = signal(false);

  categoryNames = computed(() =>
    [...new Set(this.items().map(i => i.category_name ?? '—'))]
  );

  constructor(
    private itemsService: ItemsService,
    private apiService: ApiService,
    public ts: TranslationService,
    private cdr: ChangeDetectorRef,
    private renderer: Renderer2
  ) {}

  ngOnInit(): void {
    this.loadData();
    this.loadCategories();
  }

  loadData(): void {
    this.isLoading.set(true);
    this.itemsService.getItems().subscribe({
      next: (items) => {
        const sorted = [...items].sort((a, b) =>
          (a.category_name ?? '—').localeCompare(b.category_name ?? '—')
        );
        this.items.set(sorted);
        this.isLoading.set(false);

        // Fallback: if categories not loaded yet, extract from items
        if (this.categories().length === 0) {
          this.extractCategoriesFromItems(items);
        }
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  loadCategories(): void {
    this.apiService.get<Category[]>('/api/categories').subscribe({
      next: (response) => {
        if (response.data) {
          this.categories.set(response.data);
        }
      },
      error: () => {
        // Fallback: extract from items if already loaded
        if (this.items().length > 0) {
          this.extractCategoriesFromItems(this.items());
        }
      }
    });
  }

  private extractCategoriesFromItems(items: Item[]): void {
    const catMap = new Map<number, Category>();
    for (const item of items) {
      if (!catMap.has(item.category_id)) {
        catMap.set(item.category_id, {
          id: item.category_id,
          name: item.category_name ?? '—',
          position: catMap.size
        });
      }
    }
    this.categories.set([...catMap.values()]);
  }

  // ── Suppression ──

  confirmDelete(item: Item): void {
    this.itemToDelete.set(item);
  }

  cancelDelete(): void {
    this.itemToDelete.set(null);
  }

  deleteItem(): void {
    const item = this.itemToDelete();
    if (!item) return;

    if (item.in_use) {
      this.itemsService.softDeleteItem(item.id).subscribe({
        next: (response) => {
          if (response.data) {
            this.items.update(items => items.map(i => i.id === item.id ? response.data! : i));
          }
          this.itemToDelete.set(null);
        },
        error: () => {
          this.itemToDelete.set(null);
        }
      });
    } else {
      this.itemsService.hardDeleteItem(item.id).subscribe({
        next: () => {
          this.items.update(items => items.filter(i => i.id !== item.id));
          this.itemToDelete.set(null);
        },
        error: () => {
          this.itemToDelete.set(null);
        }
      });
    }
  }

  // ── Désarchivage ──

  confirmRestore(item: Item): void {
    this.itemToRestore.set(item);
  }

  cancelRestore(): void {
    this.itemToRestore.set(null);
  }

  restoreItem(): void {
    const item = this.itemToRestore();
    if (!item) return;

    this.itemsService.restoreItem(item.id).subscribe({
      next: (response) => {
        if (response.data) {
          this.items.update(items => items.map(i => i.id === item.id ? response.data! : i));
        }
        this.itemToRestore.set(null);
      },
      error: () => {
        this.itemToRestore.set(null);
      }
    });
  }

  // ── Création ──

  openCreate(): void {
    this.isCreating.set(true);
    this.renderer.setStyle(document.documentElement, 'overflow', 'hidden');
    this.editForm.reset({ name: '', description: '', price: 0, category_id: this.categories()[0]?.id ?? 0 });
    this.editForm.markAsPristine();
    this.editForm.markAsUntouched();
    this.editImage = null;
    this.editImagePreview.set(null);
    this.editImageError.set('');
    this.editError.set('');
  }

  saveCreate(): void {
    Object.values(this.editForm.controls).forEach(c => c.markAsDirty());
    if (!this.editImage && !this.editImageError()) {
      this.editImageError.set(this.ts.t('admin.imageRequired'));
    }
    if (this.editForm.invalid) return;
    if (this.editImageError()) return;

    this.editLoading.set(true);
    this.editError.set('');

    const v = this.editForm.value;
    const createData: { name: string; description?: string; price: number; category_id: number; image?: File } = {
      name: v.name!,
      description: v.description ?? '',
      price: v.price!,
      category_id: v.category_id!
    };
    if (this.editImage) {
      createData.image = this.editImage;
    }
    this.itemsService.createItem(createData).subscribe({
      next: (created) => {
        this.items.update(items => [...items, created]);
        this.isCreating.set(false);
        this.editLoading.set(false);
        this.renderer.removeStyle(document.documentElement, 'overflow');
      },
      error: (err: any) => {
        this.editError.set(err?.errors?.join(', ') || this.ts.t('admin.createError'));
        this.editLoading.set(false);
        this.cdr.detectChanges();
      }
    });
  }

  // ── Modification ──

  openEdit(item: Item): void {
    this.editingItem.set(item);
    this.renderer.setStyle(document.documentElement, 'overflow', 'hidden');
    this.editForm.patchValue({
      name: item.name,
      description: item.description,
      price: item.price,
      category_id: item.category_id
    });
    this.editForm.markAsPristine();
    this.editForm.markAsUntouched();
    this.editImage = null;
    this.editImagePreview.set(item.image_url || null);
    this.editImageError.set('');
    this.editError.set('');
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const validTypes = ['image/jpeg', 'image/png'];
    if (!validTypes.includes(file.type)) {
      this.editImageError.set(this.ts.t('admin.imageFormat'));
      input.value = '';
      return;
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      this.editImageError.set(this.ts.t('admin.imageSize'));
      input.value = '';
      return;
    }

    this.editImageError.set('');
    this.editImage = file;

    const reader = new FileReader();
    reader.onload = () => this.editImagePreview.set(reader.result as string);
    reader.readAsDataURL(file);
  }

  cancelEdit(): void {
    this.editingItem.set(null);
    this.isCreating.set(false);
    this.editError.set('');
    this.renderer.removeStyle(document.documentElement, 'overflow');
  }

  saveEdit(): void {
    const item = this.editingItem();
    if (!item) return;

    Object.values(this.editForm.controls).forEach(c => c.markAsDirty());
    if (this.editForm.invalid) return;

    this.editLoading.set(true);
    this.editError.set('');

    if (this.editImageError()) return;

    const v = this.editForm.value;
    const updateData: { name: string; description: string; price: number; category_id: number; image?: File } = {
      name: v.name!,
      description: v.description ?? '',
      price: v.price!,
      category_id: v.category_id!
    };
    if (this.editImage) {
      updateData.image = this.editImage;
    }
    this.itemsService.updateItem(item.id, updateData).subscribe({
      next: (updated) => {
        this.items.update(items =>
          items.map(i => i.id === item.id ? updated : i)
        );
        this.editingItem.set(null);
        this.editLoading.set(false);
        this.renderer.removeStyle(document.documentElement, 'overflow');
      },
      error: (err: any) => {
        this.editError.set(err?.errors?.join(', ') || this.ts.t('admin.editError'));
        this.editLoading.set(false);
        this.cdr.detectChanges();
      }
    });
  }

  getItemsByCategory(categoryName: string): Item[] {
    return this.items().filter(i => (i.category_name ?? '—') === categoryName);
  }
}
