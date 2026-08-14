/**
 * Link vào màn được dựng ở phía client, không phải do API trả về -- cùng lý do
 * đã ghi trong `downloadLinkService`: entitlement iOS là `applinks:meup.training`
 * không wildcard, nên admin không được phép hiện một host mà app chưa claim.
 */
export const DEEPLINK_WEB_BASE = "https://meup.training/open";
export const DEEPLINK_APP_BASE = "meup://open";

export interface DeeplinkUtm {
  source?: string;
  medium?: string;
  campaign?: string;
  content?: string;
  term?: string;
}

/**
 * UTM chỉ gắn vào link web, KHÔNG gắn vào `meup://`.
 *
 * Hai lý do. Với người chưa cài app, query của link web được `index.html`
 * chuyển tiếp vào `referrer` của Play và sống sót qua lượt cài -- đó là chỗ UTM
 * thực sự làm việc. Còn `meup://` chỉ được dán vào ô linkUrl của Banner/Popup
 * trong admin, tức là người dùng đã ở TRONG app rồi: không có kênh nào để quy
 * cho, và banner đã có tracking riêng của nó.
 */
const UTM_QUERY_KEYS: Record<keyof DeeplinkUtm, string> = {
  source: "utm_source",
  medium: "utm_medium",
  campaign: "utm_campaign",
  content: "utm_content",
  term: "utm_term",
};

export const buildDeeplinkUrl = (
  base: string,
  key: string,
  params: Record<string, string>,
  utm?: DeeplinkUtm
): string => {
  const query = new URLSearchParams();

  Object.entries(params).forEach(([name, value]) => {
    const trimmed = (value ?? "").trim();
    // Một khoá rỗng trong link đọc như "có truyền nhưng bỏ trống", và app sẽ coi
    // đó là thiếu tham số. Bỏ hẳn đi thì đúng nghĩa "không truyền".
    if (trimmed) query.set(name, trimmed);
  });

  if (utm && base === DEEPLINK_WEB_BASE) {
    (Object.keys(UTM_QUERY_KEYS) as (keyof DeeplinkUtm)[]).forEach((field) => {
      const trimmed = (utm[field] ?? "").trim();
      if (trimmed) query.set(UTM_QUERY_KEYS[field], trimmed);
    });
  }

  const suffix = query.toString();
  // URLSearchParams encode dấu cách thành '+', đúng cho form nhưng không phải
  // cho một URL sẽ được dán vào push và chat -- '%20' đi qua mọi chỗ đó lành.
  const normalized = suffix.replace(/\+/g, "%20");

  return normalized ? `${base}/${key}?${normalized}` : `${base}/${key}`;
};
