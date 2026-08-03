import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { productService } from "../../services/payments/productService";
import {
  IProduct,
  ProductListQuery,
} from "../../types/interface/payments/product.interface";
import { PaymentPlatform } from "../../types/enum/payment.enum";
import {
  IDiscountTier,
  IDiscountTierPayload,
} from "../../types/interface/payments/discount-tier.interface";

// Base/target must come from the real product catalog - a free-text SKU here
// is exactly what makes the mobile paywall fail to resolve the swap. Both
// dropdowns are populated from the active catalog and filtered to the
// selected platform; there is no way to type an arbitrary product id.

const PACKAGE_KEY_MAX_LENGTH = 64;
const SKU_MAX_LENGTH = 255;

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

interface DiscountTierModalProps {
  isOpen: boolean;
  initial?: IDiscountTier | null;
  onClose: () => void;
  onSubmit: (payload: IDiscountTierPayload, id?: string) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const DiscountTierModal: React.FC<DiscountTierModalProps> = ({
  isOpen,
  initial = null,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}) => {
  const [packageKey, setPackageKey] = useState("");
  const [platform, setPlatform] = useState<PaymentPlatform>(
    PaymentPlatform.APPLE
  );
  const [discountPercent, setDiscountPercent] = useState("");
  const [baseProductId, setBaseProductId] = useState("");
  const [targetProductId, setTargetProductId] = useState("");
  const [formError, setFormError] = useState<string | null>(null);

  const [products, setProducts] = useState<ProductRecord[]>([]);
  const [productsLoading, setProductsLoading] = useState(false);
  const [productsError, setProductsError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setProductsLoading(true);
    setProductsError(null);
    try {
      const query = new ProductListQuery({
        page: 1,
        take: 200,
        isActive: true,
      });
      const res = await productService.getList(query);
      setProducts(normalizeProducts(res));
    } catch (err: any) {
      console.error("Failed to fetch active products", err);
      setProductsError(
        err?.response?.data?.message ||
          "Không thể tải danh sách sản phẩm active"
      );
    } finally {
      setProductsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isOpen) return;
    fetchProducts();
  }, [isOpen, fetchProducts]);

  useEffect(() => {
    if (!isOpen) return;

    if (initial) {
      setPackageKey(initial.packageKey || "");
      setPlatform(initial.platform || PaymentPlatform.APPLE);
      setDiscountPercent(
        initial.discountPercent !== undefined &&
          initial.discountPercent !== null
          ? String(initial.discountPercent)
          : ""
      );
      setBaseProductId(initial.baseProductId || "");
      setTargetProductId(initial.targetProductId || "");
    } else {
      setPackageKey("");
      setPlatform(PaymentPlatform.APPLE);
      setDiscountPercent("");
      setBaseProductId("");
      setTargetProductId("");
    }
    setFormError(null);
  }, [initial, isOpen]);

  const optionsForPlatform = useMemo(
    () => products.filter((product) => product.platform === platform),
    [products, platform]
  );

  const handlePlatformChange = (next: PaymentPlatform) => {
    // Base/target belong to the previous platform's catalog - reset them so
    // an operator can never submit a SKU that doesn't match the platform.
    setPlatform(next);
    setBaseProductId("");
    setTargetProductId("");
  };

  if (!isOpen) return null;

  const isEditing = Boolean(initial?.id);
  const sameAsBase =
    baseProductId && targetProductId && baseProductId === targetProductId;
  const platformLabel =
    platform === PaymentPlatform.APPLE ? "Apple" : "Google";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const trimmedKey = packageKey.trim();
    if (!trimmedKey) {
      setFormError("Package key là bắt buộc");
      return;
    }
    if (trimmedKey.length > PACKAGE_KEY_MAX_LENGTH) {
      setFormError(`Package key tối đa ${PACKAGE_KEY_MAX_LENGTH} ký tự`);
      return;
    }

    const percent = Number(discountPercent);
    if (
      discountPercent.trim() === "" ||
      !Number.isInteger(percent) ||
      percent < 0 ||
      percent > 100
    ) {
      setFormError("Giảm giá % phải là số nguyên từ 0 đến 100");
      return;
    }

    if (!baseProductId || !targetProductId) {
      setFormError("Chọn đủ SKU gốc và SKU khuyến mãi");
      return;
    }
    if (
      baseProductId.length > SKU_MAX_LENGTH ||
      targetProductId.length > SKU_MAX_LENGTH
    ) {
      setFormError(`SKU tối đa ${SKU_MAX_LENGTH} ký tự`);
      return;
    }

    setFormError(null);
    const payload: IDiscountTierPayload = {
      packageKey: trimmedKey,
      platform,
      discountPercent: percent,
      baseProductId,
      targetProductId,
    };

    await onSubmit(payload, initial?.id);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-3">
      <div className="w-full max-w-2xl bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 bg-gradient-to-r from-teal-600 to-emerald-500 text-white">
          <div>
            <p className="text-sm uppercase tracking-wide opacity-90">
              {isEditing ? "Chỉnh sửa bậc giảm giá" : "Tạo bậc giảm giá"}
            </p>
            <h2 className="text-xl font-semibold">
              {isEditing ? initial?.packageKey : "Discount tier"}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full bg-white/10 hover:bg-white/20 transition"
            aria-label="Đóng"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit}
          className="p-6 space-y-4 max-h-[75vh] overflow-y-auto"
        >
          {(formError || error) && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {formError || error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Package key</span>
              <input
                value={packageKey}
                onChange={(e) => setPackageKey(e.target.value)}
                placeholder="pre1months"
                maxLength={PACKAGE_KEY_MAX_LENGTH}
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                required
              />
              <span className="text-xs text-slate-400">
                Khoá gói của affiliate (voucher.eup.ai), ví dụ pre1months,
                pre3months, pre12months, preforevermonths.
              </span>
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Platform</span>
              <select
                value={platform}
                onChange={(e) =>
                  handlePlatformChange(e.target.value as PaymentPlatform)
                }
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              >
                <option value={PaymentPlatform.APPLE}>Apple</option>
                <option value={PaymentPlatform.GOOGLE}>Google</option>
              </select>
            </label>
          </div>

          <label className="flex flex-col gap-1 text-sm text-slate-700 md:w-40">
            <span className="font-medium">Giảm giá % (discountPercent)</span>
            <div className="relative">
              <input
                type="number"
                min="0"
                max="100"
                step="1"
                value={discountPercent}
                onChange={(e) => setDiscountPercent(e.target.value)}
                placeholder="20"
                className="w-full rounded-lg border border-slate-200 px-3 py-2 pr-8 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                required
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm pointer-events-none">
                %
              </span>
            </div>
            <span className="text-xs text-slate-400">
              Mức % affiliate trả về cho package này trên platform này.
            </span>
          </label>

          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-slate-700">
              SKU đổi giá
            </span>
            <button
              type="button"
              onClick={fetchProducts}
              disabled={productsLoading}
              className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-700"
            >
              <ArrowPathIcon
                className={`h-3.5 w-3.5 ${
                  productsLoading ? "animate-spin" : ""
                }`}
              />
              Làm mới danh sách sản phẩm
            </button>
          </div>

          {productsError && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 flex items-center justify-between gap-2">
              <span className="flex items-center gap-2">
                <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
                {productsError}
              </span>
              <button
                type="button"
                onClick={fetchProducts}
                className="underline underline-offset-2 hover:text-red-800"
              >
                Thử lại
              </button>
            </div>
          )}

          {!productsLoading &&
            !productsError &&
            optionsForPlatform.length === 0 && (
              <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
                <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
                Chưa có sản phẩm active nào cho {platformLabel}. Tạo sản phẩm ở
                tab Product management trước khi khai bậc giảm giá.
              </div>
            )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">SKU gốc (baseProductId)</span>
              <select
                value={baseProductId}
                onChange={(e) => setBaseProductId(e.target.value)}
                disabled={productsLoading || optionsForPlatform.length === 0}
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                required
              >
                <option value="">
                  {productsLoading
                    ? "Đang tải sản phẩm..."
                    : optionsForPlatform.length === 0
                    ? "Không có sản phẩm active"
                    : "Chọn sản phẩm..."}
                </option>
                {optionsForPlatform.map((product) => (
                  <option
                    key={getProductId(product)}
                    value={product.productId}
                  >
                    {product.productId} · {product.title}
                  </option>
                ))}
              </select>
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">
                SKU khuyến mãi (targetProductId)
              </span>
              <select
                value={targetProductId}
                onChange={(e) => setTargetProductId(e.target.value)}
                disabled={productsLoading || optionsForPlatform.length === 0}
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                required
              >
                <option value="">
                  {productsLoading
                    ? "Đang tải sản phẩm..."
                    : optionsForPlatform.length === 0
                    ? "Không có sản phẩm active"
                    : "Chọn sản phẩm..."}
                </option>
                {optionsForPlatform.map((product) => (
                  <option
                    key={getProductId(product)}
                    value={product.productId}
                  >
                    {product.productId} · {product.title}
                  </option>
                ))}
              </select>
            </label>
          </div>

          {sameAsBase && (
            <p className="text-xs text-amber-700 flex items-center gap-1">
              <ExclamationTriangleIcon className="h-3.5 w-3.5" />
              SKU gốc và SKU khuyến mãi đang trùng nhau - kiểm tra lại nếu đây
              không phải chủ ý.
            </p>
          )}

          <div className="flex items-center justify-end gap-3 pt-2 border-t border-slate-100 mt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 rounded-lg bg-gradient-to-r from-teal-600 to-emerald-500 text-white hover:from-teal-700 hover:to-emerald-600 shadow-md disabled:opacity-70 flex items-center gap-2 min-w-[140px] justify-center"
            >
              {loading && (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              )}
              {isEditing ? "Lưu thay đổi" : "Tạo bậc giảm giá"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default DiscountTierModal;
