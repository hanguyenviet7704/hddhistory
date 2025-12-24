import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  BanknotesIcon,
  ChartBarIcon,
  CurrencyDollarIcon,
  CheckCircleIcon,
  EyeIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { purchaseService } from "../../../services/payments/purchaseService";
import {
  GetRevenueListQuery,
  IPurchase,
  RevenueStatisticsResponse,
} from "../../../types/interface/payments/purchase.interface";
import { IWebhookEvent } from "../../../types/interface/payments/webhook-event.interface";
import {
  IProduct,
  ProductListQuery,
} from "../../../types/interface/payments/product.interface";
import {
  PaymentCurrency,
  PaymentEnvironment,
  PurchaseEventType,
} from "../../../types/enum/payment.enum";
import {
  formatDateTime,
  platformIconTone,
  platformIcons,
  platformLabels,
  priceLabel,
  eventTypeLabel,
  eventTypeTone,
} from "../paymentShared";
import { productService } from "../../../services/payments/productService";

type PurchaseRecord = IPurchase & { _id?: string };
type ProductRecord = IProduct & { _id?: string };
type WebhookRecord = IWebhookEvent & { _id?: string };

const getPurchaseId = (purchase: PurchaseRecord) =>
  purchase.id || purchase._id || "";

const normalizeEntries = (payload: any): PurchaseRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizeWebhooks = (payload: any): WebhookRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizeProducts = (payload: any): ProductRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizeStats = (payload: any): RevenueStatisticsResponse | null => {
  if (!payload) return null;
  if (payload.data) return payload.data;
  return payload;
};

const startOfCurrentMonth = () => {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
};

const endOfCurrentMonth = () => {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59)
  );
};

const defaultEnvironment =
  process.env.REACT_APP_NODE_ENV === "production"
    ? PaymentEnvironment.PRODUCTION
    : PaymentEnvironment.SANDBOX;

const RevenueDashboard: React.FC = () => {
  const [currency, setCurrency] = useState<PaymentCurrency>(
    PaymentCurrency.VND
  );
  const [environment, setEnvironment] =
    useState<PaymentEnvironment>(defaultEnvironment);
  const [from, setFrom] = useState<string>(startOfCurrentMonth().toISOString());
  const [to, setTo] = useState<string>(endOfCurrentMonth().toISOString());
  const [eventType, setEventType] = useState<string>("");
  const [productId, setProductId] = useState<string>("");
  const [stats, setStats] = useState<RevenueStatisticsResponse | null>(null);
  const [entries, setEntries] = useState<PurchaseRecord[]>([]);
  const [products, setProducts] = useState<ProductRecord[]>([]);
  const [selectedPurchase, setSelectedPurchase] =
    useState<PurchaseRecord | null>(null);
  const [webhooks, setWebhooks] = useState<WebhookRecord[]>([]);
  const [webhookLoading, setWebhookLoading] = useState(false);
  const [webhookError, setWebhookError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [productError, setProductError] = useState<string | null>(null);
  const [productLoading, setProductLoading] = useState(false);
  const [page, setPage] = useState(1);
  const take = 20;
  const [lastCount, setLastCount] = useState(0);

  const fetchProducts = useCallback(async () => {
    setProductLoading(true);
    setProductError(null);
    try {
      const query = new ProductListQuery({ page: 1, take: 200 });
      const res = await productService.getList(query);
      setProducts(normalizeProducts(res));
    } catch (err: any) {
      console.error("Fetch products failed", err);
      setProductError(
        err?.response?.data?.message || "Không thể tải danh sách sản phẩm"
      );
      setProducts([]);
    } finally {
      setProductLoading(false);
    }
  }, []);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new GetRevenueListQuery({
        environment,
        currency,
        page,
        take,
      });
      if (from) query.from = from;
      if (to) query.to = to;
      if (eventType) query.eventType = eventType as PurchaseEventType;
      if (productId) query.productId = productId;

      const [statRes, entryRes] = await Promise.all([
        purchaseService.getRevenueStatistics(query),
        purchaseService.getRevenueEntries(query),
      ]);
      const normalizedStats = normalizeStats(statRes);
      const normalizedEntries = normalizeEntries(entryRes);
      setStats(normalizedStats);
      setEntries(normalizedEntries);
      setLastCount(normalizedEntries.length);
      console.log(
        1111,
        process.env.REACT_APP_NODE_ENV,
        process.env.REACT_APP_BACKEND_AI_TUTOR
      );
    } catch (err: any) {
      console.error("Fetch revenue dashboard failed", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải dữ liệu doanh thu, vui lòng thử lại"
      );
      setStats(null);
      setEntries([]);
      setLastCount(0);
    } finally {
      setLoading(false);
    }
  }, [currency, environment, from, eventType, productId, to, page]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    setPage(1);
  }, [currency, environment, from, to, eventType, productId]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleOpenWebhooks = useCallback(async (purchase: PurchaseRecord) => {
    const purchaseId = getPurchaseId(purchase);
    setSelectedPurchase(purchase);
    setWebhookLoading(true);
    setWebhookError(null);
    setWebhooks([]);
    if (!purchaseId) {
      setWebhookError("Không tìm thấy id purchase để tra webhook");
      setWebhookLoading(false);
      return;
    }
    try {
      const res = await purchaseService.getWebhooksByPurchaseId(purchaseId);
      setWebhooks(normalizeWebhooks(res));
    } catch (err: any) {
      console.error("Fetch webhooks failed", err);
      setWebhookError(
        err?.response?.data?.message || "Không thể tải danh sách webhook"
      );
    } finally {
      setWebhookLoading(false);
    }
  }, []);

  const handleCloseWebhooks = useCallback(() => {
    setSelectedPurchase(null);
    setWebhooks([]);
    setWebhookError(null);
    setWebhookLoading(false);
  }, []);

  const refundRate = useMemo(() => {
    if (!stats) return 0;
    if (!stats.totalRevenue) return 0;
    return (stats.refundedRevenue / stats.totalRevenue) * 100;
  }, [stats]);

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
            <CurrencyDollarIcon className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500">Tổng doanh thu</p>
            <p className="text-lg font-semibold text-slate-900">
              {priceLabel(
                stats?.totalRevenue || 0,
                stats?.currency as PaymentCurrency
              )}
            </p>
          </div>
        </div>
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center">
            <ChartBarIcon className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500">Hoàn tiền</p>
            <p className="text-lg font-semibold text-slate-900">
              {priceLabel(
                stats?.refundedRevenue || 0,
                stats?.currency as PaymentCurrency
              )}
            </p>
            <p className="text-[11px] text-amber-600">
              Tỷ lệ: {refundRate.toFixed(1)}%
            </p>
          </div>
        </div>
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-sky-50 text-sky-700 flex items-center justify-center">
            <BanknotesIcon className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500">Số giao dịch</p>
            <p className="text-lg font-semibold text-slate-900">
              {stats?.totalPurchases ?? 0}
            </p>
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value as PaymentCurrency)}
              className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value={PaymentCurrency.USD}>USD</option>
              <option value={PaymentCurrency.VND}>VND</option>
            </select>

            <select
              value={environment}
              onChange={(e) =>
                setEnvironment(e.target.value as PaymentEnvironment)
              }
              className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value={PaymentEnvironment.PRODUCTION}>Production</option>
              <option value={PaymentEnvironment.SANDBOX}>Sandbox</option>
            </select>

            <div className="flex items-center gap-2">
              <label className="text-xs text-slate-500">Từ</label>
              <input
                type="date"
                value={from ? from.slice(0, 10) : ""}
                onChange={(e) => {
                  if (!e.target.value) {
                    setFrom("");
                    return;
                  }
                  setFrom(new Date(e.target.value).toISOString());
                }}
                className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
              />
              <label className="text-xs text-slate-500">Đến</label>
              <input
                type="date"
                value={to ? to.slice(0, 10) : ""}
                onChange={(e) => {
                  if (!e.target.value) {
                    setTo("");
                    return;
                  }
                  setTo(new Date(e.target.value).toISOString());
                }}
                className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
              />
            </div>

            <select
              value={eventType}
              onChange={(e) => setEventType(e.target.value)}
              className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả event</option>
              <option value={PurchaseEventType.INITIAL}>
                {eventTypeLabel[PurchaseEventType.INITIAL]}
              </option>
              <option value={PurchaseEventType.RENEWAL}>
                {eventTypeLabel[PurchaseEventType.RENEWAL]}
              </option>
              <option value={PurchaseEventType.CANCEL}>
                {eventTypeLabel[PurchaseEventType.CANCEL]}
              </option>
              <option value={PurchaseEventType.REFUND}>
                {eventTypeLabel[PurchaseEventType.REFUND]}
              </option>
            </select>

            <div className="flex flex-col gap-1">
              <select
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                disabled={productLoading}
                className="h-10 px-3 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500 disabled:opacity-60"
              >
                <option value="">Sản phẩm</option>
                {products.map((product) => (
                  <option
                    key={product.id || product._id || product.productId}
                    value={product.productId}
                  >
                    {product.title} - {product.productId}
                  </option>
                ))}
              </select>
              {productError && (
                <span className="text-[11px] text-amber-600">
                  {productError}
                </span>
              )}
            </div>
          </div>

          <button
            onClick={() => fetchData()}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
          >
            <ArrowPathIcon className="h-5 w-5" />
            Làm mới
          </button>
        </div>

        {error && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-100">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  User
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Product
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Platform
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Giá
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Event
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Thời gian
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Webhook
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-10 text-center text-slate-500">
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : entries.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-10 text-center text-slate-500">
                    Chưa có giao dịch nào trong khoảng thời gian này.
                  </td>
                </tr>
              ) : (
                entries.map((entry, index) => {
                  const purchaseId = getPurchaseId(entry);
                  const amount = entry.rawPrice ?? entry.price;
                  const PlatformIcon = platformIcons[entry.platform];
                  const platformTone = platformIconTone[entry.platform];
                  const eventTone =
                    entry.eventType && eventTypeTone[entry.eventType]
                      ? eventTypeTone[entry.eventType]
                      : "bg-slate-50 text-slate-700 border-slate-200";
                  const eventLabel =
                    entry.eventType && eventTypeLabel[entry.eventType]
                      ? eventTypeLabel[entry.eventType]
                      : entry.eventType || "-";
                  return (
                    <tr
                      key={
                        purchaseId || entry.orderId || entry.productId || index
                      }
                      className="hover:bg-slate-50/70"
                    >
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-slate-900">
                            {entry.userName || entry.userEmail || "N/A"}
                          </p>
                          {entry.userEmail && (
                            <p className="text-[11px] text-slate-500">
                              {entry.userEmail}
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-slate-900">
                            {entry.productId}
                          </p>
                          {entry.orderId && (
                            <p className="text-[11px] text-slate-500">
                              Order: {entry.orderId}
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                          <PlatformIcon className={`h-4 w-4 ${platformTone}`} />
                          {platformLabels[entry.platform]}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-800">
                        {priceLabel(amount, entry.currency)}
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        <div
                          className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full border text-xs font-medium ${eventTone}`}
                        >
                          <span className="h-2 w-2 rounded-full bg-current/60" />
                          <span className="uppercase tracking-wide">
                            {eventLabel}
                          </span>
                          {entry.isManual && (
                            <span className="inline-flex items-center gap-1 text-[11px] text-emerald-700">
                              <CheckCircleIcon className="h-4 w-4" />
                              Manual
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        {formatDateTime(entry.purchaseTime)}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => handleOpenWebhooks(entry)}
                          disabled={!purchaseId}
                          className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
                          title={
                            purchaseId ? "Xem webhook" : "Không có purchaseId"
                          }
                        >
                          <EyeIcon className="h-5 w-5" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex items-center justify-between text-sm text-slate-700">
        <div>
          Trang {page} · Hiển thị tối đa {take} mục/trang
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1 || loading}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            Trang trước
          </button>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={loading || lastCount < take}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            Trang sau
          </button>
        </div>
      </div>

      {selectedPurchase && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-5xl max-h-[85vh] overflow-hidden flex flex-col">
            <div className="flex items-start justify-between p-4 border-b border-slate-100">
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Webhook liên quan
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  Purchase: {getPurchaseId(selectedPurchase) || "-"} · Product:{" "}
                  {selectedPurchase.productId || "-"}
                </p>
              </div>
              <button
                onClick={handleCloseWebhooks}
                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3 overflow-y-auto">
              <div className="rounded-2xl border border-slate-100">
                <div className="flex items-center justify-between p-3 border-b border-slate-100">
                  <p className="text-sm font-semibold text-slate-900">
                    Danh sách webhook
                  </p>
                  {webhookLoading && (
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <span className="h-4 w-4 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải
                    </div>
                  )}
                </div>
                {webhookError ? (
                  <div className="p-4 text-sm text-red-700 bg-red-50 border border-red-200">
                    {webhookError}
                  </div>
                ) : webhookLoading ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Đang tải danh sách webhook...
                  </div>
                ) : webhooks.length === 0 ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Chưa có webhook cho purchase này.
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-100">
                      <thead className="bg-slate-50">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Event
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Platform
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Trạng thái
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Thời gian xử lý
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Lỗi
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {webhooks.map((webhook, index) => {
                          const PlatformIcon = platformIcons[webhook.platform];
                          const platformTone =
                            platformIconTone[webhook.platform];
                          const statusTone = webhook.processed
                            ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                            : "bg-slate-100 text-slate-700 border-slate-200";
                          return (
                            <tr
                              key={
                                webhook.id ||
                                webhook._id ||
                                `${webhook.purchaseId}-${index}`
                              }
                              className="hover:bg-slate-50/70"
                            >
                              <td className="px-4 py-3">
                                <div className="space-y-1">
                                  <p className="text-sm font-semibold text-slate-900">
                                    {webhook.eventType || "-"}
                                  </p>
                                  <p className="text-[11px] text-slate-500">
                                    {webhook.environment}
                                  </p>
                                </div>
                              </td>
                              <td className="px-4 py-3">
                                <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                                  <PlatformIcon
                                    className={`h-4 w-4 ${platformTone}`}
                                  />
                                  {platformLabels[webhook.platform]}
                                </span>
                              </td>
                              <td className="px-4 py-3">
                                <span
                                  className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium border ${statusTone}`}
                                >
                                  {webhook.processed
                                    ? "Đã xử lý"
                                    : "Chưa xử lý"}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700">
                                {formatDateTime(webhook.processedAt)}
                              </td>
                              <td className="px-4 py-3 text-sm text-red-600">
                                {webhook.error || "-"}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default RevenueDashboard;
