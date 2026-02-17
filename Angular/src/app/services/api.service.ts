import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ApiResponse<T = any> {
  success: boolean;
  data: T | null;
  error?: string[];
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
        const serverErrors = (error as HttpErrorResponse).error?.errors || (error as HttpErrorResponse).error?.error;
        return throwError(() => ({
          success: false,
          data: null,
          error: serverErrors || ['Une erreur est survenue'],
          errors: serverErrors || ['Une erreur est survenue']
        }));
      })
    );
  }

  get<T>(endpoint: string, queryParams?: Record<string, string>): Observable<ApiResponse<T>> {
    let params = new HttpParams();
    if (queryParams) {
      for (const key of Object.keys(queryParams)) {
        if (queryParams[key]) {
          params = params.set(key, queryParams[key]);
        }
      }
    }
    return this.http.get<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, {
      withCredentials: true,
      params
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
        const serverErrors = (error as HttpErrorResponse).error?.errors || (error as HttpErrorResponse).error?.error;
        return throwError(() => ({
          success: false,
          data: null,
          error: serverErrors || ['Une erreur est survenue'],
          errors: serverErrors || ['Une erreur est survenue']
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

        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        const serverErrors = (error as HttpErrorResponse).error?.errors || (error as HttpErrorResponse).error?.error;
        return throwError(() => ({
          success: false,
          data: null,
          error: serverErrors || ['Une erreur est survenue'],
          errors: serverErrors || ['Une erreur est survenue']
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

        if ('success' in error && error.success === false) {
          return throwError(() => error);
        }
        const serverErrors = (error as HttpErrorResponse).error?.errors || (error as HttpErrorResponse).error?.error;
        return throwError(() => ({
          success: false,
          data: null,
          error: serverErrors || ['Une erreur est survenue'],
          errors: serverErrors || ['Une erreur est survenue']
        }));
      })
    );
  }
}
