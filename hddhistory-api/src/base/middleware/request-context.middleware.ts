import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

import { LoggerService } from '@base/logging/logger.service';
import {
  redactBody,
  REDACTED_TEXT,
  safeStringify,
} from '@utils/redact.util';

function redactAuthorizationHeader(value: unknown): unknown {
  if (typeof value !== 'string' || value.length === 0) {
    return value;
  }

  const [scheme] = value.split(' ');
  if (!scheme) return REDACTED_TEXT;

  return `${scheme} ${REDACTED_TEXT}`;
}

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor(private readonly loggerService: LoggerService) {}
  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, query, body, headers } = req;
    const isProduction = process.env.NODE_ENV === 'production';
    const authorizationHeader = headers['authorization'];
    const bodyForLog = isProduction ? redactBody(body) : body;
    const authorizationForLog = isProduction
      ? redactAuthorizationHeader(authorizationHeader)
      : authorizationHeader;

    this.loggerService.log(
      `${method} ${originalUrl}
      token: ${authorizationForLog}
      lang: ${headers['lang']}
      query: ${safeStringify(query)}
      body: ${safeStringify(bodyForLog)}`,
      'Request',
    );
    next();
  }
}
