import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

/**
 * Reads the user that AuthGuard attached to the request.
 *
 * Preferred over injecting the request-scoped RequestService into a service:
 * taking the id as an argument keeps services singleton-scoped, which matters
 * on hot read paths such as the community feed.
 */
export const CurrentUser = createParamDecorator(
  (field: keyof IUser | undefined, ctx: ExecutionContext) => {
    const user = ctx.switchToHttp().getRequest()?.user as IUser;
    return field ? user?.[field] : user;
  },
);
