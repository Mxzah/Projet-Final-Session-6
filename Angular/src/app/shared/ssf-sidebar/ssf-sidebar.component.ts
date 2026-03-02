import { Component, inject, input, output } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { TranslationService } from '../../services/translation.service';
import { Category } from '../../menu/menu.models';

@Component({
  selector: 'app-ssf-sidebar',
  standalone: true,
  imports: [
    MatFormFieldModule, MatSelectModule,
    MatIconModule, MatListModule
  ],
  templateUrl: './ssf-sidebar.component.html',
  styleUrls: ['./ssf-sidebar.component.css']
})
export class SsfSidebarComponent {
  ts = inject(TranslationService);

  categories = input<Category[]>([]);
  activeCategory = input<number>(0);

  categoryChange = output<number>();
}
