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
import { ApiService } from '../../services/api.service';

export interface StatsColumn {
  key: string;
  label: string;
}

export interface StatsReportDialogData {
  endpoint: string;
  dialogTitle: string;
  categories: { id: number; name: string }[];
}

interface StatsResponse {
  columns: StatsColumn[];
  rows: Record<string, any>[];
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
    MatSelectModule
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

  loadStats(): void {
    this.isLoading.set(true);
    this.loadError.set('');

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
