import { PromoCampaignStats } from "../utils/promoCampaignForm";
import axiosClient from "./axiosClient";

/**
 * One popup campaign in the list. Position in the array is the tie-break order
 * (higher `priority` wins first; ties keep this array's order).
 */
export interface HomePopupItem {
  /** Admin-facing campaign label — never shown in the app, for finding it in this list. */
  name?: string;
  /**
   * The whole popup is this one image; copy is baked into it, which is what keeps
   * admin-entered text out of an app that ships five locales.
   *
   * CHANGING THIS (or the link) STARTS A NEW CAMPAIGN: the campaign key is a hash
   * of image + link, so everyone who already tapped the previous one will see the
   * new one. Restoring a previous image restores its key too, so people who acted
   * on that exact offer are not asked again.
   */
  imageUrl: string;
  /** Where tapping the image lands. Tapping is what retires the popup per user. */
  linkUrl?: string;
  /**
   * Market allow-list. EMPTY MEANS EVERY MARKET. Matched against the viewer's
   * resolved markets (IP, device region, app language), so picking VN still
   * reaches Vietnamese readers abroad.
   */
  countries?: string[];
  /**
   * Language allow-list, lowercase (vi, en, zh, ja, ko). EMPTY MEANS EVERY
   * LANGUAGE. Matched against the `lang` header the app sends.
   */
  locales?: string[];
  /**
   * Audience segment allow-list (see `segmentService`). EMPTY MEANS EVERYONE.
   * Matching ANY listed segment is enough — this is an OR across segments,
   * separate from (and additional to) the countries/locales targeting above.
   */
  segmentIds?: string[];
  /** Higher wins when several campaigns target the same viewer and neither was tapped yet. */
  priority?: number;
  /** Campaign window start (server clock), ISO string. `null`/omitted = already started. */
  startAt?: string | null;
  /** Campaign window end (server clock), ISO string. `null`/omitted = never expires. */
  endAt?: string | null;
  /** Per-campaign switch — false keeps the creative staged without showing it. */
  enabled?: boolean;
}

export interface HomePopupConfig {
  /** Kill switch — false stops the whole popup feature in the app without a release. */
  enabled: boolean;
  /** Legacy flat fields — still accepted by the API, superseded by `popups` below. */
  imageUrl: string;
  linkUrl: string;
  countries: string[];
  /**
   * Identity of the current (legacy flat) creative, computed by the API.
   * Read-only. Prefer the per-item `campaignKey` in `popupStats` once the list
   * shape is in use.
   */
  campaignKey?: string;
  /** The campaign list, in priority/array order. This is what the editor now writes. */
  popups?: HomePopupItem[];
  /**
   * Impressions/clicks/CTR per campaign, ALIGNED BY INDEX with `popups` (for a
   * legacy config with empty `popups` but a flat `imageUrl`, index 0 is that
   * single popup). Computed by the API — never sent back on save.
   */
  popupStats?: PromoCampaignStats[];
}

export const homePopupService = {
  /**
   * The config exactly as stored.
   *
   * `/home-popup/config`, NOT the `/home-popup` the app reads: that one's answer
   * depends on the caller's market AND on whether the caller already tapped, so an
   * operator would see their own history reflected back as config.
   */
  async get() {
    const res = await axiosClient.get("/home-popup/config");
    return res.data;
  },

  async update(payload: Partial<HomePopupConfig>) {
    const res = await axiosClient.put("/home-popup", payload);
    return res.data;
  },
};
