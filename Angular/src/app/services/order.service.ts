import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface OrderLineData {
  id: number;
  quantity: number;
  unit_price: number;
  note: string;
  status: string;
  orderable_type: string;
  orderable_id: number;
  orderable_name: string;
  orderable_description: string;
  image_url: string | null;
  created_at: string;
}

export interface OrderData {
  id: number;
  nb_people: number;
  note: string;
  tip: number;
  table_id: number;
  table_number: number;
  client_id: number;
  server_id: number | null;
  server_name: string | null;
  vibe_id: number | null;
  vibe_name: string | null;
  vibe_color: string | null;
  created_at: string;
  ended_at: string | null;
  order_lines: OrderLineData[];
  total: number;
}

export interface VibeData {
  id: number;
  name: string;
  color: string;
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {

  constructor(private api: ApiService) {}

  getOrders(): Observable<ApiResponse<OrderData[]>> {
    return this.api.get<OrderData[]>('/api/orders');
  }

  getOrder(id: number): Observable<ApiResponse<OrderData[]>> {
    return this.api.get<OrderData[]>(`/api/orders/${id}`);
  }

  createOrder(data: {
    nb_people: number;
    note: string;
    table_id: number;
    vibe_id?: number | null;
    tip?: number | null;
  }): Observable<ApiResponse<OrderData[]>> {
    return this.api.post<OrderData[]>('/api/orders', { order: data });
  }

  getOrderLines(orderId: number): Observable<ApiResponse<OrderLineData[]>> {
    return this.api.get<OrderLineData[]>(`/api/orders/${orderId}/order_lines`);
  }

  createOrderLine(orderId: number, data: {
    quantity: number;
    note: string;
    orderable_type: string;
    orderable_id: number;
  }): Observable<ApiResponse<OrderLineData[]>> {
    return this.api.post<OrderLineData[]>(`/api/orders/${orderId}/order_lines`, { order_line: data });
  }

  closeOpenOrders(): Observable<ApiResponse<any>> {
    return this.api.post<any>('/api/orders/close_open', {});
  }

  getAssignedWaiter(): Observable<ApiResponse<{ id: number; name: string }[]>> {
    return this.api.get<{ id: number; name: string }[]>('/api/waiters/assigned');
  }

  getVibes(): Observable<ApiResponse<VibeData[]>> {
    return this.api.get<VibeData[]>('/api/vibes');
  }
}
