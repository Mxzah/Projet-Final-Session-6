import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ItemsService } from '../services/items.service';
import { Item } from '../menu/menu.models';

@Component({
  selector: 'app-admin-items',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-items.component.html',
  styleUrls: ['./admin-items.component.css']
})
export class AdminItemsComponent implements OnInit {
  items = signal<Item[]>([]);
  isLoading = signal(true);

  categoryNames = computed(() =>
    [...new Set(this.items().map(i => i.category_name ?? '—'))]
  );

  constructor(private itemsService: ItemsService) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading.set(true);
    this.itemsService.getItems().subscribe({
      next: (items) => {
        const sorted = [...items].sort((a, b) =>
          (a.category_name ?? '—').localeCompare(b.category_name ?? '—')
        );
        this.items.set(sorted);
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  getItemsByCategory(categoryName: string): Item[] {
    return this.items().filter(i => (i.category_name ?? '—') === categoryName);
  }
}
