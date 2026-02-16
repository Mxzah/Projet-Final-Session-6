import { Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../services/auth.service';
import { TableService } from '../services/table.service';
import { HeaderComponent } from '../header/header.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink, HeaderComponent],
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
    private tableService: TableService,
    private router: Router
  ) { }

  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.errorMessage = '';
    this.isLoading = true;

    const { email, password } = this.loginForm.value;

    this.authService.login(email!, password!).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (this.tableService.getPendingToken()) {
          this.tableService.validateAndSavePendingToken().subscribe(() => {
            this.router.navigate(['/form']);
          });
        } else {
          this.router.navigate(['/form']);
        }
      },
      error: (error) => {
        this.isLoading = false;
        console.error('Erreur de connexion:', error);
        this.errorMessage = error.errors?.join(', ') || 'Une erreur est survenue lors de la connexion';
      }
    });
  }
}
