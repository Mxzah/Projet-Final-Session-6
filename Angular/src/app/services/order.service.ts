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
  vibe_image_url: string | null;
  created_at: string;
  ended_at: string | null;
  order_lines: OrderLineData[];
  total: number;
  discount_percentage: number;
  discount_amount: number;
  adjusted_total: number;
}

export interface VibeData {
  id: number;
  name: string;
  color: string;
  deleted_at: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {

  constructor(private api: ApiService) {}

  getOrders(filters?: { search?: string; sort?: string; closed?: boolean; total_min?: number | null; total_max?: number | null }): Observable<ApiResponse<OrderData[]>> {
    let url = '/api/orders';
    const params: string[] = [];
    if (filters?.search) params.push(`search=${encodeURIComponent(filters.search)}`);
    if (filters?.sort && filters.sort !== 'none') params.push(`sort=${filters.sort}`);
    if (filters?.closed) params.push('closed=true');
    if (filters?.total_min != null) params.push(`total_min=${filters.total_min}`);
    if (filters?.total_max != null) params.push(`total_max=${filters.total_max}`);
    if (params.length) url += '?' + params.join('&');
    return this.api.get<OrderData[]>(url);
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

  updateOrderLine(orderId: number, lineId: number, data: {
    quantity?: number;
    note?: string;
  }): Observable<ApiResponse<OrderLineData[]>> {
    return this.api.patch<OrderLineData[]>(`/api/orders/${orderId}/order_lines/${lineId}`, { order_line: data });
  }

  deleteOrderLine(orderId: number, lineId: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/orders/${orderId}/order_lines/${lineId}`);
  }

  sendOrderLines(orderId: number): Observable<ApiResponse<OrderLineData[]>> {
    return this.api.post<OrderLineData[]>(`/api/orders/${orderId}/order_lines/send_lines`, {});
  }

  updateOrder(id: number, data: { note?: string }): Observable<ApiResponse<OrderData[]>> {
    return this.api.patch<OrderData[]>(`/api/orders/${id}`, { order: data });
  }

  deleteOrder(id: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/orders/${id}`);
  }

  closeOpenOrders(): Observable<ApiResponse<any>> {
    return this.api.post<any>('/api/orders/close_open', {});
  }

  payOrder(orderId: number, tip: number): Observable<ApiResponse<OrderData[]>> {
    return this.api.post<OrderData[]>(`/api/orders/${orderId}/pay`, { tip });
  }

  getAssignedWaiter(): Observable<ApiResponse<{ id: number; name: string }[]>> {
    return this.api.get<{ id: number; name: string }[]>('/api/waiters/assigned');
  }

  getVibes(): Observable<ApiResponse<VibeData[]>> {
    return this.api.get<VibeData[]>('/api/vibes');
  }
}
