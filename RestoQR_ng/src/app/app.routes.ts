import { Routes } from '@angular/router';
import { AdminCreateComponent } from './admin-create/admin-create.component';
import { LoginComponent } from './login/login.component';

export const routes: Routes = [
    { path: '', component: AdminCreateComponent },
    { path: 'login', component: LoginComponent }
];
