import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { CuisineOrderLine, CuisineOrder } from './cuisine.service';

export interface ServerOrdersResponse {
  unassigned: CuisineOrder[];
  mine: (CuisineOrder & { ended_at?: string | null })[];
}

@Injectable({
  providedIn: 'root'
})
export class ServerService {

  constructor(private api: ApiService) {}

  getOrders(): Observable<ApiResponse<ServerOrdersResponse>> {
    return this.api.get<ServerOrdersResponse>('/api/server/orders');
  }

  assignOrder(orderId: number): Observable<ApiResponse<any>> {
    return this.api.post<any>(`/api/server/orders/${orderId}/assign`, {});
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
}
