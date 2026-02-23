import { Component, OnInit, OnDestroy, signal, computed, Renderer2 } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatBadgeModule } from '@angular/material/badge';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDividerModule } from '@angular/material/divider';
import { MatCardModule } from '@angular/material/card';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatChipsModule } from '@angular/material/chips';
import { MatSliderModule } from '@angular/material/slider';
import { ItemsService } from '../services/items.service';
import { AuthService } from '../services/auth.service';
import { CartService, CartLine } from '../services/cart.service';
import { TableService } from '../services/table.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';
import { Item, Category } from './menu.models';

@Component({
  selector: 'app-menu',
  standalone: true,
  imports: [
    CommonModule, FormsModule, HeaderComponent,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatButtonModule, MatIconModule, MatBadgeModule,
    MatProgressSpinnerModule, MatDividerModule,
    MatCardModule, MatToolbarModule, MatListModule, MatChipsModule, MatSliderModule,
    ReactiveFormsModule
  ],
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit, OnDestroy {
  categories = signal<Category[]>([]);
  allItems = signal<Item[]>([]);
  activeCategory = signal<number>(0);
  isLoading = signal<boolean>(true);
  errorMessage = signal<string>('');

  searchQuery = signal<string>('');
  sortOrder = signal<string>('none');
  priceMin = signal<number | null>(null);
  priceMax = signal<number | null>(null);
  sliderMin = signal<number>(0);
  sliderMax = signal<number>(9999);

  // Cart sidebar
  cartOpen = signal<boolean>(false);

  // Modal
  selectedItem = signal<Item | null>(null);
  modalQuantity = signal<number>(1);
  modalNote = signal<string>('');

  // Edit cart line modal
  editingCartIndex = signal<number | null>(null);
  editingCartLine = signal<CartLine | null>(null);
  editCartForm = new FormGroup({
    quantity: new FormControl<number>(1, [Validators.required, Validators.min(1), Validators.max(50)]),
    note: new FormControl('', [Validators.maxLength(255)])
  });
  editCartError = signal('');

  // Delete cart line modal
  deletingCartIndex = signal<number | null>(null);
  deletingCartLine = signal<CartLine | null>(null);

  private searchTimer: any = null;

  itemsByCategory = computed(() => {
    return this.categories().map(cat => {
      const items = this.allItems().filter(item => item.category_id === cat.id);
      return { ...cat, items };
    });
  });

  modalTotal = computed(() => {
    const item = this.selectedItem();
    if (!item) return 0;
    return item.price * this.modalQuantity();
  });

  constructor(
    private itemsService: ItemsService,
    public authService: AuthService,
    public cartService: CartService,
    private tableService: TableService,
    public ts: TranslationService,
    private router: Router,
    private renderer: Renderer2
  ) {}

  ngOnInit(): void {
    this.loadItems(true);
  }

  ngOnDestroy(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer);
  }

  loadItems(showLoading = false): void {
    if (showLoading) this.isLoading.set(true);
    this.itemsService.getItems({
      search: this.searchQuery(),
      sort: this.sortOrder(),
      price_min: this.priceMin(),
      price_max: this.priceMax()
    }).subscribe({
      next: (items: Item[]) => {
        this.allItems.set(items);
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
        const sorted = [...catMap.values()].sort((a, b) => a.position - b.position);
        this.categories.set(sorted);
        if (sorted.length > 0 && !sorted.find(c => c.id === this.activeCategory())) {
          this.activeCategory.set(sorted[0].id);
        }
        this.isLoading.set(false);
      },
      error: (err: any) => {
        this.errorMessage.set(
          err.errors?.join(', ') || this.ts.t('menu.loadError')
        );
        this.isLoading.set(false);
      }
    });
  }

  onSearchInput(event: Event): void {
    this.searchQuery.set((event.target as HTMLInputElement).value);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.loadItems(), 300);
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadItems();
  }

  onSliderMinChange(value: number): void {
    this.sliderMin.set(value);
    this.priceMin.set(value > 0 ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.loadItems(), 300);
  }

  onSliderMaxChange(value: number): void {
    this.sliderMax.set(value);
    this.priceMax.set(value < 9999 ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.loadItems(), 300);
  }

  onMobileCategoryChange(value: number): void {
    this.selectCategory(value);
  }

  selectCategory(id: number): void {
    this.activeCategory.set(id);
    const el = document.getElementById('category-' + id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  openItemModal(item: Item): void {
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/login']);
      return;
    }
    if (!this.tableService.hasTable()) {
      this.router.navigate(['/form']);
      return;
    }
    this.selectedItem.set(item);
    this.modalQuantity.set(1);
    this.modalNote.set('');
    this.renderer.setStyle(document.documentElement, 'overflow', 'hidden');
  }

  closeModal(): void {
    this.selectedItem.set(null);
    this.renderer.removeStyle(document.documentElement, 'overflow');
  }

  onOverlayClick(event: MouseEvent): void {
    if ((event.target as HTMLElement).classList.contains('modal-overlay')) {
      this.closeModal();
    }
  }

  decrementQuantity(): void {
    if (this.modalQuantity() > 1) {
      this.modalQuantity.set(this.modalQuantity() - 1);
    }
  }

  incrementQuantity(): void {
    if (this.modalQuantity() < 50) {
      this.modalQuantity.set(this.modalQuantity() + 1);
    }
  }

  onNoteInput(event: Event): void {
    this.modalNote.set((event.target as HTMLTextAreaElement).value);
  }

  addToCart(): void {
    const item = this.selectedItem();
    if (!item) return;
    this.cartService.addLine({
      orderable_type: 'Item',
      orderable_id: item.id,
      name: item.name,
      description: item.description,
      unit_price: item.price,
      quantity: this.modalQuantity(),
      note: this.modalNote(),
      image_url: item.image_url || null
    });
    this.closeModal();
  }

  toggleCart(): void {
    this.cartOpen.set(!this.cartOpen());
  }

  goToOrder(): void {
    this.router.navigate(['/order']);
  }

  canOrder(): boolean {
    return this.authService.isAuthenticated() && this.tableService.hasTable();
  }

  onAddToCart(item: Item): void {
    this.openItemModal(item);
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  // ── Edit cart line ──

  openEditCartLine(index: number): void {
    const line = this.cartService.lines()[index];
    if (!line) return;
    this.editingCartIndex.set(index);
    this.editingCartLine.set(line);
    this.editCartForm.patchValue({ quantity: line.quantity, note: line.note || '' });
    this.editCartForm.markAsPristine();
    this.editCartForm.markAsUntouched();
    this.editCartError.set('');
  }

  cancelEditCartLine(): void {
    this.editingCartIndex.set(null);
    this.editingCartLine.set(null);
    this.editCartError.set('');
  }

  saveEditCartLine(): void {
    const index = this.editingCartIndex();
    if (index === null) return;
    Object.values(this.editCartForm.controls).forEach(c => c.markAsDirty());
    if (this.editCartForm.invalid) return;
    const v = this.editCartForm.value;
    this.cartService.updateLine(index, { quantity: v.quantity!, note: v.note ?? '' });
    this.editingCartIndex.set(null);
    this.editingCartLine.set(null);
  }

  // ── Delete cart line ──

  openDeleteCartLine(index: number): void {
    const line = this.cartService.lines()[index];
    if (!line) return;
    this.deletingCartIndex.set(index);
    this.deletingCartLine.set(line);
  }

  cancelDeleteCartLine(): void {
    this.deletingCartIndex.set(null);
    this.deletingCartLine.set(null);
  }

  confirmDeleteCartLine(): void {
    const index = this.deletingCartIndex();
    if (index === null) return;
    this.cartService.removeLine(index);
    this.deletingCartIndex.set(null);
    this.deletingCartLine.set(null);
  }

  logout(): void {
    this.cartService.clear();
    this.authService.logout().subscribe({
      next: (response) => {
        if (response.success) {
          this.router.navigate(['/login']);
        }
      },
      error: () => {
        localStorage.removeItem('currentUser');
        this.router.navigate(['/login']);
      }
    });
  }
}
