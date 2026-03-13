import { Routes } from '@angular/router';
import { guestGuard } from './guards/guest.guard';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';
import { cuisineGuard } from './guards/cuisine.guard';
import { serverGuard } from './guards/server.guard';

export const routes: Routes = [
    { path: '', loadComponent: () => import('./pages/menu/menu/menu.component').then(m => m.MenuComponent) },
    { path: 'login', loadComponent: () => import('./login/login.component').then(m => m.LoginComponent), canActivate: [guestGuard] },
    { path: 'signup', loadComponent: () => import('./signup/signup.component').then(m => m.SignupComponent), canActivate: [guestGuard] },
    { path: 'table/:token', loadComponent: () => import('./table-scan/table-scan.component').then(m => m.TableScanComponent) },
    { path: 'form', loadComponent: () => import('./pages/table-form/table-form.component').then(m => m.TableFormComponent), canActivate: [authGuard] },
    {
        path: 'admin',
        loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent),
        canActivate: [adminGuard],
        children: [
            { path: '', redirectTo: 'tables', pathMatch: 'full' },
            { path: 'tables', loadComponent: () => import('./pages/admin-tables/admin-tables.component').then(m => m.AdminTablesComponent) },
            { path: 'items', loadComponent: () => import('./pages/admin-items/admin-items/admin-items.component').then(m => m.AdminItemsComponent) },
            { path: 'categories', loadComponent: () => import('./pages/admin-categories/admin-categories/admin-categories.component').then(m => m.AdminCategoriesComponent) },
            { path: 'combos', loadComponent: () => import('./pages/admin-combos/admin-combos.component').then(m => m.AdminCombosComponent) },
            { path: 'users', loadComponent: () => import('./admin-users/admin-users.component').then(m => m.AdminUsersComponent) },
            { path: 'reviews', loadComponent: () => import('./admin-reviews/admin-reviews.component').then(m => m.AdminReviewsComponent) },
            { path: 'vibes', loadComponent: () => import('./admin-vibes/admin-vibes.component').then(m => m.AdminVibesComponent) },
        ]
    },
    { path: 'menu', loadComponent: () => import('./pages/menu/menu/menu.component').then(m => m.MenuComponent) },
    { path: 'order', loadComponent: () => import('./pages/order/order.component').then(m => m.OrderComponent), canActivate: [authGuard] },
    { path: 'pay', loadComponent: () => import('./pages/pay/pay.component').then(m => m.PayComponent), canActivate: [authGuard] },
    { path: 'history', loadComponent: () => import('./pages/history/history.component').then(m => m.HistoryComponent), canActivate: [authGuard] },
    { path: 'kitchen', loadComponent: () => import('./pages/cuisine/cuisine.component').then(m => m.CuisineComponent), canActivate: [cuisineGuard] },
    { path: 'server', loadComponent: () => import('./pages/server-page/server-page.component').then(m => m.ServerPageComponent), canActivate: [serverGuard] },
    { path: '**', loadComponent: () => import('./not-found/not-found.component').then(m => m.NotFoundComponent) }
];
