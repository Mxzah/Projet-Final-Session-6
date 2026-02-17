import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatTabsModule } from '@angular/material/tabs';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { AdminTablesComponent } from '../admin-tables/admin-tables.component';
import { AdminItemsComponent } from '../admin-items/admin-items.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, MatTabsModule, HeaderComponent, AdminTablesComponent, AdminItemsComponent],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent {
  tabIndex = 0;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  onTabChange(index: number): void {
    this.tabIndex = index;
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
