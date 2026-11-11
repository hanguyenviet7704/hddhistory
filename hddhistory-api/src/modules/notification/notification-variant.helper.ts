import { NotificationLogStatus } from './notification.enum';
import {
  INotificationCopy,
  INotificationVariant,
  NOTIFICATION_FALLBACK_LOCALE,
} from './schema/notification-template.schema';

/**
 * Choosing which wording a scheduled notification goes out with.
 *
 * A separate module, like `notification-timezone.helper`, because all of it is
 * pure: the rules here ("not the same sentence as the last three days", "never
 * push a sentence whose placeholder has nothing to fill it") are the part worth
 * unit-testing, and testing them through the dispatcher would mean mocking
 * Mongo, Firebase and the clock to assert on a string choice.
 */

/**
 * How many of the user's own previous days a wording must not appear in — the
 * sheet's "random 1 nội dung, không trùng với 3 ngày gần nhất".
 *
 * Relaxed rather than enforced when a type has too few variants to honour it: a
 * type with three variants would otherwise run out of choices on day four and
 * send nothing at all, and a missed notification is a worse outcome than a
 * repeated sentence.
 */
export const VARIANT_COOLDOWN_DAYS = 3;

/**
 * Placeholders that may render empty instead of disqualifying the wording.
 *
 * Only the reader's name: guests and Apple private-relay sign-ups genuinely have
 * none, and dropping every sentence that greets them would leave those users
 * with no notification at all. Content-bearing placeholders are different — a
 * push that says `Hoàn thành "{course_name}"` with nothing to substitute is
 * worse than silence, so those disqualify the variant.
 */
const OPTIONAL_PLACEHOLDERS = new Set(['user_name']);

const PLACEHOLDER_PATTERN = /\{(\w+)\}/g;

export interface INotificationVariantPick {
  variant: INotificationVariant;
  copy: INotificationCopy;
}

/** One log row, as much of it as the cooldown map needs. */
export interface INotificationVariantHistoryRow {
  localDate: string;
  status: string;
  meta?: Record<string, unknown> | null;
}

/**
 * The wordings a template offers, including a document saved before variants
 * existed — its single [copies] map reads as one variant keyed `v1`.
 *
 * Both fields are checked rather than trusting `variants` alone because
 * `seedMissing` never rewrites a live document: every environment that already
 * had this feature running still carries copy in the old shape.
 */
export function variantsOf(template: {
  variants?: INotificationVariant[] | null;
  copies?: Record<string, INotificationCopy> | null;
}): INotificationVariant[] {
  const variants = (template.variants ?? []).filter(
    variant => variant && Object.keys(variant.copies ?? {}).length > 0,
  );
  if (variants.length > 0) return variants;

  const copies = template.copies ?? {};
  if (Object.keys(copies).length === 0) return [];
  return [{ key: 'v1', copies }];
}

/**
 * The highest `v<n>` in the list, or 0 for a list with no such key.
 *
 * Only used to bootstrap `NotificationTemplate.variantSeq` for a document
 * written before that counter existed: keys must never be recycled, because a
 * key still present in the last few days of logs would make the cooldown
 * suppress a wording that was in fact never sent.
 */
export function highestVariantSeq(variants: INotificationVariant[]): number {
  let highest = 0;
  for (const variant of variants ?? []) {
    const match = /^v(\d+)$/.exec(variant?.key ?? '');
    if (match) highest = Math.max(highest, Number(match[1]));
  }
  return highest;
}

/**
 * Copy for [language], falling back to English — which is what the sheet's
 * id/ms/fil audiences get today, since the app itself ships only five locales.
 */
export function copyForLocale(
  copies: Record<string, INotificationCopy> | undefined | null,
  language?: string,
): INotificationCopy | null {
  if (!copies) return null;
  const normalized = (language ?? '').toLowerCase().split(/[-_]/)[0];
  return copies[normalized] ?? copies[NOTIFICATION_FALLBACK_LOCALE] ?? null;
}

/** Every `{placeholder}` the wording uses, deduplicated. */
export function placeholdersOf(copy: INotificationCopy): string[] {
  const found = new Set<string>();
  for (const text of [copy?.title ?? '', copy?.body ?? '']) {
    for (const match of text.matchAll(PLACEHOLDER_PATTERN)) found.add(match[1]);
  }
  return [...found];
}

/**
 * How many days ago each wording last reached this user, from their own log rows.
 *
 * Only `sent` rows count. A claimed-then-failed row means the phone never showed
 * that sentence, so letting it burn the wording's cooldown would narrow the pool
 * for nothing.
 */
export function variantCooldownMap(
  rows: INotificationVariantHistoryRow[],
  todayLocalDate: string,
): Map<string, number> {
  const daysAgoByKey = new Map<string, number>();
  for (const row of rows ?? []) {
    if (row?.status !== NotificationLogStatus.SENT) continue;
    const key = row.meta?.variantKey;
    if (typeof key !== 'string' || key === '') continue;

    const daysAgo = localDaysBetween(row.localDate, todayLocalDate);
    if (daysAgo === null || daysAgo < 0) continue;

    const known = daysAgoByKey.get(key);
    if (known === undefined || daysAgo < known) daysAgoByKey.set(key, daysAgo);
  }
  return daysAgoByKey;
}

/**
 * The wording to send, or null when none can be rendered for this user.
 *
 * Order of the three filters matters: eligibility first (a variant that cannot
 * render is never a candidate, however long since it was used), then the
 * cooldown, then chance. The cooldown is the only one allowed to be relaxed.
 */
export function pickVariant(args: {
  variants: INotificationVariant[];
  language?: string;
  variables: Record<string, string>;
  /** From [variantCooldownMap]; absent means this user has no history. */
  daysSinceLastUse?: Map<string, number>;
  /** Injected in tests; production uses `Math.random`. */
  random?: () => number;
}): INotificationVariantPick | null {
  const { variants, language, variables, daysSinceLastUse } = args;
  const random = args.random ?? Math.random;

  const renderable: INotificationVariantPick[] = [];
  const renderableWithoutName: INotificationVariantPick[] = [];

  for (const variant of variants ?? []) {
    const copy = copyForLocale(variant?.copies, language);
    // No title is a push with no text on the lock screen.
    if (!copy || !copy.title?.trim()) continue;

    const unresolved = placeholdersOf(copy).filter(
      name => !(variables[name] ?? '').trim(),
    );
    if (unresolved.some(name => !OPTIONAL_PLACEHOLDERS.has(name))) continue;

    const pick = { variant, copy };
    if (unresolved.length === 0) renderable.push(pick);
    else renderableWithoutName.push(pick);
  }

  // A greeting-free wording beats greeting nobody, so the nameless-reader pool
  // is only used when nothing else can render.
  const pool = renderable.length > 0 ? renderable : renderableWithoutName;
  if (pool.length === 0) return null;

  for (const window of [VARIANT_COOLDOWN_DAYS, 1]) {
    const fresh = pool.filter(
      item => (daysSinceLastUse?.get(item.variant.key) ?? Infinity) > window,
    );
    if (fresh.length > 0) return pickRandom(fresh, random);
  }
  return pickRandom(pool, random);
}

/** [localDate] shifted by [days], both `YYYY-MM-DD`. */
export function shiftLocalDate(localDate: string, days: number): string {
  const parsed = parseLocalDate(localDate);
  if (parsed === null) return localDate;
  const shifted = new Date(parsed + days * MS_PER_DAY);
  return shifted.toISOString().slice(0, 10);
}

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/** Whole days from [from] to [to], or null when either is not a local date. */
function localDaysBetween(from: string, to: string): number | null {
  const start = parseLocalDate(from);
  const end = parseLocalDate(to);
  if (start === null || end === null) return null;
  return Math.round((end - start) / MS_PER_DAY);
}

/**
 * `YYYY-MM-DD` as a UTC instant. UTC on purpose: these strings are already the
 * user's own calendar day, so re-interpreting them in the server's zone would
 * shift the day boundary by the server's offset.
 */
function parseLocalDate(localDate: string): number | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate ?? '')) return null;
  const parsed = Date.parse(`${localDate}T00:00:00.000Z`);
  return Number.isNaN(parsed) ? null : parsed;
}

function pickRandom<T>(items: T[], random: () => number): T {
  const index = Math.min(items.length - 1, Math.floor(random() * items.length));
  return items[index];
}
