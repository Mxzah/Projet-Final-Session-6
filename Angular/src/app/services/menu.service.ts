import { Injectable } from '@angular/core';
import { Observable, map } from 'rxjs';
import { ApiService } from './api.service';
import { MenuData } from '../menu/menu.models';

@Injectable({
  providedIn: 'root'
})
export class MenuService {
  constructor(private apiService: ApiService) {}

  getMenu(): Observable<MenuData> {
    return this.apiService.get<MenuData>('/api/menu').pipe(
      map(response => response.data!)
    );
  }
}
