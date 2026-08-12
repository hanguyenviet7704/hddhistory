import axiosClient from "./axiosClient";

/** One slide of the Home carousel. Position in the array is the display order. */
export interface HomeBannerSlide {
  /** Slide image URL (R2 upload). A slide with no image is never shown. */
  imageUrl: string;
  /** Tap destination: https:// URL or deeplink. Empty = not tappable. */
  linkUrl: string;
  /**
   * Per-slide market allow-list. EMPTY MEANS EVERY MARKET. Matched against the
   * viewer's resolved markets (IP, device region, app language), so one config
   * can carry a VN slide and a JP slide and each viewer only sees their own.
   */
  countries: string[];
  /** Per-slide switch — false keeps image and link staged without showing it. */
  enabled: boolean;
}

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
  /** The carousel, in display order. */
  slides: HomeBannerSlide[];
}

export const homeBannerService = {
  /**
   * The config exactly as stored.
   *
   * `/home-banner/config`, NOT the `/home-banner` the app reads: that one filters
   * slides to the caller's own markets, so opening this page from Vietnam would
   * show a Japan-only slide as simply absent — indistinguishable from lost.
   */
  async get() {
    const res = await axiosClient.get("/home-banner/config");
    return res.data;
  },

  async update(payload: Partial<HomeBannerConfig>) {
    const res = await axiosClient.put("/home-banner", payload);
    return res.data;
  },
};
