import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { Item } from '../menu/menu.models';

@Injectable({
  providedIn: 'root'
})
export class ItemsService {
  constructor(private apiService: ApiService) {}

  getItems(filters?: { search?: string; sort?: string; price_min?: number | null; price_max?: number | null }): Observable<Item[]> {
    const params: Record<string, string> = {};
    if (filters?.search) params['search'] = filters.search;
    if (filters?.sort && filters.sort !== 'none') params['sort'] = filters.sort;
    if (filters?.price_min != null && filters.price_min > 0) params['price_min'] = String(filters.price_min);
    if (filters?.price_max != null && filters.price_max > 0) params['price_max'] = String(filters.price_max);

    return this.apiService.get<Item[]>('/api/items', params).pipe(
      map(response => response.data!)
    );
  }

  getItem(id: number): Observable<Item> {
    return this.apiService.get<Item>(`/api/items/${id}`).pipe(
      map(response => response.data!)
    );
  }

  createItem(data: { name: string; description?: string; price: number; category_id: number; image?: File }): Observable<Item> {
    const formData = this.buildFormData(data);
    return this.apiService.post<Item>('/api/items', formData).pipe(
      map(response => response.data!)
    );
  }

  updateItem(id: number, data: { name?: string; description?: string; price?: number; category_id?: number; image?: File }): Observable<Item> {
    const formData = this.buildFormData(data);
    return this.apiService.put<Item>(`/api/items/${id}`, formData).pipe(
      map(response => response.data!)
    );
  }

  softDeleteItem(id: number): Observable<ApiResponse<Item>> {
    return this.apiService.delete<Item>(`/api/items/${id}`);
  }

  hardDeleteItem(id: number): Observable<ApiResponse<null>> {
    return this.apiService.delete<null>(`/api/items/${id}/hard`);
  }

  restoreItem(id: number): Observable<ApiResponse<Item>> {
    return this.apiService.put<Item>(`/api/items/${id}/restore`, {});
  }

  private buildFormData(data: Record<string, any>): FormData {
    const formData = new FormData();
    for (const key of Object.keys(data)) {
      if (data[key] !== undefined && data[key] !== null) {
        if (data[key] instanceof File) {
          formData.append(`item[${key}]`, data[key]);
        } else {
          formData.append(`item[${key}]`, String(data[key]));
        }
      }
    }
    return formData;
  }
}
