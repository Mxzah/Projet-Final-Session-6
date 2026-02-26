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
import { OrderService } from '../services/order.service';
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
    private orderService: OrderService,
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

        if (this.authService.isCook()) {
          this.router.navigate(['/kitchen']);
          return;
        }

        if (this.authService.isAdmin()) {
          this.router.navigate(['/admin', 'tables']);
          return;
        }

        // Check if the user already has an open order
        this.orderService.getOrders().subscribe({
          next: (res) => {
            const orders = (res.data || []) as any[];
            const openOrder = orders.find((o: any) => !o.ended_at);

            if (openOrder) {
              // User already has an open order — restore table info and go to menu
              this.tableService.setCurrentTable({
                id: openOrder.table_id,
                number: openOrder.table_number,
                capacity: 20,
                status: 'active',
                qr_token: ''
              });
              this.router.navigate(['/menu']);
            } else {
              // No open order — proceed with the QR scan flow
              if (this.tableService.getPendingToken()) {
                this.tableService.validateAndSavePendingToken().subscribe(() => {
                  this.router.navigate(['/form']);
                });
              } else {
                this.router.navigate(['/form']);
              }
            }
          },
          error: () => {
            // Fallback: go to /form
            this.router.navigate(['/form']);
          }
        });
      },
      error: (error: any) => {
        this.isLoading = false;
        this.errorMessage.set(error?.errors?.join(', ') || this.ts.t('login.defaultError'));
      }
    });
  }
}
