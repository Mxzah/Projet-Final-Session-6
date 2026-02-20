import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';
import { UserInfo } from '../admin-users/user.model';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private apiService: ApiService) {}

  getUsers(filters?: { search?: string; sort?: string; sort_by?: string; status?: string; type?: string }): Observable<UserInfo[]> {
    const params: Record<string, string> = {};
    if (filters?.search) params['search'] = filters.search;
    if (filters?.sort && filters.sort !== 'none') params['sort'] = filters.sort;
    if (filters?.sort_by) params['sort_by'] = filters.sort_by;
    if (filters?.status && filters.status !== 'all') params['status'] = filters.status;
    if (filters?.type && filters.type !== 'all') params['type'] = filters.type;

    return this.apiService.get<UserInfo[]>('/api/users', params).pipe(
      map(response => response.data!)
    );
  }

  getUser(id: number): Observable<UserInfo> {
    return this.apiService.get<UserInfo>(`/api/users/${id}`).pipe(
      map(response => response.data!)
    );
  }

  createUser(data: Record<string, any>): Observable<UserInfo> {
    return this.apiService.post<UserInfo>('/api/users', { user: data }).pipe(
      map(response => response.data!)
    );
  }

  updateUser(id: number, data: Record<string, any>): Observable<UserInfo> {
    return this.apiService.put<UserInfo>(`/api/users/${id}`, { user: data }).pipe(
      map(response => response.data!)
    );
  }

  deleteUser(id: number): Observable<ApiResponse<null>> {
    return this.apiService.delete<null>(`/api/users/${id}`);
  }
}
