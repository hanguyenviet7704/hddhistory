import React, { useState } from "react";
import { DocumentDuplicateIcon, ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import {
  PAYWALL_CONFIG_LOCALES,
  PAYWALL_CONFIG_LOCALE_LABELS,
  PaywallLocale,
} from "../../types/interface/paywall-config.interface";
import {
  isReviewContentEmpty,
  ReviewLocalizedContentDraft,
} from "../../pages/paywall-config/paywallConfigDraft";

interface ReviewContentEditorProps {
  value: ReviewLocalizedContentDraft;
  onChange: (next: ReviewLocalizedContentDraft) => void;
  disabled?: boolean;
  /** Shown once, above the tab bar, when the English copy is missing/required. */
  requiredError?: string;
  idPrefix: string;
}

/**
 * Same tab-bar convention as `LocaleContentEditor` (EN required, dot marks a
 * filled locale, "copy from EN" once a locale is untouched) but for a review
 * card's two free-text fields instead of subheading/heading/benefits.
 */
const ReviewContentEditor: React.FC<ReviewContentEditorProps> = ({
  value,
  onChange,
  disabled = false,
  requiredError,
  idPrefix,
}) => {
  const [activeLocale, setActiveLocale] = useState<PaywallLocale>("en");

  const updateLocale = (locale: PaywallLocale, patch: Partial<{ title: string; body: string }>) => {
    onChange({ ...value, [locale]: { ...value[locale], ...patch } });
  };

  const current = value[activeLocale];

  const copyFromEn = () => {
    updateLocale(activeLocale, { title: value.en.title, body: value.en.body });
  };

  const canCopyFromEn =
    activeLocale !== "en" &&
    !isReviewContentEmpty(value.en) &&
    isReviewContentEmpty(current);

  return (
    <div className="space-y-3">
      {requiredError && (
        <p className="text-xs text-red-600 flex items-center gap-1.5">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          {requiredError}
        </p>
      )}

      <div className="flex flex-wrap items-center gap-1.5" role="tablist">
        {PAYWALL_CONFIG_LOCALES.map((locale) => {
          const isActive = locale === activeLocale;
          const filled = !isReviewContentEmpty(value[locale]);
          return (
            <button
              key={locale}
              type="button"
              role="tab"
              aria-selected={isActive}
              aria-controls={`${idPrefix}-panel-${locale}`}
              id={`${idPrefix}-tab-${locale}`}
              onClick={() => setActiveLocale(locale)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition inline-flex items-center gap-1.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1 ${
                isActive
                  ? "bg-teal-600 border-teal-600 text-white"
                  : "border-slate-200 text-slate-600 hover:bg-slate-50"
              }`}
              title={PAYWALL_CONFIG_LOCALE_LABELS[locale]}
            >
              {locale.toUpperCase()}
              {locale === "en" && <span className="opacity-80">*</span>}
              {filled && (
                <span
                  className={`h-1.5 w-1.5 rounded-full ${
                    isActive ? "bg-white" : "bg-emerald-500"
                  }`}
                  aria-hidden="true"
                />
              )}
            </button>
          );
        })}

        {canCopyFromEn && (
          <button
            type="button"
            onClick={copyFromEn}
            disabled={disabled}
            className="ml-1 inline-flex items-center gap-1 text-xs text-teal-700 hover:text-teal-800 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1 rounded"
          >
            <DocumentDuplicateIcon className="h-3.5 w-3.5" />
            Sao chép từ EN
          </button>
        )}
      </div>

      <div
        role="tabpanel"
        id={`${idPrefix}-panel-${activeLocale}`}
        aria-labelledby={`${idPrefix}-tab-${activeLocale}`}
        className="rounded-lg border border-slate-200 p-3 space-y-3"
      >
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Tiêu đề review</span>
          <input
            value={current.title}
            onChange={(e) => updateLocale(activeLocale, { title: e.target.value })}
            placeholder="Đúng thứ tôi cần"
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Nội dung review</span>
          <textarea
            value={current.body}
            onChange={(e) => updateLocale(activeLocale, { body: e.target.value })}
            placeholder="Dùng app này giúp tôi duy trì thói quen học đều đặn."
            disabled={disabled}
            rows={2}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 resize-y"
          />
        </label>
      </div>
    </div>
  );
};

export default ReviewContentEditor;
