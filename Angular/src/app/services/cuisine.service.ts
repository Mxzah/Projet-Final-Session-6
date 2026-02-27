import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface CuisineOrderLine {
  id: number;
  quantity: number;
  unit_price: number;
  note: string | null;
  status: string;
  orderable_type: string;
  orderable_id: number;
  orderable_name: string;
}

export interface CuisineOrder {
  id: number;
  nb_people: number;
  note: string | null;
  tip: number;
  vibe_name: string | null;
  vibe_color: string | null;
  table_number: number;
  server_id: number | null;
  server_name: string | null;
  created_at: string;
  order_lines: CuisineOrderLine[];
}

@Injectable({
  providedIn: 'root'
})
export class CuisineService {

  constructor(private api: ApiService) {}

  getActiveOrders(): Observable<ApiResponse<CuisineOrder[]>> {
    return this.api.get<CuisineOrder[]>('/api/kitchen/orders');
  }

  // Advances the line to the next status (all kitchen staff)
  nextStatus(lineId: number): Observable<ApiResponse<CuisineOrderLine[]>> {
    return this.api.put<CuisineOrderLine[]>(`/api/kitchen/order_lines/${lineId}/next_status`, {});
  }

  // Edit quantity/note (waiter/admin only)
  updateOrderLine(lineId: number, data: {
    quantity?: number;
    note?: string;
  }): Observable<ApiResponse<CuisineOrderLine[]>> {
    return this.api.put<CuisineOrderLine[]>(`/api/kitchen/order_lines/${lineId}`, { order_line: data });
  }

  // Delete line (waiter/admin only)
  deleteOrderLine(lineId: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/kitchen/order_lines/${lineId}`);
  }

  // Release/close an order (waiter/admin only — like paying, frees the table)
  releaseOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/kitchen/orders/${orderId}/release`, {});
  }

  // Assign current user as server (waiter/admin only)
  assignServer(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/kitchen/orders/${orderId}/assign_server`, {});
  }
}
