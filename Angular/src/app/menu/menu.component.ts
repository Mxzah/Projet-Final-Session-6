import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ItemsService } from '../services/items.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { Item, Category } from './menu.models';

@Component({
  selector: 'app-menu',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent],
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit {
  categories = signal<Category[]>([]);
  allItems = signal<Item[]>([]);
  activeCategory = signal<number>(0);
  isLoading = signal<boolean>(true);
  errorMessage = signal<string>('');

  searchQuery = signal<string>('');
  sortOrder = signal<string>('none');
  priceMin = signal<number | null>(null);
  priceMax = signal<number | null>(null);

  // Modal
  selectedItem = signal<Item | null>(null);
  modalQuantity = signal<number>(1);
  modalNote = signal<string>('');

  itemsByCategory = computed(() => {
    const query = this.searchQuery().toLowerCase().trim();
    const sort = this.sortOrder();
    const min = this.priceMin();
    const max = this.priceMax();

    return this.categories().map(cat => {
      let items = this.allItems().filter(item => item.category_id === cat.id);

      if (query) {
        items = items.filter(item => item.name.toLowerCase().includes(query));
      }

      if (min !== null && min > 0) {
        items = items.filter(item => item.price >= min);
      }
      if (max !== null && max > 0) {
        items = items.filter(item => item.price <= max);
      }

      if (sort === 'asc') {
        items = [...items].sort((a, b) => a.price - b.price);
      } else if (sort === 'desc') {
        items = [...items].sort((a, b) => b.price - a.price);
      }

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
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.itemsService.getItems().subscribe({
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
        if (sorted.length > 0) {
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
  }

  onSortChange(event: Event): void {
    this.sortOrder.set((event.target as HTMLSelectElement).value);
  }

  onPriceMinChange(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.priceMin.set(val ? parseFloat(val) : null);
  }

  onPriceMaxChange(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.priceMax.set(val ? parseFloat(val) : null);
  }

  onMobileCategoryChange(event: Event): void {
    const id = parseInt((event.target as HTMLSelectElement).value, 10);
    this.selectCategory(id);
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
    console.log('Ajout au panier:', {
      item: item.name,
      quantity: this.modalQuantity(),
      note: this.modalNote(),
      total: this.modalTotal()
    });
    this.closeModal();
  }

  onAddToCart(item: Item): void {
    this.openItemModal(item);
  }

  logout(): void {
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
