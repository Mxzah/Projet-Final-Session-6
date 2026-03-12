import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { TableService, TableData } from '../../services/table.service';
import { AuthService } from '../../services/auth.service';
import { HeaderComponent } from '../../header/header.component';
import { OrderService, VibeData } from '../../services/order.service';
import { TranslationService } from '../../services/translation.service';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  selector: 'app-table-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    HeaderComponent,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './table-form.component.html',
  styleUrls: ['./table-form.component.css']
})
export class TableFormComponent implements OnInit {
  table: TableData | null = null;
  noTable = false;
  tableUnavailable = false;
  vibes: VibeData[] = [];
  vibesLoading = true;
  isSubmitting = signal(false);
  apiError = signal<string | null>(null);
  hasOpenOrder = signal(false);
  openOrderInfo = signal<{ table_number: number; nb_people: number; vibe_name: string | null; vibe_color: string | null } | null>(null);
  openOrderLoading = signal(false);
  form!: FormGroup;

  constructor(
    private tableService: TableService,
    private authService: AuthService,
    private orderService: OrderService,
    public ts: TranslationService,
    private router: Router,
    private route: ActivatedRoute
  ) { }

  ngOnInit(): void {
    this.table = this.tableService.getCurrentTable();
    if (!this.table) {
      this.noTable = true;
      return;
    }

    // Check if table has an active availability
    const now = new Date();
    const avails = this.table.availabilities ?? [];
    const hasActive = avails.some(a => {
      const start = new Date(a.start_at);
      const end = a.end_at ? new Date(a.end_at) : null;
      return start <= now && (!end || end > now);
    });
    if (!hasActive) {
      this.tableUnavailable = true;
      return;
    }

    // If login told us the user already has an open order, show that right away
    if (this.route.snapshot.queryParamMap.get('open') === '1') {
      this.hasOpenOrder.set(true);
      this.loadOpenOrderInfo();
      return;
    }

    this.form = new FormGroup({
      guestCount: new FormControl<number | null>(null, [
        Validators.required,
        Validators.min(1),
        Validators.max(this.table.capacity)
      ]),
      vibeId: new FormControl<number | null>(null)
    });

    this.loadVibes();
  }

  private loadVibes(): void {
    this.orderService.getVibes().subscribe({
      next: (res) => {
        this.vibes = (res.data || []).filter(v => !v.deleted_at);
        this.vibesLoading = false;
      },
      error: () => {
        this.vibesLoading = false;
      }
    });
  }

  get guestCtrl() { return this.form.get('guestCount')!; }
  get vibeCtrl() { return this.form.get('vibeId')!; }

  getSelectedVibe(): VibeData | null {
    return this.vibes.find(v => v.id === this.vibeCtrl.value) ?? null;
  }

  goToMenu(): void {
    if (this.form.invalid || this.isSubmitting()) return;

    const { guestCount, vibeId } = this.form.value;
    const table = this.table!;

    this.isSubmitting.set(true);
    this.apiError.set(null);

    // Check for server_id from QR code scan
    const pendingServerId = this.tableService.getPendingServerId();
    const serverIdNum = pendingServerId ? parseInt(pendingServerId, 10) : null;
    this.tableService.clearPendingServerId();

    this.orderService.createOrder({
      nb_people: guestCount!,
      note: '',
      table_id: table.id,
      vibe_id: vibeId ?? null,
      server_id: serverIdNum
    }).subscribe({
      next: () => {
        this.router.navigate(['/menu']);
      },
      error: (err: any) => {
        const messages: string[] = err?.errors ?? [];
        const joined = messages.join(' ').toLowerCase();
        const isOpenOrder = joined.includes('open order') || joined.includes('commande ouverte');
        this.hasOpenOrder.set(isOpenOrder);
        this.apiError.set(isOpenOrder ? this.ts.t('form.alreadyOpenOrder') : (messages.length ? messages.join(' ') : this.ts.t('form.createError')));
        this.isSubmitting.set(false);
      }
    });
  }

  private loadOpenOrderInfo(): void {
    this.openOrderLoading.set(true);
    this.orderService.getOrders().subscribe({
      next: (res) => {
        const open = (res.data || []).find(o => !o.ended_at);
        if (open) {
          this.openOrderInfo.set({
            table_number: open.table_number,
            nb_people: open.nb_people,
            vibe_name: open.vibe_name,
            vibe_color: open.vibe_color
          });
        }
        this.openOrderLoading.set(false);
      },
      error: () => this.openOrderLoading.set(false)
    });
  }

  goToOrder(): void {
    this.router.navigate(['/menu']);
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        this.tableService.clearTable();
        this.router.navigate(['/login']);
      },
      error: () => {
        this.tableService.clearTable();
        this.router.navigate(['/login']);
      }
    });
  }
}
