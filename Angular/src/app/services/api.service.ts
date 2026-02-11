import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ApiResponse<T = any> {
  success: boolean;
  data: T | null;
  errors?: string[];
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  post<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.post<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, body, {
      withCredentials: true
    }).pipe(
      map(response => {
        if (!response.success) {
          throw response;
        }
        return response;
      }),
      catchError((error: HttpErrorResponse | ApiResponse<T>) => {
        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        return throwError(() => ({
          success: false,
          data: null,
          errors: (error as HttpErrorResponse).error?.errors || ['Une erreur est survenue']
        }));
      })
    );
  }

  get<T>(endpoint: string): Observable<ApiResponse<T>> {
    return this.http.get<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, {
      withCredentials: true
    }).pipe(
      map(response => {
        if (!response.success) {
          throw response;
        }
        return response;
      }),
      catchError((error: HttpErrorResponse | ApiResponse<T>) => {
        console.error('API Error:', error);
        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        return throwError(() => ({
          success: false,
          data: null,
          errors: (error as HttpErrorResponse).error?.errors || ['Une erreur est survenue']
        }));
      })
    );
  }

  put<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.put<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, body, {
      withCredentials: true
    }).pipe(
      map(response => {
        if (!response.success) {
          throw response;
        }
        return response;
      }),
      catchError((error: HttpErrorResponse | ApiResponse<T>) => {
        console.error('API Error:', error);
        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        return throwError(() => ({
          success: false,
          data: null,
          errors: (error as HttpErrorResponse).error?.errors || ['Une erreur est survenue']
        }));
      })
    );
  }

  delete<T>(endpoint: string): Observable<ApiResponse<T>> {
    return this.http.delete<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, {
      withCredentials: true
    }).pipe(
      map(response => {
        if (!response.success) {
          throw response;
        }
        return response;
      }),
      catchError((error: HttpErrorResponse | ApiResponse<T>) => {
        console.error('API Error:', error);
        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        return throwError(() => ({
          success: false,
          data: null,
          errors: (error as HttpErrorResponse).error?.errors || ['Une erreur est survenue']
        }));
      })
    );
  }
}
