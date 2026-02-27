import { Component, signal } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';
import { TableService } from '../services/table.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink, HeaderComponent, MatFormFieldModule, MatInputModule, MatButtonModule, MatIconModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', [Validators.required, Validators.minLength(6), Validators.maxLength(128)])
  });

  errorMessage = signal('');
  isLoading: boolean = false;

  constructor(
    private authService: AuthService,
    private cartService: CartService,
    private tableService: TableService,
    private router: Router,
    public ts: TranslationService
  ) { }

  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.errorMessage.set('');
    this.isLoading = true;

    const { email, password } = this.loginForm.value;

    this.authService.login(email!, password!).subscribe({
      next: (response) => {
        this.isLoading = false;
        this.cartService.clear();

        const redirectTo = response.data?.redirect_to || '/form';

        // Handle QR pending token for /form redirect
        if (redirectTo === '/form' && this.tableService.getPendingToken()) {
          this.tableService.validateAndSavePendingToken().subscribe(() => {
            this.router.navigate(['/form']);
          });
        } else if (redirectTo === '/menu') {
          // Restore table info from open order for menu navigation
          this.restoreTableAndNavigate(redirectTo);
        } else {
          this.router.navigate([redirectTo]);
        }
      },
      error: (error: any) => {
        this.isLoading = false;
        this.errorMessage.set(error?.errors?.join(', ') || this.ts.t('login.defaultError'));
      }
    });
  }

  private restoreTableAndNavigate(path: string): void {
    // Import OrderService lazily to restore table context
    import('../services/order.service').then(m => {
      // We need to get the injector — simplest approach: just navigate, the order page handles its own loading
      this.router.navigate([path]);
    });
  }
}
