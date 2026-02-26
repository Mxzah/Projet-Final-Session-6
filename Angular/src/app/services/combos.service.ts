import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService } from './api.service';

export interface Combo {
    id: number;
    name: string;
    description: string | null;
    price: number;
    image_url: string | null;
    created_at: string;
    deleted_at: string | null;
    availabilities?: { id: number; start_at: string; end_at?: string | null; description?: string | null }[];
}

export interface CreateComboPayload {
    name: string;
    description?: string;
    price: number;
    image?: File;
}

export interface ComboQueryParams {
    search?: string;
    sort?: string;
    price_min?: number | null;
    price_max?: number | null;
    include_deleted?: boolean;
}

@Injectable({
    providedIn: 'root'
})
export class CombosService {
    constructor(private apiService: ApiService) { }

    getCombos(params?: ComboQueryParams): Observable<Combo[]> {
        const queryParams: Record<string, string> = {};
        if (params?.search) queryParams['search'] = params.search;
        if (params?.sort) queryParams['sort'] = params.sort;
        if (params?.price_min != null) queryParams['price_min'] = params.price_min.toString();
        if (params?.price_max != null) queryParams['price_max'] = params.price_max.toString();
        if (params?.include_deleted) queryParams['include_deleted'] = 'true';

        return this.apiService.get<Combo[]>('/api/combos', queryParams).pipe(
            map(response => response.data ?? [])
        );
    }

    createCombo(payload: CreateComboPayload): Observable<Combo> {
        const formData = this.buildFormData(payload);
        return this.apiService.post<Combo>('/api/combos', formData).pipe(
            map(response => response.data!)
        );
    }

    private buildFormData(data: Record<string, any>): FormData {
        const formData = new FormData();
        for (const key of Object.keys(data)) {
            if (data[key] !== undefined && data[key] !== null) {
                if (data[key] instanceof File) {
                    formData.append(`combo[${key}]`, data[key]);
                } else {
                    formData.append(`combo[${key}]`, String(data[key]));
                }
            }
        }
        return formData;
    }
}
