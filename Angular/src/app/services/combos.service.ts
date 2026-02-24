import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService } from './api.service';

export interface Combo {
    id: number;
    name: string;
    description: string | null;
    price: number;
    created_at: string;
}

export interface CreateComboPayload {
    name: string;
    description?: string;
    price: number;
}

@Injectable({
    providedIn: 'root'
})
export class CombosService {
    constructor(private apiService: ApiService) { }

    getCombos(): Observable<Combo[]> {
        return this.apiService.get<Combo[]>('/api/combos').pipe(
            map(response => response.data ?? [])
        );
    }

    createCombo(payload: CreateComboPayload): Observable<Combo> {
        return this.apiService.post<Combo>('/api/combos', { combo: payload }).pipe(
            map(response => response.data!)
        );
    }
}
