import { Component, Inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { VibeService, VibeData } from '../services/vibe.service';
import { TranslationService } from '../services/translation.service';
import { ErrorService } from '../services/error.service';
import { ImageUploadComponent, ImageValidationResult } from '../shared/image-upload/image-upload.component';

export interface VibeFormDialogData {
  vibe: VibeData | null;
}

export interface VibeFormDialogResult {
  created?: VibeData;
  updated?: VibeData;
}

@Component({
  selector: 'app-vibe-form-dialog',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressSpinnerModule,
    ImageUploadComponent,
  ],
  templateUrl: './vibe-form-dialog.component.html',
  styleUrls: ['./vibe-form-dialog.component.css']
})
export class VibeFormDialogComponent {
  isCreating: boolean;

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(50), Validators.pattern(/.*\S.*/)]),
    color: new FormControl('#C87941', [Validators.required, Validators.maxLength(7), Validators.pattern(/^#[0-9A-Fa-f]{6}$/)])
  });

  image: File | null = null;
  imagePreview = signal<string | null>(null);
  error = signal('');
  loading = signal(false);

  constructor(
    private dialogRef: MatDialogRef<VibeFormDialogComponent, VibeFormDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: VibeFormDialogData,
    private vibeService: VibeService,
    public ts: TranslationService,
    private errorService: ErrorService
  ) {
    this.isCreating = data.vibe === null;

    if (data.vibe) {
      this.form.patchValue({
        name: data.vibe.name,
        color: data.vibe.color
      });
      this.imagePreview.set(data.vibe.image?.url || null);
    }
  }

  onImagesSelected(results: ImageValidationResult[]): void {
    if (results.length > 0) {
      this.image = results[0].file;
      this.imagePreview.set(results[0].preview);
    }
  }

  save(): void {
    Object.values(this.form.controls).forEach(c => c.markAsDirty());

    if (this.form.invalid) return;

    this.loading.set(true);
    this.error.set('');

    const v = this.form.value;

    if (this.isCreating) {
      const createData: { name: string; color: string; image?: File } = {
        name: v.name!,
        color: v.color!
      };
      if (this.image) createData.image = this.image;

      this.vibeService.createVibe(createData).subscribe({
        next: (res) => {
          this.loading.set(false);
          if (res.success && res.data) {
            this.dialogRef.close({ created: res.data });
          } else {
            this.error.set((res.errors || []).join(', '));
          }
        },
        error: (err) => {
          this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.loading.set(false);
        }
      });
    } else {
      const updateData: { name: string; color: string; image?: File } = {
        name: v.name!,
        color: v.color!
      };
      if (this.image) updateData.image = this.image;

      this.vibeService.updateVibe(this.data.vibe!.id, updateData).subscribe({
        next: (res) => {
          this.loading.set(false);
          if (res.success && res.data) {
            this.dialogRef.close({ updated: res.data });
          } else {
            this.error.set((res.errors || []).join(', '));
          }
        },
        error: (err) => {
          this.error.set(this.errorService.format(this.errorService.fromApiError(err)));
          this.loading.set(false);
        }
      });
    }
  }
}
