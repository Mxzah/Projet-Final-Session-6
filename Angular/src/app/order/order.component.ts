import { Component, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';
import { OrderLineData, OrderService } from '../services/order.service';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { MatIconModule } from '@angular/material/icon';
import { ConfirmDialogComponent, ConfirmDialogData, EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/confirm-dialog.component';

interface DisplayOrderLine {
  id: number;
  quantity: number;
  unit_price: number;
  note: string;
  status: string;
  name: string;
  image_url: string | null;
}

@Component({
  selector: 'app-order',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    HeaderComponent,
    MatButtonModule,
    MatCardModule,
    MatDividerModule,
    MatIconModule,
  ],
  templateUrl: './order.component.html',
  styleUrls: ['./order.component.css']
})
export class OrderComponent implements OnInit, OnDestroy {
  private pollingInterval: ReturnType<typeof setInterval> | null = null;
  openOrderId = signal<number | null>(null);
  private serverLines = signal<DisplayOrderLine[]>([]);
  isSending = signal<boolean>(false);
  loadError = signal('');
  actionError = signal('');

  existingNote = signal<string | null>(null);
  existingVibeName = signal<string | null>(null);
  existingVibeColor = signal<string | null>(null);
  existingNbPeople = signal<number | null>(null);

  private pendingLines = computed<DisplayOrderLine[]>(() =>
    this.cartService.lines().map((line, index) => ({
      id: -1 - index,
      quantity: line.quantity,
      unit_price: line.unit_price,
      note: line.note,
      status: 'pending',
      name: line.name,
      image_url: line.image_url || null
    }))
  );

  lines = computed<DisplayOrderLine[]>(() => [...this.serverLines(), ...this.pendingLines()]);
  subtotal = computed(() => this.lines().reduce((sum, line) => sum + line.unit_price * line.quantity, 0));
  totalItems = computed(() => this.lines().reduce((sum, line) => sum + line.quantity, 0));
  pendingCount = computed(() => this.cartService.lines().length);


  //regarder si toutes les lignes sont servies et qu'il n'y a aucune ligne en attente (panier vide)
  allServed = computed(() => {
    const sLines = this.serverLines();
    return sLines.length > 0 && sLines.every(l => l.status === 'served') && this.pendingCount() === 0;
  });

  constructor(
    public cartService: CartService,
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private router: Router,
    private dialog: MatDialog,
    private errorService: ErrorService
  ) {}

  ngOnInit(): void {
    this.loadOpenOrder();
    this.pollingInterval = setInterval(() => this.loadOpenOrder(), 10000);
  }

  ngOnDestroy(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  private mapApiLine(line: OrderLineData): DisplayOrderLine {
    return {
      id: line.id,
      quantity: line.quantity,
      unit_price: line.unit_price,
      note: line.note,
      status: line.status,
      name: line.orderable_name || `${line.orderable_type} #${line.orderable_id}`,
      image_url: line.image_url || null
    };
  }

  private loadOpenOrder(): void {
    this.loadError.set('');
    this.orderService.getOrders().subscribe({
      next: (response) => {
        const orders = response.data || [];
        const openOrder = orders.find(order => !order.ended_at) || null;

        if (!openOrder) {
          this.openOrderId.set(null);
          this.serverLines.set([]);
          this.existingNote.set(null);
          this.existingVibeName.set(null);
          this.existingVibeColor.set(null);
          this.existingNbPeople.set(null);
          return;
        }

        this.openOrderId.set(openOrder.id);
        this.existingNote.set(openOrder.note || null);
        this.existingVibeName.set(openOrder.vibe_name ?? null);
        this.existingVibeColor.set(openOrder.vibe_color ?? null);
        this.existingNbPeople.set(openOrder.nb_people ?? null);
        this.serverLines.set((openOrder.order_lines || []).map(line => this.mapApiLine(line)));
      },
      error: (err) => {
        this.loadError.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.openOrderId.set(null);
        this.serverLines.set([]);
      }
    });
  }

  getStatusClass(status: string): string {
    const classes: Record<string, string> = {
      sent: 'status-sent',
      in_preparation: 'status-prep',
      ready: 'status-ready',
      served: 'status-served'
    };
    return classes[status] ?? '';
  }

  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      sent: 'order.status.sent',
      in_preparation: 'order.status.inPreparation',
      ready: 'order.status.ready',
      served: 'order.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : '';
  }

  canModifyLine(line: DisplayOrderLine): boolean {
    return line.status === 'sent' || line.status === 'pending';
  }

  // ── Edit order line ──

  openEditLine(line: DisplayOrderLine): void {
    const isCart = line.id < 0;
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

      if (isCart) {
        const cartIndex = (-line.id) - 1;
        this.cartService.updateLine(cartIndex, { quantity: result.quantity, note: result.note });
        return;
      }

      const orderId = this.openOrderId();
      if (!orderId) return;

      this.actionError.set('');
      this.orderService.updateOrderLine(orderId, line.id, {
        quantity: result.quantity,
        note: result.note
      }).subscribe({
        next: () => this.loadOpenOrder(),
        error: (err) => {
          this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
        }
      });
    });
  }

  // ── Delete order line ──

  confirmDeleteLine(line: DisplayOrderLine): void {
    const isCart = line.id < 0;
    const data: ConfirmDialogData = {
      title: this.ts.t('order.deleteLine'),
      message: this.ts.t('order.deleteLineConfirm'),
      itemName: line.name,
      warning: isCart ? this.ts.t('order.cartRemoveInfo') : this.ts.t('order.hardDeleteWarning'),
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;

      if (isCart) {
        const cartIndex = (-line.id) - 1;
        this.cartService.removeLine(cartIndex);
        return;
      }

      const orderId = this.openOrderId();
      if (!orderId) return;

      this.actionError.set('');
      this.orderService.deleteOrderLine(orderId, line.id).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.loadOpenOrder();
          } else {
            this.actionError.set(this.errorService.format(this.errorService.fromApiError(res)));
          }
        },
        error: (err) => {
          this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
        }
      });
    });
  }

  // ── Send order lines ──

  onSend(): void {
    const linesToCreate = this.cartService.lines();
    const orderId = this.openOrderId();

    if (linesToCreate.length === 0 || this.isSending()) return;

    if (!orderId) {
      this.actionError.set(this.ts.t('order.noOrderRedirect'));
      this.router.navigate(['/form']);
      return;
    }

    this.isSending.set(true);
    this.actionError.set('');

    const requests = linesToCreate.map(line =>
      this.orderService.createOrderLine(orderId, {
        quantity: line.quantity,
        note: line.note,
        orderable_type: line.orderable_type,
        orderable_id: line.orderable_id
      })
    );

    forkJoin(requests).subscribe({
      next: () => {
        this.cartService.clear();
        this.loadOpenOrder();
      },
      error: (err) => {
        this.actionError.set(this.errorService.format(this.errorService.fromApiError(err)));
        this.isSending.set(false);
      },
      complete: () => {
        this.isSending.set(false);
      }
    });
  }

  onAddItems(): void {
    this.router.navigate(['/menu']);
  }

  goToPay(): void {
    this.router.navigate(['/pay']);
  }

  goBack(): void {
    this.router.navigate(['/menu']);
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
