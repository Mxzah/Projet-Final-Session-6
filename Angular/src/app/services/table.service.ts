import { Injectable, PLATFORM_ID, Inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { BehaviorSubject, Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface TableData {
    id: number;
    number: number;
    capacity: number;
    status: string;
    qr_token: string;
}

@Injectable({
    providedIn: 'root'
})
export class TableService {
    private currentTable: TableData | null = null;
    private currentTableSubject = new BehaviorSubject<TableData | null>(null);
    public currentTable$ = this.currentTableSubject.asObservable();
    private isBrowser: boolean;

    constructor(
        private apiService: ApiService,
        @Inject(PLATFORM_ID) platformId: Object
    ) {
        this.isBrowser = isPlatformBrowser(platformId);
        if (this.isBrowser) {
            this.loadTableFromStorage();
        }
    }

    private loadTableFromStorage(): void {
        if (!this.isBrowser) return;
        const tableData = sessionStorage.getItem('currentTable');
        if (tableData) {
            this.currentTable = JSON.parse(tableData);
            this.currentTableSubject.next(this.currentTable);
        }
    }

    private saveTableToStorage(table: TableData): void {
        if (!this.isBrowser) return;
        sessionStorage.setItem('currentTable', JSON.stringify(table));
    }

    validateQrToken(qrToken: string): Observable<ApiResponse<TableData>> {
        return this.apiService.get<TableData>(`/api/tables/${qrToken}`);
    }

    setCurrentTable(table: TableData): void {
        this.currentTable = table;
        this.saveTableToStorage(table);
        this.currentTableSubject.next(table);
    }

    getCurrentTable(): TableData | null {
        return this.currentTable;
    }

    hasTable(): boolean {
        return this.currentTable !== null;
    }

    clearTable(): void {
        this.currentTable = null;
        if (this.isBrowser) sessionStorage.removeItem('currentTable');
        this.currentTableSubject.next(null);
    }

    setPendingToken(token: string): void {
        if (this.isBrowser) sessionStorage.setItem('pendingQrToken', token);
    }

    getPendingToken(): string | null {
        if (!this.isBrowser) return null;
        return sessionStorage.getItem('pendingQrToken');
    }

    clearPendingToken(): void {
        if (this.isBrowser) sessionStorage.removeItem('pendingQrToken');
    }

    validateAndSavePendingToken(): Observable<boolean> {
        const token = this.getPendingToken();
        if (!token) {
            return new Observable(obs => { obs.next(false); obs.complete(); });
        }
        return new Observable(obs => {
            this.validateQrToken(token).subscribe({
                next: (response) => {
                    if (response.success && response.data) {
                        this.setCurrentTable(response.data);
                    }
                    this.clearPendingToken();
                    obs.next(true);
                    obs.complete();
                },
                error: () => {
                    this.clearPendingToken();
                    obs.next(false);
                    obs.complete();
                }
            });
        });
    }
}
