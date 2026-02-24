import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router } from '@angular/router';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
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
export class CuisineComponent implements OnInit {
  orders: CuisineOrder[] = [];
  loading = true;
  error: string | null = null;

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
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadOrders();
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
      error: () => {
        this.error = 'Impossible de charger les commandes.';
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  canManageLines(): boolean {
    return this.authService.isAdmin() || this.authService.isWaiter();
  }

  getNextStatus(status: string): string | null {
    const idx = this.statuses.indexOf(status);
    if (idx === -1 || idx === this.statuses.length - 1) return null;
    return this.statuses[idx + 1];
  }

  advanceStatus(line: CuisineOrderLine): void {
    if (this.advancingLineIds.has(line.id)) return;
    this.advancingLineIds.add(line.id);

    this.cuisineService.nextStatus(line.id).subscribe({
      next: (res) => {
        this.advancingLineIds.delete(line.id);
        if (res.success) {
          this.loadOrders();
        } else {
          const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
          this.snackBar.open(msg, 'OK', { duration: 5000 });
        }
      },
      error: () => {
        this.advancingLineIds.delete(line.id);
        this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
      }
    });
  }

  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      sent: 'cuisine.status.sent',
      in_preparation: 'cuisine.status.inPreparation',
      ready: 'cuisine.status.ready',
      served: 'cuisine.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : status;
  }

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
      this.cuisineService.updateOrderLine(line.id, {
        quantity: result.quantity,
        note: result.note
      }).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => {
          this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 });
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
      this.cuisineService.deleteOrderLine(line.id).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.loadOrders();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.deleteError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => {
          this.snackBar.open(this.ts.t('order.deleteError'), 'OK', { duration: 5000 });
        }
      });
    });
  }

  goBack(): void {
    this.location.back();
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
