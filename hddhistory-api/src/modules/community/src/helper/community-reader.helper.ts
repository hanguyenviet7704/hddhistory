import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import {
  COMMUNITY_LOCALES,
  CommunityLocale,
  DEFAULT_COMMUNITY_LOCALE,
} from '../interface/community.interface';

/**
 * Which feed this reader sees, taken from the `lang` header.
 *
 * NOT from `user.language`: `AuthGuard` sets `request.user` to the decoded JWT,
 * whose payload is `{id, deviceId, email, name, anonymous}` — there is no
 * `language` on it, so reading one gave every caller the English feed and left
 * the whole locale split inert.
 *
 * Also not `I18nContext.current().lang`: nestjs-i18n only ships en and vi under
 * `src/base/i18n`, so it resolves `ja` down to the default and would collapse
 * three of the five feeds into English. The raw header is what the app and the
 * admin panel both send (`app_interceptor.dart`, `axiosClient.ts`), and it is
 * the language the caller is actually reading in.
 */
export function normalizeCommunityLocale(raw?: string): CommunityLocale {
  // Accepts 'vi' and 'vi-VN' alike; anything the community does not ship falls
  // back to English rather than filtering the feed down to nothing.
  const language = (raw ?? '').toLowerCase().split('-')[0];

  return (COMMUNITY_LOCALES as readonly string[]).includes(language)
    ? (language as CommunityLocale)
    : DEFAULT_COMMUNITY_LOCALE;
}

/** The caller's community locale, resolved from the `lang` header. */
export const ReaderLocale = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): CommunityLocale =>
    normalizeCommunityLocale(
      ctx.switchToHttp().getRequest()?.headers?.['lang'] as string,
    ),
);

// createdBy / updatedBy stamp on writes. UserMetaDto exposes id/email/name,
// all of which the JWT payload carries.
export function userMeta(user: IUser): IUserMeta {
  return user as unknown as IUserMeta;
}
