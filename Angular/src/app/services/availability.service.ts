import { Injectable } from '@angular/core';
import { forkJoin, Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiService } from './api.service';
import { AvailabilityEntry } from '../menu/menu.models';

@Injectable({
  providedIn: 'root'
})
export class AvailabilityService {
  constructor(private api: ApiService) {}

  private base(resource: 'items' | 'tables', id: number) {
    return `/api/${resource}/${id}/availabilities`;
  }

  getAvailabilities(resource: 'items' | 'tables', id: number): Observable<AvailabilityEntry[]> {
    return this.api.get<AvailabilityEntry[]>(this.base(resource, id))
      .pipe(map(r => r.data!));
  }

  createAvailability(resource: 'items' | 'tables', id: number, entry: Omit<AvailabilityEntry, 'id'>): Observable<AvailabilityEntry> {
    return this.api.post<AvailabilityEntry>(this.base(resource, id), { availability: entry })
      .pipe(map(r => r.data!));
  }

  updateAvailability(resource: 'items' | 'tables', id: number, availId: number, entry: Omit<AvailabilityEntry, 'id'>): Observable<AvailabilityEntry> {
    return this.api.put<AvailabilityEntry>(`${this.base(resource, id)}/${availId}`, { availability: entry })
      .pipe(map(r => r.data!));
  }

  deleteAvailability(resource: 'items' | 'tables', id: number, availId: number): Observable<void> {
    return this.api.delete<null>(`${this.base(resource, id)}/${availId}`)
      .pipe(map(() => void 0));
  }

  syncAvailabilities(
    current: AvailabilityEntry[],
    original: AvailabilityEntry[],
    createFn: (entry: Omit<AvailabilityEntry, 'id'>) => Observable<unknown>,
    updateFn: (id: number, entry: Omit<AvailabilityEntry, 'id'>) => Observable<unknown>,
    deleteFn: (id: number) => Observable<unknown>
  ): Observable<unknown> {
    const toCreate = current.filter(a => !a.id);
    const toMs = (s?: string | null) => s ? new Date(s).getTime() : null;
    const toUpdate = current.filter(a => {
      if (!a.id) return false;
      const orig = original.find(o => o.id === a.id);
      if (!orig) return false;
      return toMs(orig.start_at) !== toMs(a.start_at)
          || toMs(orig.end_at) !== toMs(a.end_at)
          || (orig.description ?? null) !== (a.description ?? null);
    });
    const currentIds = new Set(current.filter(a => a.id).map(a => a.id!));
    const toDelete = original.filter(o => !currentIds.has(o.id!));

    const ops: Observable<unknown>[] = [
      ...toCreate.map(a => createFn({ start_at: a.start_at, end_at: a.end_at, description: a.description })),
      ...toUpdate.map(a => updateFn(a.id!, { start_at: a.start_at, end_at: a.end_at, description: a.description })),
      ...toDelete.map(a => deleteFn(a.id!))
    ];

    return ops.length > 0 ? forkJoin(ops) : of(null);
  }
}
