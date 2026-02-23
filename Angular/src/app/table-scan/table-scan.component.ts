import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { TableService } from '../services/table.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';

@Component({
    selector: 'app-table-scan',
    standalone: true,
    imports: [CommonModule, HeaderComponent],
    templateUrl: './table-scan.component.html',
    styleUrls: ['./table-scan.component.css']
})
export class TableScanComponent implements OnInit {
    constructor(
        private route: ActivatedRoute,
        private router: Router,
        private tableService: TableService,
        private authService: AuthService
    ) { }

    ngOnInit(): void {
        const qrToken = this.route.snapshot.paramMap.get('token');

        if (!qrToken) {
            this.router.navigate(['/login']);
            return;
        }

        this.tableService.setPendingToken(qrToken);

        if (this.authService.isAuthenticated()) {
            this.tableService.validateAndSavePendingToken().subscribe(() => {
                this.router.navigate(['/form']);
            });
        } else {
            this.router.navigate(['/login']);
        }
    }
}
