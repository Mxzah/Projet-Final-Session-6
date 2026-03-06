import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { tap } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const authService = inject(AuthService);

  return next(req).pipe(
    tap((event) => {
      // Our API returns 200 for everything — check the body for session_expired flag
      if (event.type !== 0 && 'body' in event) {
        const body = event.body as any;
        if (body?.session_expired && authService.isAuthenticated()) {
          authService.clearSession();
          router.navigate(['/login']);
        }
      }
    })
  );
};
