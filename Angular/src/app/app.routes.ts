import { Routes } from '@angular/router';
import { guestGuard } from './guards/guest.guard';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';
import { cuisineGuard } from './guards/cuisine.guard';

export const routes: Routes = [
    { path: '', loadComponent: () => import('./menu/menu.component').then(m => m.MenuComponent) },
    { path: 'login', loadComponent: () => import('./login/login.component').then(m => m.LoginComponent), canActivate: [guestGuard] },
    { path: 'signup', loadComponent: () => import('./signup/signup.component').then(m => m.SignupComponent), canActivate: [guestGuard] },
    { path: 'table/:token', loadComponent: () => import('./table-scan/table-scan.component').then(m => m.TableScanComponent) },
    { path: 'form', loadComponent: () => import('./table-form/table-form.component').then(m => m.TableFormComponent), canActivate: [authGuard] },
    { path: 'admin', loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent), canActivate: [adminGuard] },
    { path: 'menu', loadComponent: () => import('./menu/menu.component').then(m => m.MenuComponent) },
    { path: 'order', loadComponent: () => import('./order/order.component').then(m => m.OrderComponent), canActivate: [authGuard] },
    { path: 'pay', loadComponent: () => import('./pay/pay.component').then(m => m.PayComponent), canActivate: [authGuard] },
    { path: 'kitchen', loadComponent: () => import('./cuisine/cuisine.component').then(m => m.CuisineComponent), canActivate: [cuisineGuard] },
    { path: '**', loadComponent: () => import('./not-found/not-found.component').then(m => m.NotFoundComponent) }
];
