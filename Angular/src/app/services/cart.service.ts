import { Injectable, signal, computed } from '@angular/core';

export interface CartLine {
  orderable_type: string;
  orderable_id: number;
  name: string;
  description: string;
  unit_price: number;
  quantity: number;
  note: string;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  lines = signal<CartLine[]>([]);

  totalItems = computed(() => this.lines().reduce((sum, l) => sum + l.quantity, 0));
  subtotal = computed(() => this.lines().reduce((sum, l) => sum + l.unit_price * l.quantity, 0));

  addLine(line: CartLine): void {
    const current = this.lines();
    const existing = current.findIndex(
      l => l.orderable_type === line.orderable_type && l.orderable_id === line.orderable_id && l.note === line.note
    );
    if (existing >= 0) {
      const updated = [...current];
      updated[existing] = { ...updated[existing], quantity: updated[existing].quantity + line.quantity };
      this.lines.set(updated);
    } else {
      this.lines.set([...current, line]);
    }
  }

  clear(): void {
    this.lines.set([]);
  }
}
