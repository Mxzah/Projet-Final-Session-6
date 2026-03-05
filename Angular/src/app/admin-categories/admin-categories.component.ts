import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CdkDragDrop, DragDropModule, moveItemInArray } from '@angular/cdk/drag-drop';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { CategoriesService } from '../services/categories.service';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { Category } from '../menu/menu.models';
import { CategoryFormDialogComponent, CategoryFormDialogData, CategoryFormDialogResult } from './category-form-dialog/category-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';

@Component({
  selector: 'app-admin-categories',
  standalone: true,
  imports: [
    CommonModule,
    DragDropModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatDialogModule
  ],
  templateUrl: './admin-categories.component.html',
  styleUrls: ['./admin-categories.component.css']
})
export class AdminCategoriesComponent implements OnInit {
  categories = signal<Category[]>([]);
  isLoading = signal(true);
  loadError = signal('');
  actionError = signal('');

  unavailableIds = computed(() => {
    const now = Date.now();
    return new Set(
      this.categories()
        .filter(cat => {
          if (!cat.availabilities || cat.availabilities.length === 0) return true;
          return !cat.availabilities.some(a => {
            const start = new Date(a.start_at).getTime();
            const end = a.end_at ? new Date(a.end_at).getTime() : Infinity;
            return start <= now && now < end;
          });
        })
        .map(cat => cat.id)
    );
  });

  constructor(
    private categoriesService: CategoriesService,
    public ts: TranslationService,
    private errorService: ErrorService,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading.set(true);
    this.loadError.set('');
    this.categoriesService.getCategories().subscribe({
      next: (response) => {
        if (response.data) {
          this.categories.set(response.data);
        }
        this.isLoading.set(false);
      },
      error: (err) => {
        this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.isLoading.set(false);
      }
    });
  }

  drop(event: CdkDragDrop<Category[]>): void {
    if (event.previousIndex === event.currentIndex) return;

    const list = [...this.categories()];
    moveItemInArray(list, event.previousIndex, event.currentIndex);
    this.categories.set(list);

    const ids = list.map(c => c.id);
    this.actionError.set('');
    this.categoriesService.reorder(ids).subscribe({
      next: (res) => {
        if (res.data) {
          this.categories.set(res.data);
        }
      },
      error: (err) => {
        this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.loadData();
      }
    });
  }

  openCreate(): void {
    const nextPosition = this.categories().length > 0
      ? Math.max(...this.categories().map(c => c.position)) + 1
      : 0;

    const data: CategoryFormDialogData = { category: null, nextPosition };
    const ref = this.dialog.open<CategoryFormDialogComponent, CategoryFormDialogData, CategoryFormDialogResult>(
      CategoryFormDialogComponent,
      { data, width: '480px', maxWidth: '95vw', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe({
      next: (result) => {
        if (result?.categories) {
          this.categories.set(result.categories);
        }
      }
    });
  }

  openEdit(category: Category): void {
    const data: CategoryFormDialogData = { category, nextPosition: category.position };
    const ref = this.dialog.open<CategoryFormDialogComponent, CategoryFormDialogData, CategoryFormDialogResult>(
      CategoryFormDialogComponent,
      { data, width: '480px', maxWidth: '95vw', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe({
      next: (result) => {
        if (result?.categories) {
          this.categories.set(result.categories);
        }
      }
    });
  }

  confirmDelete(category: Category): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('admin.deleteCategory'),
      message: this.ts.t('admin.deleteCategoryConfirm'),
      itemName: category.name,
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };

    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );

    ref.afterClosed().subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.actionError.set('');
        this.categoriesService.deleteCategory(category.id).subscribe({
          next: () => {
            this.categories.update(cats => cats.filter(c => c.id !== category.id));
          },
          error: (err) => {
            this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
          }
        });
      }
    });
  }
}
