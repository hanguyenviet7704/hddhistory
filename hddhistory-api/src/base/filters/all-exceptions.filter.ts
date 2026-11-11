import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

import { LoggerService } from '@base/logging/logger.service';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly loggerService: LoggerService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let errors: unknown[] | undefined;
    let meta: Record<string, unknown> | undefined;
    let errorType = 'InternalError';

    // 1. Nếu là HttpException (Nest mặc định)
    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'string') {
        message = res;
      } else if (typeof res === 'object' && res !== null) {
        // Nếu validation error -> chỉ lấy lỗi đầu tiên
        if ((res as any).message) {
          const errMsg = (res as any).message;
          message = Array.isArray(errMsg) ? errMsg[0] : String(errMsg);
        }
        // Forward a structured `errors` array when the thrower supplied one.
        // Collapsing everything to a single string means a client can say
        // "something is invalid" but never which field — the paywall-config
        // editor needs to point at the offending product id. Additive: the
        // key is simply absent for the exceptions that don't set it.
        const structured = (res as any).errors;
        if (Array.isArray(structured) && structured.length > 0) {
          errors = structured;
        }
        // Same idea for facts the client has to ACT on rather than display: the
        // community's 429 carries how many seconds until the write ceiling
        // lifts, and flattening everything into `message` would leave the app
        // guessing at the number it has to show. Additive — absent for every
        // exception that does not set it.
        const extra = (res as any).meta;
        if (extra && typeof extra === 'object' && !Array.isArray(extra)) {
          meta = extra as Record<string, unknown>;
        }
      } else {
        message = exception.message || message;
      }

      errorType = exception.name;
    }

    // 2. Nếu là AxiosError (external service)
    else if (
      typeof exception === 'object' &&
      exception !== null &&
      (exception as any).isAxiosError
    ) {
      status = (exception as any).response?.status || HttpStatus.BAD_GATEWAY;
      message =
        (exception as any).response?.data?.message ||
        (exception as any).message ||
        'External service error';
      errorType = 'ExternalServiceError';
    }

    // 3. Nếu là DatabaseError
    else if (
      exception instanceof Error &&
      (exception.name === 'QueryFailedError' || // TypeORM
        exception.name === 'MongoServerError') // Mongo
    ) {
      // TypeORM
      if ((exception as any).code === '23505') {
        status = HttpStatus.CONFLICT;
        message = 'Duplicate key error';
      } else if ((exception as any).code === '22P02') {
        status = HttpStatus.BAD_REQUEST;
        message = 'Invalid data format';
      } else if ((exception as any).code === '23503') {
        status = HttpStatus.CONFLICT;
        message = 'Foreign key violation';
      }

      // Mongo
      else if ((exception as any).code === 11000) {
        status = HttpStatus.CONFLICT;
        message = 'Duplicate key error';
      } else if ((exception as any).code === 121) {
        status = HttpStatus.BAD_REQUEST;
        message = 'Document validation failed';
      }

      // Fallback cho các DB errors khác
      else {
        status = HttpStatus.INTERNAL_SERVER_ERROR;
        message = exception.message || 'Database error';
      }

      errorType = exception.name;
    }

    // 4. Nếu là Error thường
    else if (exception instanceof Error) {
      message = exception.message;
      errorType = exception.name;
      // Honor a status carried by non-Nest errors (e.g. Express body-parser's
      // PayloadTooLargeError.status = 413) instead of defaulting them to 500.
      const rawStatus =
        (exception as any).status ?? (exception as any).statusCode;
      if (typeof rawStatus === 'number' && rawStatus >= 400 && rawStatus <= 599) {
        status = rawStatus;
      }
    }

    // 4. Nếu là giá trị lạ (string, number…)
    else {
      message = String(exception);
    }

    // this.loggerService.error(message, exception);
    this.loggerService.error(
      `[ERROR] ${request.method} ${request.url} | status=${status} | message=${message}`,
      exception,
    );

    response.status(status).json({
      statusCode: status,
      message,
      error: errorType,
      ...(errors ? { errors } : {}),
      ...(meta ? { meta } : {}),
    });
  }
}
