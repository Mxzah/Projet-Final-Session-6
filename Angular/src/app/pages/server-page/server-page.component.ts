import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
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
import { MatTooltipModule } from '@angular/material/tooltip';
import { ServerService, ServerOrdersResponse, ServerTable } from '../../services/server.service';
import { CuisineOrder, CuisineOrderLine } from '../../services/cuisine.service';
import { AuthService } from '../../services/auth.service';
import { HeaderComponent } from '../../header/header.component';
import { TranslationService } from '../../services/translation.service';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog/confirm-dialog.component';
import { EditOrderLineDialogComponent, EditOrderLineDialogData, EditOrderLineDialogResult } from '../admin-items/edit-order-line-dialog/edit-order-line-dialog.component';
import { QrDialogComponent, QrDialogData } from './qr-dialog/qr-dialog.component';
import QRCodeStyling from 'styled-qr-code';

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
    MatTooltipModule,
    HeaderComponent
  ],
  templateUrl: './server-page.component.html',
  styleUrls: ['./server-page.component.css']
})
export class ServerPageComponent implements OnInit, OnDestroy {
  myOrders: (CuisineOrder & { ended_at?: string | null; server_released?: boolean })[] = [];
  groupedOrders: (CuisineOrder & { ended_at?: string | null; server_released?: boolean })[] = [];
  loading = true;
  error: string | null = null;
  actionError = '';
  private pollTimer: ReturnType<typeof setInterval> | null = null;

  // Tables with QR codes
  tables: ServerTable[] = [];
  tablesLoading = true;
  tablesError: string | null = null;

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
  ) { }

  ngOnInit(): void {
    this.loadOrders();
    this.loadTables();
    this.pollTimer = setInterval(() => {
      this.loadOrders(false);
      this.loadTables(false);
    }, 5000);
  }

  ngOnDestroy(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  loadOrders(showLoading = true): void {
    if (showLoading) this.loading = true;
    this.error = null;
    this.serverService.getOrders().subscribe({
      next: (response) => {
        const data = response.data as any;
        this.myOrders = data?.mine ?? [];
        this.groupedOrders = this.groupOrdersByTable(this.myOrders);
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

  // ── Clean table (after payment or release) ──
  confirmClean(order: CuisineOrder & { ended_at?: string | null }): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('server.cleanTable'),
      message: this.ts.t('server.cleanConfirm'),
      itemName: this.ts.t('cuisine.table') + ' ' + order.table_number,
      warning: '',
      confirmLabel: this.ts.t('server.cleanTable'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open(ConfirmDialogComponent, { data, width: '440px', maxHeight: '90vh' });
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.serverService.cleanOrder(order.id).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
            this.loadTables();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
      });
    });
  }

  // ── Release without payment (override) ──
  confirmRelease(order: CuisineOrder & { ended_at?: string | null }): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('server.releaseTable'),
      message: this.ts.t('server.releaseOverrideConfirm'),
      itemName: this.ts.t('cuisine.table') + ' ' + order.table_number,
      warning: '',
      confirmLabel: this.ts.t('server.releaseOverride'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open(ConfirmDialogComponent, { data, width: '440px', maxHeight: '90vh' });
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.serverService.releaseOrder(order.id).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
            this.loadTables();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
      });
    });
  }

  // All items served but not yet paid or released
  isAwaitingPayment(order: any): boolean {
    return !order.ended_at && this.allLinesServed(order);
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

  // Commande fermée = ended_at est présent.
  // Ça arrive quand le client paie OU quand le serveur libère la table.
  // La table n'est PAS encore disponible — le serveur doit d'abord cliquer "Nettoyer la table".
  isOrderClosed(order: any): boolean {
    return !!order.ended_at;
  }

  // Commande payée par le client = ended_at présent ET server_released est false.
  // Affiche le badge bleu "Payée" sur la carte dans /serve.
  isOrderPaid(order: any): boolean {
    return !!order.ended_at && !order.server_released;
  }

  // Table libérée par le serveur (sans paiement) = server_released est true.
  // Affiche le badge orange "Libérée" sur la carte dans /serve.
  // La table devient disponible seulement après le clic sur "Nettoyer la table" (server_id → null).
  isOrderReleased(order: any): boolean {
    return !!order.server_released;
  }

  allLinesServed(order: CuisineOrder): boolean {
    return order.order_lines.length > 0 && order.order_lines.every(l => l.status === 'served');
  }

  isEmptyOrder(order: CuisineOrder & { ended_at?: string | null }): boolean {
    return !order.ended_at && order.order_lines.length === 0;
  }

  confirmCancel(order: CuisineOrder): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('server.cancelOrder'),
      message: this.ts.t('server.cancelConfirm'),
      itemName: this.ts.t('cuisine.table') + ' ' + order.table_number,
      warning: '',
      confirmLabel: this.ts.t('server.cancelOrder'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open(ConfirmDialogComponent, { data, width: '440px', maxHeight: '90vh' });
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.serverService.cancelOrder(order.id).subscribe({
        next: (res) => {
          if (res.success) {
            this.loadOrders();
            this.loadTables();
          } else {
            const msg = (res.errors as string[])?.join(', ') || this.ts.t('order.editError');
            this.snackBar.open(msg, 'OK', { duration: 5000 });
          }
        },
        error: () => this.snackBar.open(this.ts.t('order.editError'), 'OK', { duration: 5000 })
      });
    });
  }

  // ── Group orders by table (multiple clients on same table → one card) ──
  private groupOrdersByTable(orders: any[]): any[] {
    const groups = new Map<number, any>();
    for (const order of orders) {
      const key = order.table_id;
      if (!groups.has(key)) {
        groups.set(key, {
          ...order,
          nb_people: order.nb_people,
          order_lines: [...order.order_lines],
        });
      } else {
        const group = groups.get(key)!;
        group.nb_people += order.nb_people;
        group.order_lines = [...group.order_lines, ...order.order_lines];
        group.tip = (group.tip || 0) + (order.tip || 0);
        if (order.note) {
          group.note = group.note ? group.note + ' | ' + order.note : order.note;
        }
        // If any order is still open, the group is open
        if (!order.ended_at) {
          group.ended_at = null;
          group.server_released = false;
        }
        // Use earliest created_at
        if (new Date(order.created_at) < new Date(group.created_at)) {
          group.created_at = order.created_at;
        }
      }
    }
    return Array.from(groups.values());
  }

  // ── Tables with QR codes ──
  loadTables(showLoading = true): void {
    if (showLoading) this.tablesLoading = true;
    this.tablesError = null;
    this.serverService.getTables().subscribe({
      next: (res) => {
        this.tables = res.data ?? [];
        this.tablesLoading = false;
        this.cdr.detectChanges();
      },
      error: (err: any) => {
        const detail = err?.errors?.join(', ') || '';
        this.tablesError = this.ts.t('server.tablesLoadError') + (detail ? ' — ' + detail : '');
        this.tablesLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  getTableQrUrl(table: ServerTable): string {
    const base = window.location.origin.replace(/\/+$/, '');
    const userId = this.authService.getCurrentUser()?.id;
    const url = `${base}/table/${table.qr_token}`;
    return userId ? `${url}?s=${userId}` : url;
  }

  openQrDialog(table: ServerTable): void {
    const data: QrDialogData = {
      tableNumber: table.number,
      qrUrl: this.getTableQrUrl(table),
      scanInstruction: this.ts.t('server.scanInstruction')
    };
    this.dialog.open(QrDialogComponent, { data, width: '420px', maxHeight: '90vh' });
  }

  isTableAvailable(table: ServerTable): boolean {
    return table.status === 'available';
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
