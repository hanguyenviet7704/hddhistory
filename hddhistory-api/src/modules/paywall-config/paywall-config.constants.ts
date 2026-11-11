/**
 * MySQL (`paywall_configs`) is now the source of truth for `paywall_config`
 * -- see the `PaywallConfig` entity and `PaywallConfigRepository`. Firebase
 * Remote Config is kept ONLY as a one-time read source: the very first call
 * to `GET /paywall-config` (or `/paywall-config/mobile`) after this table is
 * created seeds version 1 from whatever value is live there today, so the
 * cutover never resets the paywall to defaults. There is no write-to-Remote-
 * Config path anymore.
 */
export const PAYWALL_CONFIG_PARAMETER_KEY = 'paywall_config';

/** `publishedBy` sentinel for the version-1 row created by that seed. */
export const REMOTE_CONFIG_SEED_PUBLISHED_BY = 'system:remote-config-seed';

/**
 * The app-side event names and param the body A/B readout reads back.
 *
 * Hard-coded here rather than passed in by the caller: the readout is only
 * meaningful over the exact three steps the paywall reports, and they must
 * match `TrackingKey` in the Flutter app character for character
 * (`premiumScrView` / `premiumAllpackPick` / `premiumPurchase`). A typo would
 * not fail -- it would return an honest-looking zero.
 */
export const PAYWALL_EXPERIMENT_EVENTS = {
  view: 'paywall_scr_view',
  planClick: 'paywall_plan_click',
  upgradeClick: 'paywall_upgrade_click',
} as const;

/** Param the app stamps the arm on. Mirrors `_premiumParams()` in the app. */
export const PAYWALL_EXPERIMENT_PARAM = 'paywall_body_variant';

/** Param the app stamps the run on, used to scope the funnel to one run. */
export const PAYWALL_EXPERIMENT_KEY_PARAM = 'paywall_experiment_key';
