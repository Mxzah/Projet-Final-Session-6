import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { TableService } from '../services/table.service';
import { AuthService } from '../services/auth.service';
import { OrderService } from '../services/order.service';
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
        private authService: AuthService,
        private orderService: OrderService
    ) { }

    ngOnInit(): void {
        const qrToken = this.route.snapshot.paramMap.get('token');

        if (!qrToken) {
            this.router.navigate(['/login']);
            return;
        }

        this.tableService.setPendingToken(qrToken);

        // Extract server_id from query params (e.g. /table/:token?s=123)
        const serverId = this.route.snapshot.queryParamMap.get('s');
        if (serverId) {
            this.tableService.setPendingServerId(serverId);
        }

        if (this.authService.isAuthenticated()) {
            this.tableService.validateAndSavePendingToken().subscribe(() => {
                const table = this.tableService.getCurrentTable();

                // If the table already has an open order, join it directly (skip form)
                if (table && table.has_open_order) {
                    const pendingServerId = this.tableService.getPendingServerId();
                    const serverIdNum = pendingServerId ? parseInt(pendingServerId, 10) : (table.open_order_server_id ?? null);
                    this.tableService.clearPendingServerId();

                    this.orderService.createOrder({
                        nb_people: 1,
                        note: '',
                        table_id: table.id,
                        vibe_id: table.open_order_vibe_id ?? null,
                        server_id: serverIdNum
                    }).subscribe({
                        next: () => this.router.navigate(['/menu']),
                        error: () => this.router.navigate(['/menu'])  // may already have an open order
                    });
                } else {
                    this.router.navigate(['/form']);
                }
            });
        } else {
            this.router.navigate(['/login']);
        }
    }
}
