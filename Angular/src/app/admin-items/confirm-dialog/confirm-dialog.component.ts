import { Component, inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { TranslationService } from '../../services/translation.service';

export interface ConfirmDialogData {
  title: string;
  message: string;
  itemName: string;
  warning?: string;
  confirmLabel: string;
  confirmClass: 'btn-danger' | 'btn-restore';
}

@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule, MatIconModule],
  templateUrl: './confirm-dialog.component.html',
  styleUrls: ['./confirm-dialog.component.css']
})
export class ConfirmDialogComponent {
  dialogRef = inject(MatDialogRef<ConfirmDialogComponent, boolean>);
  data = inject<ConfirmDialogData>(MAT_DIALOG_DATA);
  ts = inject(TranslationService);

  confirm(): void {
    this.dialogRef.close(true);
  }
}
