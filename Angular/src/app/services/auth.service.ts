import { Injectable } from '@angular/core';
import { of } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { ApiService } from './api.service';

export interface UserData {
  email: string;
  first_name: string;
  last_name: string;
  type: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUser: UserData | null = null;
  private isLoggedIn = false;

  constructor(private apiService: ApiService) {
    this.loadUserFromStorage();
  }

  private loadUserFromStorage(): void {
    const userData = localStorage.getItem('currentUser');
    if (userData) {
      this.currentUser = JSON.parse(userData);
      this.isLoggedIn = true;
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
          this.isLoggedIn = true;
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
          this.isLoggedIn = true;
        }
      })
    );
  }

  logout() {
    return this.apiService.delete<null>('/users/sign_out').pipe(
      tap(() => {
        this.currentUser = null;
        this.clearUserFromStorage();
        this.isLoggedIn = false;
      }),
      catchError(() => {
        this.currentUser = null;
        this.clearUserFromStorage();
        this.isLoggedIn = false;
        return of(null);
      })
    );
  }

  isAuthenticated(): boolean {
    return this.isLoggedIn;
  }

  isAdmin(): boolean {
    return this.currentUser?.type === 'Administrator';
  }

  isWaiter(): boolean {
    return this.currentUser?.type === 'Waiter';
  }

  isCook(): boolean {
    return this.currentUser?.type === 'Cook';
  }

  isKitchenStaff(): boolean {
    return this.isAdmin() || this.isWaiter() || this.isCook();
  }

  getCurrentUser(): UserData | null {
    return this.currentUser;
  }
}
