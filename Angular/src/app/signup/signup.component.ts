import { Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-signup',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink],
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
    private router: Router
  ) {}

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

    const requestBody = {
      user: {
        email,
        password,
        password_confirmation: passwordConfirmation,
        first_name: firstName,
        last_name: lastName,
        type: 'Client'
      }
    };
    console.log('Requête envoyée:', requestBody);

    this.authService.signup(
      email!,
      password!,
      passwordConfirmation!,
      firstName!,
      lastName!,
      'Client'
    ).subscribe(response => {
      this.isLoading = false;
      console.log('Réponse reçue:', response);
      if (response.success && response.data) {
        console.log('Inscription réussie!', response.data.email);
        this.router.navigate(['/reservation']);
      } else {
        this.errorMessage = response.errors?.join(', ') || 'Échec de l\'inscription';
      }
    });
  }
}
