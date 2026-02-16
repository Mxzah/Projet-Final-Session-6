import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { AdminTablesComponent } from '../admin-tables/admin-tables.component';
import { AdminItemsComponent } from '../admin-items/admin-items.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, HeaderComponent, AdminTablesComponent, AdminItemsComponent],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent {
  activeTab: 'tables' | 'menu' = 'tables';

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  switchTab(tab: 'tables' | 'menu'): void {
    this.activeTab = tab;
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
