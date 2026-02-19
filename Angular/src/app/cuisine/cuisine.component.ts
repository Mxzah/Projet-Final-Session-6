import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CuisineService, CuisineOrder } from '../services/cuisine.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { TranslationService } from '../services/translation.service';

@Component({
  selector: 'app-cuisine',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatChipsModule,
    MatIconModule,
    MatButtonModule,
    MatDividerModule,
    MatProgressSpinnerModule,
    HeaderComponent
  ],
  templateUrl: './cuisine.component.html',
  styleUrl: './cuisine.component.css'
})
export class CuisineComponent implements OnInit {
  orders: CuisineOrder[] = [];
  loading = true;
  error: string | null = null;

  constructor(
    public ts: TranslationService,
    private cuisineService: CuisineService,
    private authService: AuthService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading = true;
    this.error = null;
    this.cuisineService.getActiveOrders().subscribe({
      next: (response) => {
        this.orders = response.data ?? [];
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Impossible de charger les commandes.';
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  getStatusLabel(status: string): string {
    const keys: Record<string, string> = {
      sent: 'cuisine.status.sent',
      in_preparation: 'cuisine.status.inPreparation',
      ready: 'cuisine.status.ready',
      served: 'cuisine.status.served'
    };
    return keys[status] ? this.ts.t(keys[status]) : status;
  }

  getStatusClass(status: string): string {
    const classes: Record<string, string> = {
      sent: 'status-sent',
      in_preparation: 'status-prep',
      ready: 'status-ready',
      served: 'status-served'
    };
    return classes[status] ?? '';
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
