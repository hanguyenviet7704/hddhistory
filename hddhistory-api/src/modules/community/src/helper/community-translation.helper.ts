import { ITranslation } from '@utils/interface/common.interface';

import { DEFAULT_COMMUNITY_LOCALE } from '../interface/community.interface';

/**
 * The reader's language, then English, then whatever is filled in.
 *
 * A topic or weekly question missing its Japanese translation should still
 * render for a Japanese reader — a blank row reads as a bug, and this content
 * is authored by hand so gaps are normal.
 */
export function pickTranslation(
  value: ITranslation | Record<string, string> | undefined,
  locale: string,
): string {
  if (!value) return '';

  const bag = value as Record<string, string>;
  return (
    bag[locale] ||
    bag[DEFAULT_COMMUNITY_LOCALE] ||
    Object.values(bag).find(Boolean) ||
    ''
  );
}
