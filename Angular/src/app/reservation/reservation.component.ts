import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-reservation',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './reservation.component.html',
  styleUrls: ['./reservation.component.css']
})
export class ReservationComponent {
  tableId: string | null = null;
  guestCount: number | null = null;
  reservationVibe: string = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  onSubmit(event: Event): void {
    event.preventDefault();
    console.log('Reservation:', {
      tableId: this.tableId,
      guestCount: this.guestCount,
      vibe: this.reservationVibe
    });
    // TODO: Envoyer la réservation au serveur
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: (response) => {
        console.log('Logout response:', response);
        if (response.success) {
          this.router.navigate(['/login']);
        }
      },
      error: (error) => {
        console.error('Logout error:', error);
        // Déconnexion locale même si le serveur échoue
        localStorage.removeItem('currentUser');
        this.router.navigate(['/login']);
      }
    });
  }
}
