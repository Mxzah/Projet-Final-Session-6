import { Component } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router } from '@angular/router';
import { MatTabsModule } from '@angular/material/tabs';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../services/auth.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';
import { AdminTablesComponent } from '../admin-tables/admin-tables.component';
import { AdminItemsComponent } from '../admin-items/admin-items.component';
import { AdminUsersComponent } from '../admin-users/admin-users.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, MatTabsModule, MatButtonModule, MatIconModule, HeaderComponent, AdminTablesComponent, AdminItemsComponent, AdminUsersComponent],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent {
  tabIndex = 0;

  constructor(
    private authService: AuthService,
    private router: Router,
    private location: Location,
    public ts: TranslationService
  ) {}

  onTabChange(index: number): void {
    this.tabIndex = index;
  }

  goBack(): void {
    this.location.back();
  }

  goToKitchen(): void {
    this.router.navigate(['/kitchen']);
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
