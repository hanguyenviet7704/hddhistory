/**
 * Link vào màn được dựng ở phía client, không phải do API trả về -- cùng lý do
 * đã ghi trong `downloadLinkService`: entitlement iOS là `applinks:meup.training`
 * không wildcard, nên admin không được phép hiện một host mà app chưa claim.
 */
export const DEEPLINK_WEB_BASE = "https://meup.training/open";
export const DEEPLINK_APP_BASE = "meup://open";

/** Nhãn campaign. Chỉ đi vào event tracking; app không đọc để điều hướng. */
export const DEEPLINK_CAMPAIGN_KEY = "c";

export const buildDeeplinkUrl = (
  base: string,
  key: string,
  params: Record<string, string>,
  campaign?: string
): string => {
  const query = new URLSearchParams();

  Object.entries(params).forEach(([name, value]) => {
    const trimmed = (value ?? "").trim();
    // Một khoá rỗng trong link đọc như "có truyền nhưng bỏ trống", và app sẽ coi
    // đó là thiếu tham số. Bỏ hẳn đi thì đúng nghĩa "không truyền".
    if (trimmed) query.set(name, trimmed);
  });

  const trimmedCampaign = (campaign ?? "").trim();
  if (trimmedCampaign) query.set(DEEPLINK_CAMPAIGN_KEY, trimmedCampaign);

  const suffix = query.toString();
  // URLSearchParams encode dấu cách thành '+', đúng cho form nhưng không phải
  // cho một URL sẽ được dán vào push và chat -- '%20' đi qua mọi chỗ đó lành.
  const normalized = suffix.replace(/\+/g, "%20");

  return normalized ? `${base}/${key}?${normalized}` : `${base}/${key}`;
};
