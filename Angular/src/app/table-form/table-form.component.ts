import { Component, OnInit, PLATFORM_ID, Inject } from '@angular/core';
import { isPlatformBrowser, CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TableService, TableData } from '../services/table.service';
import { AuthService } from '../services/auth.service';

@Component({
    selector: 'app-table-form',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './table-form.component.html',
    styleUrls: ['./table-form.component.css']
})
export class TableFormComponent implements OnInit {
    table: TableData | null = null;
    guestCount: number | null = null;
    selectedVibe: string = '';
    noTable = false;

    vibes: string[] = [
        'Romantique',
        'Familiale',
        'Entre amis',
        'Affaires',
        'Décontractée',
        'Festive'
    ];

    constructor(
        private tableService: TableService,
        private authService: AuthService,
        private router: Router,
        @Inject(PLATFORM_ID) private platformId: Object
    ) { }

    ngOnInit(): void {
        if (!isPlatformBrowser(this.platformId)) return;

        this.table = this.tableService.getCurrentTable();
        if (!this.table) {
            this.noTable = true;
        }
    }

    goToMenu(): void {
        alert('Accéder au menu — test');
    }

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
