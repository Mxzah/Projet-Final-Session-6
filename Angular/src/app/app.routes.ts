import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { SignupComponent } from './signup/signup.component';
import { TableScanComponent } from './table-scan/table-scan.component';
import { TableFormComponent } from './table-form/table-form.component';
import { AdminComponent } from './admin/admin.component';
import { MenuComponent } from './menu/menu.component';
import { OrderComponent } from './order/order.component';
import { CuisineComponent } from './cuisine/cuisine.component';
import { NotFoundComponent } from './not-found/not-found.component';
import { guestGuard } from './guards/guest.guard';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';
import { cuisineGuard } from './guards/cuisine.guard';

export const routes: Routes = [
    { path: '', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'signup', component: SignupComponent, canActivate: [guestGuard] },
    { path: 'table/:token', component: TableScanComponent },
    { path: 'form', component: TableFormComponent, canActivate: [authGuard] },
    { path: 'admin', component: AdminComponent, canActivate: [adminGuard] },
    { path: 'menu', component: MenuComponent, canActivate: [authGuard] },
    { path: 'order', component: OrderComponent, canActivate: [authGuard] },
    { path: 'cuisine', component: CuisineComponent, canActivate: [cuisineGuard] },
    { path: '**', component: NotFoundComponent }
];
