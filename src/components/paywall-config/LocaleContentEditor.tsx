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
  ComparisonRowDraft,
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

// `hasCheck: true` — mọi dòng trong design đều có tick, nên dòng mới phải giống
// design ngay lúc thêm chứ không bắt người ta bấm thêm một ô mới đúng.
const emptyComparisonRow = (): ComparisonRowDraft => ({
  _localId: nextLocalId(),
  label: "",
  free: "",
  premium: "",
  hasCheck: true,
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

  const updateComparisonRow = (index: number, patch: Partial<ComparisonRowDraft>) => {
    updateLocale(activeLocale, {
      comparison: current.comparison.map((row, i) =>
        i === index ? { ...row, ...patch } : row
      ),
    });
  };

  const addComparisonRow = () => {
    updateLocale(activeLocale, {
      comparison: [...current.comparison, emptyComparisonRow()],
    });
  };

  const removeComparisonRow = (index: number) => {
    updateLocale(activeLocale, {
      comparison: current.comparison.filter((_, i) => i !== index),
    });
  };

  const copyFromEn = () => {
    updateLocale(activeLocale, {
      subheading: value.en.subheading,
      heading: value.en.heading,
      benefits: value.en.benefits.map((b) => ({ ...b, _localId: nextLocalId() })),
      // Bảng phải đi cùng: thiếu dòng này thì "Copy từ EN" copy một nửa và để
      // locale đó có tiêu đề tiếng Anh nhưng bảng rỗng.
      comparison: value.en.comparison.map((row) => ({ ...row, _localId: nextLocalId() })),
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
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Tiêu đề phụ</span>
            <input
              value={current.subheading}
              onChange={(e) => updateLocale(activeLocale, { subheading: e.target.value })}
              placeholder="Ưu đãi có thời hạn"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
          </label>

          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Tiêu đề chính</span>
            <input
              value={current.heading}
              onChange={(e) => updateLocale(activeLocale, { heading: e.target.value })}
              placeholder="Mở khóa toàn bộ"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
          </label>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-700">Lợi ích</span>
          </div>

          {current.benefits.length === 0 ? (
            <p className="text-xs text-slate-500">Chưa có lợi ích nào cho ngôn ngữ này.</p>
          ) : (
            <div className="space-y-2">
              {current.benefits.map((benefit, index) => (
                <div key={benefit._localId} className="flex items-start gap-2">
                  <input
                    value={benefit.icon}
                    onChange={(e) => updateBenefit(index, { icon: e.target.value })}
                    placeholder="icon (vd: sparkle)"
                    disabled={disabled}
                    className="w-36 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <input
                    value={benefit.title}
                    onChange={(e) => updateBenefit(index, { title: e.target.value })}
                    placeholder="Học không giới hạn"
                    disabled={disabled}
                    className="flex-1 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <button
                    type="button"
                    onClick={() => removeBenefit(index)}
                    disabled={disabled}
                    aria-label="Xóa lợi ích"
                    title="Xóa lợi ích"
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
            Thêm lợi ích
          </button>
        </div>

        <div className="space-y-2 border-t border-slate-100 pt-4">
          <div>
            <span className="text-xs font-medium text-slate-700">
              Bảng so sánh (Miễn phí vs Premium)
            </span>
            <p className="mt-0.5 text-xs text-slate-500">
              Chỉ hiện khi "Thân paywall" đặt là <em>Bảng so sánh</em>. Để trống
              thì app rơi về danh sách lợi ích ở trên, nên bật layout trước khi
              nhập dữ liệu cũng không làm paywall trông như bị lỗi. Ba nhãn cột và
              tiêu đề bảng nằm trong app (5 ngôn ngữ), không sửa ở đây.
            </p>
          </div>

          {current.comparison.length === 0 ? (
            <p className="text-xs text-slate-500">
              Chưa có dòng nào cho ngôn ngữ này.
            </p>
          ) : (
            <div className="space-y-2">
              {current.comparison.map((row, index) => (
                <div key={row._localId} className="flex items-start gap-2">
                  <input
                    value={row.label}
                    onChange={(e) => updateComparisonRow(index, { label: e.target.value })}
                    placeholder="Quyền lợi (vd: Bài học)"
                    disabled={disabled}
                    className="w-36 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <input
                    value={row.free}
                    onChange={(e) => updateComparisonRow(index, { free: e.target.value })}
                    placeholder="Miễn phí (vd: 1 / ngày)"
                    disabled={disabled}
                    className="flex-1 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <input
                    value={row.premium}
                    onChange={(e) => updateComparisonRow(index, { premium: e.target.value })}
                    placeholder="Premium (vd: Không giới hạn)"
                    disabled={disabled}
                    className="flex-1 rounded-lg border border-slate-200 px-2 py-1.5 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                  />
                  <label
                    title="Hiện icon tick trước chữ ở cột Premium"
                    className="inline-flex h-8 flex-shrink-0 items-center gap-1.5 px-1 text-xs text-slate-600"
                  >
                    <input
                      type="checkbox"
                      checked={row.hasCheck}
                      onChange={(e) =>
                        updateComparisonRow(index, { hasCheck: e.target.checked })
                      }
                      disabled={disabled}
                      className="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
                    />
                    tick
                  </label>
                  <button
                    type="button"
                    onClick={() => removeComparisonRow(index)}
                    disabled={disabled}
                    aria-label="Xóa dòng so sánh"
                    title="Xóa dòng so sánh"
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
            onClick={addComparisonRow}
            disabled={disabled}
            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-dashed border-slate-300 text-xs text-slate-600 hover:bg-slate-50 disabled:opacity-50"
          >
            <PlusIcon className="h-3.5 w-3.5" />
            Thêm dòng so sánh
          </button>
        </div>
      </div>
    </div>
  );
};

export default LocaleContentEditor;
