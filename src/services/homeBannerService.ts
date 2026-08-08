import axiosClient from "./axiosClient";

export interface HomeBannerConfig {
  /** Kill switch — false hides the banner in the app without a release. */
  enabled: boolean;
  /** Banner image URL (R2 upload). Empty also hides the banner. */
  imageUrl: string;
  /** Where a tap lands: https:// URL or app deeplink. Empty = not tappable. */
  linkUrl: string;
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
