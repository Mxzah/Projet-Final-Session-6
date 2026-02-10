import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { SignupComponent } from './signup/signup.component';
import { ReservationComponent } from './reservation/reservation.component';
import { NotFoundComponent } from './not-found/not-found.component';
import { guestGuard } from './guards/guest.guard';

export const routes: Routes = [
    { path: '', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'signup', component: SignupComponent, canActivate: [guestGuard] },
    { path: 'reservation', component: ReservationComponent },
    { path: '**', component: NotFoundComponent }
];
