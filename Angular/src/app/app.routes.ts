import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { SignupComponent } from './signup/signup.component';
import { TableScanComponent } from './table-scan/table-scan.component';
import { TableFormComponent } from './table-form/table-form.component';
import { AdminTablesComponent } from './admin-tables/admin-tables.component';
import { NotFoundComponent } from './not-found/not-found.component';
import { guestGuard } from './guards/guest.guard';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
    { path: '', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'signup', component: SignupComponent, canActivate: [guestGuard] },
    { path: 'table/:token', component: TableScanComponent },
    { path: 'form', component: TableFormComponent, canActivate: [authGuard] },
    { path: 'admin/tables', component: AdminTablesComponent, canActivate: [authGuard] },
    { path: '**', component: NotFoundComponent }
];
