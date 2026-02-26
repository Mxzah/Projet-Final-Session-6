import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { TableService, TableData } from '../services/table.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { OrderService, VibeData } from '../services/order.service';
import { TranslationService } from '../services/translation.service';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  selector: 'app-table-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    HeaderComponent,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './table-form.component.html',
  styleUrls: ['./table-form.component.css']
})
export class TableFormComponent implements OnInit {
  table: TableData | null = null;
  noTable = false;
  vibes: VibeData[] = [];
  vibesLoading = true;
  isSubmitting = signal(false);
  apiError = signal<string | null>(null);
  form!: FormGroup;

  constructor(
    private tableService: TableService,
    private authService: AuthService,
    private orderService: OrderService,
    public ts: TranslationService,
    private router: Router
  ) {}

  // Appelé au chargement — vérifie qu'une table est sélectionnée et initialise le formulaire
  ngOnInit(): void {
    this.table = this.tableService.getCurrentTable();
    if (!this.table) {
      this.noTable = true;
      return;
    }

    this.form = new FormGroup({
      guestCount: new FormControl<number | null>(null, [
        Validators.required,
        Validators.min(1),
        Validators.max(this.table.capacity)
      ]),
      vibeId: new FormControl<number | null>(null, Validators.required)
    });

    this.loadVibes();
  }

  // Charge la liste des vibes depuis le backend (créées dans seeds.rb)
  private loadVibes(): void {
    this.orderService.getVibes().subscribe({
      next: (res) => {
        this.vibes = res.data || [];
        this.vibesLoading = false;
      },
      error: () => {
        this.vibesLoading = false;
      }
    });
  }

  // Raccourcis pour accéder aux champs du formulaire facilement dans le HTML
  get guestCtrl() { return this.form.get('guestCount')!; }
  get vibeCtrl() { return this.form.get('vibeId')!; }

  // Retourne l'objet vibe sélectionné (pour afficher sa couleur par exemple)
  getSelectedVibe(): VibeData | null {
    return this.vibes.find(v => v.id === this.vibeCtrl.value) ?? null;
  }

  // Crée la commande dans le backend et redirige vers le menu
  goToMenu(): void {
    if (this.form.invalid || this.isSubmitting()) return;

    const { guestCount, vibeId } = this.form.value;
    const table = this.table!;

    this.isSubmitting.set(true);
    this.apiError.set(null);

    this.orderService.createOrder({
      nb_people: guestCount!,
      note: '',
      table_id: table.id,
      vibe_id: vibeId ?? null
    }).subscribe({
      next: () => {
        this.router.navigate(['/menu']);
      },
      error: (err: any) => {
        const messages: string[] = err?.errors ?? [];
        this.apiError.set(messages.length ? messages.join(' ') : this.ts.t('form.createError'));
        this.isSubmitting.set(false);
      }
    });
  }

  // Appelé quand l'utilisateur clique sur déconnexion dans le header
  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        this.tableService.clearTable();
        this.router.navigate(['/login']);
      },
      error: () => {
        this.tableService.clearTable();
        this.router.navigate(['/login']);
      }
    });
  }
}
