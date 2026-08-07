import React, { useState } from "react";
import { DocumentDuplicateIcon } from "@heroicons/react/24/outline";
import {
  PAYWALL_CONFIG_LOCALES,
  PAYWALL_CONFIG_LOCALE_LABELS,
  PaywallLocale,
} from "../../types/interface/paywall-config.interface";
import { LocalizedLineDraft } from "../../pages/paywall-config/paywallConfigDraft";

interface GiftTitleEditorProps {
  value: LocalizedLineDraft;
  onChange: (next: LocalizedLineDraft) => void;
  disabled?: boolean;
  idPrefix: string;
}

/**
 * Same tab-bar convention as `LocaleContentEditor`/`ReviewContentEditor` (EN
 * required, dot marks a filled locale, "copy from EN") but for the gift
 * popup's single free-text field.
 */
const GiftTitleEditor: React.FC<GiftTitleEditorProps> = ({
  value,
  onChange,
  disabled = false,
  idPrefix,
}) => {
  const [activeLocale, setActiveLocale] = useState<PaywallLocale>("en");

  const updateLocale = (locale: PaywallLocale, text: string) => {
    onChange({ ...value, [locale]: text });
  };

  const canCopyFromEn =
    activeLocale !== "en" && Boolean(value.en.trim()) && !value[activeLocale].trim();

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-1.5" role="tablist">
        {PAYWALL_CONFIG_LOCALES.map((locale) => {
          const isActive = locale === activeLocale;
          const filled = Boolean(value[locale].trim());
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
            onClick={() => updateLocale(activeLocale, value.en)}
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
        className="rounded-lg border border-slate-200 p-3"
      >
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">
            Tiêu đề popup
            {activeLocale === "en" && <span className="text-red-500 ml-0.5">*</span>}
          </span>
          <input
            value={value[activeLocale]}
            onChange={(e) => updateLocale(activeLocale, e.target.value)}
            placeholder="A special gift for you!"
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
        </label>
      </div>
    </div>
  );
};

export default GiftTitleEditor;
