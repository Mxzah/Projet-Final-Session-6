import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService } from './api.service';

export interface ComboItem {
    id: number;
    combo_id: number;
    combo_name: string | null;
    item_id: number;
    item_name: string | null;
    item_image_url: string | null;
    quantity: number;
}

export interface CreateComboItemPayload {
    combo_id: number;
    item_id: number;
    quantity: number;
}

@Injectable({
    providedIn: 'root'
})
export class ComboItemsService {
    constructor(private apiService: ApiService) { }

    getComboItems(): Observable<ComboItem[]> {
        return this.apiService.get<ComboItem[]>('/api/combo_items').pipe(
            map(response => response.data ?? [])
        );
    }

    createComboItem(payload: CreateComboItemPayload): Observable<ComboItem> {
        return this.apiService.post<ComboItem>('/api/combo_items', { combo_item: payload }).pipe(
            map(response => response.data!)
        );
    }

    deleteComboItem(id: number): Observable<void> {
        return this.apiService.delete<void>(`/api/combo_items/${id}`).pipe(
            map(() => void 0)
        );
    }
}
