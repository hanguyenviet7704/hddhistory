import {
  CanActivate,
  ExecutionContext,
  Injectable,
  OnModuleDestroy,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { LoggerService } from '@base/logging/logger.service';
import { JwtUtil } from '@utils/jwt';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

@Injectable()
export class AuthGuard implements CanActivate, OnModuleInit, OnModuleDestroy {
  // Cache validated user+device pairs to skip a DB round-trip on every
  // authenticated request. Stores expiry timestamps (ms); only positive
  // results are cached, so a removed device is rejected within the TTL.
  private readonly deviceCache = new Map<string, number>();
  private static readonly DEVICE_CACHE_TTL_MS = 60_000;
  // Periodically sweep expired entries so the map doesn't grow unboundedly
  // over the life of the (long-running, PM2-managed) process — otherwise
  // every distinct device ever seen stays cached forever.
  private static readonly DEVICE_CACHE_SWEEP_INTERVAL_MS =
    AuthGuard.DEVICE_CACHE_TTL_MS * 5;
  private sweepTimer?: NodeJS.Timeout;

  constructor(
    private readonly jwt: JwtUtil,
    private readonly reflector: Reflector,
    private readonly i18n: I18nService,
    private readonly loggerService: LoggerService,
    private readonly userRepository: UserRepository,
  ) {}

  onModuleInit() {
    this.sweepTimer = setInterval(
      () => this.sweepDeviceCache(),
      AuthGuard.DEVICE_CACHE_SWEEP_INTERVAL_MS,
    );
  }

  onModuleDestroy() {
    if (this.sweepTimer) {
      clearInterval(this.sweepTimer);
    }
  }

  private sweepDeviceCache() {
    const now = Date.now();
    for (const [key, expiry] of this.deviceCache) {
      if (expiry <= now) {
        this.deviceCache.delete(key);
      }
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    const isPublic = this.reflector.get<boolean>(
      'isPublic',
      context.getHandler(),
    );
    if (isPublic) {
      return true;
    }

    const authHeader = request.headers['authorization'];
    const lang = I18nContext.current().lang;
    if (!authHeader)
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.UNAUTHORIZED', {
          lang,
        }),
      );

    const token = authHeader.split(' ')[1];

    if (!token)
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.INVALID_TOKEN_FORMAT', {
          lang,
        }),
      );

    try {
      const decode = await this.jwt.verify(token);

      if (decode === null) {
        throw new UnauthorizedException(
          this.i18n.t('error.AUTH.EXPIRED_TOKEN', {
            lang,
          }),
        );
      } else if (!decode) {
        throw new UnauthorizedException(
          this.i18n.t('error.AUTH.INVALID_TOKEN_FORMAT', {
            lang,
          }),
        );
      }

      // check device (cached for a short TTL to avoid a DB hit per request)
      const deviceCacheKey = `${decode.id}:${decode.deviceId}`;
      const now = Date.now();
      const cachedExpiry = this.deviceCache.get(deviceCacheKey);

      let deviceValid = cachedExpiry !== undefined && cachedExpiry > now;
      if (!deviceValid) {
        deviceValid = !!(await this.userRepository.checkExitsDevice(
          decode.id,
          decode.deviceId,
        ));
        if (deviceValid) {
          this.deviceCache.set(
            deviceCacheKey,
            now + AuthGuard.DEVICE_CACHE_TTL_MS,
          );
        }
      }

      if (!deviceValid) {
        throw new UnauthorizedException(
          this.i18n.t('error.AUTH.WRONG_DEVICE', {
            lang,
          }),
        );
      }

      request.user = decode;

      return true;
    } catch (err: any) {
      throw new UnauthorizedException(err?.message ?? 'Unauthorized', {
        cause: err,
      });
    }
  }
}
