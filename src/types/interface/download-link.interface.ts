export type ClickPlatform = "ios" | "android" | "desktop" | "unknown";

/**
 * Where a click came from, detected server-side from the in-app webview's
 * User-Agent first (those send no Referer) and the Referer host second.
 * "unknown" = clicks recorded before source detection existed.
 */
export type ClickSource =
  | "facebook"
  | "instagram"
  | "threads"
  | "tiktok"
  | "zalo"
  | "telegram"
  | "google"
  | "direct"
  | "other"
  | "unknown";

export interface IDownloadLink {
  id: string;
  slug: string;
  name: string;
  description?: string | null;
  utmSource?: string | null;
  utmMedium?: string | null;
  utmCampaign?: string | null;
  /** Preview card served to link crawlers. Empty = generic MeUp card. */
  ogTitle?: string | null;
  ogDescription?: string | null;
  /** Absolute https URL, ideally 1200x630 — crawlers reject data: URIs. */
  ogImage?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  /** Present on the list endpoint only. */
  totalClicks?: number;
}

/** `slug` is create-only — see UpdateDownloadLinkDto on the API side. */
export interface DownloadLinkPayload {
  slug?: string;
  name: string;
  description?: string;
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
  ogTitle?: string;
  ogDescription?: string;
  ogImage?: string;
  isActive?: boolean;
}

export interface DownloadLinkListQuery {
  page: number;
  take: number;
  search: string;
  isActive: boolean;
}

export interface ClickBucket {
  key: string;
  total: number;
}

export interface DownloadLinkStats {
  link: IDownloadLink;
  range: { from: string; to: string };
  total: number;
  /**
   * Null when DOWNLOAD_LINK_IP_SALT is not configured on the server: the API
   * stores no ip hash at all in that case, so "0 unique" would be a confident
   * lie. Render it as "not measured", not as zero.
   */
  unique: number | null;
  byDay: ClickBucket[];
  byPlatform: ClickBucket[];
  byCountry: ClickBucket[];
  bySource: ClickBucket[];
}
