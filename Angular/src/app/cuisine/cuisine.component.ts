import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router } from '@angular/router';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CuisineService, CuisineOrder, CuisineOrderLine } from '../services/cuisine.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { ConfirmDialogComponent, ConfirmDialogData, EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/confirm-dialog.component';

@Component({
  selector: 'app-cuisine',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatCardModule,
    MatChipsModule,
    MatIconModule,
    MatButtonModule,
    MatDividerModule,
    MatProgressSpinnerModule,
    HeaderComponent
  ],
  templateUrl: './cuisine.component.html',
  styleUrl: './cuisine.component.css'
})
export class CuisineComponent implements OnInit, OnDestroy {
  private pollingInterval: ReturnType<typeof setInterval> | null = null;
  orders: CuisineOrder[] = [];
  loading = true;
  error: string | null = null;
  actionError = '';

  readonly statuses = ['sent', 'in_preparation', 'ready', 'served'];

  advancingLineIds = new Set<number>();

  constructor(
    public ts: TranslationService,
    private cuisineService: CuisineService,
    public authService: AuthService,
    private router: Router,
    private location: Location,
    private cdr: ChangeDetectorRef,
    private dialog: MatDialog,
    private errorService: ErrorService
  ) {}

  ngOnInit(): void {
    this.loadOrders();
    this.pollingInterval = setInterval(() => this.loadOrders(), 10000);
  }

  ngOnDestroy(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  loadOrders(): void {
    this.loading = true;
    this.error = null;
    this.cuisineService.getActiveOrders().subscribe({
      next: (response) => {
        this.orders = response.data ?? [];
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = this.errorService.format(this.errorService.fromApiError(err));
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  canManageLines(): boolean {
    return this.authService.isAdmin() || this.authService.isWaiter();
  }

  // Retourne le prochain statut dans la liste (ex: 'sent' → 'in_preparation')
  // Retourne null si le statut est déjà le dernier (ex: 'served')
  getNextStatus(status: string): string | null {
    const idx = this.statuses.indexOf(status);
    if (idx === -1 || idx === this.statuses.length - 1) return null;
    return this.statuses[idx + 1];
  }

  // Envoie une requête au backend pour avancer le statut d'une ligne de commande
  // Ex: 'sent' → 'in_preparation' → 'ready' → 'served'
  // advancingLineIds empêche de cliquer deux fois sur le même bouton en même temps
  advanceStatus(line: CuisineOrderLine): void {
    if (this.advancingLineIds.has(line.id)) return;
    this.advancingLineIds.add(line.id);
    this.actionError = '';

    this.cuisineService.nextStatus(line.id).subscribe({
      next: (res) => {
        this.advancingLineIds.delete(line.id);
        if (res.success) {
          this.loadOrders();
        } else {
          this.actionError = this.errorService.format(this.errorService.fromApiError(res));
        }
      },
      error: (err) => {
        this.advancingLineIds.delete(line.id);
        this.actionError = this.errorService.format(this.errorService.fromApiError(err));
      }
    });
  }

  // Traduit un statut interne (ex: 'in_preparation') en texte affiché à l'écran
  // Utilise le service de traduction (ts.t) pour supporter le français/anglais
  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      sent: 'cuisine.status.sent',
      in_preparation: 'cuisine.status.inPreparation',
      ready: 'cuisine.status.ready',
      served: 'cuisine.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : status;
  }

  // Formate une date en texte lisible selon la langue choisie (fr ou en)
  // Ex: '2024-03-15T14:30:00' → 'mars 15, 14:30' (fr) ou 'Mar 15, 2:30 PM' (en)
  formatOrderTime(dateStr: string): string {
    const date = new Date(dateStr);
    const locale = this.ts.lang() === 'en' ? 'en-CA' : 'fr-CA';
    return date.toLocaleString(locale, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  // Retourne la classe CSS correspondant au statut pour colorier visuellement la ligne
  // Ex: 'sent' → 'status-sent', 'ready' → 'status-ready'
  // ?? '' = si le statut est inconnu, retourne une chaîne vide (pas de classe appliquée)
  getStatusClass(status: string): string {
    const classes: Record<string, string> = {
      sent: 'status-sent',
      in_preparation: 'status-prep',
      ready: 'status-ready',
      served: 'status-served'
    };
    return classes[status] ?? '';
  }

  // ── Edit order line (waiter/admin, via kitchen API) ──

  openEditLine(line: CuisineOrderLine): void {
    const data: EditOrderLineDialogData = {
      itemName: line.orderable_name,
      quantity: line.quantity,
      note: line.note || ''
    };
    const ref = this.dialog.open<EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult>(
      EditOrderLineDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(result => {
      if (!result) return;
      this.actionError = '';
      this.cuisineService.updateOrderLine(line.id, {
        quantity: result.quantity,
        note: result.note
      }).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
          } else {
            this.actionError = this.errorService.format(this.errorService.fromApiError(res));
          }
        },
        error: (err) => {
          this.actionError = this.errorService.format(this.errorService.fromApiError(err));
        }
      });
    });
  }

  // ── Delete order line (waiter/admin, hard delete, status must be 'sent') ──

  confirmDeleteLine(line: CuisineOrderLine): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('order.deleteLine'),
      message: this.ts.t('order.deleteLineConfirm'),
      itemName: line.orderable_name,
      warning: this.ts.t('order.hardDeleteWarning'),
      confirmLabel: this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.actionError = '';
      this.cuisineService.deleteOrderLine(line.id).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.loadOrders();
          } else {
            this.actionError = this.errorService.format(this.errorService.fromApiError(res));
          }
        },
        error: (err) => {
          this.actionError = this.errorService.format(this.errorService.fromApiError(err));
        }
      });
    });
  }

  goBack(): void {
    this.location.back();
  }

  // ── Release table / close order (waiter/admin only) ──

  confirmReleaseOrder(order: CuisineOrder): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('cuisine.releaseTable'),
      message: this.ts.t('cuisine.releaseConfirm'),
      itemName: `${this.ts.t('cuisine.table')} ${order.table_number}`,
      confirmLabel: this.ts.t('cuisine.releaseTable'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '440px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.actionError = '';
      this.cuisineService.releaseOrder(order.id).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
          } else {
            this.actionError = this.errorService.format(this.errorService.fromApiError(res));
          }
        },
        error: (err) => {
          this.actionError = this.errorService.format(this.errorService.fromApiError(err));
        }
      });
    });
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
