import { Component, inject, input, output } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { MatSliderModule } from '@angular/material/slider';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-ssf-bar',
  standalone: true,
  imports: [
    MatFormFieldModule, MatInputModule, MatSelectModule,
    MatIconModule, MatSliderModule
  ],
  templateUrl: './ssf-bar.component.html',
  styleUrls: ['./ssf-bar.component.css']
})
export class SsfBarComponent {
  ts = inject(TranslationService);

  searchQuery = input<string>('');
  sortOrder = input<string>('none');
  sliderMin = input<number>(0);
  sliderMax = input<number>(9999);
  computedMaxPrice = input<number>(9999);

  searchChange = output<string>();
  sortChange = output<string>();
  sliderMinChange = output<number>();
  sliderMaxChange = output<number>();
  inputMinChange = output<number>();
  inputMaxChange = output<number>();

  onSearchInput(event: Event): void {
    this.searchChange.emit((event.target as HTMLInputElement).value);
  }

  onInputMinChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, 0), this.sliderMax());
    input.value = String(clamped);
    this.inputMinChange.emit(clamped);
  }

  onInputMaxChange(value: number, input: HTMLInputElement): void {
    const clamped = Math.min(Math.max(value, this.sliderMin()), this.computedMaxPrice());
    input.value = String(clamped);
    this.inputMaxChange.emit(clamped);
  }
}
