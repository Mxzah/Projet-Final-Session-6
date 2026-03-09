import { Component, Inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ApiService, ApiResponse } from '../../services/api.service';
import { StatCardComponent } from '../stat-card/stat-card.component';

export interface StatsReportDialogData {
  endpoint: string;
  dialogTitle: string;
}

export interface StatEntry {
  title: string;
  value: string | number;
}

@Component({
  selector: 'app-stats-report-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    StatCardComponent
  ],
  templateUrl: './stats-report-dialog.component.html',
  styleUrls: ['./stats-report-dialog.component.css']
})
export class StatsReportDialogComponent implements OnInit {
  stats = signal<StatEntry[]>([]);
  isLoading = signal(true);
  loadError = signal('');

  constructor(
    @Inject(MAT_DIALOG_DATA) public data: StatsReportDialogData,
    private apiService: ApiService
  ) {}

  ngOnInit(): void {
    this.apiService.get<StatEntry[]>(this.data.endpoint).subscribe({
      next: (response) => {
        if (response.data) {
          this.stats.set(response.data);
        }
        this.isLoading.set(false);
      },
      error: () => {
        this.loadError.set('Erreur lors du chargement des statistiques.');
        this.isLoading.set(false);
      }
    });
  }
}
