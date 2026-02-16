import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { Item } from '../menu/menu.models';

@Injectable({
  providedIn: 'root'
})
export class ItemsService {
  constructor(private apiService: ApiService) {}

  getItems(): Observable<Item[]> {
    return this.apiService.get<Item[]>('/api/items').pipe(
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

  deleteItem(id: number): Observable<ApiResponse<null>> {
    return this.apiService.delete<null>(`/api/items/${id}`);
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
