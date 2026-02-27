import { Component, OnInit, OnDestroy, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { UserService } from '../services/user.service';
import { ErrorService } from '../services/error.service';
import { UserInfo } from './user.model';
import { TranslationService } from '../services/translation.service';
import { UserFormDialogComponent, UserFormDialogResult } from './user-form-dialog.component';
import { ConfirmDeleteDialogComponent } from './confirm-delete-dialog.component';

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
export class AdminUsersComponent implements OnInit, OnDestroy {
  users = signal<UserInfo[]>([]);
  isLoading = signal(true);

  // Filters
  searchTerm = signal('');
  filterStatus = signal('all');
  filterType = signal('all');
  sortOrder = signal('none');

  // Debounce search
  private searchSubject = new Subject<string>();
  private searchSubscription!: Subscription;

  // Computed: split employees and clients
  employees = computed(() =>
    this.users().filter(u => ['Administrator', 'Waiter', 'Cook'].includes(u.type))
  );
  clients = computed(() =>
    this.users().filter(u => u.type === 'Client')
  );

  // Sort indicator
  sortIndicator = computed(() => {
    if (this.sortOrder() === 'asc') return this.ts.t('admin.users.sortedByAZ');
    if (this.sortOrder() === 'desc') return this.ts.t('admin.users.sortedByZA');
    return '';
  });

  userTypes = ['Administrator', 'Waiter', 'Client', 'Cook'];
  userStatuses = ['active', 'inactive', 'blocked'];

  constructor(
    private userService: UserService,
    private errorService: ErrorService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    public ts: TranslationService
  ) {}

  ngOnInit(): void {
    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => this.loadData());

    this.loadData();
  }

  ngOnDestroy(): void {
    this.searchSubscription?.unsubscribe();
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
    const value = (event.target as HTMLInputElement).value;
    this.searchTerm.set(value);
    this.searchSubject.next(value);
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
      next: () => this.loadData()
    });
  }

  // ── Delete ──

  confirmDelete(user: UserInfo): void {
    const dialogRef = this.dialog.open(ConfirmDeleteDialogComponent, {
      width: '400px',
      data: { userName: `${user.first_name} ${user.last_name}` }
    });

    dialogRef.afterClosed().subscribe(confirmed => {
      if (confirmed) {
        this.userService.deleteUser(user.id).subscribe({
          next: () => {
            this.loadData();
            this.snackBar.open(this.ts.t('admin.users.userDeleted'), '', { duration: 3000 });
          },
          error: (err: any) => {
            const appError = this.errorService.fromApiError(err);
            this.snackBar.open(this.errorService.format(appError), '', { duration: 5000 });
          }
        });
      }
    });
  }

  // ── Create ──

  openCreate(): void {
    const dialogRef = this.dialog.open(UserFormDialogComponent, {
      width: '440px',
      data: { mode: 'create' }
    });

    dialogRef.afterClosed().subscribe((result: UserFormDialogResult | undefined) => {
      if (!result) return;

      this.userService.createUser(result.data).subscribe({
        next: () => {
          this.loadData();
          this.snackBar.open(this.ts.t('admin.users.userCreated'), '', { duration: 3000 });
        },
        error: (err: any) => {
          const appError = this.errorService.fromApiError(err);
          // Reopen dialog with error
          const retryRef = this.dialog.open(UserFormDialogComponent, {
            width: '440px',
            data: { mode: 'create' }
          });
          retryRef.componentInstance.setServerError(this.errorService.format(appError));
        }
      });
    });
  }

  // ── Edit ──

  openEdit(user: UserInfo): void {
    const dialogRef = this.dialog.open(UserFormDialogComponent, {
      width: '440px',
      data: { mode: 'edit', user }
    });

    dialogRef.afterClosed().subscribe((result: UserFormDialogResult | undefined) => {
      if (!result) return;

      this.userService.updateUser(user.id, result.data).subscribe({
        next: () => {
          this.loadData();
          this.snackBar.open(this.ts.t('admin.users.userUpdated'), '', { duration: 3000 });
        },
        error: (err: any) => {
          const appError = this.errorService.fromApiError(err);
          // Reopen dialog with error
          const retryRef = this.dialog.open(UserFormDialogComponent, {
            width: '440px',
            data: { mode: 'edit', user }
          });
          retryRef.componentInstance.setServerError(this.errorService.format(appError));
        }
      });
    });
  }

  getTypeLabel(type: string): string {
    return this.ts.t('admin.users.type.' + type);
  }

  getStatusLabel(status: string): string {
    return this.ts.t('admin.users.status.' + status);
  }
}
