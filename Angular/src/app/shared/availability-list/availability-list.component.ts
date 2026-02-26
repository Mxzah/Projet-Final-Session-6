import { Component, Input, Output, EventEmitter, OnChanges, SimpleChanges } from '@angular/core';
import { ReactiveFormsModule, FormArray, FormGroup, FormControl, Validators, AbstractControl } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { AvailabilityEntry } from '../../menu/menu.models';
import { TranslationService } from '../../services/translation.service';

function isValidDate(value: string): boolean {
  const d = new Date(value);
  return !isNaN(d.getTime());
}

function startNotInPastValidator(control: AbstractControl): { [key: string]: boolean } | null {
  if (!control.value) return null;
  if (!isValidDate(control.value)) return { invalidDate: true };
  const now = new Date();
  now.setSeconds(0, 0);
  return new Date(control.value) < now ? { startInPast: true } : null;
}

function makeStartValidator(originalValue: string) {
  return (control: AbstractControl): { [key: string]: boolean } | null => {
    if (!control.value) return null;
    if (!isValidDate(control.value)) return { invalidDate: true };
    // Allow the original value unchanged (even if in the past)
    if (control.value === originalValue) return null;
    const now = new Date();
    now.setSeconds(0, 0);
    return new Date(control.value) < now ? { startInPast: true } : null;
  };
}

function makeEndValidator(getGroup: () => FormGroup | null) {
  return (control: AbstractControl): { [key: string]: boolean } | null => {
    if (!control.value) return null;
    if (!isValidDate(control.value)) return { invalidDate: true };
    const group = getGroup();
    if (!group) return null;
    const start = group.get('start_at')?.value;
    if (!start) return null;
    const startDate = new Date(start);
    const endDate = new Date(control.value);
    if (endDate <= startDate) return { endBeforeStart: true };
    if (endDate.getTime() - startDate.getTime() < 60 * 60 * 1000) return { minDuration: true };
    return null;
  };
}

function overlapsValidator(array: AbstractControl): { [key: string]: boolean } | null {
  const groups = (array as FormArray).controls as FormGroup[];
  // Reset overlap errors on all groups first
  groups.forEach(g => {
    const errors = { ...g.errors };
    delete errors['overlap'];
    g.setErrors(Object.keys(errors).length ? errors : null);
  });

  const INF = Infinity;
  const toMs = (v: string | null | undefined) => (v && isValidDate(v) ? new Date(v).getTime() : null);

  let hasOverlap = false;
  for (let i = 0; i < groups.length; i++) {
    for (let j = i + 1; j < groups.length; j++) {
      const a = groups[i];
      const b = groups[j];
      const startA = toMs(a.get('start_at')?.value);
      const endA   = toMs(a.get('end_at')?.value) ?? INF;
      const startB = toMs(b.get('start_at')?.value);
      const endB   = toMs(b.get('end_at')?.value) ?? INF;
      if (startA === null || startB === null) continue;
      if (startA < endB && startB < endA) {
        a.setErrors({ ...(a.errors ?? {}), overlap: true });
        b.setErrors({ ...(b.errors ?? {}), overlap: true });
        hasOverlap = true;
      }
    }
  }
  return hasOverlap ? { overlap: true } : null;
}

@Component({
  selector: 'app-availability-list',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule
  ],
  templateUrl: './availability-list.component.html',
  styleUrls: ['./availability-list.component.css']
})
export class AvailabilityListComponent implements OnChanges {
  @Input() availabilities: AvailabilityEntry[] = [];
  @Input() disabled = false;
  @Output() availabilitiesChange = new EventEmitter<AvailabilityEntry[]>();

  rows = new FormArray<FormGroup>([], { validators: overlapsValidator });

  constructor(public ts: TranslationService) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['availabilities']) {
      const prev: AvailabilityEntry[] = changes['availabilities'].previousValue ?? [];
      const next: AvailabilityEntry[] = changes['availabilities'].currentValue ?? [];
      // Rebuild rows only when the list is populated from outside (e.g. loaded from API)
      // and the current FormArray doesn't already reflect the incoming data
      const prevIds = prev.map(a => a.id).filter(Boolean).sort().join(',');
      const nextIds = next.map(a => a.id).filter(Boolean).sort().join(',');
      if (prevIds !== nextIds) {
        this.rows.clear();
        for (const a of next) {
          this.rows.push(this.buildRow(a));
        }
      }
    }
  }

  private buildRow(a?: AvailabilityEntry): FormGroup {
    const group: FormGroup = new FormGroup({
      id: new FormControl<number | undefined>(a?.id),
      start_at: new FormControl(a ? this.toDatetimeLocal(a.start_at) : '', a?.id ? [Validators.required, makeStartValidator(this.toDatetimeLocal(a.start_at))] : [Validators.required, startNotInPastValidator]),
      end_at: new FormControl(a?.end_at ? this.toDatetimeLocal(a.end_at) : ''),
      description: new FormControl(a?.description ?? '', [Validators.maxLength(255)])
    });
    group.get('end_at')!.addValidators(makeEndValidator(() => group));
    return group;
  }

  addRow(): void {
    this.rows.push(this.buildRow());
    this.emit();
  }

  removeRow(i: number): void {
    this.rows.removeAt(i);
    this.emit();
  }

  onStartChange(group: FormGroup): void {
    group.get('end_at')?.updateValueAndValidity();
    this.rows.updateValueAndValidity();
    this.emit();
  }

  onFieldChange(): void {
    this.rows.updateValueAndValidity();
    this.emit();
  }

  asGroup(control: AbstractControl): FormGroup {
    return control as FormGroup;
  }

  private emit(): void {
    const entries: AvailabilityEntry[] = this.rows.controls.map(row => {
      const g = row as FormGroup;
      const val = g.value;
      return {
        id: val.id ?? undefined,
        start_at: val.start_at ? new Date(val.start_at).toISOString() : '',
        end_at: val.end_at ? new Date(val.end_at).toISOString() : null,
        description: val.description || null
      };
    });
    this.availabilitiesChange.emit(entries);
  }

  private toDatetimeLocal(iso: string): string {
    if (!iso) return '';
    const d = new Date(iso);
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  markAllDirty(): void {
    this.rows.controls.forEach(row => {
      row.markAsDirty();
      Object.values((row as FormGroup).controls).forEach(c => c.markAsDirty());
      row.updateValueAndValidity();
    });
    this.rows.updateValueAndValidity();
  }

  get isValid(): boolean {
    return this.rows.valid;
  }
}
