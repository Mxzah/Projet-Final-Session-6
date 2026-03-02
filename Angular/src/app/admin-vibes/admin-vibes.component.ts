import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { VibeService, VibeData } from '../services/vibe.service';
import { TranslationService } from '../services/translation.service';
import { VibeFormDialogComponent, VibeFormDialogData, VibeFormDialogResult } from './vibe-form-dialog.component';
import { ConfirmDialogComponent, ConfirmDialogData } from '../admin-items/confirm-dialog.component';

@Component({
  selector: 'app-admin-vibes',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
  ],
  templateUrl: './admin-vibes.component.html',
  styleUrls: ['./admin-vibes.component.css']
})
export class AdminVibesComponent implements OnInit {
  vibes = signal<VibeData[]>([]);
  isLoading = signal(true);
  actionError = signal('');

  constructor(
    private vibeService: VibeService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    public ts: TranslationService
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading.set(true);
    this.vibeService.getVibes().subscribe({
      next: (res) => {
        this.vibes.set(res.data || []);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  openCreate(): void {
    const data: VibeFormDialogData = { vibe: null };
    const ref = this.dialog.open<VibeFormDialogComponent, VibeFormDialogData, VibeFormDialogResult>(
      VibeFormDialogComponent,
      { data, width: '480px', maxWidth: '95vw', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(result => {
      if (result?.created) {
        this.vibes.update(v => [...v, result.created!]);
      }
    });
  }

  openEdit(vibe: VibeData): void {
    const data: VibeFormDialogData = { vibe };
    const ref = this.dialog.open<VibeFormDialogComponent, VibeFormDialogData, VibeFormDialogResult>(
      VibeFormDialogComponent,
      { data, width: '480px', maxWidth: '95vw', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(result => {
      if (result?.updated) {
        this.vibes.update(v => v.map(x => x.id === vibe.id ? result.updated! : x));
      }
    });
  }

  confirmDelete(vibe: VibeData): void {
    const isInUse = vibe.in_use;
    const data: ConfirmDialogData = {
      title: isInUse ? this.ts.t('admin.vibes.archive') : this.ts.t('admin.vibes.deleteVibe'),
      message: isInUse ? this.ts.t('admin.vibes.archiveConfirm') : this.ts.t('admin.vibes.deleteConfirm'),
      itemName: vibe.name,
      warning: isInUse ? this.ts.t('admin.vibes.archiveWarning') : undefined,
      confirmLabel: isInUse ? this.ts.t('admin.vibes.archive') : this.ts.t('admin.delete'),
      confirmClass: 'btn-danger'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.vibeService.deleteVibe(vibe.id).subscribe({
        next: (res) => {
          if (res.success) {
            if (res.data?.deleted_at) {
              this.vibes.update(v => v.map(x => x.id === vibe.id ? res.data! : x));
            } else {
              this.vibes.update(v => v.filter(x => x.id !== vibe.id));
            }
            this.snackBar.open(this.ts.t('admin.vibes.deleted'), '', { duration: 3000 });
          }
        },
        error: () => {
          this.snackBar.open(this.ts.t('admin.vibes.error'), '', { duration: 4000 });
        }
      });
    });
  }

  confirmRestore(vibe: VibeData): void {
    const data: ConfirmDialogData = {
      title: this.ts.t('admin.vibes.restoreVibe'),
      message: this.ts.t('admin.vibes.restoreConfirm'),
      itemName: vibe.name,
      confirmLabel: this.ts.t('admin.restoreBtn'),
      confirmClass: 'btn-restore'
    };
    const ref = this.dialog.open<ConfirmDialogComponent, ConfirmDialogData, boolean>(
      ConfirmDialogComponent,
      { data, width: '400px', maxHeight: '90vh' }
    );
    ref.afterClosed().subscribe(confirmed => {
      if (!confirmed) return;
      this.vibeService.restoreVibe(vibe.id).subscribe({
        next: (res) => {
          if (res.success && res.data) {
            this.vibes.update(v => v.map(x => x.id === vibe.id ? res.data! : x));
            this.snackBar.open(this.ts.t('admin.vibes.restored'), '', { duration: 3000 });
          }
        },
        error: () => {
          this.snackBar.open(this.ts.t('admin.vibes.error'), '', { duration: 4000 });
        }
      });
    });
  }
}
