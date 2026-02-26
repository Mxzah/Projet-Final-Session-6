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
}
