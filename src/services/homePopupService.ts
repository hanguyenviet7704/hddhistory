import axiosClient from "./axiosClient";

export interface HomePopupConfig {
  /** Kill switch — false stops the popup in the app without a release. */
  enabled: boolean;
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
  linkUrl: string;
  /**
   * Market allow-list. EMPTY MEANS EVERY MARKET. Matched against the viewer's
   * resolved markets (IP, device region, app language), so picking VN still
   * reaches Vietnamese readers abroad.
   */
  countries: string[];
  /**
   * Identity of the current creative, computed by the API. Read-only — shown so an
   * operator can tell at a glance whether an edit started a new campaign.
   */
  campaignKey?: string;
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
