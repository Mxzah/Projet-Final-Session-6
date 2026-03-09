import { Component, Inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { provideNativeDateAdapter } from '@angular/material/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { ApiService } from '../../services/api.service';

export interface StatsColumn {
  key: string;
  label: string;
}

export interface StatsReportDialogData {
  endpoint: string;
  dialogTitle: string;
  categories: { id: number; name: string }[];
  categoryLabel?: string;
  expandable?: boolean;
}

interface DetailOrderLine {
  name: string;
  quantity: number;
  unit_price: number;
  total: number;
  status: string;
  note: string | null;
}

interface DetailOrder {
  id: number;
  created_at: string;
  ended_at: string | null;
  nb_people: number;
  tip: number;
  revenue: number;
  vibe_name: string;
  server_name: string;
  note: string | null;
  order_lines: DetailOrderLine[];
}

interface TableDetail {
  table_id: number;
  table_number: number;
  orders: DetailOrder[];
}

interface StatsResponse {
  columns: StatsColumn[];
  rows: Record<string, any>[];
  details?: TableDetail[];
}

@Component({
  selector: 'app-stats-report-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatDialogModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatDatepickerModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule
  ],
  providers: [provideNativeDateAdapter()],
  templateUrl: './stats-report-dialog.component.html',
  styleUrls: ['./stats-report-dialog.component.css']
})
export class StatsReportDialogComponent implements OnInit {
  columns = signal<StatsColumn[]>([]);
  rows = signal<Record<string, any>[]>([]);
  displayedColumns = computed(() => this.columns().map(c => c.key));
  isLoading = signal(true);
  loadError = signal('');

  details = signal<TableDetail[]>([]);
  expandedRowKey = signal<string | null>(null);
  expandedOrderIds = signal<Set<number>>(new Set());

  startDate: Date | null = null;
  endDate: Date | null = null;
  selectedCategoryIds: number[] = [];

  constructor(
    @Inject(MAT_DIALOG_DATA) public data: StatsReportDialogData,
    private apiService: ApiService
  ) {}

  ngOnInit(): void {
    this.loadStats();
  }

  onStartDate(event: any): void {
    this.startDate = event.value;
    this.loadStats();
  }

  onEndDate(event: any): void {
    this.endDate = event.value;
    this.loadStats();
  }

  onCategoryChange(event: any): void {
    this.selectedCategoryIds = event.value;
    this.loadStats();
  }

  getRowKey(row: Record<string, any>): string {
    return `${row['table_number']}__${row['vibe_name']}__${row['server_name']}`;
  }

  toggleTableDetail(row: Record<string, any>): void {
    if (!this.data.expandable) return;
    const key = this.getRowKey(row);
    if (this.expandedRowKey() === key) {
      this.expandedRowKey.set(null);
      this.expandedOrderIds.set(new Set());
    } else {
      this.expandedRowKey.set(key);
      this.expandedOrderIds.set(new Set());
    }
  }

  toggleOrder(event: Event, orderId: number): void {
    event.stopPropagation();
    const current = new Set(this.expandedOrderIds());
    if (current.has(orderId)) {
      current.delete(orderId);
    } else {
      current.add(orderId);
    }
    this.expandedOrderIds.set(current);
  }

  isTableExpanded(row: Record<string, any>): boolean {
    return this.expandedRowKey() === this.getRowKey(row);
  }

  isOrderExpanded(orderId: number): boolean {
    return this.expandedOrderIds().has(orderId);
  }

  getOrdersForRow(row: Record<string, any>): DetailOrder[] {
    const detail = this.details().find(d => d.table_number == row['table_number']);
    if (!detail) return [];
    return detail.orders.filter(o =>
      o.vibe_name === (row['vibe_name'] ?? '—') &&
      o.server_name === (row['server_name'] ?? '—')
    );
  }

  formatDateTime(dateStr: string): string {
    const d = new Date(dateStr);
    return d.toLocaleString('fr-CA', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  }

  getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      waiting: 'En attente', sent: 'Envoyé', in_preparation: 'En préparation',
      ready: 'Prêt', served: 'Servi'
    };
    return map[status] ?? status;
  }

  loadStats(): void {
    this.isLoading.set(true);
    this.loadError.set('');
    this.expandedRowKey.set(null);
    this.expandedOrderIds.set(new Set());

    const params: Record<string, string> = {};
    if (this.startDate) {
      params['start_date'] = this.formatDate(this.startDate);
    }
    if (this.endDate) {
      params['end_date'] = this.formatDate(this.endDate);
    }

    // Build endpoint with query params (supports array params for category_ids)
    let url = this.data.endpoint;
    const parts: string[] = [];
    for (const [key, value] of Object.entries(params)) {
      parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
    }
    for (const id of this.selectedCategoryIds) {
      parts.push(`category_ids[]=${encodeURIComponent(id)}`);
    }
    if (parts.length > 0) {
      url += '?' + parts.join('&');
    }

    this.apiService.get<StatsResponse>(url).subscribe({
      next: (response) => {
        if (response.data) {
          this.columns.set(response.data.columns);
          this.rows.set(response.data.rows);
          this.details.set(response.data.details ?? []);
        }
        this.isLoading.set(false);
      },
      error: () => {
        this.loadError.set('Erreur lors du chargement des statistiques.');
        this.isLoading.set(false);
      }
    });
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}
