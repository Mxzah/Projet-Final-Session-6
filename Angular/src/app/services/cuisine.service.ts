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
  table_number: number;
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
    return this.api.get<CuisineOrder[]>('/api/cuisine/orders');
  }
}
