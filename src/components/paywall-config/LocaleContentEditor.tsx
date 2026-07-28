import React, { useState } from "react";
import {
  DocumentDuplicateIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import {
  PAYWALL_CONFIG_LOCALES,
  PAYWALL_CONFIG_LOCALE_LABELS,
  PaywallLocale,
} from "../../types/interface/paywall-config.interface";
import {
  BenefitDraft,
  isLocaleContentEmpty,
  LocaleContentDraft,
  LocalizedContentDraft,
  nextLocalId,
} from "../../pages/paywall-config/paywallConfigDraft";

interface LocaleContentEditorProps {
  value: LocalizedContentDraft;
  onChange: (next: LocalizedContentDraft) => void;
  disabled?: boolean;
  /** Shown once, above the tab bar, when the whole content object is missing/required. */
  requiredError?: string;
  idPrefix: string;
}

const emptyBenefit = (): BenefitDraft => ({
  _localId: nextLocalId(),
  icon: "",
  title: "",
});

const LocaleContentEditor: React.FC<LocaleContentEditorProps> = ({
  value,
  onChange,
  disabled = false,
  requiredError,
  idPrefix,
}) => {
  const [activeLocale, setActiveLocale] = useState<PaywallLocale>("en");

  const updateLocale = (locale: PaywallLocale, patch: Partial<LocaleContentDraft>) => {
    onChange({ ...value, [locale]: { ...value[locale], ...patch } });
  };

  const current = value[activeLocale];

  const updateBenefit = (index: number, patch: Partial<BenefitDraft>) => {
    const benefits = current.benefits.map((b, i) =>
      i === index ? { ...b, ...patch } : b
    );
    updateLocale(activeLocale, { benefits });
  };

  const addBenefit = () => {
    updateLocale(activeLocale, { benefits: [...current.benefits, emptyBenefit()] });
  };

  const removeBenefit = (index: number) => {
    updateLocale(activeLocale, {
      benefits: current.benefits.filter((_, i) => i !== index),
    });
  };

  const copyFromEn = () => {
    updateLocale(activeLocale, {
      subheading: value.en.subheading,
      heading: value.en.heading,
      benefits: value.en.benefits.map((b) => ({ ...b, _localId: nextLocalId() })),
    });
  };

  const canCopyFromEn =
    activeLocale !== "en" &&
    !isLocaleContentEmpty(value.en) &&
    isLocaleContentEmpty(current);

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
          const filled = !isLocaleContentEmpty(value[locale]);
          return (
            <button
              key={locale}
              type="button"
              role="tab"
              aria-selected={isActive}
              aria-controls={`${idPrefix}-panel-${locale}`}
              id={`${idPrefix}-tab-${locale}`}
              onClick={() => setActiveLocale(locale)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition inline-flex items-center gap-1.5 ${
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
            className="ml-1 inline-flex items-center gap-1 text-xs text-teal-700 hover:text-teal-800 disabled:opacity-50"
          >
            <DocumentDuplicateIcon className="h-3.5 w-3.5" />
            Copy from EN
          </button>
        )}
      </div>

      <div
        role="tabpanel"
        id={`${idPrefix}-panel-${activeLocale}`}
        aria-labelledby={`${idPrefix}-tab-${activeLocale}`}
        className="rounded-lg border border-slate-200 p-3 space-y-3"
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <label className="flex flex-col gap-1 text-xs text-slate-600">
            <span className="font-medium">Subheading</span>
            <input
              value={current.subheading}
              onChange={(e) => updateLocale(activeLocale, { subheading: e.target.value })}
              placeholder="Limited time offer"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
          </label>

          <label className="flex flex-col gap-1 text-xs text-slate-600">
            <span className="font-medium">Heading</span>
            <input
              value={current.heading}
              onChange={(e) => updateLocale(activeLocale, { heading: e.target.value })}
              placeholder="Unlock everything"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
          </label>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-600">Benefits</span>
          </div>

          {current.benefits.length === 0 ? (
            <p className="text-xs text-slate-400">No benefits listed for this locale.</p>
          ) : (
            <div className="space-y-2">
              {current.benefits.map((benefit, index) => (
                <div key={benefit._localId} className="flex items-start gap-2">
                  <input
                    value={benefit.icon}
                    onChange={(e) => updateBenefit(index, { icon: e.target.value })}
                    placeholder="icon (e.g. sparkle)"
                    disabled={disabled}
                    className="w-36 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <input
                    value={benefit.title}
                    onChange={(e) => updateBenefit(index, { title: e.target.value })}
                    placeholder="Unlimited lessons"
                    disabled={disabled}
                    className="flex-1 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <button
                    type="button"
                    onClick={() => removeBenefit(index)}
                    disabled={disabled}
                    aria-label="Remove benefit"
                    title="Remove benefit"
                    className="inline-flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          )}

          <button
            type="button"
            onClick={addBenefit}
            disabled={disabled}
            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-dashed border-slate-300 text-xs text-slate-600 hover:bg-slate-50 disabled:opacity-50"
          >
            <PlusIcon className="h-3.5 w-3.5" />
            Add benefit
          </button>
        </div>
      </div>
    </div>
  );
};

export default LocaleContentEditor;
