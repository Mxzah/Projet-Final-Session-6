import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api.service';

export interface UserData {
  email: string;
  first_name: string;
  last_name: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUser: UserData | null = null;
  private isLoggedInSubject = new BehaviorSubject<boolean>(false);
  public isLoggedIn$ = this.isLoggedInSubject.asObservable();

  constructor(private apiService: ApiService) {
    this.loadUserFromStorage();
  }

  private loadUserFromStorage(): void {
    const userData = localStorage.getItem('currentUser');
    if (userData) {
      this.currentUser = JSON.parse(userData);
      this.isLoggedInSubject.next(true);
    }
  }

  private saveUserToStorage(user: UserData): void {
    localStorage.setItem('currentUser', JSON.stringify(user));
  }

  private clearUserFromStorage(): void {
    localStorage.removeItem('currentUser');
  }

  login(email: string, password: string) {
    const body = { user: { email, password } };
    return this.apiService.post<UserData>('/users/sign_in', body).pipe(
      tap(response => {
        if (response.success && response.data) {
          this.currentUser = response.data;
          this.saveUserToStorage(response.data);
          this.isLoggedInSubject.next(true);
        }
      })
    );
  }

  signup(email: string, password: string, passwordConfirmation: string, firstName: string, lastName: string, type: string) {
    const body = {
      user: {
        email,
        password,
        password_confirmation: passwordConfirmation,
        first_name: firstName,
        last_name: lastName,
        type
      }
    };
    return this.apiService.post<UserData>('/users', body).pipe(
      tap(response => {
        if (response.success && response.data) {
          this.currentUser = response.data;
          this.saveUserToStorage(response.data);
          this.isLoggedInSubject.next(true);
        }
      })
    );
  }

  logout() {
    return this.apiService.delete<null>('/users/sign_out').pipe(
      tap({
        next: (response) => {
          this.currentUser = null;
          this.clearUserFromStorage();
          this.isLoggedInSubject.next(false);
        },
        error: () => {
          this.currentUser = null;
          this.clearUserFromStorage();
          this.isLoggedInSubject.next(false);
        }
      })
    );
  }

  isAuthenticated(): boolean {
    return this.isLoggedInSubject.value;
  }

  getCurrentUser(): UserData | null {
    return this.currentUser;
  }
}
