import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../services/auth.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive, MatButtonModule, MatIconModule, HeaderComponent],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent {
  tabs = [
    { path: 'tables', label: 'admin.tables.tab' },
    { path: 'items', label: 'admin.items.tab' },
    { path: 'combos', label: 'admin.combos.tab' },
    { path: 'combo-items', label: 'admin.comboItems.tab' },
    { path: 'users', label: 'admin.users.tab' },
  ];

  constructor(
    private authService: AuthService,
    private router: Router,
    public ts: TranslationService
  ) { }

  goToKitchen(): void {
    this.router.navigate(['/kitchen']);
  }

  goToMenu(): void {
    this.router.navigate(['/menu']);
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => this.router.navigate(['/login']),
      error: () => this.router.navigate(['/login'])
    });
  }
}
