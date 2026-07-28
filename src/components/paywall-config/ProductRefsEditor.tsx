import React from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import {
  ProductOption,
  ProductRefDraft,
  ProductsByPlatform,
  emptyProductRef,
} from "../../pages/paywall-config/paywallConfigDraft";

interface ProductRefsEditorProps {
  value: ProductRefDraft[];
  onChange: (rows: ProductRefDraft[]) => void;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
  disabled?: boolean;
  /** Whether the backend requires this list to be non-empty. */
  required?: boolean;
  fieldErrors?: Record<string, string>;
  /** Backend field path prefix, e.g. "saleStrategy.defaultUser.products". */
  fieldPrefix: string;
}

const PlatformSelect: React.FC<{
  label: string;
  value: string;
  options: ProductOption[];
  loading: boolean;
  disabled?: boolean;
  error?: string;
  onChange: (value: string) => void;
}> = ({ label, value, options, loading, disabled, error, onChange }) => {
  const selectedMissing = Boolean(value) && !options.some((o) => o.productId === value);

  return (
    <label className="flex flex-1 flex-col gap-1 text-xs text-slate-600">
      <span className="font-medium">{label}</span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled || loading}
        className={`rounded-lg border px-2 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
          error || selectedMissing ? "border-red-300" : "border-slate-200"
        }`}
      >
        <option value="">
          {loading ? "Đang tải..." : "Không chọn"}
        </option>
        {selectedMissing && (
          <option value={value}>
            {value} (không có trong catalog active)
          </option>
        )}
        {options.map((product) => (
          <option key={product.id} value={product.productId}>
            {product.productId} · {product.title}
          </option>
        ))}
      </select>
      {selectedMissing && !error && (
        <span className="text-[11px] text-red-600 flex items-center gap-1">
          <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0" />
          SKU này không tồn tại hoặc đã inactive trong iap_products - chọn lại
          trước khi đăng.
        </span>
      )}
      {error && (
        <span className="text-[11px] text-red-600 flex items-center gap-1">
          <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0" />
          {error}
        </span>
      )}
    </label>
  );
};

const ProductRefsEditor: React.FC<ProductRefsEditorProps> = ({
  value,
  onChange,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
  disabled = false,
  required = false,
  fieldErrors = {},
  fieldPrefix,
}) => {
  const appleOptions = productsByPlatform?.apple ?? [];
  const googleOptions = productsByPlatform?.google ?? [];
  const catalogEmpty =
    !productsLoading && !productsError && appleOptions.length === 0 && googleOptions.length === 0;

  const updateRow = (index: number, patch: Partial<ProductRefDraft>) => {
    onChange(value.map((row, i) => (i === index ? { ...row, ...patch } : row)));
  };

  const removeRow = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const addRow = () => {
    onChange([...value, emptyProductRef()]);
  };

  const listError = fieldErrors[fieldPrefix];

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-slate-600">
          Sản phẩm {required && <span className="text-red-500">*</span>}
        </span>
        <button
          type="button"
          onClick={onRefreshProducts}
          disabled={productsLoading}
          className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-700"
        >
          <ArrowPathIcon className={`h-3.5 w-3.5 ${productsLoading ? "animate-spin" : ""}`} />
          Làm mới catalog
        </button>
      </div>

      {productsError && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 flex items-center gap-2">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          {productsError}
        </div>
      )}

      {catalogEmpty && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          Chưa có sản phẩm active nào. Tạo sản phẩm ở Payment {'>'} Product
          management trước.
        </div>
      )}

      {listError && (
        <p className="text-xs text-red-600 flex items-center gap-1.5">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          {listError}
        </p>
      )}

      {value.length === 0 ? (
        <p className="text-xs text-slate-500">
          Chưa có sản phẩm nào được gán cho mục này.
        </p>
      ) : (
        <div className="space-y-2">
          {value.map((row, index) => {
            const rowPrefix = `${fieldPrefix}[${index}]`;
            return (
              <div key={row._localId} className="rounded-lg border border-slate-200 p-2.5">
                <div className="flex items-start gap-2">
                  <PlatformSelect
                    label="Sản phẩm Apple"
                    value={row.appleProductId ?? ""}
                    options={appleOptions}
                    loading={productsLoading}
                    disabled={disabled}
                    error={fieldErrors[`${rowPrefix}.appleProductId`]}
                    onChange={(v) => updateRow(index, { appleProductId: v })}
                  />
                  <PlatformSelect
                    label="Sản phẩm Google"
                    value={row.googleProductId ?? ""}
                    options={googleOptions}
                    loading={productsLoading}
                    disabled={disabled}
                    error={fieldErrors[`${rowPrefix}.googleProductId`]}
                    onChange={(v) => updateRow(index, { googleProductId: v })}
                  />
                  <button
                    type="button"
                    onClick={() => removeRow(index)}
                    disabled={disabled}
                    aria-label="Xóa sản phẩm"
                    title="Xóa sản phẩm"
                    className="mt-5 inline-flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>
                {fieldErrors[rowPrefix] && (
                  <p className="mt-1.5 text-[11px] text-red-600 flex items-center gap-1">
                    <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0" />
                    {fieldErrors[rowPrefix]}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      )}

      <button
        type="button"
        onClick={addRow}
        disabled={disabled}
        className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border border-dashed border-slate-300 text-xs text-slate-600 hover:bg-slate-50 disabled:opacity-50"
      >
        <PlusIcon className="h-3.5 w-3.5" />
        Thêm sản phẩm
      </button>
    </div>
  );
};

export default ProductRefsEditor;
