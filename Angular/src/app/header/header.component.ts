import { Component, Input, Output, EventEmitter, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { RouterModule } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { TranslationService, Lang } from '../services/translation.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, MatToolbarModule, MatButtonModule, MatIconModule, MatMenuModule, RouterModule],
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css']
})
export class HeaderComponent {
  @Input() showLogout = true;
  @Input() showLogin = false;
  @Input() showAdmin = true;
  @Input() showKitchen = false;
  @Input() showQuitMenu = false;
  @Output() logoutClick = new EventEmitter<void>();
  @Output() loginClick = new EventEmitter<void>();
  @Output() kitchenClick = new EventEmitter<void>();
  @Output() quitMenuClick = new EventEmitter<void>();

  mobileMenuOpen = signal(false);

  constructor(
    public ts: TranslationService,
    public authService: AuthService,
    private router: Router
  ) { }

  toggleMobileMenu(): void {
    this.mobileMenuOpen.update(v => !v);
  }

  setLang(lang: Lang): void {
    this.ts.setLang(lang);
  }

  goToAdmin(): void {
    this.router.navigate(['/admin', 'tables']);
  }

  goToReviews(): void {
    this.router.navigate(['/reviews']);
  }

  isClient(): boolean {
    return this.authService.getCurrentUser()?.type === 'Client';
  }

  getRoleIcon(): string {
    switch (this.authService.getCurrentUser()?.type) {
      case 'Administrator': return 'admin_panel_settings';
      case 'Waiter': return 'room_service';
      case 'Cook': return 'soup_kitchen';
      default: return 'person';
    }
  }

  getRoleLabel(): string {
    switch (this.authService.getCurrentUser()?.type) {
      case 'Administrator': return this.ts.t('header.roleAdmin');
      case 'Waiter': return this.ts.t('header.roleWaiter');
      case 'Cook': return this.ts.t('header.roleCook');
      default: return this.ts.t('header.roleClient');
    }
  }
}
