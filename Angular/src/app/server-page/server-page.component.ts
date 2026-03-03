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
import { ServerService, ServerOrdersResponse } from '../services/server.service';
import { CuisineOrder, CuisineOrderLine } from '../services/cuisine.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { TranslationService } from '../services/translation.service';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/edit-order-line-dialog/edit-order-line-dialog.component';

@Component({
  selector: 'app-server-page',
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
  templateUrl: './server-page.component.html',
  styleUrls: ['./server-page.component.css']
})
export class ServerPageComponent implements OnInit {
  unassignedOrders: CuisineOrder[] = [];
  myOrders: (CuisineOrder & { ended_at?: string | null })[] = [];
  loading = true;
  error: string | null = null;
  actionError = '';

  readonly statuses = ['sent', 'in_preparation', 'ready', 'served'];
  advancingLineIds = new Set<number>();

  constructor(
    public ts: TranslationService,
    private serverService: ServerService,
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
    this.serverService.getOrders().subscribe({
      next: (response) => {
        const data = response.data as any;
        this.unassignedOrders = data?.unassigned ?? [];
        this.myOrders = data?.mine ?? [];
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = this.ts.t('server.loadError');
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  // ── Assign order to me ──
  assignOrder(order: CuisineOrder): void {
    this.actionError = '';
    this.serverService.assignOrder(order.id).subscribe({
      next: (res) => {
        if (res.success) {
          this.loadOrders();
        } else {
          const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
          this.snackBar.open(msg, 'OK', { duration: 5000 });
        }
      },
      error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
    });
  }

  // ── Release / Clean table ──
  confirmReleaseOrder(order: CuisineOrder & { ended_at?: string | null }): void {
    const isPaid = !!order.ended_at;
    const title = isPaid ? this.ts.t('server.cleanTable') : this.ts.t('server.releaseTable');
    const message = isPaid ? this.ts.t('server.cleanConfirm') : this.ts.t('server.releaseConfirm');

    const data: ConfirmDialogData = {
      title,
      message,
      itemName: this.ts.t('cuisine.table') + ' ' + order.table_number,
      warning: '',
      confirmLabel: title,
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open(ConfirmDialogComponent, { data, width: '440px', maxHeight: '90vh' });
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      const action$ = isPaid
        ? this.serverService.cleanOrder(order.id)
        : this.serverService.releaseOrder(order.id);
      action$.subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
      });
    });
  }

  // ── Edit order line ──
  canEditLine(line: CuisineOrderLine): boolean {
    return line.status !== 'served';
  }

  canDeleteLine(line: CuisineOrderLine): boolean {
    return line.status === 'sent' || line.status === 'in_preparation';
  }

  // ── Serve a line (ready → served) ──
  serveLine(line: CuisineOrderLine): void {
    if (this.advancingLineIds.has(line.id)) return;
    this.advancingLineIds.add(line.id);

    this.serverService.serveLine(line.id).subscribe({
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
      this.serverService.updateOrderLine(line.id, {
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
        error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
      });
    });
  }

  // ── Delete order line ──
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
      this.serverService.deleteOrderLine(line.id).subscribe({
        next: (res: any) => {
          if (res.success) {
            this.loadOrders();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.deleteError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => this.snackBar.open(this.ts.t('order.deleteError'), 'OK', { duration: 5000 })
      });
    });
  }

  // ── Helpers ──
  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      sent: 'cuisine.status.sent',
      in_preparation: 'cuisine.status.inPreparation',
      ready: 'cuisine.status.ready',
      served: 'cuisine.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : status;
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

  isOrderPaid(order: any): boolean {
    return !!order.ended_at;
  }

  allLinesServed(order: CuisineOrder): boolean {
    return order.order_lines.length > 0 && order.order_lines.every(l => l.status === 'served');
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
