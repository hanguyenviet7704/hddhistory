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
import {
  MARKET_TERRITORIES,
  MARKET_TERRITORY_PARAM,
  territoryCodeFor,
} from "../marketTerritoryMap";

type ProductRecord = IProduct & { _id?: string };
type ProductOption = { productId: string; title: string; platforms: PaymentPlatform[] };

// SKU column + one column per market (see marketTerritoryMap.ts).
const TOTAL_COLUMNS = MARKET_TERRITORIES.length + 1;

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

// Cell lookup key: platform + SKU + the store-specific territory code that
// SKU's row would have been persisted with for that platform.
const cellKey = (platform: PaymentPlatform, productId: string, territory: string) =>
  `${platform}|${productId}|${territory.toUpperCase()}`;

const RegionalPriceSection: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [productOptions, setProductOptions] = useState<ProductOption[]>([]);
  const [productsLoading, setProductsLoading] = useState(false);
  const [productsError, setProductsError] = useState<string | null>(null);

  const [selectedProductId, setSelectedProductId] = useState("");
  const [platformFilter, setPlatformFilter] = useState<string>("");
  const [skuSearch, setSkuSearch] = useState("");

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
    setLoading(true);
    setError(null);
    try {
      // Always scope to the markets the matrix actually renders -- a single
      // SKU has ~175 synced territories per platform, and the matrix only
      // ever shows the columns in marketTerritoryMap.ts.
      const params: IProductPriceQuery = { territories: MARKET_TERRITORY_PARAM };
      if (selectedProductId) params.productId = selectedProductId;
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

  // One lookup per (platform, SKU, store-specific territory code) so a cell
  // render never has to guess which code form the row was stored with.
  const priceLookup = useMemo(() => {
    const map = new Map<string, IProductPrice>();
    prices.forEach((row) => {
      map.set(cellKey(row.platform, row.productId, row.territory), row);
    });
    return map;
  }, [prices]);

  // Currency sub-label per market column, read off whichever synced row
  // happens to match that market (Apple or Google code) -- purely a display
  // hint, never used for the actual per-cell formatting.
  const columnCurrency = useMemo(() => {
    const map = new Map<string, string>();
    MARKET_TERRITORIES.forEach((market) => {
      const match = prices.find((row) => {
        const t = row.territory.toUpperCase();
        return t === market.apple || t === market.google;
      });
      if (match) map.set(market.label, match.currency);
    });
    return map;
  }, [prices]);

  const freshestSync = useMemo(() => {
    if (prices.length === 0) return null;
    const newest = prices.reduce((acc, row) => {
      const t = new Date(row.syncedAt).getTime();
      return Number.isFinite(t) && t > acc ? t : acc;
    }, 0);
    return newest ? new Date(newest) : null;
  }, [prices]);

  const matchesFilters = useCallback(
    (option: ProductOption) => {
      if (selectedProductId && option.productId !== selectedProductId) {
        return false;
      }
      const term = skuSearch.trim().toLowerCase();
      if (!term) return true;
      return (
        option.title.toLowerCase().includes(term) ||
        option.productId.toLowerCase().includes(term)
      );
    },
    [selectedProductId, skuSearch]
  );

  // Platform is never merged: each store gets its own row group, built from
  // that store's own SKU list, so an Apple-only or Google-only SKU can never
  // silently borrow the other platform's price.
  const showApple = platformFilter === "" || platformFilter === PaymentPlatform.APPLE;
  const showGoogle = platformFilter === "" || platformFilter === PaymentPlatform.GOOGLE;

  const appleOptions = useMemo(
    () => productOptions.filter((o) => o.platforms.includes(PaymentPlatform.APPLE)),
    [productOptions]
  );
  const googleOptions = useMemo(
    () => productOptions.filter((o) => o.platforms.includes(PaymentPlatform.GOOGLE)),
    [productOptions]
  );

  const visibleAppleOptions = useMemo(
    () => (showApple ? appleOptions.filter(matchesFilters) : []),
    [showApple, appleOptions, matchesFilters]
  );
  const visibleGoogleOptions = useMemo(
    () => (showGoogle ? googleOptions.filter(matchesFilters) : []),
    [showGoogle, googleOptions, matchesFilters]
  );

  const totalVisibleRows = visibleAppleOptions.length + visibleGoogleOptions.length;
  const hasActiveRowFilters = Boolean(selectedProductId) || Boolean(skuSearch.trim());

  const googleHasSyncedRows = useMemo(
    () => prices.some((row) => row.platform === PaymentPlatform.GOOGLE),
    [prices]
  );
  const showGoogleGapNotice =
    !loading && showGoogle && googleOptions.length > 0 && !googleHasSyncedRows;

  const resetRowFilters = () => {
    setSkuSearch("");
    setSelectedProductId("");
  };

  const syncScopeLabel = useMemo(() => {
    const productPart = selectedProductId ? `"${selectedProductId}"` : "tất cả SKU đang bật";
    const platformPart = platformFilter
      ? `trên ${platformLabels[platformFilter as PaymentPlatform]}`
      : "trên cả Apple và Google";
    return `Đồng bộ ngay sẽ chỉ chạy cho ${productPart} ${platformPart}.`;
  }, [platformFilter, selectedProductId]);

  const AppleSectionIcon = platformIcons[PaymentPlatform.APPLE];
  const GoogleSectionIcon = platformIcons[PaymentPlatform.GOOGLE];

  const renderRow = (option: ProductOption, platform: PaymentPlatform) => {
    const PlatformIcon = platformIcons[platform];
    const tone = platformIconTone[platform];
    return (
      <tr key={`${platform}-${option.productId}`} className="group hover:bg-slate-50/70">
        <th
          scope="row"
          className="sticky left-0 z-10 bg-white group-hover:bg-slate-50 px-4 py-3 border-r border-slate-100 align-top text-left font-normal min-w-[220px] max-w-[240px]"
        >
          <div className="flex items-start gap-2 min-w-0">
            <PlatformIcon className={`h-4 w-4 mt-0.5 flex-shrink-0 ${tone}`} />
            <div className="min-w-0">
              <p
                className="font-semibold text-slate-900 truncate"
                title={option.title}
              >
                {option.title}
              </p>
              <code className="text-[11px] text-slate-500">{option.productId}</code>
            </div>
          </div>
        </th>
        {MARKET_TERRITORIES.map((market) => {
          const code = territoryCodeFor(market, platform);
          const row = priceLookup.get(cellKey(platform, option.productId, code));
          return (
            <td
              key={market.label}
              className="px-4 py-3 text-right tabular-nums whitespace-nowrap min-w-[92px]"
            >
              {row ? (
                <span
                  className="font-semibold text-slate-800"
                  title={`Đồng bộ lúc ${formatDateTime(row.syncedAt)}`}
                >
                  {formatRegionalPrice(row.customerPrice, row.currency)}
                </span>
              ) : (
                <span
                  className="text-slate-300"
                  title="Chưa đồng bộ giá cho thị trường này"
                >
                  —
                </span>
              )}
            </td>
          );
        })}
      </tr>
    );
  };

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
              <option value="">Tất cả sản phẩm</option>
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
              <option value="">Cả hai platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>

            <div className="relative">
              <input
                value={skuSearch}
                onChange={(e) => setSkuSearch(e.target.value)}
                placeholder="Tìm theo tên hoặc SKU..."
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
              {skuSearch && (
                <button
                  onClick={() => setSkuSearch("")}
                  aria-label="Xóa tìm kiếm"
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
            {totalVisibleRows} SKU × {MARKET_TERRITORIES.length} thị trường đang hiển thị
          </span>
          <span>— = chưa đồng bộ giá cho thị trường đó, không phải giá bằng 0</span>
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

        <div className="mx-4 mt-3 overflow-x-auto rounded-xl border border-slate-100">
          <div className="max-h-[560px] overflow-y-auto">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr>
                  <th
                    scope="col"
                    className="sticky left-0 top-0 z-30 bg-slate-50 px-4 py-3 text-left text-xs font-semibold text-slate-600 border-b border-r border-slate-200 min-w-[220px]"
                  >
                    SKU
                  </th>
                  {MARKET_TERRITORIES.map((market) => (
                    <th
                      key={market.label}
                      scope="col"
                      className="sticky top-0 z-20 bg-slate-50 px-4 py-3 text-right text-xs font-semibold text-slate-600 border-b border-slate-200 whitespace-nowrap min-w-[92px]"
                    >
                      <div>{market.label}</div>
                      <div className="text-[10px] font-normal text-slate-400">
                        {columnCurrency.get(market.label) ?? "—"}
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {productsLoading || loading ? (
                  <tr>
                    <td colSpan={TOTAL_COLUMNS} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                        <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                        Đang tải bảng giá theo khu vực...
                      </div>
                    </td>
                  </tr>
                ) : productOptions.length === 0 ? (
                  <tr>
                    <td colSpan={TOTAL_COLUMNS} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-2 text-center px-4">
                        <GlobeAltIcon className="h-10 w-10 text-slate-300" />
                        <p className="font-medium text-slate-700">
                          Chưa có sản phẩm nào để xem giá
                        </p>
                        <p className="text-sm text-slate-500">
                          Thêm sản phẩm ở tab Product management trước.
                        </p>
                      </div>
                    </td>
                  </tr>
                ) : totalVisibleRows === 0 ? (
                  <tr>
                    <td colSpan={TOTAL_COLUMNS} className="py-10">
                      <div className="flex flex-col items-center justify-center text-slate-500 gap-2 text-center px-4">
                        <GlobeAltIcon className="h-10 w-10 text-slate-300" />
                        <p className="font-medium text-slate-700">
                          Không tìm thấy SKU phù hợp với bộ lọc hiện tại
                        </p>
                        <p className="text-sm text-slate-500 max-w-md">
                          Kiểm tra lại bộ lọc sản phẩm/tìm kiếm, hoặc bộ lọc
                          Platform nếu SKU chỉ tồn tại trên store còn lại.
                        </p>
                        {hasActiveRowFilters && (
                          <button
                            onClick={resetRowFilters}
                            className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800"
                          >
                            Xóa bộ lọc
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ) : (
                  <>
                    {visibleAppleOptions.length > 0 && (
                      <React.Fragment>
                        <tr className="bg-slate-100/70">
                          <td
                            colSpan={TOTAL_COLUMNS}
                            className="px-4 py-2 text-xs font-semibold text-slate-600 border-y border-slate-200"
                          >
                            <span className="inline-flex items-center gap-2">
                              <AppleSectionIcon
                                className={`h-4 w-4 ${platformIconTone[PaymentPlatform.APPLE]}`}
                              />
                              Apple · {visibleAppleOptions.length} SKU
                            </span>
                          </td>
                        </tr>
                        {visibleAppleOptions.map((option) =>
                          renderRow(option, PaymentPlatform.APPLE)
                        )}
                      </React.Fragment>
                    )}
                    {visibleGoogleOptions.length > 0 && (
                      <React.Fragment>
                        <tr className="bg-slate-100/70">
                          <td
                            colSpan={TOTAL_COLUMNS}
                            className="px-4 py-2 text-xs font-semibold text-slate-600 border-y border-slate-200"
                          >
                            <span className="inline-flex items-center gap-2">
                              <GoogleSectionIcon
                                className={`h-4 w-4 ${platformIconTone[PaymentPlatform.GOOGLE]}`}
                              />
                              Google · {visibleGoogleOptions.length} SKU
                            </span>
                          </td>
                        </tr>
                        {visibleGoogleOptions.map((option) =>
                          renderRow(option, PaymentPlatform.GOOGLE)
                        )}
                      </React.Fragment>
                    )}
                  </>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {showGoogleGapNotice && (
          <div className="mx-4 mb-4 mt-3 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
            <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
            Không có dòng giá Google nào được đồng bộ — nhiều khả năng do
            thiếu quyền Play Console Monetization, không phải vì giá bằng 0.
          </div>
        )}
      </div>
    </div>
  );
};

export default RegionalPriceSection;
