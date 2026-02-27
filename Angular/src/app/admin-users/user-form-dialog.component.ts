import { Component, Inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { TranslationService } from '../services/translation.service';
import { UserInfo } from './user.model';

export interface UserFormDialogData {
  mode: 'create' | 'edit';
  user?: UserInfo;
}

export interface UserFormDialogResult {
  data: Record<string, any>;
}

@Component({
  selector: 'app-user-form-dialog',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule, MatDialogModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatButtonModule, MatIconModule
  ],
  template: `
    <h2 mat-dialog-title class="dialog-title">
      {{ data.mode === 'create' ? ts.t('admin.users.add') : ts.t('admin.users.edit') }}
    </h2>

    <mat-dialog-content>
      @if (serverError) {
        <div class="dialog-error">{{ serverError }}</div>
      }

      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.firstName') }}</mat-label>
          <input matInput formControlName="first_name" />
          @if (fc.first_name.dirty && fc.first_name.errors) {
            <mat-error>
              @if (fc.first_name.errors['required']) {
                {{ ts.t('admin.users.firstNameRequired') }}
              } @else if (fc.first_name.errors['maxlength']) {
                {{ ts.t('admin.users.firstNameMaxLength') }}
              } @else if (fc.first_name.errors['pattern']) {
                {{ ts.t('admin.users.firstNameWhitespace') }}
              }
            </mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.lastName') }}</mat-label>
          <input matInput formControlName="last_name" />
          @if (fc.last_name.dirty && fc.last_name.errors) {
            <mat-error>
              @if (fc.last_name.errors['required']) {
                {{ ts.t('admin.users.lastNameRequired') }}
              } @else if (fc.last_name.errors['maxlength']) {
                {{ ts.t('admin.users.lastNameMaxLength') }}
              } @else if (fc.last_name.errors['pattern']) {
                {{ ts.t('admin.users.lastNameWhitespace') }}
              }
            </mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.email') }}</mat-label>
          <input matInput formControlName="email" type="email" />
          @if (fc.email.dirty && fc.email.errors) {
            <mat-error>
              @if (fc.email.errors['required']) {
                {{ ts.t('admin.users.emailRequired') }}
              } @else if (fc.email.errors['email']) {
                {{ ts.t('admin.users.emailInvalid') }}
              }
            </mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.typeLabel') }}</mat-label>
          <mat-select formControlName="type">
            @for (t of typeOptions; track t) {
              <mat-option [value]="t">{{ ts.t('admin.users.type.' + t) }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.statusLabel') }}</mat-label>
          <mat-select formControlName="status">
            @for (s of userStatuses; track s) {
              <mat-option [value]="s">{{ ts.t('admin.users.status.' + s) }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        @if (fc.status.value === 'blocked') {
          <mat-form-field appearance="outline" class="field-full">
            <mat-label>{{ ts.t('admin.users.blockNote') }}</mat-label>
            <input matInput formControlName="block_note" />
          </mat-form-field>
        }

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.password') }}</mat-label>
          <input matInput formControlName="password" type="password" />
          @if (fc.password.dirty && fc.password.errors) {
            <mat-error>
              @if (fc.password.errors['required']) {
                {{ ts.t('admin.users.passwordRequired') }}
              } @else if (fc.password.errors['minlength']) {
                {{ ts.t('admin.users.passwordMinLength') }}
              } @else if (fc.password.errors['maxlength']) {
                {{ ts.t('admin.users.passwordMaxLength') }}
              }
            </mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="field-full">
          <mat-label>{{ ts.t('admin.users.passwordConfirmation') }}</mat-label>
          <input matInput formControlName="password_confirmation" type="password" />
          @if (fc.passwordConfirmation.dirty && fc.passwordConfirmation.errors) {
            <mat-error>
              @if (fc.passwordConfirmation.errors['required']) {
                {{ ts.t('admin.users.passwordConfirmationRequired') }}
              } @else if (fc.passwordConfirmation.errors['minlength']) {
                {{ ts.t('admin.users.passwordMinLength') }}
              } @else if (fc.passwordConfirmation.errors['maxlength']) {
                {{ ts.t('admin.users.passwordMaxLength') }}
              } @else if (fc.passwordConfirmation.errors['passwordMismatch']) {
                {{ ts.t('admin.users.passwordMismatch') }}
              }
            </mat-error>
          }
        </mat-form-field>
      </form>
    </mat-dialog-content>

    <mat-dialog-actions align="end">
      <button mat-stroked-button class="btn-cancel" (click)="onCancel()">{{ ts.t('admin.cancel') }}</button>
      <button mat-flat-button class="btn-primary" (click)="onSubmit()" [disabled]="isLoading">
        {{ isLoading ? ts.t('admin.saving') : (data.mode === 'create' ? ts.t('admin.add') : ts.t('admin.save')) }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    :host {
      display: block;
      font-family: "Space Grotesk", "Segoe UI", sans-serif;
    }

    .dialog-title {
      font-family: "Fraunces", "Times New Roman", serif;
      font-size: 1.25rem;
      color: #1b1a17;
      margin: 0 0 0.25rem 0;
    }

    .dialog-error {
      background: rgba(220, 53, 69, 0.1);
      color: #dc3545;
      padding: 0.5rem 0.75rem;
      border-radius: 8px;
      font-size: 0.85rem;
      margin-bottom: 1rem;
    }

    .field-full {
      width: 100%;
      margin-bottom: 0.15rem;
    }

    /* ── Buttons ── */
    .btn-cancel {
      border-radius: 10px !important;
      color: #1b1a17 !important;
      border-color: rgba(27, 26, 23, 0.15) !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }

    .btn-cancel:hover {
      background: rgba(27, 26, 23, 0.04) !important;
    }

    .btn-primary {
      border-radius: 10px !important;
      background: #c86d3f !important;
      color: #fff !important;
      font-family: "Space Grotesk", "Segoe UI", sans-serif !important;
    }

    .btn-primary:hover {
      opacity: 0.9;
    }

    .btn-primary:disabled {
      opacity: 0.5 !important;
      cursor: not-allowed;
    }

    /* ── Dialog layout ── */
    ::ng-deep .mat-mdc-dialog-content {
      max-height: 65vh;
      padding-top: 0.75rem !important;
    }

    ::ng-deep .mat-mdc-dialog-actions {
      padding: 0.75rem 1.5rem 1rem !important;
    }

    /* ── Focused outline ── */
    ::ng-deep .mat-mdc-form-field.mat-focused .mdc-notched-outline__leading,
    ::ng-deep .mat-mdc-form-field.mat-focused .mdc-notched-outline__notch,
    ::ng-deep .mat-mdc-form-field.mat-focused .mdc-notched-outline__trailing {
      border-color: rgba(27, 26, 23, 0.25) !important;
      border-width: 1px !important;
    }

    ::ng-deep .mat-mdc-form-field.mat-focused .mat-mdc-floating-label {
      color: rgba(27, 26, 23, 0.6) !important;
    }
  `]
})
export class UserFormDialogComponent implements OnInit {
  form!: FormGroup;
  serverError = '';
  isLoading = false;

  employeeTypes = ['Administrator', 'Waiter', 'Cook'];
  allTypes = ['Administrator', 'Waiter', 'Client', 'Cook'];
  userStatuses = ['active', 'inactive', 'blocked'];

  get fc() {
    return {
      first_name: this.form.get('first_name')!,
      last_name: this.form.get('last_name')!,
      email: this.form.get('email')!,
      type: this.form.get('type')!,
      status: this.form.get('status')!,
      block_note: this.form.get('block_note')!,
      password: this.form.get('password')!,
      passwordConfirmation: this.form.get('password_confirmation')!
    };
  }

  get typeOptions(): string[] {
    return this.data.mode === 'create' ? this.employeeTypes : this.allTypes;
  }

  constructor(
    public dialogRef: MatDialogRef<UserFormDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: UserFormDialogData,
    public ts: TranslationService
  ) {}

  ngOnInit(): void {
    const isCreate = this.data.mode === 'create';
    const user = this.data.user;

    this.form = new FormGroup({
      first_name: new FormControl(user?.first_name ?? '', [Validators.required, Validators.maxLength(50), Validators.pattern(/.*\S.*/)]),
      last_name: new FormControl(user?.last_name ?? '', [Validators.required, Validators.maxLength(50), Validators.pattern(/.*\S.*/)]),
      email: new FormControl(user?.email ?? '', [Validators.required, Validators.email]),
      type: new FormControl(user?.type ?? 'Waiter', [Validators.required]),
      status: new FormControl(user?.status ?? 'active', [Validators.required]),
      block_note: new FormControl(user?.block_note ?? ''),
      password: new FormControl('', isCreate
        ? [Validators.required, Validators.minLength(6), Validators.maxLength(128)]
        : [Validators.minLength(6), Validators.maxLength(128)]
      ),
      password_confirmation: new FormControl('', isCreate
        ? [Validators.required, Validators.minLength(6), Validators.maxLength(128)]
        : [Validators.minLength(6), Validators.maxLength(128)]
      )
    });

    // Clear mismatch error when either password field changes
    this.form.get('password')!.valueChanges.subscribe(() => this.clearMismatchError());
    this.form.get('password_confirmation')!.valueChanges.subscribe(() => this.clearMismatchError());
  }

  private clearMismatchError(): void {
    const conf = this.form.get('password_confirmation')!;
    if (conf.hasError('passwordMismatch')) {
      const errors = { ...conf.errors };
      delete errors['passwordMismatch'];
      conf.setErrors(Object.keys(errors).length ? errors : null);
    }
  }

  onSubmit(): void {
    // Mark all controls dirty so mat-error shows
    Object.values(this.form.controls).forEach(c => c.markAsDirty());

    // Check password mismatch and set error directly on the control
    const pw = this.form.get('password')!.value;
    const conf = this.form.get('password_confirmation')!;
    if (pw && pw !== conf.value) {
      conf.setErrors({ ...(conf.errors || {}), passwordMismatch: true });
      conf.markAsDirty();
    }

    if (this.form.invalid) return;

    const v = this.form.value;
    const result: Record<string, any> = {
      first_name: v.first_name,
      last_name: v.last_name,
      email: v.email,
      type: v.type,
      status: v.status,
      block_note: v.status === 'blocked' ? v.block_note : null
    };

    if (v.password) {
      result['password'] = v.password;
      result['password_confirmation'] = v.password_confirmation;
    }

    this.dialogRef.close({ data: result } as UserFormDialogResult);
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  setServerError(error: string): void {
    this.serverError = error;
    this.isLoading = false;
  }
}
