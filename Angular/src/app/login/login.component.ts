import { Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', [Validators.required, Validators.minLength(6), Validators.maxLength(128)])
  });

  errorMessage: string = '';
  isLoading: boolean = false;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.errorMessage = '';
    this.isLoading = true;

    const { email, password } = this.loginForm.value;

    const requestBody = { user: { email, password } };
    console.log('Requête envoyée:', requestBody);

    this.authService.login(email!, password!).subscribe(response => {
      this.isLoading = false;
      console.log('Réponse reçue:', response);
      if (response.success && response.data) {
        console.log('Connexion réussie!', response.data.email);
        this.router.navigate(['/reservation']);
      } else {
        this.errorMessage = response.errors?.join(', ') || 'Identifiants invalides';
      }
    });
  }
}
