import { Component, Inject } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { CommonModule } from '@angular/common';
import { TranslationService } from '../services/translation.service';

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
  constructor(
    public dialogRef: MatDialogRef<ConfirmDialogComponent, boolean>,
    @Inject(MAT_DIALOG_DATA) public data: ConfirmDialogData
  ) {}

  confirm(): void {
    this.dialogRef.close(true);
  }
}

/* ── Edit Order Line Dialog ── */

export interface EditOrderLineDialogData {
  itemName: string;
  quantity: number;
  note: string;
}

export interface EditOrderLineDialogResult {
  quantity: number;
  note: string;
}

@Component({
  selector: 'app-edit-order-line-dialog',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule
  ],
  templateUrl: './edit-order-line-dialog.component.html',
  styleUrls: ['./edit-order-line-dialog.component.css']
})
export class EditOrderLineDialogComponent {
  form: FormGroup;

  constructor(
    public dialogRef: MatDialogRef<EditOrderLineDialogComponent, EditOrderLineDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: EditOrderLineDialogData,
    public ts: TranslationService
  ) {
    this.form = new FormGroup({
      quantity: new FormControl(data.quantity, [
        Validators.required,
        Validators.min(1),
        Validators.max(50)
      ]),
      note: new FormControl(data.note || '', [
        Validators.maxLength(255)
      ])
    });
  }

  save(): void {
    if (this.form.invalid) return;
    this.dialogRef.close({
      quantity: this.form.value.quantity,
      note: this.form.value.note ?? ''
    });
  }
}
