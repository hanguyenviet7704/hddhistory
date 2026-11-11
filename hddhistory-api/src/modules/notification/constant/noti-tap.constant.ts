/**
 * The app event a tap on one of our pushes fires, and the `params` keys it
 * carries. All three are the app's vocabulary (`TrackingKey.notiTap` and the
 * map built in `deeplink_cubit._handleScheduledNotificationTap`), mirrored to
 * `user_events` by its BackendTrackingService.
 *
 * Named in one place rather than inlined at each reader so the coupling is
 * findable: if the app ever renames one of them the click column goes silently
 * to zero — nothing fails, nothing logs — and this is the file a grep for
 * `noti_tap` lands on.
 */
export const NOTI_TAP_EVENT = 'noti_tap';

/**
 * The `NotificationType` this API put in the push payload. Present on the eight
 * scheduled types; on a manual campaign it is always `CAMPAIGN_NOTI_TYPE`,
 * which is why it cannot tell two campaigns apart.
 */
export const NOTI_TAP_TYPE_PARAM = 'noti_type';

/**
 * The campaign a tap belongs to — the only param that separates one manual
 * campaign from another. Sent by app builds from 2026-08-25 on; a tap from an
 * older build carries `noti_type: 'campaign'` and no id, so it is invisible to
 * the per-campaign count while still landing in the type-level one.
 */
export const NOTI_TAP_CAMPAIGN_PARAM = 'campaign_id';
