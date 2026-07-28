// Draft model for the paywall-config editor: a form-friendly mirror of
// `PaywallConfig` (numbers as strings for controlled inputs, stable
// `_localId`s on every repeatable array so React keys / add-remove stay
// simple), plus the mapping to/from the wire shape and client-side
// validation that mirrors `PaywallConfigService.validateShape` +
// `assertProductsExist` field-for-field so the operator sees inline errors
// immediately, without a round trip -- see PaywallConfigPage for why this
// matters (the shared AllExceptionsFilter/BaseValidationPipe in meup-api
// collapse structured `errors` arrays down to a single message today).
import {
  PAYWALL_CONFIG_LOCALES,
  PaywallAutoOpen,
  PaywallBenefit,
  PaywallConfig,
  PaywallDefaultUser,
  PaywallImpressionRule,
  PaywallLocale,
  PaywallLocaleContent,
  PaywallLocalizedContent,
  PaywallNewUser,
  PaywallProductRef,
  PaywallSaleEvent,
  PaywallSaleStrategy,
} from "../../types/interface/paywall-config.interface";

let localIdCounter = 0;
export const nextLocalId = () => `local-${++localIdCounter}`;

export interface ProductOption {
  id: string;
  productId: string;
  title: string;
}

export interface ProductsByPlatform {
  apple: ProductOption[];
  google: ProductOption[];
}

export interface ProductRefDraft extends PaywallProductRef {
  _localId: string;
}

export interface BenefitDraft extends PaywallBenefit {
  _localId: string;
}

export interface LocaleContentDraft {
  subheading: string;
  heading: string;
  benefits: BenefitDraft[];
}

export type LocalizedContentDraft = Record<PaywallLocale, LocaleContentDraft>;

export interface DefaultUserDraft {
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
}

export interface ImpressionRuleDraft {
  _localId: string;
  fromImpression: string;
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
}

export interface NewUserDraft {
  enabled: boolean;
  windowDays: string;
  content: LocalizedContentDraft;
  impressionRules: ImpressionRuleDraft[];
}

export interface SaleEventDraft {
  enabled: boolean;
  campaignId: string;
  startAtUtc: string;
  endAtUtc: string;
  appliesTo: string;
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
}

export interface ConfigDraft {
  schemaVersion: string;
  enableLessonLock: boolean;
  lessonLockText: string;
  autoOpenEnabled: boolean;
  autoOpenPercent: string;
  defaultUser: DefaultUserDraft;
  newUser: NewUserDraft;
  saleEvent: SaleEventDraft;
}

// ---------------------------------------------------------------------
// Empty / default builders
// ---------------------------------------------------------------------

export const emptyLocaleContent = (): LocaleContentDraft => ({
  subheading: "",
  heading: "",
  benefits: [],
});

export const emptyLocalizedContent = (): LocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [locale, emptyLocaleContent()])
  ) as LocalizedContentDraft;

export const emptyProductRef = (): ProductRefDraft => ({
  _localId: nextLocalId(),
  appleProductId: "",
  googleProductId: "",
});

export const emptyImpressionRule = (): ImpressionRuleDraft => ({
  _localId: nextLocalId(),
  fromImpression: "",
  content: emptyLocalizedContent(),
  products: [],
});

export const defaultDraft = (): ConfigDraft => ({
  schemaVersion: "1",
  enableLessonLock: false,
  lessonLockText: "",
  autoOpenEnabled: false,
  autoOpenPercent: "0",
  defaultUser: {
    content: emptyLocalizedContent(),
    products: [],
  },
  newUser: {
    enabled: false,
    windowDays: "",
    content: emptyLocalizedContent(),
    impressionRules: [],
  },
  saleEvent: {
    enabled: false,
    campaignId: "",
    startAtUtc: "",
    endAtUtc: "",
    appliesTo: "",
    content: emptyLocalizedContent(),
    products: [],
  },
});

// ---------------------------------------------------------------------
// Wire (PaywallConfig) -> Draft
// ---------------------------------------------------------------------

const toLocaleContentDraft = (content?: PaywallLocaleContent): LocaleContentDraft => ({
  subheading: content?.subheading ?? "",
  heading: content?.heading ?? "",
  benefits: (content?.benefits ?? []).map((b) => ({ ...b, _localId: nextLocalId() })),
});

const toLocalizedContentDraft = (
  content?: PaywallLocalizedContent
): LocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [
      locale,
      toLocaleContentDraft(content?.[locale]),
    ])
  ) as LocalizedContentDraft;

const toProductRefDraft = (ref: PaywallProductRef): ProductRefDraft => ({
  _localId: nextLocalId(),
  appleProductId: ref.appleProductId ?? "",
  googleProductId: ref.googleProductId ?? "",
});

const toDateTimeInput = (value?: string): string => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate()
  )}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

const stringifyAppliesTo = (value: unknown): string => {
  if (value === undefined || value === null) return "";
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
};

export const toDraft = (config: PaywallConfig): ConfigDraft => ({
  schemaVersion: String(config.schemaVersion ?? 1),
  enableLessonLock: Boolean(config.enableLessonLock),
  lessonLockText: config.lessonLock
    ? JSON.stringify(config.lessonLock, null, 2)
    : "",
  autoOpenEnabled: Boolean(config.autoOpen?.enabled),
  autoOpenPercent:
    config.autoOpen?.sessionRolloutPercent != null
      ? String(config.autoOpen.sessionRolloutPercent)
      : "0",
  defaultUser: {
    content: toLocalizedContentDraft(config.saleStrategy?.defaultUser?.content),
    products: (config.saleStrategy?.defaultUser?.products ?? []).map(
      toProductRefDraft
    ),
  },
  newUser: {
    enabled: Boolean(config.saleStrategy?.newUser?.enabled),
    windowDays:
      config.saleStrategy?.newUser?.windowDays != null
        ? String(config.saleStrategy.newUser.windowDays)
        : "",
    content: toLocalizedContentDraft(config.saleStrategy?.newUser?.content),
    impressionRules: (config.saleStrategy?.newUser?.impressionRules ?? []).map(
      (rule): ImpressionRuleDraft => ({
        _localId: nextLocalId(),
        fromImpression: String(rule.fromImpression ?? ""),
        content: toLocalizedContentDraft(rule.content),
        products: (rule.products ?? []).map(toProductRefDraft),
      })
    ),
  },
  saleEvent: {
    enabled: Boolean(config.saleStrategy?.saleEvent?.enabled),
    campaignId: config.saleStrategy?.saleEvent?.campaignId ?? "",
    startAtUtc: toDateTimeInput(config.saleStrategy?.saleEvent?.startAtUtc),
    endAtUtc: toDateTimeInput(config.saleStrategy?.saleEvent?.endAtUtc),
    appliesTo: stringifyAppliesTo(config.saleStrategy?.saleEvent?.appliesTo),
    content: toLocalizedContentDraft(config.saleStrategy?.saleEvent?.content),
    products: (config.saleStrategy?.saleEvent?.products ?? []).map(
      toProductRefDraft
    ),
  },
});

// ---------------------------------------------------------------------
// Draft -> Wire (PaywallConfig payload)
// ---------------------------------------------------------------------

export const isLocaleContentEmpty = (content: LocaleContentDraft): boolean =>
  !content.subheading.trim() &&
  !content.heading.trim() &&
  content.benefits.every((b) => !b.icon.trim() && !b.title.trim());

export const isLocalizedContentEmpty = (content: LocalizedContentDraft): boolean =>
  PAYWALL_CONFIG_LOCALES.every((locale) => isLocaleContentEmpty(content[locale]));

const fromLocaleContentDraft = (content: LocaleContentDraft): PaywallLocaleContent => {
  const result: PaywallLocaleContent = {};
  if (content.subheading.trim()) result.subheading = content.subheading.trim();
  if (content.heading.trim()) result.heading = content.heading.trim();
  const benefits = content.benefits
    .filter((b) => b.icon.trim() || b.title.trim())
    .map((b) => ({ icon: b.icon.trim(), title: b.title.trim() }));
  if (benefits.length) result.benefits = benefits;
  return result;
};

/** Always includes `en`; other locales only if they have any content. */
const fromLocalizedContentDraft = (
  content: LocalizedContentDraft
): PaywallLocalizedContent => {
  const result = { en: fromLocaleContentDraft(content.en) } as PaywallLocalizedContent;
  PAYWALL_CONFIG_LOCALES.forEach((locale) => {
    if (locale === "en") return;
    if (!isLocaleContentEmpty(content[locale])) {
      (result as any)[locale] = fromLocaleContentDraft(content[locale]);
    }
  });
  return result;
};

const fromProductRefDraft = (ref: ProductRefDraft): PaywallProductRef => ({
  appleProductId: ref.appleProductId?.trim() || undefined,
  googleProductId: ref.googleProductId?.trim() || undefined,
});

const fromDateTimeInput = (value: string): string | undefined => {
  if (!value) return undefined;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString();
};

const parseAppliesTo = (value: string): unknown => {
  const trimmed = value.trim();
  if (!trimmed) return undefined;
  try {
    return JSON.parse(trimmed);
  } catch {
    // Not JSON (e.g. the bare word `all`, per the DTO's example) -- pass
    // the raw string through, matching `appliesTo: unknown`.
    return trimmed;
  }
};

export const fromDraft = (draft: ConfigDraft): PaywallConfig => {
  const defaultUser: PaywallDefaultUser = {
    content: fromLocalizedContentDraft(draft.defaultUser.content),
    products: draft.defaultUser.products.map(fromProductRefDraft),
  };

  const newUserContentEmpty = isLocalizedContentEmpty(draft.newUser.content);
  const newUser: PaywallNewUser = {
    enabled: draft.newUser.enabled,
    windowDays: draft.newUser.windowDays.trim()
      ? Number(draft.newUser.windowDays)
      : undefined,
    content: newUserContentEmpty
      ? undefined
      : fromLocalizedContentDraft(draft.newUser.content),
    impressionRules: draft.newUser.impressionRules.map(
      (rule): PaywallImpressionRule => ({
        fromImpression: Number(rule.fromImpression),
        content: fromLocalizedContentDraft(rule.content),
        products: rule.products.map(fromProductRefDraft),
      })
    ),
  };

  const saleEventContentEmpty = isLocalizedContentEmpty(draft.saleEvent.content);
  const saleEvent: PaywallSaleEvent = {
    enabled: draft.saleEvent.enabled,
    campaignId: draft.saleEvent.campaignId.trim() || undefined,
    startAtUtc: fromDateTimeInput(draft.saleEvent.startAtUtc),
    endAtUtc: fromDateTimeInput(draft.saleEvent.endAtUtc),
    appliesTo: parseAppliesTo(draft.saleEvent.appliesTo),
    content: saleEventContentEmpty
      ? undefined
      : fromLocalizedContentDraft(draft.saleEvent.content),
    products: draft.saleEvent.products.length
      ? draft.saleEvent.products.map(fromProductRefDraft)
      : undefined,
  };

  const saleStrategy: PaywallSaleStrategy = { defaultUser, newUser, saleEvent };

  const autoOpen: PaywallAutoOpen = {
    enabled: draft.autoOpenEnabled,
    sessionRolloutPercent: Number(draft.autoOpenPercent || 0),
  };

  let lessonLock: Record<string, unknown> | undefined;
  if (draft.lessonLockText.trim()) {
    try {
      lessonLock = JSON.parse(draft.lessonLockText);
    } catch {
      lessonLock = undefined;
    }
  }

  return {
    schemaVersion: Number(draft.schemaVersion || 1),
    enableLessonLock: draft.enableLessonLock,
    lessonLock,
    autoOpen,
    saleStrategy,
  };
};

// ---------------------------------------------------------------------
// Client-side validation -- mirrors PaywallConfigService.validateShape +
// assertProductsExist field-for-field (same `field` path strings) so this
// still works even though the shared exception filter in meup-api does not
// currently forward structured `errors` arrays back to the client.
// ---------------------------------------------------------------------

const validateProductRefRow = (
  ref: ProductRefDraft,
  field: string,
  productsByPlatform: ProductsByPlatform | null,
  errors: Record<string, string>
) => {
  const apple = ref.appleProductId?.trim();
  const google = ref.googleProductId?.trim();

  if (!apple && !google) {
    errors[field] = `${field}: phải có appleProductId và/hoặc googleProductId`;
    return;
  }

  if (!productsByPlatform) return; // catalog still loading -- skip existence check

  if (apple && !productsByPlatform.apple.some((p) => p.productId === apple)) {
    errors[`${field}.appleProductId`] = `Sản phẩm "${apple}" (apple) không tồn tại hoặc không active trong iap_products`;
  }
  if (google && !productsByPlatform.google.some((p) => p.productId === google)) {
    errors[`${field}.googleProductId`] = `Sản phẩm "${google}" (google) không tồn tại hoặc không active trong iap_products`;
  }
};

const validateProductsNonEmpty = (
  products: ProductRefDraft[],
  field: string,
  productsByPlatform: ProductsByPlatform | null,
  errors: Record<string, string>
) => {
  if (!products.length) {
    errors[field] = `${field}: phải có ít nhất 1 sản phẩm`;
    return;
  }
  products.forEach((ref, index) =>
    validateProductRefRow(ref, `${field}[${index}]`, productsByPlatform, errors)
  );
};

export const validateDraft = (
  draft: ConfigDraft,
  productsByPlatform: ProductsByPlatform | null
): Record<string, string> => {
  const errors: Record<string, string> = {};

  if (!draft.schemaVersion.trim() || Number(draft.schemaVersion) < 1) {
    errors.schemaVersion = "schemaVersion là bắt buộc và phải >= 1";
  }

  const percent = Number(draft.autoOpenPercent);
  if (
    draft.autoOpenPercent.trim() === "" ||
    Number.isNaN(percent) ||
    percent < 0 ||
    percent > 100
  ) {
    errors["autoOpen.sessionRolloutPercent"] =
      "autoOpen.sessionRolloutPercent là bắt buộc và phải là số từ 0 đến 100";
  }

  if (draft.lessonLockText.trim()) {
    try {
      JSON.parse(draft.lessonLockText);
    } catch {
      errors.lessonLock = "lessonLock phải là JSON hợp lệ";
    }
  }

  // defaultUser
  if (isLocalizedContentEmpty(draft.defaultUser.content)) {
    errors["saleStrategy.defaultUser.content"] =
      "saleStrategy.defaultUser.content là bắt buộc";
  }
  validateProductsNonEmpty(
    draft.defaultUser.products,
    "saleStrategy.defaultUser.products",
    productsByPlatform,
    errors
  );

  // newUser
  if (draft.newUser.enabled && draft.newUser.impressionRules.length === 0) {
    errors["saleStrategy.newUser.impressionRules"] =
      "saleStrategy.newUser.impressionRules: phải có ít nhất 1 rule khi bật người dùng mới";
  }
  draft.newUser.impressionRules.forEach((rule, index) => {
    const prefix = `saleStrategy.newUser.impressionRules[${index}]`;
    const fromImpression = Number(rule.fromImpression);
    if (
      !rule.fromImpression.trim() ||
      !Number.isInteger(fromImpression) ||
      fromImpression < 1
    ) {
      errors[`${prefix}.fromImpression`] = `${prefix}.fromImpression phải là số nguyên >= 1`;
    }
    if (isLocalizedContentEmpty(rule.content)) {
      errors[`${prefix}.content`] = `${prefix}.content là bắt buộc`;
    }
    validateProductsNonEmpty(
      rule.products,
      `${prefix}.products`,
      productsByPlatform,
      errors
    );
  });

  // saleEvent
  if (draft.saleEvent.enabled) {
    validateProductsNonEmpty(
      draft.saleEvent.products,
      "saleStrategy.saleEvent.products",
      productsByPlatform,
      errors
    );
  }

  return errors;
};

export const hasAnyError = (errors: Record<string, string>) =>
  Object.keys(errors).length > 0;

/** All [field, message] pairs whose field is `prefix` or nested under it. */
export const errorsWithPrefix = (
  errors: Record<string, string>,
  prefix: string
): [string, string][] =>
  Object.entries(errors).filter(
    ([field]) =>
      field === prefix || field.startsWith(`${prefix}.`) || field.startsWith(`${prefix}[`)
  );
