import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiService } from './api.service';
import { AvailabilityEntry } from '../menu/menu.models';

@Injectable({
  providedIn: 'root'
})
export class AvailabilityService {
  constructor(private api: ApiService) {}

  getItemAvailabilities(itemId: number): Observable<AvailabilityEntry[]> {
    return this.api.get<AvailabilityEntry[]>(`/api/items/${itemId}/availabilities`)
      .pipe(map(r => r.data!));
  }

  createAvailability(itemId: number, entry: Omit<AvailabilityEntry, 'id'>): Observable<AvailabilityEntry> {
    return this.api.post<AvailabilityEntry>(`/api/items/${itemId}/availabilities`, { availability: entry })
      .pipe(map(r => r.data!));
  }

  updateAvailability(itemId: number, id: number, entry: Omit<AvailabilityEntry, 'id'>): Observable<AvailabilityEntry> {
    return this.api.put<AvailabilityEntry>(`/api/items/${itemId}/availabilities/${id}`, { availability: entry })
      .pipe(map(r => r.data!));
  }

  deleteAvailability(itemId: number, id: number): Observable<void> {
    return this.api.delete<null>(`/api/items/${itemId}/availabilities/${id}`)
      .pipe(map(() => void 0));
  }
}
