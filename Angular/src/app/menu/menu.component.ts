import { Component, OnInit, OnDestroy, signal, computed, Renderer2 } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
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
import { CombosService, Combo } from '../services/combos.service';
import { ComboItemsService, ComboItem } from '../services/combo-items.service';
import { TableService } from '../services/table.service';
import { OrderService } from '../services/order.service';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { HeaderComponent } from '../header/header.component';
import { Item, Category } from './menu.models';
import { ConfirmDialogComponent, ConfirmDialogData, EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/confirm-dialog.component';

@Component({
  selector: 'app-menu',
  standalone: true,
  imports: [
    CommonModule, FormsModule, HeaderComponent,
    MatDialogModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatButtonModule, MatIconModule, MatBadgeModule,
    MatProgressSpinnerModule, MatDividerModule,
    MatCardModule, MatToolbarModule, MatListModule, MatChipsModule, MatSliderModule
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

  cartOpen = signal<boolean>(false);

  selectedItem = signal<Item | null>(null);
  modalQuantity = signal<number>(1);
  modalNote = signal<string>('');

  readonly COMBOS_CATEGORY_ID = -1;
  combos = signal<Combo[]>([]);
  selectedCombo = signal<Combo | null>(null);
  allComboItems = signal<ComboItem[]>([]);

  selectedComboItems = computed(() => {
    const combo = this.selectedCombo();
    if (!combo) return [];
    return this.allComboItems().filter(ci => ci.combo_id === combo.id);
  });

  comboModalTotal = computed(() => {
    const combo = this.selectedCombo();
    if (!combo) return 0;
    return combo.price * this.modalQuantity();
  });

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

  // Track if the user has an open order (even without a scanned table)
  hasOpenOrder = signal<boolean>(false);

  constructor(
    private itemsService: ItemsService,
    public authService: AuthService,
    public cartService: CartService,
    private tableService: TableService,
    private orderService: OrderService,
    public ts: TranslationService,
    private router: Router,
    private renderer: Renderer2,
    private dialog: MatDialog,
    private errorService: ErrorService,
    private combosService: CombosService,
    private comboItemsService: ComboItemsService
  ) {}

  ngOnInit(): void {
    this.loadItems(true);
    this.loadComboItems();
    this.checkOpenOrder();
  }

  ngOnDestroy(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer);
  }

  // Check if the user already has an open order — if so, restore table info
  private checkOpenOrder(): void {
    if (!this.authService.isAuthenticated()) return;
    this.orderService.getOrders().subscribe({
      next: (res) => {
        const orders = (res.data || []) as any[];
        const openOrder = orders.find((o: any) => !o.ended_at);
        if (openOrder) {
          this.hasOpenOrder.set(true);
          // Restore table info so the menu works without re-scanning
          if (!this.tableService.hasTable()) {
            this.tableService.setCurrentTable({
              id: openOrder.table_id,
              number: openOrder.table_number,
              capacity: 20,
              status: 'active',
              qr_token: ''
            });
          }
        }
      }
    });
  }

  loadItems(showLoading = false): void {
    if (showLoading) this.isLoading.set(true);
    this.loadCombos();
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
        const categories = [...catMap.values()];
        this.categories.set(categories);
        if (categories.length > 0 && !categories.find(c => c.id === this.activeCategory())) {
          this.activeCategory.set(categories[0].id);
        }
        this.isLoading.set(false);
      },
      error: (err: any) => {
        this.errorMessage.set(this.errorService.format(this.errorService.fromApiError(err)));
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

  onInputMinChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, 0), this.sliderMax());
    input.value = String(clamped);
    this.onSliderMinChange(clamped);
  }

  onInputMaxChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, this.sliderMin()), 9999);
    input.value = String(clamped);
    this.onSliderMaxChange(clamped);
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
    if (!this.tableService.hasTable() && !this.hasOpenOrder()) {
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
    this.selectedCombo.set(null);
    this.renderer.removeStyle(document.documentElement, 'overflow');
  }

  // Charge la liste des combos depuis le backend
  loadCombos(): void {
    this.combosService.getCombos({
      search: this.searchQuery(),
      sort: this.sortOrder(),
      price_min: this.priceMin(),
      price_max: this.priceMax()
    }).subscribe({
      next: (combos) => this.combos.set(combos),
      error: () => {}
    });
  }

  // Charge tous les combo_items pour afficher le détail dans le modal
  loadComboItems(): void {
    this.comboItemsService.getComboItems().subscribe({
      next: (items) => this.allComboItems.set(items),
      error: () => {}
    });
  }

  // Ouvre le modal de détail d'un combo
  openComboModal(combo: Combo): void {
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/login']);
      return;
    }
    if (!this.tableService.hasTable() && !this.hasOpenOrder()) {
      this.router.navigate(['/form']);
      return;
    }
    this.selectedCombo.set(combo);
    this.modalQuantity.set(1);
    this.modalNote.set('');
    this.renderer.setStyle(document.documentElement, 'overflow', 'hidden');
  }

  // Ajoute le combo sélectionné au panier (orderable_type: 'Combo')
  addComboToCart(): void {
    const combo = this.selectedCombo();
    if (!combo) return;
    this.cartService.addLine({
      orderable_type: 'Combo',
      orderable_id: combo.id,
      name: combo.name,
      description: combo.description ?? '',
      unit_price: combo.price,
      quantity: this.modalQuantity(),
      note: this.modalNote(),
      image_url: combo.image_url || null
    });
    this.closeModal();
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
    return this.authService.isAuthenticated() && (this.tableService.hasTable() || this.hasOpenOrder());
  }

  onAddToCart(item: Item): void {
    this.openItemModal(item);
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  // ── Delete cart line (removes from in-memory cart, no hard delete) ──

  openEditCartLine(index: number): void {
    const line: CartLine = this.cartService.lines()[index];
    if (!line) return;

    const data: EditOrderLineDialogData = {
      itemName: line.name,
      quantity: line.quantity,
      note: line.note
    };
    const ref = this.dialog.open<EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult>(
      EditOrderLineDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(result => {
      if (!result) return;
      this.cartService.updateLine(index, { quantity: result.quantity, note: result.note });
    });
  }

  openDeleteCartLine(index: number): void {
    const line: CartLine = this.cartService.lines()[index];
    if (!line) return;

    const data: ConfirmDialogData = {
      title: this.ts.t('order.deleteLine'),
      message: this.ts.t('order.deleteLineConfirm'),
      itemName: line.name,
      warning: this.ts.t('order.cartRemoveInfo'),
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.cartService.removeLine(index);
    });
  }

  logout(): void {
    this.cartService.clear();
    this.authService.logout().subscribe({
      next: (response) => {
        if (response?.success) {
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
