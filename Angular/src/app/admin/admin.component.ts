import { Component, OnInit } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { MatTabsModule } from '@angular/material/tabs';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../services/auth.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';
import { AdminTablesComponent } from '../admin-tables/admin-tables.component';
import { AdminItemsComponent } from '../admin-items/admin-items.component';
import { AdminUsersComponent } from '../admin-users/admin-users.component';

const TAB_NAMES = ['tables', 'items', 'users'];

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, MatTabsModule, MatButtonModule, MatIconModule, HeaderComponent, AdminTablesComponent, AdminItemsComponent, AdminUsersComponent],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent implements OnInit {
  tabIndex = 0;

  constructor(
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private location: Location,
    public ts: TranslationService
  ) {}

  ngOnInit(): void {
    const tab = this.route.snapshot.queryParamMap.get('tab');
    const index = TAB_NAMES.indexOf(tab ?? '');
    this.tabIndex = index >= 0 ? index : 0;
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab: TAB_NAMES[this.tabIndex] },
      replaceUrl: true
    });
  }

  onTabChange(index: number): void {
    this.tabIndex = index;
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab: TAB_NAMES[index] },
      replaceUrl: true
    });
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
