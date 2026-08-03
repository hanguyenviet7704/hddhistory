import React, { useEffect, useState } from "react";
import {
  ChevronDownIcon,
  ChevronUpIcon,
  ExclamationTriangleIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import LocaleContentEditor from "../../../components/paywall-config/LocaleContentEditor";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { ImpressionRuleDraft, ProductsByPlatform } from "../paywallConfigDraft";

interface ImpressionRuleCardProps {
  index: number;
  value: ImpressionRuleDraft;
  onChange: (next: ImpressionRuleDraft) => void;
  onRemove: () => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

const ImpressionRuleCard: React.FC<ImpressionRuleCardProps> = ({
  index,
  value,
  onChange,
  onRemove,
  disabled = false,
  fieldErrors,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  const prefix = `saleStrategy.newUser.impressionRules[${index}]`;
  const rowErrors = Object.keys(fieldErrors).filter((f) => f.startsWith(prefix));
  const [expanded, setExpanded] = useState(true);

  // Never let a collapsed rule hide a validation error from view.
  useEffect(() => {
    if (rowErrors.length > 0) setExpanded(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rowErrors.length]);

  const productCount = value.products.filter(
    (p) => p.appleProductId || p.googleProductId
  ).length;

  return (
    <div className="rounded-xl border border-slate-200 bg-white">
      <div className="flex items-center justify-between gap-2 p-3 hover:bg-slate-50/60 rounded-xl transition-colors">
        <button
          type="button"
          onClick={() => setExpanded((prev) => !prev)}
          className="flex flex-1 items-center gap-2 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1 rounded"
          aria-expanded={expanded}
        >
          {expanded ? (
            <ChevronUpIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          ) : (
            <ChevronDownIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          )}
          <span className="text-sm font-medium text-slate-800">
            Rule {index + 1}
            {value.fromImpression && ` · từ impression thứ ${value.fromImpression}`}
          </span>
          <span className="text-xs text-slate-500">{productCount} sản phẩm</span>
          {rowErrors.length > 0 && (
            <span className="inline-flex items-center gap-1 text-xs text-red-600">
              <ExclamationTriangleIcon className="h-3.5 w-3.5" />
              {rowErrors.length} lỗi
            </span>
          )}
        </button>
        <button
          type="button"
          onClick={onRemove}
          disabled={disabled}
          aria-label={`Xóa rule ${index + 1}`}
          title="Xóa rule"
          className="inline-flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
        >
          <TrashIcon className="h-4 w-4" />
        </button>
      </div>

      {expanded && (
        <div className="border-t border-slate-100 p-3 space-y-3">
          <label className="flex flex-col gap-1 text-xs text-slate-700 max-w-[180px]">
            <span className="font-medium">Từ impression thứ</span>
            <input
              type="number"
              min={1}
              step={1}
              value={value.fromImpression}
              onChange={(e) => onChange({ ...value, fromImpression: e.target.value })}
              disabled={disabled}
              placeholder="3"
              className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                fieldErrors[`${prefix}.fromImpression`] ? "border-red-300" : "border-slate-200"
              }`}
            />
            <span className="text-[11px] text-slate-500">
              Số lần hiển thị paywall mà từ đó rule này bắt đầu áp dụng.
            </span>
            {fieldErrors[`${prefix}.fromImpression`] && (
              <span className="text-[11px] text-red-600">
                {fieldErrors[`${prefix}.fromImpression`]}
              </span>
            )}
          </label>

          <LocaleContentEditor
            idPrefix={`impression-rule-${index}`}
            value={value.content}
            onChange={(content) => onChange({ ...value, content })}
            disabled={disabled}
            requiredError={fieldErrors[`${prefix}.content`]}
          />

          <ProductRefsEditor
            fieldPrefix={`${prefix}.products`}
            title="Sản phẩm — danh sách đầy đủ"
            value={value.products}
            onChange={(products) => onChange({ ...value, products })}
            disabled={disabled}
            required
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={onRefreshProducts}
          />

          <ProductRefsEditor
            fieldPrefix={`${prefix}.compactProducts`}
            title="Sản phẩm — danh sách rút gọn"
            hint="Để trống thì các điểm 'rút gọn' dùng danh sách đầy đủ."
            emptyHint="Để trống — dùng danh sách đầy đủ ở trên."
            value={value.compactProducts}
            onChange={(compactProducts) => onChange({ ...value, compactProducts })}
            disabled={disabled}
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={onRefreshProducts}
          />
        </div>
      )}
    </div>
  );
};

export default ImpressionRuleCard;
