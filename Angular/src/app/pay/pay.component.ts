import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HeaderComponent } from '../header/header.component';
import { AuthService } from '../services/auth.service';
import { CartService } from '../services/cart.service';
import { OrderService, OrderData } from '../services/order.service';
import { TranslationService } from '../services/translation.service';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-pay',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    HeaderComponent,
    MatButtonModule,
    MatCardModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
  ],
  templateUrl: './pay.component.html',
  styleUrls: ['./pay.component.css']
})
export class PayComponent implements OnInit {
  order = signal<OrderData | null>(null);
  tip = signal<number>(0);
  tipError = signal<string>('');
  isPaying = signal<boolean>(false);

  constructor(
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private cartService: CartService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  // Appelé automatiquement au chargement de la page
  ngOnInit(): void {
    this.loadOrder();
  }

  // Charge la commande ouverte du client depuis le backend
  // Si aucune commande ouverte, redirige vers /order
  private loadOrder(): void {
    this.orderService.getOrders().subscribe({
      next: (res) => {
        const orders = res.data || [];
        const open = orders.find(o => !o.ended_at) || null;
        if (!open) {
          this.router.navigate(['/order']);
          return;
        }
        this.order.set(open);
      },
      error: () => {
        this.router.navigate(['/order']);
      }
    });
  }

  // Valide le montant du pourboire (doit être entre 0 et 999.99)
  // Retourne true si valide, false sinon
  validateTip(): boolean {
    const val = this.tip();
    if (val < 0) {
      this.tipError.set(this.ts.t('pay.tipNegative'));
      return false;
    }
    if (val > 999.99) {
      this.tipError.set(this.ts.t('pay.tipMax'));
      return false;
    }
    this.tipError.set('');
    return true;
  }

  // Appelé chaque fois que l'utilisateur modifie le champ pourboire
  onTipChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const val = parseFloat(input.value) || 0;
    this.tip.set(val);
    this.validateTip();
  }

  // Appelé quand l'utilisateur clique sur Payer
  // Envoie la commande + pourboire au backend, puis déconnecte et redirige vers /login
  onPay(): void {
    if (!this.validateTip() || this.isPaying()) return;

    const o = this.order();
    if (!o) return;

    this.isPaying.set(true);

    this.orderService.payOrder(o.id, this.tip()).subscribe({
      next: (res) => {
        if (res.success) {
          this.cartService.clear();
          this.authService.logout().subscribe({
            next: () => this.router.navigate(['/login']),
            error: () => {
              localStorage.removeItem('currentUser');
              this.router.navigate(['/login']);
            }
          });
        } else {
          const msg = (res.errors as string[])?.join(', ') || this.ts.t('pay.error');
          this.snackBar.open(msg, 'OK', { duration: 5000 });
          this.isPaying.set(false);
        }
      },
      error: () => {
        this.snackBar.open(this.ts.t('pay.error'), 'OK', { duration: 5000 });
        this.isPaying.set(false);
      }
    });
  }

  // Appelé quand l'utilisateur clique sur déconnexion dans le header
  logout(): void {
    this.cartService.clear();
    this.authService.logout().subscribe({
      next: (response) => {
        if (response?.success) {
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
