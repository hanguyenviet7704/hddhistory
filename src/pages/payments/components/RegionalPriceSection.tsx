import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  GlobeAltIcon,
  InformationCircleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { productPriceService } from "../../../services/payments/productPriceService";
import { productService } from "../../../services/payments/productService";
import {
  IProductPrice,
  IProductPriceQuery,
  IProductPriceSyncPayload,
  IProductPriceSyncResult,
  IPlatformSyncResult,
} from "../../../types/interface/payments/product-price.interface";
import {
  IProduct,
  ProductListQuery,
} from "../../../types/interface/payments/product.interface";
import { PaymentPlatform } from "../../../types/enum/payment.enum";
import { useNotification } from "../../../utils/hooks/useNotification";
import {
  formatDateTime,
  platformIconTone,
  platformIcons,
  platformLabels,
} from "../paymentShared";

type ProductRecord = IProduct & { _id?: string };
type ProductOption = { productId: string; title: string; platforms: PaymentPlatform[] };

const normalizeProducts = (payload: any): ProductRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizePrices = (payload: any): IProductPrice[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const unwrapSyncResult = (payload: any): IProductPriceSyncResult | null => {
  const data = payload?.data ?? payload;
  if (!data || typeof data !== "object") return null;
  if (!data.apple && !data.google) return null;
  return data as IProductPriceSyncResult;
};

const formatRegionalPrice = (value: number, currency: string) => {
  if (value === undefined || value === null || Number.isNaN(value)) return "-";
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    return `${currency} ${value}`;
  }
};

const describeSyncResult = (label: string, result: IPlatformSyncResult) => {
  if (result.skippedReason) return `${label}: bỏ qua - ${result.skippedReason}`;
  const failedPart = result.failed ? `, lỗi ${result.failed} SKU` : "";
  return `${label}: đã đồng bộ ${result.synced} dòng giá${failedPart}`;
};

const RegionalPriceSection: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [productOptions, setProductOptions] = useState<ProductOption[]>([]);
  const [productsLoading, setProductsLoading] = useState(false);
  const [productsError, setProductsError] = useState<string | null>(null);

  const [selectedProductId, setSelectedProductId] = useState("");
  const [platformFilter, setPlatformFilter] = useState<string>("");
  const [territorySearch, setTerritorySearch] = useState("");

  const [prices, setPrices] = useState<IProductPrice[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [syncing, setSyncing] = useState(false);
  const [lastSyncResult, setLastSyncResult] =
    useState<IProductPriceSyncResult | null>(null);
  const [lastSyncAt, setLastSyncAt] = useState<Date | null>(null);

  const fetchProductOptions = useCallback(async () => {
    setProductsLoading(true);
    setProductsError(null);
    try {
      const query = new ProductListQuery({ page: 1, take: 500, isAll: true });
      const res = await productService.getList(query);
      const list = normalizeProducts(res);
      const map = new Map<string, ProductOption>();
      list.forEach((product) => {
        const existing = map.get(product.productId);
        if (existing) {
          if (!existing.platforms.includes(product.platform)) {
            existing.platforms.push(product.platform);
          }
        } else {
          map.set(product.productId, {
            productId: product.productId,
            title: product.title,
            platforms: [product.platform],
          });
        }
      });
      const options = Array.from(map.values()).sort((a, b) =>
        a.title.localeCompare(b.title)
      );
      setProductOptions(options);
      setSelectedProductId((prev) => prev || options[0]?.productId || "");
    } catch (err: any) {
      console.error("Failed to fetch products for regional prices", err);
      setProductsError(
        err?.response?.data?.message ||
          "Không thể tải danh sách sản phẩm để chọn khu vực"
      );
      setProductOptions([]);
    } finally {
      setProductsLoading(false);
    }
  }, []);

  const fetchPrices = useCallback(async () => {
    if (!selectedProductId) {
      setPrices([]);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const params: IProductPriceQuery = { productId: selectedProductId };
      if (platformFilter) params.platform = platformFilter as PaymentPlatform;
      const res = await productPriceService.getList(params);
      setPrices(normalizePrices(res));
    } catch (err: any) {
      console.error("Failed to fetch regional prices", err);
      setError(
        err?.response?.data?.message || "Không thể tải giá theo khu vực"
      );
      setPrices([]);
    } finally {
      setLoading(false);
    }
  }, [platformFilter, selectedProductId]);

  useEffect(() => {
    fetchProductOptions();
  }, [fetchProductOptions]);

  useEffect(() => {
    fetchPrices();
  }, [fetchPrices]);

  const handleSync = async () => {
    setSyncing(true);
    try {
      const payload: IProductPriceSyncPayload = {};
      if (selectedProductId) payload.productId = selectedProductId;
      if (platformFilter) payload.platform = platformFilter as PaymentPlatform;

      const res = await productPriceService.sync(payload);
      const result = unwrapSyncResult(res);
      setLastSyncAt(new Date());

      if (!result) {
        showError("Đồng bộ đã chạy nhưng không nhận được kết quả hợp lệ");
      } else {
        setLastSyncResult(result);

        const appleMessage = describeSyncResult("Apple", result.apple);
        const googleMessage = describeSyncResult("Google", result.google);

        if (result.apple.skippedReason || result.apple.failed > 0) {
          showError(appleMessage);
        } else if (result.apple.synced > 0) {
          showSuccess(appleMessage);
        }

        if (result.google.skippedReason || result.google.failed > 0) {
          showError(googleMessage);
        } else if (result.google.synced > 0) {
          showSuccess(googleMessage);
        }
      }

      await fetchPrices();
    } catch (err: any) {
      console.error("Sync regional prices failed", err);
      showError(
        err?.response?.data?.message || "Không thể đồng bộ giá theo khu vực"
      );
    } finally {
      setSyncing(false);
    }
  };

  const filteredPrices = useMemo(() => {
    const term = territorySearch.trim().toLowerCase();
    if (!term) return prices;
    return prices.filter(
      (row) =>
        row.territory.toLowerCase().includes(term) ||
        row.currency.toLowerCase().includes(term)
    );
  }, [prices, territorySearch]);

  const freshestSync = useMemo(() => {
    if (prices.length === 0) return null;
    const newest = prices.reduce((acc, row) => {
      const t = new Date(row.syncedAt).getTime();
      return Number.isFinite(t) && t > acc ? t : acc;
    }, 0);
    return newest ? new Date(newest) : null;
  }, [prices]);

  const googleRowCount = useMemo(
    () => prices.filter((row) => row.platform === PaymentPlatform.GOOGLE).length,
    [prices]
  );

  const syncScopeLabel = useMemo(() => {
    const productPart = selectedProductId ? `"${selectedProductId}"` : "tất cả SKU đang bật";
    const platformPart = platformFilter
      ? `trên ${platformLabels[platformFilter as PaymentPlatform]}`
      : "trên cả Apple và Google";
    return `Đồng bộ ngay sẽ chỉ chạy cho ${productPart} ${platformPart}.`;
  }, [platformFilter, selectedProductId]);

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-sky-100 bg-sky-50 px-4 py-3 text-sm text-sky-900 flex items-start gap-2">
        <InformationCircleIcon className="h-5 w-5 mt-0.5 flex-shrink-0" />
        <div className="space-y-1.5">
          <p>
            Bảng này chỉ để nhân viên tham khảo và{" "}
            <strong>không thể chỉnh sửa</strong>. Ứng dụng luôn lấy giá thực tế
            từ App Store / Google Play ngay tại thời điểm thanh toán, nên dữ
            liệu ở đây không bao giờ ảnh hưởng đến số tiền user bị tính.
          </p>
          <p>
            Đường đồng bộ Apple đã được xác minh hoạt động. Đường đồng bộ
            Google Play <strong>có thể chưa đọc được</strong> do thiếu quyền
            Play Console <em>Monetization</em> (khác với quyền xác minh giao
            dịch mà service account hiện có) — nếu vậy, kết quả đồng bộ và
            bảng bên dưới sẽ ghi rõ lý do thay vì để trống.
          </p>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <select
              value={selectedProductId}
              onChange={(e) => setSelectedProductId(e.target.value)}
              disabled={productsLoading}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500 disabled:opacity-60 min-w-[220px]"
            >
              <option value="">Chọn sản phẩm</option>
              {productOptions.map((option) => (
                <option key={option.productId} value={option.productId}>
                  {option.title} — {option.productId}
                </option>
              ))}
            </select>

            <select
              value={platformFilter}
              onChange={(e) => setPlatformFilter(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>

            <div className="relative">
              <input
                value={territorySearch}
                onChange={(e) => setTerritorySearch(e.target.value)}
                placeholder="Tìm theo mã khu vực hoặc currency..."
                className="pl-10 pr-9 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 bg-slate-50/50 min-w-[220px]"
              />
              <svg
                className="h-5 w-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              {territorySearch && (
                <button
                  onClick={() => setTerritorySearch("")}
                  aria-label="Xóa tìm kiếm khu vực"
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  <XMarkIcon className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchPrices()}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              <ArrowPathIcon className="h-5 w-5" />
              Làm mới
            </button>
            <button
              onClick={handleSync}
              disabled={syncing}
              className={`inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl min-w-[150px] text-white shadow transition ${
                syncing
                  ? "bg-slate-300 cursor-not-allowed"
                  : "bg-gradient-to-r from-teal-600 to-emerald-500 hover:from-teal-700 hover:to-emerald-600"
              }`}
            >
              {syncing ? (
                <span className="h-4 w-4 border-2 border-white/70 border-t-transparent rounded-full animate-spin" />
              ) : (
                <ArrowPathIcon className="h-5 w-5" />
              )}
              Đồng bộ ngay
            </button>
          </div>
        </div>

        <p className="px-4 pt-3 text-[11px] text-slate-400">{syncScopeLabel}</p>

        {productsError && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center justify-between gap-2">
            <span className="flex items-center gap-2">
              <ExclamationTriangleIcon className="h-5 w-5" />
              {productsError}
            </span>
            <button
              onClick={() => fetchProductOptions()}
              className="text-red-700 underline underline-offset-2 hover:text-red-800"
            >
              Thử lại
            </button>
          </div>
        )}

        {error && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center justify-between gap-2">
            <span className="flex items-center gap-2">
              <ExclamationTriangleIcon className="h-5 w-5" />
              {error}
            </span>
            <button
              onClick={() => fetchPrices()}
              className="text-red-700 underline underline-offset-2 hover:text-red-800"
            >
              Thử lại
            </button>
          </div>
        )}

        <div className="mx-4 mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500">
          <span>
            {filteredPrices.length} / {prices.length} khu vực đang hiển thị
          </span>
          {freshestSync && (
            <span>Cập nhật gần nhất: {formatDateTime(freshestSync)}</span>
          )}
        </div>

        {lastSyncResult && (
          <div className="mx-4 mt-3 grid grid-cols-1 md:grid-cols-2 gap-3">
            {(
              [
                ["Apple", lastSyncResult.apple],
                ["Google", lastSyncResult.google],
              ] as [string, IPlatformSyncResult][]
            ).map(([label, result]) => {
              const hasIssue = Boolean(result.skippedReason) || result.failed > 0;
              return (
                <div
                  key={label}
                  className={`rounded-xl border px-3 py-2 text-xs ${
                    hasIssue
                      ? "border-amber-200 bg-amber-50 text-amber-800"
                      : "border-emerald-200 bg-emerald-50 text-emerald-800"
                  }`}
                >
                  <p className="font-semibold">
                    {label}
                    {lastSyncAt ? ` · ${formatDateTime(lastSyncAt)}` : ""}
                  </p>
                  <p>
                    Đồng bộ: {result.synced} dòng · Lỗi: {result.failed}
                  </p>
                  {result.skippedReason && (
                    <p className="mt-1">Bỏ qua: {result.skippedReason}</p>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <div className="overflow-x-auto">
          <div className="max-h-[480px] overflow-y-auto">
            <table className="min-w-full divide-y divide-slate-100">
              <thead className="bg-slate-50 sticky top-0 z-10">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                    Khu vực
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                    Platform
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                    Giá
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                    Nguồn
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                    Đồng bộ lúc
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                        <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                        Đang tải giá theo khu vực...
                      </div>
                    </td>
                  </tr>
                ) : !selectedProductId ? (
                  <tr>
                    <td colSpan={5} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-2 text-center px-4">
                        <GlobeAltIcon className="h-10 w-10 text-slate-300" />
                        <p className="font-medium text-slate-700">
                          {productOptions.length === 0 && !productsLoading
                            ? "Chưa có sản phẩm nào để xem giá"
                            : "Chọn một sản phẩm để xem giá theo khu vực"}
                        </p>
                        {productOptions.length === 0 && !productsLoading && (
                          <p className="text-sm text-slate-500">
                            Thêm sản phẩm ở tab Product management trước.
                          </p>
                        )}
                      </div>
                    </td>
                  </tr>
                ) : prices.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-2 text-center px-4">
                        <GlobeAltIcon className="h-10 w-10 text-slate-300" />
                        <p className="font-medium text-slate-700">
                          Chưa có giá theo khu vực cho sản phẩm này
                        </p>
                        <p className="text-sm text-slate-500 max-w-md">
                          {platformFilter === PaymentPlatform.GOOGLE
                            ? "Có thể do chưa đồng bộ, hoặc do thiếu quyền Play Console Monetization (xem ghi chú phía trên) — nhấn Đồng bộ ngay để kiểm tra."
                            : "Nhấn Đồng bộ ngay để lấy giá mới nhất từ store."}
                        </p>
                        <button
                          onClick={handleSync}
                          disabled={syncing}
                          className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800 disabled:opacity-60"
                        >
                          Đồng bộ ngay
                        </button>
                      </div>
                    </td>
                  </tr>
                ) : filteredPrices.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                        <GlobeAltIcon className="h-10 w-10 text-slate-300" />
                        <p className="font-medium text-slate-700">
                          Không tìm thấy khu vực phù hợp với "{territorySearch}"
                        </p>
                        <button
                          onClick={() => setTerritorySearch("")}
                          className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800"
                        >
                          Xóa tìm kiếm
                        </button>
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredPrices.map((row) => {
                    const PlatformIcon = platformIcons[row.platform];
                    const platformTone = platformIconTone[row.platform];
                    return (
                      <tr
                        key={`${row.platform}-${row.territory}`}
                        className="hover:bg-slate-50/70"
                      >
                        <td className="px-4 py-3">
                          <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700 font-semibold">
                            {row.territory}
                          </code>
                        </td>
                        <td className="px-4 py-3">
                          <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                            <PlatformIcon className={`h-4 w-4 ${platformTone}`} />
                            {platformLabels[row.platform]}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                          {formatRegionalPrice(row.customerPrice, row.currency)}
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-600">
                          {row.source ? platformLabels[row.source] : "-"}
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-600">
                          {formatDateTime(row.syncedAt)}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {!loading && prices.length > 0 && platformFilter !== PaymentPlatform.APPLE && googleRowCount === 0 && (
          <div className="mx-4 mb-4 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
            <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
            Không có dòng giá Google nào cho sản phẩm này — nhiều khả năng do
            thiếu quyền Play Console Monetization, không phải vì giá bằng 0.
          </div>
        )}
      </div>
    </div>
  );
};

export default RegionalPriceSection;
