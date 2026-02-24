import { Injectable } from '@angular/core';
import { TranslationService } from './translation.service';

export type ErrorType = 'server' | 'image' | 'unknown';

export interface AppError {
  type: ErrorType;
  messages: string[];
}

@Injectable({
  providedIn: 'root'
})
export class ErrorService {
  fromApiError(err: any): AppError {
    const messages: string[] = err?.errors?.length ? err.errors : ['Une erreur est survenue'];
    return { type: 'server', messages };
  }

  imageError(key: 'format' | 'size' | 'required', ts: TranslationService): AppError {
    const keyMap = {
      format: 'admin.imageFormat',
      size: 'admin.imageSize',
      required: 'admin.imageRequired'
    };
    return { type: 'image', messages: [ts.t(keyMap[key])] };
  }

  format(error: AppError): string {
    return error.messages.join(', ');
  }
}
