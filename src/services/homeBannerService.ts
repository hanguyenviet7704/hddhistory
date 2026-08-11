import axiosClient from "./axiosClient";

export interface HomeBannerConfig {
  /** Kill switch — false hides the banner in the app without a release. */
  enabled: boolean;
  /** Banner image URL (R2 upload). Empty also hides the banner. */
  imageUrl: string;
  /** Where a tap lands: https:// URL or app deeplink. Empty = not tappable. */
  linkUrl: string;
  /**
   * ISO-3166 alpha-2 allow-list. EMPTY MEANS EVERYWHERE — that is what keeps
   * existing banners showing unchanged after this field was added.
   */
  countries: string[];
  /**
   * Computed by the API for whoever asked, from their IP country. Useless to
   * the admin panel — an operator sitting outside the target sees `false` for a
   * perfectly live banner — which is exactly why `enabled` was left alone and
   * this was added beside it. Read `enabled` + `countries` here, never this.
   */
  visible: boolean;
}

export const homeBannerService = {
  async get() {
    const res = await axiosClient.get("/home-banner");
    return res.data;
  },

  async update(payload: Partial<HomeBannerConfig>) {
    const res = await axiosClient.put("/home-banner", payload);
    return res.data;
  },
};
