import { Component, signal } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../services/auth.service';
import { CartService } from '../../services/cart.service';
import { TableService } from '../../services/table.service';
import { TranslationService } from '../../services/translation.service';
import { HeaderComponent } from '../../shared/header/header.component';

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

        if (this.tableService.getPendingToken()) {
          // Always validate pending QR token — it takes priority
          // Always go to /form so the user sets up their table session
          const hasOpenOrder = redirectTo === '/menu';
          this.tableService.validateAndSavePendingToken().subscribe(() => {
            this.router.navigate(['/form'], hasOpenOrder ? { queryParams: { open: '1' } } : undefined);
          });
        } else if (redirectTo === '/form' && !this.tableService.hasTable()) {
          // No table scanned, no pending token → browse menu
          this.router.navigate(['/menu']);
        } else {
          this.router.navigate([redirectTo]);
        }
      },
      error: (error: any) => {
        this.isLoading = false;
        this.errorMessage.set(error?.errors?.join(', ') || this.ts.t('login.defaultError'));
      }
    });
  }}
