import { Injectable, signal, computed } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService, ApiResponse } from './api.service';

export interface TableData {
    id: number;
    number: number;
    capacity: number;
    status: string;
    qr_token: string;
    availabilities?: { id: number; start_at: string; end_at?: string | null }[];
}

@Injectable({
    providedIn: 'root'
})
export class TableService {
    private currentTableSignal = signal<TableData | null>(null);
    public currentTable = this.currentTableSignal.asReadonly();
    public hasTable = computed(() => this.currentTableSignal() !== null);

    constructor(private apiService: ApiService) {
        this.loadTableFromStorage();
    }

    private loadTableFromStorage(): void {
        const tableData = sessionStorage.getItem('currentTable');
        if (tableData) {
            this.currentTableSignal.set(JSON.parse(tableData));
        }
    }

    private saveTableToStorage(table: TableData): void {
        sessionStorage.setItem('currentTable', JSON.stringify(table));
    }

    validateQrToken(qrToken: string): Observable<ApiResponse<TableData>> {
        return this.apiService.get<TableData>(`/api/tables/${qrToken}`);
    }

    setCurrentTable(table: TableData): void {
        this.currentTableSignal.set(table);
        this.saveTableToStorage(table);
    }

    getCurrentTable(): TableData | null {
        return this.currentTableSignal();
    }

    clearTable(): void {
        this.currentTableSignal.set(null);
        sessionStorage.removeItem('currentTable');
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
