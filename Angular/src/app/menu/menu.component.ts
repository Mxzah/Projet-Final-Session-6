import { Component, OnInit, OnDestroy, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
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
import { ItemsService } from '../services/items.service';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';
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
    MatCardModule, MatToolbarModule, MatListModule, MatChipsModule
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

  // Cart sidebar
  cartOpen = signal<boolean>(false);

  // Modal
  selectedItem = signal<Item | null>(null);
  modalQuantity = signal<number>(1);
  modalNote = signal<string>('');

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
    private router: Router
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
          err.errors?.join(', ') || 'Erreur lors du chargement du menu'
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

  onPriceMinChange(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.priceMin.set(val ? parseFloat(val) : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.loadItems(), 300);
  }

  onPriceMaxChange(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.priceMax.set(val ? parseFloat(val) : null);
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
    this.selectedItem.set(item);
    this.modalQuantity.set(1);
    this.modalNote.set('');
  }

  closeModal(): void {
    this.selectedItem.set(null);
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
    this.modalQuantity.set(this.modalQuantity() + 1);
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

  onAddToCart(item: Item): void {
    this.openItemModal(item);
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
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
