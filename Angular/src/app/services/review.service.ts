import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface ReviewData {
  id: number;
  user_id: number;
  user_name: string;
  reviewable_type: string;
  reviewable_id: number;
  reviewable_name: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class ReviewService {

  constructor(private api: ApiService) {}

  getReviews(filters?: Record<string, string>): Observable<ApiResponse<ReviewData[]>> {
    let url = '/api/reviews';
    if (filters) {
      const params = new URLSearchParams(filters).toString();
      if (params) url += `?${params}`;
    }
    return this.api.get<ReviewData[]>(url);
  }

  getReview(id: number): Observable<ApiResponse<ReviewData>> {
    return this.api.get<ReviewData>(`/api/reviews/${id}`);
  }

  createReview(data: {
    rating: number;
    comment: string;
    reviewable_type: string;
    reviewable_id: number;
  }): Observable<ApiResponse<ReviewData>> {
    return this.api.post<ReviewData>('/api/reviews', { review: data });
  }

  updateReview(id: number, data: {
    rating?: number;
    comment?: string;
  }): Observable<ApiResponse<ReviewData>> {
    return this.api.put<ReviewData>(`/api/reviews/${id}`, { review: data });
  }

  deleteReview(id: number): Observable<ApiResponse<null>> {
    return this.api.delete<null>(`/api/reviews/${id}`);
  }
}
