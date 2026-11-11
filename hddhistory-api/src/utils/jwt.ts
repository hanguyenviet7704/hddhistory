import { Injectable } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';

import { Configuration } from '@base/config/configuration';

@Injectable()
export class JwtUtil {
  constructor(private readonly configuration: Configuration) {}
  private readonly secret = this.configuration.jwtSecret;

  sign(payload: any, expiresIn = '7d') {
    return jwt.sign(payload, this.secret, { expiresIn });
  }

  verify<T = any>(token: string): T | null {
    try {
      return jwt.verify(token, this.secret) as T;
    } catch {
      return null;
    }
  }
}
