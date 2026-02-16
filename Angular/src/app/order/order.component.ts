import { Component, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';

@Component({
  selector: 'app-order',
  standalone: true,
  imports: [CommonModule, HeaderComponent],
  templateUrl: './order.component.html',
  styleUrls: ['./order.component.css']
})
export class OrderComponent {
  lines = computed(() => this.cartService.lines());
  subtotal = computed(() => this.cartService.subtotal());

  constructor(
    public cartService: CartService,
    private authService: AuthService,
    private router: Router
  ) {}

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      sent: 'Envoyée',
      in_preparation: 'En préparation',
      ready: 'Prête',
      served: 'Servie'
    };
    return labels[status] || status;
  }

  onSend(): void {
    // nothing for now
  }

  onEdit(): void {
    // nothing for now
  }

  onDelete(): void {
    // nothing for now
  }

  goBack(): void {
    this.router.navigate(['/menu']);
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: (response) => {
        if (response.success) {
          this.router.navigate(['/login']);
        }
      },
      error: () => {
        localStorage.removeItem('currentUser');
        this.router.navigate(['/login']);
      }
    });
  }
}
