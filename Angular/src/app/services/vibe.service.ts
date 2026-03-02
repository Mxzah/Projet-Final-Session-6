import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface VibeData {
  id: number;
  name: string;
  color: string;
  deleted_at: string | null;
  image_url: string | null;
  in_use: boolean;
}

@Injectable({ providedIn: 'root' })
export class VibeService {

  constructor(private api: ApiService) {}

  getVibes(): Observable<ApiResponse<VibeData[]>> {
    return this.api.get<VibeData[]>('/api/vibes');
  }

  getVibesAdmin(): Observable<ApiResponse<VibeData[]>> {
    return this.api.get<VibeData[]>('/api/vibes');
  }

  createVibe(data: { name: string; color: string; image?: File }): Observable<ApiResponse<VibeData>> {
    const fd = this.buildFormData(data);
    return this.api.post<VibeData>('/api/vibes', fd);
  }

  updateVibe(id: number, data: { name?: string; color?: string; image?: File }): Observable<ApiResponse<VibeData>> {
    const fd = this.buildFormData(data);
    return this.api.put<VibeData>(`/api/vibes/${id}`, fd);
  }

  deleteVibe(id: number): Observable<ApiResponse<VibeData>> {
    return this.api.delete<VibeData>(`/api/vibes/${id}`);
  }

  restoreVibe(id: number): Observable<ApiResponse<VibeData>> {
    return this.api.put<VibeData>(`/api/vibes/${id}/restore`, {});
  }

  private buildFormData(data: Record<string, any>): FormData {
    const fd = new FormData();
    for (const key of Object.keys(data)) {
      if (data[key] !== undefined && data[key] !== null) {
        if (data[key] instanceof File) {
          fd.append(`vibe[${key}]`, data[key]);
        } else {
          fd.append(`vibe[${key}]`, String(data[key]));
        }
      }
    }
    return fd;
  }
}
