import { Component, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { HeaderComponent } from '../../header/header.component';
import { AuthService } from '../../services/auth.service';
import { CartService } from '../../services/cart.service';
import { OrderLineData, OrderService } from '../../services/order.service';
import { TableService } from '../../services/table.service';
import { TranslationService } from '../../services/translation.service';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/edit-order-line-dialog/edit-order-line-dialog.component';
import { ImageData } from '../../services/order.service';

interface DisplayOrderLine {
  id: number;
  quantity: number;
  unit_price: number;
  note: string;
  status: string;
  name: string;
  image: ImageData | null;
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
    MatProgressBarModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
  ],
  templateUrl: './order.component.html',
  styleUrls: ['./order.component.css']
})
export class OrderComponent implements OnInit, OnDestroy {
  openOrderId = signal<number | null>(null);
  isSending = signal<boolean>(false);
  private pollTimer: ReturnType<typeof setInterval> | null = null;

  existingNote = signal<string | null>(null);
  editingNote = signal(false);
  noteInput = signal('');
  isSavingNote = signal(false);
  existingVibeName = signal<string | null>(null);
  existingVibeColor = signal<string | null>(null);
  existingVibeImageUrl = signal<string | null>(null);
  existingNbPeople = signal<number | null>(null);
  existingServerName = signal<string | null>(null);
  existingTableNumber = signal<number | null>(null);

  /** All order lines from backend */
  private allLines = signal<DisplayOrderLine[]>([]);

  /** Waiting lines = the "cart" (not yet sent) */
  waitingLines = computed(() => this.allLines().filter(l => l.status === 'waiting'));
  /** Sent/in-progress/ready/served lines */
  sentLines = computed(() => this.allLines().filter(l => l.status !== 'waiting'));

  lines = computed<DisplayOrderLine[]>(() => [...this.sentLines(), ...this.waitingLines()]);
  subtotal = computed(() => this.lines().reduce((sum, line) => sum + line.unit_price * line.quantity, 0));
  totalItems = computed(() => this.lines().reduce((sum, line) => sum + line.quantity, 0));
  pendingCount = computed(() => this.waitingLines().length);
  canPay = computed(() =>
    this.openOrderId() !== null &&
    this.pendingCount() === 0 &&
    this.sentLines().length > 0 &&
    this.sentLines().every(l => l.status === 'served')
  );
  servedCount = computed(() => this.sentLines().filter(l => l.status === 'served').length);
  progressPercent = computed(() => {
    const total = this.sentLines().length;
    return total > 0 ? (this.servedCount() / total) * 100 : 0;
  });

  constructor(
    public cartService: CartService,
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private tableService: TableService,
    private router: Router,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadOpenOrder();
    this.startPolling();
  }

  ngOnDestroy(): void {
    this.stopPolling();
  }

  private startPolling(): void {
    this.pollTimer = setInterval(() => {
      if (this.openOrderId() && !this.canPay()) {
        this.loadOpenOrder();
      }
    }, 5000);
  }

  private stopPolling(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
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
      image: line.image || null
    };
  }

  private loadOpenOrder(): void {
    this.orderService.getOrders().subscribe({
      next: (response) => {
        const orders = response.data || [];
        const openOrder = orders.find(order => !order.ended_at) || null;

        if (!openOrder) {
          this.openOrderId.set(null);
          this.allLines.set([]);
          this.existingNote.set(null);
          this.existingVibeName.set(null);
          this.existingVibeColor.set(null);
          this.existingVibeImageUrl.set(null);
          this.existingNbPeople.set(null);
          this.existingServerName.set(null);
          this.existingTableNumber.set(null);
          return;
        }

        this.openOrderId.set(openOrder.id);
        this.cartService.setOrderId(openOrder.id);
        this.existingNote.set(openOrder.note || null);
        this.existingVibeName.set(openOrder.vibe_name ?? null);
        this.existingVibeColor.set(openOrder.vibe_color ?? null);
        this.existingVibeImageUrl.set(openOrder.vibe_image?.url ?? null);
        this.existingNbPeople.set(openOrder.nb_people ?? null);
        this.existingServerName.set(openOrder.server_name ?? null);
        this.existingTableNumber.set(openOrder.table_number ?? null);
        this.allLines.set((openOrder.order_lines || []).map(line => this.mapApiLine(line)));
        // Sync cart service with waiting lines
        this.cartService.loadFromOrder(openOrder.id);
      },
      error: () => {
        this.openOrderId.set(null);
        this.allLines.set([]);
      }
    });
  }

  getStatusClass(status: string): string {
    const classes: Record<string, string> = {
      waiting: 'status-waiting',
      sent: 'status-sent',
      in_preparation: 'status-prep',
      ready: 'status-ready',
      served: 'status-served'
    };
    return classes[status] ?? '';
  }

  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      waiting: 'order.status.waiting',
      sent: 'order.status.sent',
      in_preparation: 'order.status.inPreparation',
      ready: 'order.status.ready',
      served: 'order.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : '';
  }

  canModifyLine(line: DisplayOrderLine): boolean {
    return line.status === 'waiting' || line.status === 'sent';
  }

  // ── Edit order line ──

  openEditLine(line: DisplayOrderLine): void {
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
      const orderId = this.openOrderId();
      if (!orderId) return;

      if (line.status === 'waiting') {
        // Waiting lines: update via cart service (backend-backed)
        this.cartService.updateLine(line.id, { quantity: result.quantity, note: result.note }, (ok) => {
          if (ok) this.loadOpenOrder();
          else this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
        });
      } else {
        // Already-sent lines: update directly
        this.orderService.updateOrderLine(orderId, line.id, {
          quantity: result.quantity,
          note: result.note
        }).subscribe({
          next: () => this.loadOpenOrder(),
          error: () => {
            this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
          }
        });
      }
    });
  }

  // ── Delete order line ──

  confirmDeleteLine(line: DisplayOrderLine): void {
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

      if (line.status === 'waiting') {
        // Waiting lines: delete via cart service (backend-backed)
        this.cartService.removeLine(line.id, (ok) => {
          if (ok) this.loadOpenOrder();
          else this.snackBar.open(this.ts.t('order.deleteError'), 'OK', { duration: 5000 });
        });
      } else {
        const orderId = this.openOrderId();
        if (!orderId) return;
        this.orderService.deleteOrderLine(orderId, line.id).subscribe({
          next: (res: any) => {
            if (res.success) {
              this.loadOpenOrder();
            } else {
              const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.deleteError');
              this.snackBar.open(msg, 'OK', { duration: 5000 });
            }
          },
          error: () => {
            this.snackBar.open(this.ts.t('order.deleteError'), 'OK', { duration: 5000 });
          }
        });
      }
    });
  }

  // ── Send order lines ──

  onSend(): void {
    const orderId = this.openOrderId();
    const waitingCount = this.waitingLines().length;

    if (waitingCount === 0 || this.isSending()) return;

    if (!orderId) {
      this.snackBar.open(this.ts.t('order.noOrderRedirect'), 'OK', { duration: 4000 });
      this.router.navigate(['/form']);
      return;
    }

    this.isSending.set(true);

    this.orderService.sendOrderLines(orderId).subscribe({
      next: () => {
        this.cartService.clear();
        this.loadOpenOrder();
      },
      error: () => {
        this.snackBar.open(this.ts.t('order.sendError'), 'OK', { duration: 5000 });
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

  // Ouvre le mode édition de la note de commande
  openEditNote(): void {
    this.noteInput.set(this.existingNote() ?? '');
    this.editingNote.set(true);
  }

  // Annule l'édition de la note
  cancelEditNote(): void {
    this.editingNote.set(false);
  }

  // Sauvegarde la note modifiée dans le backend
  saveNote(): void {
    const orderId = this.openOrderId();
    if (!orderId || this.isSavingNote()) return;
    this.isSavingNote.set(true);
    this.orderService.updateOrder(orderId, { note: this.noteInput() }).subscribe({
      next: () => {
        this.editingNote.set(false);
        this.isSavingNote.set(false);
        this.snackBar.open(this.ts.t('order.noteSaved'), 'OK', { duration: 3000 });
        this.loadOpenOrder();
      },
      error: () => {
        this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
        this.isSavingNote.set(false);
      }
    });
  }

  // ── Quit & delete order (client confirms, order deleted, logout) ──

  confirmQuitOrder(): void {
    const orderId = this.openOrderId();
    if (!orderId) return;

    const data: ConfirmDialogData = {
      title: this.ts.t('order.quitOrder'),
      message: this.ts.t('order.quitOrderConfirm'),
      itemName: this.ts.t('order.yourOrder'),
      confirmLabel: this.ts.t('order.quitOrder'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.cartService.clear();
      this.tableService.clearTable();
      this.orderService.deleteOrder(orderId).subscribe({
        next: () => {
          this.authService.logout().subscribe({
            next: () => this.router.navigate(['/login']),
            error: () => {
              localStorage.removeItem('currentUser');
              this.router.navigate(['/login']);
            }
          });
        },
        error: () => {
          this.snackBar.open(this.ts.t('order.deleteError'), 'OK', { duration: 5000 });
        }
      });
    });
  }

  goBack(): void {
    this.router.navigate(['/menu']);
  }

  logout(): void {
    this.cartService.clear();
    this.tableService.clearTable();
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
