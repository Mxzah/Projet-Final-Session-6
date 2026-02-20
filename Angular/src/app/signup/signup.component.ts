import { Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../services/auth.service';
import { TableService } from '../services/table.service';
import { TranslationService } from '../services/translation.service';
import { HeaderComponent } from '../header/header.component';

@Component({
  selector: 'app-signup',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink, HeaderComponent, MatFormFieldModule, MatInputModule, MatButtonModule, MatIconModule],
  templateUrl: './signup.component.html',
  styleUrl: './signup.component.css'
})
export class SignupComponent {
  signupForm = new FormGroup({
    firstName: new FormControl('', [Validators.required, Validators.maxLength(50)]),
    lastName: new FormControl('', [Validators.required, Validators.maxLength(50)]),
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', [Validators.required, Validators.minLength(6), Validators.maxLength(128)]),
    passwordConfirmation: new FormControl('', [Validators.required, Validators.minLength(6), Validators.maxLength(128)])
  }, { validators: this.passwordMatchValidator });

  errorMessage: string = '';
  isLoading: boolean = false;

  constructor(
    private authService: AuthService,
    private tableService: TableService,
    private router: Router,
    public ts: TranslationService
  ) { }

  passwordMatchValidator(control: AbstractControl): ValidationErrors | null {
    const password = control.get('password');
    const passwordConfirmation = control.get('passwordConfirmation');

    if (password && passwordConfirmation && password.value !== passwordConfirmation.value) {
      return { passwordMismatch: true };
    }
    return null;
  }

  onSubmit(): void {
    if (this.signupForm.invalid) {
      this.signupForm.markAllAsTouched();
      return;
    }

    this.errorMessage = '';
    this.isLoading = true;

    const { email, password, passwordConfirmation, firstName, lastName } = this.signupForm.value;

    this.authService.signup(
      email!,
      password!,
      passwordConfirmation!,
      firstName!,
      lastName!,
      'Client'
    ).subscribe(response => {
      this.isLoading = false;
      if (response.success && response.data) {
        if (this.tableService.getPendingToken()) {
          this.tableService.validateAndSavePendingToken().subscribe(() => {
            this.router.navigate(['/form']);
          });
        } else {
          this.router.navigate(['/form']);
        }
      } else {
        this.errorMessage = response.errors?.join(', ') || this.ts.t('signup.defaultError');
      }
    });
  }
}
