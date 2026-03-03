import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { Category } from '../menu/menu.models';

@Injectable({ providedIn: 'root' })
export class CategoriesService {

  constructor(private api: ApiService) {}

  getCategories(): Observable<ApiResponse<Category[]>> {
    return this.api.get<Category[]>('/api/categories');
  }

  createCategory(body: { name: string; position: number }): Observable<ApiResponse<Category[]>> {
    return this.api.post<Category[]>('/api/categories', { category: body });
  }

  updateCategory(id: number, body: { name?: string }): Observable<ApiResponse<Category[]>> {
    return this.api.patch<Category[]>(`/api/categories/${id}`, { category: body });
  }

  deleteCategory(id: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/categories/${id}`);
  }

  reorder(ids: number[]): Observable<ApiResponse<Category[]>> {
    return this.api.patch<Category[]>('/api/categories/reorder', { ids });
  }
}
