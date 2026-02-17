import { Injectable, signal, computed } from '@angular/core';

export interface CartLine {
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

  totalItems = computed(() => this.lines().reduce((sum, l) => sum + l.quantity, 0));
  subtotal = computed(() => this.lines().reduce((sum, l) => sum + l.unit_price * l.quantity, 0));

  addLine(line: CartLine): void {
    this.lines.set([...this.lines(), { ...line }]);
  }

  clear(): void {
    this.lines.set([]);
  }
}
