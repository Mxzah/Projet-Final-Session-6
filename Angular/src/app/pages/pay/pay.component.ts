import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { HeaderComponent } from '../../shared/header/header.component';
import { AuthService } from '../../services/auth.service';
import { CartService } from '../../services/cart.service';
import { OrderService, OrderData } from '../../services/order.service';
import { TranslationService } from '../../services/translation.service';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { ThankYouDialogComponent, ThankYouDialogResult } from './thank-you-dialog.component';

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
    MatDialogModule,
  ],
  templateUrl: './pay.component.html',
  styleUrls: ['./pay.component.css']
})
export class PayComponent implements OnInit {
  order = signal<OrderData | null>(null);
  tip = signal<number>(0);
  tipError = signal<string>('');
  isPaying = signal<boolean>(false);
  paid = signal<boolean>(false);

  constructor(
    public ts: TranslationService,
    private authService: AuthService,
    private orderService: OrderService,
    private cartService: CartService,
    private router: Router,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
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
    if (isNaN(val)) {
      this.tipError.set(this.ts.t('pay.tipInvalid'));
      return false;
    }
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
    // Remove anything that isn't a digit or a single decimal point
    const sanitized = input.value.replace(/[^0-9.]/g, '').replace(/^(\d*\.?\d*).*$/, '$1');
    input.value = sanitized;
    const val = sanitized === '' ? 0 : parseFloat(sanitized);
    this.tip.set(isNaN(val) ? 0 : val);
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
          this.paid.set(true);
          this.isPaying.set(false);
          this.openThankYouDialog();
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

  goToReviews(): void {
    const o = this.order();
    this.router.navigate(['/history'], o ? { queryParams: { openReview: o.id } } : {});
  }

  skipReview(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => {
        localStorage.removeItem('currentUser');
        this.router.navigate(['/login']);
      }
    });
  }

  private isClient(): boolean {
    return this.authService.getCurrentUser()?.type === 'Client';
  }

  private openThankYouDialog(): void {
    window.scrollTo({ top: 0, behavior: 'smooth' });

    const showReviewOption = this.isClient();
    const ref = this.dialog.open<ThankYouDialogComponent, any, ThankYouDialogResult>(
      ThankYouDialogComponent,
      {
        data: {
          title: this.ts.t('pay.thankYouTitle'),
          message: this.ts.t('pay.thankYouMsg'),
          reviewLabel: showReviewOption ? this.ts.t('pay.reviewNow') : null,
          quitLabel: showReviewOption ? this.ts.t('pay.reviewLater') : this.ts.t('header.logout'),
        },
        width: '400px',
        maxHeight: '90vh',
        disableClose: true,
      }
    );
    ref.afterClosed().subscribe(result => {
      if (result === 'review') {
        this.goToReviews();
      } else {
        this.skipReview();
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
