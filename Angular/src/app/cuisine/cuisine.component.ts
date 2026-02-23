import { Component, OnInit, ChangeDetectorRef, signal } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { CuisineService, CuisineOrder, CuisineOrderLine } from '../services/cuisine.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { TranslationService } from '../services/translation.service';

@Component({
  selector: 'app-cuisine',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatCardModule,
    MatChipsModule,
    MatIconModule,
    MatButtonModule,
    MatDividerModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatInputModule,
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

  // Tracks which lines are currently advancing status (to show loading state)
  advancingLineIds = new Set<number>();

  // Edit order line modal (waiter/admin only - quantity and note)
  editingLine = signal<CuisineOrderLine | null>(null);
  editLineForm = new FormGroup({
    quantity: new FormControl<number>(1, [Validators.required, Validators.min(1), Validators.max(50)]),
    note: new FormControl('', [Validators.maxLength(255)])
  });
  editLineError = signal('');
  editLineLoading = signal(false);

  // Delete order line modal (waiter/admin only)
  lineToDelete = signal<CuisineOrderLine | null>(null);

  constructor(
    public ts: TranslationService,
    private cuisineService: CuisineService,
    public authService: AuthService,
    private router: Router,
    private location: Location,
    private cdr: ChangeDetectorRef
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

  // Returns true for waiter and admin (can edit/delete)
  canManageLines(): boolean {
    return this.authService.isAdmin() || this.authService.isWaiter();
  }

  // Returns the next status, or null if already at the last
  getNextStatus(status: string): string | null {
    const idx = this.statuses.indexOf(status);
    if (idx === -1 || idx === this.statuses.length - 1) return null;
    return this.statuses[idx + 1];
  }

  // One-click: advance line to next status
  advanceStatus(line: CuisineOrderLine): void {
    if (this.advancingLineIds.has(line.id)) return;
    this.advancingLineIds.add(line.id);

    this.cuisineService.nextStatus(line.id).subscribe({
      next: () => {
        this.advancingLineIds.delete(line.id);
        this.loadOrders();
      },
      error: () => {
        this.advancingLineIds.delete(line.id);
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

  // ── Edit order line (waiter/admin) ──

  openEditLine(line: CuisineOrderLine): void {
    this.editingLine.set(line);
    this.editLineForm.patchValue({
      quantity: line.quantity,
      note: line.note || ''
    });
    this.editLineForm.markAsPristine();
    this.editLineForm.markAsUntouched();
    this.editLineError.set('');
  }

  cancelEditLine(): void {
    this.editingLine.set(null);
    this.editLineError.set('');
  }

  saveEditLine(): void {
    const line = this.editingLine();
    if (!line) return;

    Object.values(this.editLineForm.controls).forEach(c => c.markAsDirty());
    if (this.editLineForm.invalid) return;

    const v = this.editLineForm.value;
    this.editLineLoading.set(true);
    this.editLineError.set('');

    this.cuisineService.updateOrderLine(line.id, {
      quantity: v.quantity!,
      note: v.note ?? ''
    }).subscribe({
      next: (res) => {
        this.editLineLoading.set(false);
        if (res.success) {
          this.editingLine.set(null);
          this.loadOrders();
        } else {
          this.editLineError.set(res.errors?.[0] ?? 'Error');
        }
      },
      error: () => {
        this.editLineLoading.set(false);
        this.editLineError.set(this.ts.t('order.editError'));
      }
    });
  }

  // ── Delete order line (waiter/admin) ──

  confirmDeleteLine(line: CuisineOrderLine): void {
    this.lineToDelete.set(line);
  }

  cancelDeleteLine(): void {
    this.lineToDelete.set(null);
  }

  deleteLine(): void {
    const line = this.lineToDelete();
    if (!line) return;

    this.cuisineService.deleteOrderLine(line.id).subscribe({
      next: () => {
        this.lineToDelete.set(null);
        this.loadOrders();
      },
      error: () => {
        this.lineToDelete.set(null);
      }
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
