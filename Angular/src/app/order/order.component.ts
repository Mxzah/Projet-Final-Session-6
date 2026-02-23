import { Component, OnInit, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';
import { OrderLineData, OrderService } from '../services/order.service';
import { TableService } from '../services/table.service';
import { TranslationService } from '../services/translation.service';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatDividerModule } from '@angular/material/divider';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

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
    FormsModule,
    ReactiveFormsModule,
    HeaderComponent,
    MatButtonModule,
    MatCardModule,
    MatChipsModule,
    MatDividerModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule
  ],
  templateUrl: './order.component.html',
  styleUrls: ['./order.component.css']
})
export class OrderComponent implements OnInit {
  openOrderId = signal<number | null>(null);
  private serverLines = signal<DisplayOrderLine[]>([]);
  isSending = signal<boolean>(false);

  // Existing order data
  existingNote = signal<string | null>(null);
  existingVibeName = signal<string | null>(null);
  existingVibeColor = signal<string | null>(null);

  // Form inputs for new order
  noteInput = '';

  // Edit order line dialog
  editingLine = signal<DisplayOrderLine | null>(null);
  editLineForm = new FormGroup({
    quantity: new FormControl<number>(1, [Validators.required, Validators.min(1), Validators.max(50)]),
    note: new FormControl('', [Validators.maxLength(255)])
  });
  editLineError = signal('');
  editLineLoading = signal(false);

  // Delete order line dialog
  lineToDelete = signal<DisplayOrderLine | null>(null);

  // Note editing
  isEditingNote = signal(false);
  noteEditInput = '';

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

  constructor(
    public cartService: CartService,
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private tableService: TableService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadOpenOrder();
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
          return;
        }

        this.openOrderId.set(openOrder.id);
        this.existingNote.set(openOrder.note || null);
        this.existingVibeName.set(openOrder.vibe_name ?? null);
        this.existingVibeColor.set(openOrder.vibe_color ?? null);

        this.serverLines.set((openOrder.order_lines || []).map(line => this.mapApiLine(line)));
      },
      error: () => {
        this.openOrderId.set(null);
        this.serverLines.set([]);
      }
    });
  }

  isFormInvalid(): boolean {
    if (this.openOrderId() !== null) return false;
    const noteOnlySpaces = this.noteInput.length > 0 && this.noteInput.trim().length === 0;
    return noteOnlySpaces;
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

  // Returns true if the line can be edited/deleted (sent on server OR pending in cart)
  canModifyLine(line: DisplayOrderLine): boolean {
    return line.status === 'sent' || line.status === 'pending';
  }

  // ── Edit order line ──

  openEditLine(line: DisplayOrderLine): void {
    this.editingLine.set(line);
    this.editLineForm.patchValue({
      quantity: line.quantity,
      note: line.note || ''
    });
    this.editLineForm.markAsPristine();
    this.editLineForm.markAsUntouched();
    this.editLineError.set('');
  }

  cancelEditLine(): void {
    this.editingLine.set(null);
    this.editLineError.set('');
  }

  saveEditLine(): void {
    const line = this.editingLine();
    if (!line) return;

    Object.values(this.editLineForm.controls).forEach(c => c.markAsDirty());
    if (this.editLineForm.invalid) return;

    const v = this.editLineForm.value;

    // Pending cart line (not yet sent)
    if (line.id < 0) {
      const cartIndex = (-line.id) - 1;
      this.cartService.updateLine(cartIndex, {
        quantity: v.quantity!,
        note: v.note ?? ''
      });
      this.editingLine.set(null);
      return;
    }

    // Server line
    const orderId = this.openOrderId();
    if (!orderId) return;

    this.editLineLoading.set(true);
    this.editLineError.set('');

    this.orderService.updateOrderLine(orderId, line.id, {
      quantity: v.quantity!,
      note: v.note ?? ''
    }).subscribe({
      next: () => {
        this.editingLine.set(null);
        this.editLineLoading.set(false);
        this.loadOpenOrder();
      },
      error: () => {
        this.editLineError.set(this.ts.t('order.editError'));
        this.editLineLoading.set(false);
      }
    });
  }

  // ── Delete order line ──

  confirmDeleteLine(line: DisplayOrderLine): void {
    this.lineToDelete.set(line);
  }

  cancelDeleteLine(): void {
    this.lineToDelete.set(null);
  }

  deleteLine(): void {
    const line = this.lineToDelete();
    if (!line) return;

    // Pending cart line (not yet sent)
    if (line.id < 0) {
      const cartIndex = (-line.id) - 1;
      this.cartService.removeLine(cartIndex);
      this.lineToDelete.set(null);
      return;
    }

    // Server line
    const orderId = this.openOrderId();
    if (!orderId) return;

    this.orderService.deleteOrderLine(orderId, line.id).subscribe({
      next: () => {
        this.lineToDelete.set(null);
        this.loadOpenOrder();
      },
      error: () => {
        this.lineToDelete.set(null);
      }
    });
  }

  // ── Note editing (anytime) ──

  openEditNote(): void {
    this.isEditingNote.set(true);
    this.noteEditInput = this.existingNote() || '';
  }

  cancelEditNote(): void {
    this.isEditingNote.set(false);
  }

  saveNote(): void {
    const orderId = this.openOrderId();
    if (!orderId) return;

    this.orderService.updateOrder(orderId, { note: this.noteEditInput }).subscribe({
      next: () => {
        this.existingNote.set(this.noteEditInput || null);
        this.isEditingNote.set(false);
      },
      error: () => {
        this.isEditingNote.set(false);
      }
    });
  }

  // ── Send order ──

  onSend(): void {
    const linesToCreate = this.cartService.lines();

    if (linesToCreate.length === 0 || this.isSending() || this.isFormInvalid()) {
      return;
    }

    const createLines = (orderId: number) => {
      const requests = linesToCreate.map((line) =>
        this.orderService.createOrderLine(orderId, {
          quantity: line.quantity,
          note: line.note,
          orderable_type: line.orderable_type,
          orderable_id: line.orderable_id
        })
      );
      return forkJoin(requests);
    };

    const existingOrderId = this.openOrderId();
    this.isSending.set(true);

    const send$ = existingOrderId
      ? createLines(existingOrderId)
      : (() => {
          const table = this.tableService.getCurrentTable();

          if (!table) {
            this.isSending.set(false);
            alert('Please scan/select a table before sending the order.');
            this.router.navigate(['/form']);
            return of(null);
          }

          return this.orderService.createOrder({
            nb_people: 1,
            note: this.noteInput,
            table_id: table.id
          }).pipe(
            switchMap((response) => {
              const createdOrder = response.data?.[0];
              if (!createdOrder) return of(null);
              this.openOrderId.set(createdOrder.id);
              return createLines(createdOrder.id);
            })
          );
        })();

    send$.subscribe({
      next: (result) => {
        if (!result) return;
        this.cartService.clear();
        this.loadOpenOrder();
      },
      error: () => {
        alert('Unable to send order lines. Please try again.');
      },
      complete: () => {
        this.isSending.set(false);
      }
    });
  }

  onAddItems(): void {
    this.router.navigate(['/menu']);
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
