import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ItemsService } from '../services/items.service';
import { Item, Category } from '../menu/menu.models';
import { ApiService } from '../services/api.service';
import { TranslationService } from '../services/translation.service';
import { ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult } from './item-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from './confirm-dialog.component';

@Component({
  selector: 'app-admin-items',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatCardModule, MatButtonModule, MatIconModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './admin-items.component.html',
  styleUrls: ['./admin-items.component.css']
})
export class AdminItemsComponent implements OnInit {
  items = signal<Item[]>([]);
  isLoading = signal(true);
  categories = signal<Category[]>([]);

  categoryNames = computed(() =>
    [...new Set(this.items().map(i => i.category_name ?? '—'))]
  );

  constructor(
    private itemsService: ItemsService,
    private apiService: ApiService,
    public ts: TranslationService,
    private dialog: MatDialog
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

  // ── Création ──

  openCreate(): void {
    const data: ItemFormDialogData = { item: null, categories: this.categories() };
    const ref = this.dialog.open<ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult>(
      ItemFormDialogComponent,
      { data, width: '460px', maxHeight: '90vh', disableClose: false }
    );
    ref.afterClosed().subscribe(result => {
      if (result?.created) {
        this.items.update(items => [...items, result.created!]);
      }
    });
  }

  // ── Modification ──

  openEdit(item: Item): void {
    const data: ItemFormDialogData = { item, categories: this.categories() };
    const ref = this.dialog.open<ItemFormDialogComponent, ItemFormDialogData, ItemFormDialogResult>(
      ItemFormDialogComponent,
      { data, width: '460px', maxHeight: '90vh', disableClose: false }
    );
    ref.afterClosed().subscribe(result => {
      if (result?.updated) {
        this.items.update(items =>
          items.map(i => i.id === item.id ? result.updated! : i)
        );
      }
    });
  }

  // ── Suppression / Archivage ──

  confirmDelete(item: Item): void {
    const data: ConfirmDialogData = item.in_use
      ? {
          title: this.ts.t('admin.archiveItem'),
          message: this.ts.t('admin.archiveConfirm'),
          itemName: item.name,
          warning: this.ts.t('admin.archiveWarning'),
          confirmLabel: this.ts.t('admin.archive'),
          confirmClass: 'btn-danger'
        }
      : {
          title: this.ts.t('admin.deleteItem'),
          message: this.ts.t('admin.deleteConfirm'),
          itemName: item.name,
          confirmLabel: this.ts.t('admin.delete'),
          confirmClass: 'btn-danger'
        };

    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );

    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      if (item.in_use) {
        this.itemsService.softDeleteItem(item.id).subscribe({
          next: (response) => {
            if (response.data) {
              this.items.update(items => items.map(i => i.id === item.id ? response.data! : i));
            }
          }
        });
      } else {
        this.itemsService.hardDeleteItem(item.id).subscribe({
          next: () => {
            this.items.update(items => items.filter(i => i.id !== item.id));
          }
        });
      }
    });
  }

  // ── Désarchivage ──

  confirmRestore(item: Item): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('admin.restoreItem'),
      message: this.ts.t('admin.restoreConfirm'),
      itemName: item.name,
      confirmLabel: this.ts.t('admin.restoreBtn'),
      confirmClass: 'btn-restore'
    };

    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );

    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.itemsService.restoreItem(item.id).subscribe({
        next: (response) => {
          if (response.data) {
            this.items.update(items => items.map(i => i.id === item.id ? response.data! : i));
          }
        }
      });
    });
  }

  getItemsByCategory(categoryName: string): Item[] {
    return this.items().filter(i => (i.category_name ?? '—') === categoryName);
  }
}
