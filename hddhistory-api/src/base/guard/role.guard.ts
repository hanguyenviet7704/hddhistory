import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

@Injectable()
export class RoleGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly i18n: I18nService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.get<boolean>(
      'isPublic',
      context.getHandler(),
    );
    if (isPublic) {
      return true;
    }

    const requiredRoles = this.reflector.get<string[]>(
      'roles',
      context.getHandler(),
    );
    if (!requiredRoles || requiredRoles.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const lang = I18nContext.current().lang;

    if (!user || !user.role)
      throw new ForbiddenException(
        this.i18n.t('error.AUTH.FORBIDDEN', {
          lang,
        }),
      );

    if (!requiredRoles.includes(user.role)) {
      throw new ForbiddenException(
        this.i18n.t('error.AUTH.FORBIDDEN', {
          lang,
        }),
      );
    }

    return true;
  }
}
