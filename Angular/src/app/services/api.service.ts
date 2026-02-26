import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpParams, HttpHeaders } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { TranslationService } from './translation.service';

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
  private ts = inject(TranslationService);

  constructor(private http: HttpClient) { }

  private getHeaders(): HttpHeaders {
    return new HttpHeaders().set('X-Locale', this.ts.lang());
  }

  post<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.post<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, body, {
      withCredentials: true,
      headers: this.getHeaders()
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
        const serverErrors = (error as HttpErrorResponse).error?.errors;
        return throwError(() => ({
          success: false,
          data: null,
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
      headers: this.getHeaders(),
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
        const serverErrors = (error as HttpErrorResponse).error?.errors;
        return throwError(() => ({
          success: false,
          data: null,
          errors: serverErrors || ['Une erreur est survenue']
        }));
      })
    );
  }

  put<T>(endpoint: string, body: any): Observable<ApiResponse<T>> {
    return this.http.put<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, body, {
      withCredentials: true,
      headers: this.getHeaders()
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
        const serverErrors = (error as HttpErrorResponse).error?.errors;
        return throwError(() => ({
          success: false,
          data: null,
          errors: serverErrors || ['Une erreur est survenue']
        }));
      })
    );
  }

  delete<T>(endpoint: string): Observable<ApiResponse<T>> {
    return this.http.delete<ApiResponse<T>>(`${this.apiUrl}${endpoint}`, {
      withCredentials: true,
      headers: this.getHeaders()
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
        const serverErrors = (error as HttpErrorResponse).error?.errors;
        return throwError(() => ({
          success: false,
          data: null,
          errors: serverErrors || ['Une erreur est survenue']
        }));
      })
    );
  }
}
