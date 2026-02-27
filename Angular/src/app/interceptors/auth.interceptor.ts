import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { tap } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const authService = inject(AuthService);

  return next(req).pipe(
    tap({
      error: (err) => {
        // Check for session expiry: HTTP 401 or our custom 200 + "Invalid email or password" from CustomFailure
        const isUnauthorized = err.status === 401;
        const isSessionExpired = err?.error?.success === false &&
          err?.error?.errors?.some((e: string) => e === 'Invalid email or password');

        if ((isUnauthorized || isSessionExpired) && authService.isAuthenticated()) {
          authService.clearSession();
          router.navigate(['/login']);
        }
      }
    })
  );
};
