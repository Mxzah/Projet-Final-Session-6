import { Component, OnInit, OnDestroy, signal, computed, Renderer2 } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
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
import { MatChipsModule } from '@angular/material/chips';
import { ItemsService } from '../services/items.service';
import { CombosService, Combo } from '../services/combos.service';
import { ComboItemsService, ComboItem } from '../services/combo-items.service';
import { AuthService } from '../services/auth.service';
import { forkJoin } from 'rxjs';
import { CartService, CartLine } from '../services/cart.service';
import { TableService } from '../services/table.service';
import { OrderService } from '../services/order.service';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { HeaderComponent } from '../header/header.component';
import { SsfSidebarComponent } from '../shared/ssf-sidebar/ssf-sidebar.component';
import { SsfBarComponent } from '../shared/ssf-bar/ssf-bar.component';
import { Item, Category } from './menu.models';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/edit-order-line-dialog/edit-order-line-dialog.component';

const COMBOS_CATEGORY_ID = -999;

@Component({
  selector: 'app-menu',
  standalone: true,
  imports: [
    CommonModule, FormsModule, HeaderComponent, SsfSidebarComponent, SsfBarComponent,
    MatDialogModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatButtonModule, MatIconModule, MatBadgeModule,
    MatProgressSpinnerModule, MatDividerModule,
    MatCardModule, MatToolbarModule, MatChipsModule
  ],
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit, OnDestroy {
  readonly COMBOS_CATEGORY_ID = COMBOS_CATEGORY_ID;

  categories = signal<Category[]>([]);
  allItems = signal<Item[]>([]);
  combos = signal<Combo[]>([]);

  comboItems = signal<ComboItem[]>([]);
  activeCategory = signal<number>(0);
  isLoading = signal<boolean>(true);
  errorMessage = signal<string>('');

    // Compute normal total price for selected combo
    comboNormalTotal = computed(() => {
      const combo = this.selectedCombo();
      if (!combo) return 0;
      // Get combo items for this combo
      const comboItems = this.comboItems().filter(ci => ci.combo_id === combo.id);
      // Sum up normal price: quantity * item price
      let total = 0;
      for (const ci of comboItems) {
        // Find item price from allItems
        const item = this.allItems().find(i => i.id === ci.item_id);
        if (item) {
          total += ci.quantity * item.price;
        }
      }
      return total;
    });

    // Compute normal total price for any combo (for menu card display)
    comboNormalTotalFor(combo: Combo): number {
      const comboItems = this.comboItems().filter(ci => ci.combo_id === combo.id);
      let total = 0;
      for (const ci of comboItems) {
        const item = this.allItems().find(i => i.id === ci.item_id);
        if (item) {
          total += ci.quantity * item.price;
        }
      }
      return total;
    }

  searchQuery = signal<string>('');
  sortOrder = signal<string>('none');
  priceMin = signal<number | null>(null);
  priceMax = signal<number | null>(null);
  sliderMin = signal<number>(0);
  sliderMax = signal<number>(9999);
  computedMaxPrice = signal<number>(9999);

  cartOpen = signal<boolean>(false);

  selectedItem = signal<Item | null>(null);
  selectedCombo = signal<Combo | null>(null);
  modalQuantity = signal<number>(1);
  modalNote = signal<string>('');

  private searchTimer: any = null;
  private maxPriceInitialized = false;

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

  selectedComboItems = computed(() => {
    const combo = this.selectedCombo();
    if (!combo) return [];
    return this.comboItems().filter(ci => ci.combo_id === combo.id);
  });

  comboModalTotal = computed(() => {
    const combo = this.selectedCombo();
    if (!combo) return 0;
    return combo.price * this.modalQuantity();
  });

  // Track if the user has an open order (even without a scanned table)
  hasOpenOrder = signal<boolean>(false);

  constructor(
    private itemsService: ItemsService,
    private combosService: CombosService,
    private comboItemsService: ComboItemsService,
    public authService: AuthService,
    public cartService: CartService,
    private tableService: TableService,
    private orderService: OrderService,
    public ts: TranslationService,
    private router: Router,
    private route: ActivatedRoute,
    private renderer: Renderer2,
    private dialog: MatDialog,
    private errorService: ErrorService
  ) {}

  ngOnInit(): void {
    this.isLoading.set(true);
    // First load without filters to compute the real max price
    forkJoin({
      items: this.itemsService.getItems({}),
      combos: this.combosService.getCombos({})
    }).subscribe({
      next: ({ items, combos }) => {
        const maxPrice = Math.ceil(Math.max(...items.map(i => i.price), ...combos.map(c => c.price), 0));
        this.computedMaxPrice.set(maxPrice);
        this.maxPriceInitialized = true;

        // Now read query params and apply them
        const params = this.route.snapshot.queryParams;
        if (params['search']) this.searchQuery.set(params['search']);
        if (params['sort'] && params['sort'] !== 'none') this.sortOrder.set(params['sort']);
        if (params['min']) {
          const min = +params['min'];
          this.sliderMin.set(min);
          this.priceMin.set(min > 0 ? min : null);
        }
        if (params['max']) {
          const max = +params['max'];
          this.sliderMax.set(max);
          this.priceMax.set(max < maxPrice ? max : null);
        } else {
          this.sliderMax.set(maxPrice);
        }

        this.loadItems(true);
      },
      error: () => {
        // Fallback: load normally
        this.loadItems(true);
      }
    });
    this.checkOpenOrder();
  }

  ngOnDestroy(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer);
  }

  // Check if the user already has an open order — if so, restore table info and cart
  private checkOpenOrder(): void {
    if (!this.authService.isAuthenticated()) return;
    this.orderService.getOrders().subscribe({
      next: (res) => {
        const orders = (res.data || []) as any[];
        const openOrder = orders.find((o: any) => !o.ended_at);
        if (openOrder) {
          this.hasOpenOrder.set(true);
          // Set orderId on cartService so addLine works
          this.cartService.setOrderId(openOrder.id);
          // Load waiting lines into cart from backend
          this.cartService.loadFromOrder(openOrder.id);
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

    forkJoin({
      items: this.itemsService.getItems({
        search: this.searchQuery(),
        sort: this.sortOrder(),
        price_min: this.priceMin(),
        price_max: this.priceMax()
      }),
      combos: this.combosService.getCombos({
        search: this.searchQuery(),
        sort: this.sortOrder(),
        price_min: this.priceMin(),
        price_max: this.priceMax()
      }),
      comboItems: this.comboItemsService.getComboItems()
    }).subscribe({
      next: ({ items, combos, comboItems }) => {
        this.allItems.set(items);
        this.combos.set(combos);
        this.comboItems.set(comboItems);

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

        if (!this.maxPriceInitialized) {
          const maxPrice = Math.ceil(Math.max(...items.map(i => i.price), ...combos.map(c => c.price), 0));
          this.computedMaxPrice.set(maxPrice);
          if (this.priceMax() === null) {
            this.sliderMax.set(maxPrice);
          }
          this.maxPriceInitialized = true;
        }

        this.isLoading.set(false);
      },
      error: (err: any) => {
        this.errorMessage.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.isLoading.set(false);
      }
    });
  }

  private updateQueryParams(): void {
    const queryParams: any = {};
    if (this.searchQuery()) queryParams.search = this.searchQuery();
    if (this.sortOrder() !== 'none') queryParams.sort = this.sortOrder();
    if (this.priceMin() !== null) queryParams.min = this.priceMin();
    if (this.priceMax() !== null) queryParams.max = this.priceMax();
    this.router.navigate([], { queryParams, replaceUrl: true });
  }

  onSearchInput(value: string): void {
    this.searchQuery.set(value);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadItems(); this.updateQueryParams(); }, 300);
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadItems();
    this.updateQueryParams();
  }

  onSliderMinChange(value: number): void {
    this.sliderMin.set(value);
    this.priceMin.set(value > 0 ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadItems(); this.updateQueryParams(); }, 300);
  }

  onSliderMaxChange(value: number): void {
    this.sliderMax.set(value);
    this.priceMax.set(value < this.computedMaxPrice() ? value : null);
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.loadItems(); this.updateQueryParams(); }, 300);
  }

  onInputMinChange(value: number): void {
    this.onSliderMinChange(value);
  }

  onInputMaxChange(value: number): void {
    this.onSliderMaxChange(value);
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
  // openComboModal and addComboToCart are defined below

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
    }, (success) => {
      if (!success) {
        this.errorMessage.set(this.ts.t('order.sendError'));
      }
    });
    this.closeModal();
  }

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
    }, (success) => {
      if (!success) {
        this.errorMessage.set(this.ts.t('order.sendError'));
      }
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

  // ── Edit/Delete cart line (backend-backed) ──

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
      this.cartService.updateLine(line.id, { quantity: result.quantity, note: result.note });
    });
  }

  openDeleteCartLine(index: number): void {
    const line: CartLine = this.cartService.lines()[index];
    if (!line) return;

    const data: ConfirmDialogData = {
      title: this.ts.t('order.deleteLine'),
      message: this.ts.t('order.deleteLineConfirm'),
      itemName: line.name,
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.cartService.removeLine(line.id);
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
