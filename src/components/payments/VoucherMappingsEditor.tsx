import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { productService } from "../../services/payments/productService";
import {
  IProduct,
  ProductListQuery,
} from "../../types/interface/payments/product.interface";
import { PaymentPlatform } from "../../types/enum/payment.enum";
import { IVoucherMappingInput } from "../../types/interface/payments/voucher.interface";

// Every SKU swap this voucher unlocks MUST point at a product that actually
// exists in iap_products - a free-text SKU here is exactly what makes the
// mobile paywall render blank. Both dropdowns are populated from the active
// product catalog and filtered to the row's platform; there is no way to
// type an arbitrary product id.

type ProductRecord = IProduct & { _id?: string };

const getProductId = (product: ProductRecord) =>
  product.id || product._id || "";

const normalizeProducts = (payload: any): ProductRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const emptyRow = (): IVoucherMappingInput => ({
  platform: PaymentPlatform.APPLE,
  baseProductId: "",
  targetProductId: "",
});

interface VoucherMappingsEditorProps {
  value: IVoucherMappingInput[];
  onChange: (rows: IVoucherMappingInput[]) => void;
  disabled?: boolean;
}

const VoucherMappingsEditor: React.FC<VoucherMappingsEditorProps> = ({
  value,
  onChange,
  disabled = false,
}) => {
  const [products, setProducts] = useState<ProductRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new ProductListQuery({ page: 1, take: 200, isActive: true });
      const res = await productService.getList(query);
      setProducts(normalizeProducts(res));
    } catch (err: any) {
      console.error("Failed to fetch active products", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải danh sách sản phẩm active"
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const productsByPlatform = useMemo(() => {
    const map: Record<PaymentPlatform, ProductRecord[]> = {
      [PaymentPlatform.APPLE]: [],
      [PaymentPlatform.GOOGLE]: [],
    };
    products.forEach((product) => {
      if (map[product.platform]) map[product.platform].push(product);
    });
    return map;
  }, [products]);

  const updateRow = (index: number, patch: Partial<IVoucherMappingInput>) => {
    const next = value.map((row, i) =>
      i === index ? { ...row, ...patch } : row
    );
    onChange(next);
  };

  const handlePlatformChange = (index: number, platform: PaymentPlatform) => {
    // Base/target belong to the previous platform's catalog - reset them so
    // an operator can never submit a SKU that doesn't match the new platform.
    updateRow(index, { platform, baseProductId: "", targetProductId: "" });
  };

  const removeRow = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const addRow = () => {
    onChange([...value, emptyRow()]);
  };

  const hasProducts = products.length > 0;

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium text-slate-700">
          Ánh xạ SKU (mappings)
        </span>
        <button
          type="button"
          onClick={fetchProducts}
          disabled={loading}
          className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-700"
        >
          <ArrowPathIcon className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} />
          Làm mới danh sách sản phẩm
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 flex items-center gap-2">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {!loading && !error && !hasProducts && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          Chưa có sản phẩm nào đang active. Tạo sản phẩm ở tab Product
          management trước khi cấu hình ánh xạ SKU.
        </div>
      )}

      {value.length === 0 ? (
        <p className="text-xs text-slate-400">
          Voucher này chưa unlock SKU nào. Thêm ánh xạ để voucher đổi giá hiển
          thị trên paywall.
        </p>
      ) : (
        <div className="space-y-2">
          {value.map((row, index) => {
            const baseOptions = productsByPlatform[row.platform] ?? [];
            const targetOptions = productsByPlatform[row.platform] ?? [];
            const sameAsBase =
              row.baseProductId &&
              row.targetProductId &&
              row.baseProductId === row.targetProductId;
            return (
              <div
                key={index}
                className="rounded-lg border border-slate-200 p-3 space-y-2"
              >
                <div className="grid grid-cols-1 md:grid-cols-[minmax(0,120px)_1fr_1fr_auto] gap-2 items-start">
                  <label className="flex flex-col gap-1 text-xs text-slate-600">
                    <span className="font-medium">Platform</span>
                    <select
                      value={row.platform}
                      onChange={(e) =>
                        handlePlatformChange(
                          index,
                          e.target.value as PaymentPlatform
                        )
                      }
                      disabled={disabled}
                      className="rounded-lg border border-slate-200 px-2 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                    >
                      <option value={PaymentPlatform.APPLE}>Apple</option>
                      <option value={PaymentPlatform.GOOGLE}>Google</option>
                    </select>
                  </label>

                  <label className="flex flex-col gap-1 text-xs text-slate-600">
                    <span className="font-medium">SKU gốc (baseProductId)</span>
                    <select
                      value={row.baseProductId}
                      onChange={(e) =>
                        updateRow(index, { baseProductId: e.target.value })
                      }
                      disabled={disabled || loading || baseOptions.length === 0}
                      className="rounded-lg border border-slate-200 px-2 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                    >
                      <option value="">
                        {loading
                          ? "Đang tải sản phẩm..."
                          : baseOptions.length === 0
                          ? "Không có sản phẩm active"
                          : "Chọn sản phẩm..."}
                      </option>
                      {baseOptions.map((product) => (
                        <option
                          key={getProductId(product)}
                          value={product.productId}
                        >
                          {product.productId} · {product.title}
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="flex flex-col gap-1 text-xs text-slate-600">
                    <span className="font-medium">
                      SKU khuyến mãi (targetProductId)
                    </span>
                    <select
                      value={row.targetProductId}
                      onChange={(e) =>
                        updateRow(index, { targetProductId: e.target.value })
                      }
                      disabled={disabled || loading || targetOptions.length === 0}
                      className="rounded-lg border border-slate-200 px-2 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                    >
                      <option value="">
                        {loading
                          ? "Đang tải sản phẩm..."
                          : targetOptions.length === 0
                          ? "Không có sản phẩm active"
                          : "Chọn sản phẩm..."}
                      </option>
                      {targetOptions.map((product) => (
                        <option
                          key={getProductId(product)}
                          value={product.productId}
                        >
                          {product.productId} · {product.title}
                        </option>
                      ))}
                    </select>
                  </label>

                  <button
                    type="button"
                    onClick={() => removeRow(index)}
                    disabled={disabled}
                    aria-label="Xóa ánh xạ"
                    title="Xóa ánh xạ"
                    className="mt-5 inline-flex h-9 w-9 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>
                {sameAsBase && (
                  <p className="text-xs text-amber-700 flex items-center gap-1">
                    <ExclamationTriangleIcon className="h-3.5 w-3.5" />
                    SKU gốc và SKU khuyến mãi đang trùng nhau - kiểm tra lại nếu
                    đây không phải chủ ý.
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
        disabled={disabled || !hasProducts}
        className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border border-dashed border-slate-300 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
      >
        <PlusIcon className="h-4 w-4" />
        Thêm ánh xạ SKU
      </button>
    </div>
  );
};

export default VoucherMappingsEditor;
