import { Component, Input, Output, EventEmitter, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { ErrorService } from '../../services/error.service';
import { TranslationService } from '../../services/translation.service';

export interface ImageValidationResult {
  file: File;
  preview: string;
}

@Component({
  selector: 'app-image-upload',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatFormFieldModule],
  templateUrl: './image-upload.component.html',
  styleUrls: ['./image-upload.component.css']
})
export class ImageUploadComponent {
  @Input() previews: string[] = [];
  @Input() multiple = false;
  @Output() imagesSelected = new EventEmitter<ImageValidationResult[]>();

  error = signal('');

  private readonly validTypes = ['image/jpeg', 'image/png'];
  private readonly maxSize = 5 * 1024 * 1024;

  constructor(
    private errorService: ErrorService,
    public ts: TranslationService
  ) {}

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = input.files;
    if (!files || files.length === 0) return;

    const results: ImageValidationResult[] = [];
    let remaining = files.length;

    for (let i = 0; i < files.length; i++) {
      const file = files[i];

      if (!this.validTypes.includes(file.type)) {
        this.error.set(this.errorService.format(this.errorService.imageError('format', this.ts)));
        input.value = '';
        return;
      }

      if (file.size > this.maxSize) {
        this.error.set(this.errorService.format(this.errorService.imageError('size', this.ts)));
        input.value = '';
        return;
      }

      const reader = new FileReader();
      reader.onload = () => {
        results.push({ file, preview: reader.result as string });
        remaining--;
        if (remaining === 0) {
          this.error.set('');
          this.imagesSelected.emit(results);
        }
      };
      reader.readAsDataURL(file);
    }
  }

  setError(message: string): void {
    this.error.set(message);
  }

  hasError(): boolean {
    return this.error() !== '';
  }
}
