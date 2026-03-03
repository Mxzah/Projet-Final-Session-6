import { Injectable, signal, computed } from '@angular/core';
import { OrderService, OrderLineData } from './order.service';

export interface CartLine {
  id: number;              // backend order_line id
  orderable_type: string;
  orderable_id: number;
  name: string;
  description: string;
  unit_price: number;
  quantity: number;
  note: string;
  image_url: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  lines = signal<CartLine[]>([]);
  private _orderId = signal<number | null>(null);

  totalItems = computed(() => this.lines().reduce((sum, l) => sum + l.quantity, 0));
  subtotal = computed(() => this.lines().reduce((sum, l) => sum + l.unit_price * l.quantity, 0));

  constructor(private orderService: OrderService) {}

  get orderId(): number | null {
    return this._orderId();
  }

  setOrderId(id: number | null): void {
    this._orderId.set(id);
  }

  /** Load waiting lines from backend order into the cart */
  loadFromOrder(orderId: number): void {
    this._orderId.set(orderId);
    this.orderService.getOrders().subscribe({
      next: (res) => {
        const order = (res.data || []).find(o => o.id === orderId);
        if (!order) return;
        const waitingLines = (order.order_lines || [])
          .filter(l => l.status === 'waiting')
          .map(l => this.mapApiLine(l));
        this.lines.set(waitingLines);
      }
    });
  }

  /** Add a line to cart by creating it in backend with status=waiting */
  addLine(line: Omit<CartLine, 'id'>, callback?: (success: boolean) => void): void {
    const orderId = this._orderId();
    if (!orderId) {
      callback?.(false);
      return;
    }
    this.orderService.createOrderLine(orderId, {
      quantity: line.quantity,
      note: line.note,
      orderable_type: line.orderable_type,
      orderable_id: line.orderable_id
    }).subscribe({
      next: (res) => {
        if (res.success && res.data?.[0]) {
          const created = res.data[0];
          this.lines.update(lines => [...lines, {
            id: created.id,
            orderable_type: created.orderable_type,
            orderable_id: created.orderable_id,
            name: created.orderable_name || line.name,
            description: line.description,
            unit_price: created.unit_price,
            quantity: created.quantity,
            note: created.note,
            image_url: created.image_url || line.image_url
          }]);
          callback?.(true);
        } else {
          callback?.(false);
        }
      },
      error: () => callback?.(false)
    });
  }

  /** Remove a line from cart by deleting it from backend */
  removeLine(lineId: number, callback?: (success: boolean) => void): void {
    const orderId = this._orderId();
    if (!orderId) return;
    this.orderService.deleteOrderLine(orderId, lineId).subscribe({
      next: (res: any) => {
        if (res.success) {
          this.lines.update(lines => lines.filter(l => l.id !== lineId));
          callback?.(true);
        } else {
          callback?.(false);
        }
      },
      error: () => callback?.(false)
    });
  }

  /** Update a line in cart via backend */
  updateLine(lineId: number, data: { quantity: number; note: string }, callback?: (success: boolean) => void): void {
    const orderId = this._orderId();
    if (!orderId) return;
    this.orderService.updateOrderLine(orderId, lineId, data).subscribe({
      next: (res) => {
        if (res.success) {
          this.lines.update(lines => lines.map(l =>
            l.id === lineId ? { ...l, quantity: data.quantity, note: data.note } : l
          ));
          callback?.(true);
        } else {
          callback?.(false);
        }
      },
      error: () => callback?.(false)
    });
  }

  clear(): void {
    this.lines.set([]);
    this._orderId.set(null);
  }

  /** Refresh cart from backend */
  refresh(): void {
    const orderId = this._orderId();
    if (orderId) {
      this.loadFromOrder(orderId);
    }
  }

  private mapApiLine(l: OrderLineData): CartLine {
    return {
      id: l.id,
      orderable_type: l.orderable_type,
      orderable_id: l.orderable_id,
      name: l.orderable_name || `${l.orderable_type} #${l.orderable_id}`,
      description: l.orderable_description || '',
      unit_price: l.unit_price,
      quantity: l.quantity,
      note: l.note,
      image_url: l.image_url || null
    };
  }
}
