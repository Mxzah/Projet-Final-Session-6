import { Injectable } from '@angular/core';
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

    constructor(private apiService: ApiService) {
        this.loadTableFromStorage();
    }

    private loadTableFromStorage(): void {
        const tableData = sessionStorage.getItem('currentTable');
        if (tableData) {
            this.currentTable = JSON.parse(tableData);
            this.currentTableSubject.next(this.currentTable);
        }
    }

    private saveTableToStorage(table: TableData): void {
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
        sessionStorage.removeItem('currentTable');
        this.currentTableSubject.next(null);
    }

    setPendingToken(token: string): void {
        sessionStorage.setItem('pendingQrToken', token);
    }

    getPendingToken(): string | null {
        return sessionStorage.getItem('pendingQrToken');
    }

    clearPendingToken(): void {
        sessionStorage.removeItem('pendingQrToken');
    }

    setOrderPreferences(nbPeople: number, vibeId: number | null): void {
        sessionStorage.setItem('orderPreferences', JSON.stringify({ nb_people: nbPeople, vibe_id: vibeId }));
    }

    getOrderPreferences(): { nb_people: number; vibe_id: number | null } {
        const data = sessionStorage.getItem('orderPreferences');
        if (data) return JSON.parse(data);
        return { nb_people: 1, vibe_id: null };
    }

    clearOrderPreferences(): void {
        sessionStorage.removeItem('orderPreferences');
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
