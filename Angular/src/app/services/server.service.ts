import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { CuisineOrderLine, CuisineOrder } from './cuisine.service';

export interface ServerTable {
  id: number;
  number: number;
  capacity: number;
  status: string;
  qr_token: string;
  server_name?: string | null;
  availabilities?: { id: number; start_at: string; end_at?: string | null }[];
}

export interface ServerOrdersResponse {
  mine: (CuisineOrder & { ended_at?: string | null })[];
}

@Injectable({
  providedIn: 'root'
})
export class ServerService {

  constructor(private api: ApiService) { }

  getTables(): Observable<ApiResponse<ServerTable[]>> {
    return this.api.get<ServerTable[]>('/api/server/tables');
  }

  getOrders(): Observable<ApiResponse<ServerOrdersResponse>> {
    return this.api.get<ServerOrdersResponse>('/api/server/orders');
  }

  releaseOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/server/orders/${orderId}/release`, {});
  }

  cleanOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/server/orders/${orderId}/clean`, {});
  }

  serveLine(lineId: number): Observable<ApiResponse<any>> {
    return this.api.patch<any>(`/api/server/order_lines/${lineId}/serve`, {});
  }

  updateOrderLine(lineId: number, data: { quantity?: number; note?: string }): Observable<ApiResponse<CuisineOrderLine[]>> {
    return this.api.patch<CuisineOrderLine[]>(`/api/server/order_lines/${lineId}`, { order_line: data });
  }

  deleteOrderLine(lineId: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/server/order_lines/${lineId}`);
  }

  assignOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/server/orders/${orderId}/assign`, {});
  }

  cancelOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.delete<any>(`/api/server/orders/${orderId}/cancel`);
  }
}
