import { Component, OnInit, signal, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { UserService } from '../services/user.service';
import { UserInfo } from './user.model';
import { TranslationService } from '../services/translation.service';

function notOnlyWhitespace(control: AbstractControl): ValidationErrors | null {
  if (control.value && /^\s*$/.test(control.value)) {
    return { whitespace: true };
  }
  return null;
}

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule,
    MatCardModule, MatButtonModule, MatIconModule,
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './admin-users.component.html',
  styleUrls: ['./admin-users.component.css']
})
export class AdminUsersComponent implements OnInit {
  users = signal<UserInfo[]>([]);
  isLoading = signal(true);

  // Filters
  searchTerm = signal('');
  filterStatus = signal('all');
  filterType = signal('all');
  sortOrder = signal('none');

  // Delete
  userToDelete = signal<UserInfo | null>(null);

  // Create
  isCreating = signal(false);

  // Edit
  editingUser = signal<UserInfo | null>(null);
  editForm = new FormGroup({
    first_name: new FormControl('', [Validators.required, Validators.maxLength(50), notOnlyWhitespace]),
    last_name: new FormControl('', [Validators.required, Validators.maxLength(50), notOnlyWhitespace]),
    email: new FormControl('', [Validators.required, Validators.email]),
    type: new FormControl('Client', [Validators.required]),
    status: new FormControl('active', [Validators.required]),
    password: new FormControl('', [Validators.minLength(6), Validators.maxLength(128)]),
    password_confirmation: new FormControl('', [Validators.minLength(6), Validators.maxLength(128)])
  });
  editError = signal('');
  editLoading = signal(false);

  userTypes = ['Administrator', 'Waiter', 'Client', 'Cook'];
  userStatuses = ['active', 'inactive', 'blocked'];

  constructor(
    private userService: UserService,
    public ts: TranslationService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading.set(true);
    const filters: Record<string, string> = {};
    if (this.searchTerm()) filters['search'] = this.searchTerm();
    if (this.filterStatus() !== 'all') filters['status'] = this.filterStatus();
    if (this.filterType() !== 'all') filters['type'] = this.filterType();
    if (this.sortOrder() === 'asc' || this.sortOrder() === 'desc') {
      filters['sort'] = this.sortOrder();
      filters['sort_by'] = 'last_name';
    }

    this.userService.getUsers(filters).subscribe({
      next: (users) => {
        this.users.set(users);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  onSearchChange(event: Event): void {
    this.searchTerm.set((event.target as HTMLInputElement).value);
    this.loadData();
  }

  onFilterStatusChange(value: string): void {
    this.filterStatus.set(value);
    this.loadData();
  }

  onFilterTypeChange(value: string): void {
    this.filterType.set(value);
    this.loadData();
  }

  onSortChange(value: string): void {
    this.sortOrder.set(value);
    this.loadData();
  }

  // ── Status toggle ──

  toggleStatus(user: UserInfo): void {
    const newStatus = user.status === 'active' ? 'blocked' : 'active';
    this.userService.updateUser(user.id, { status: newStatus }).subscribe({
      next: (updated) => {
        this.users.update(users => users.map(u => u.id === user.id ? updated : u));
      }
    });
  }

  // ── Delete ──

  confirmDelete(user: UserInfo): void {
    this.userToDelete.set(user);
  }

  cancelDelete(): void {
    this.userToDelete.set(null);
  }

  deleteUser(): void {
    const user = this.userToDelete();
    if (!user) return;

    this.userService.deleteUser(user.id).subscribe({
      next: () => {
        this.users.update(users => users.filter(u => u.id !== user.id));
        this.userToDelete.set(null);
      },
      error: () => {
        this.userToDelete.set(null);
      }
    });
  }

  // ── Create ──

  openCreate(): void {
    this.isCreating.set(true);
    this.editForm.reset({ first_name: '', last_name: '', email: '', type: 'Client', status: 'active', password: '', password_confirmation: '' });
    this.editForm.markAsPristine();
    this.editForm.markAsUntouched();
    this.editForm.controls.password.setValidators([Validators.required, Validators.minLength(6), Validators.maxLength(128)]);
    this.editForm.controls.password_confirmation.setValidators([Validators.required, Validators.minLength(6), Validators.maxLength(128)]);
    this.editForm.controls.password.updateValueAndValidity();
    this.editForm.controls.password_confirmation.updateValueAndValidity();
    this.editError.set('');
  }

  saveCreate(): void {
    Object.values(this.editForm.controls).forEach(c => c.markAsDirty());
    if (this.editForm.invalid) return;

    this.editLoading.set(true);
    this.editError.set('');

    const v = this.editForm.value;
    this.userService.createUser({
      first_name: v.first_name,
      last_name: v.last_name,
      email: v.email,
      type: v.type,
      status: v.status,
      password: v.password,
      password_confirmation: v.password_confirmation
    }).subscribe({
      next: (created) => {
        this.users.update(users => [...users, created]);
        this.isCreating.set(false);
        this.editLoading.set(false);
      },
      error: (err: any) => {
        this.editError.set(err?.errors?.join(', ') || this.ts.t('admin.users.createError'));
        this.editLoading.set(false);
        this.cdr.detectChanges();
      }
    });
  }

  // ── Edit ──

  openEdit(user: UserInfo): void {
    this.editingUser.set(user);
    this.editForm.patchValue({
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      type: user.type,
      status: user.status,
      password: '',
      password_confirmation: ''
    });
    this.editForm.markAsPristine();
    this.editForm.markAsUntouched();
    this.editForm.controls.password.setValidators([Validators.minLength(6), Validators.maxLength(128)]);
    this.editForm.controls.password_confirmation.setValidators([Validators.minLength(6), Validators.maxLength(128)]);
    this.editForm.controls.password.updateValueAndValidity();
    this.editForm.controls.password_confirmation.updateValueAndValidity();
    this.editError.set('');
  }

  cancelEdit(): void {
    this.editingUser.set(null);
    this.isCreating.set(false);
    this.editError.set('');
  }

  saveEdit(): void {
    const user = this.editingUser();
    if (!user) return;

    Object.values(this.editForm.controls).forEach(c => c.markAsDirty());
    if (this.editForm.invalid) return;

    this.editLoading.set(true);
    this.editError.set('');

    const v = this.editForm.value;
    const data: Record<string, any> = {
      first_name: v.first_name,
      last_name: v.last_name,
      email: v.email,
      type: v.type,
      status: v.status
    };
    if (v.password) {
      data['password'] = v.password;
      data['password_confirmation'] = v.password_confirmation;
    }

    this.userService.updateUser(user.id, data).subscribe({
      next: (updated) => {
        this.users.update(users => users.map(u => u.id === user.id ? updated : u));
        this.editingUser.set(null);
        this.editLoading.set(false);
      },
      error: (err: any) => {
        this.editError.set(err?.errors?.join(', ') || this.ts.t('admin.users.editError'));
        this.editLoading.set(false);
        this.cdr.detectChanges();
      }
    });
  }

  getTypeLabel(type: string): string {
    const key = 'admin.users.type.' + type;
    return this.ts.t(key);
  }

  getStatusLabel(status: string): string {
    const key = 'admin.users.status.' + status;
    return this.ts.t(key);
  }
}
