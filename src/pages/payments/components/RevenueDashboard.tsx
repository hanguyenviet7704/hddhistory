import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  BanknotesIcon,
  ChartBarIcon,
  CurrencyDollarIcon,
  CheckCircleIcon,
  EyeIcon,
  PencilSquareIcon,
  ExclamationTriangleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { purchaseService } from "../../../services/payments/purchaseService";
import {
  GetRevenueListQuery,
  IPurchase,
  PurchaseHistory,
  RevenueStatisticsResponse,
} from "../../../types/interface/payments/purchase.interface";
import {
  IProduct,
  ProductListQuery,
} from "../../../types/interface/payments/product.interface";
import {
  PaymentCurrency,
  PaymentEnvironment,
  PurchaseEventType,
  PurchaseStatus,
} from "../../../types/enum/payment.enum";
import {
  formatDateTime,
  platformIconTone,
  platformIcons,
  platformLabels,
  priceLabel,
  purchaseStatusLabel,
  purchaseStatusTone,
  eventTypeLabel,
  eventTypeTone,
} from "../paymentShared";
import { productService } from "../../../services/payments/productService";

type PurchaseRecord = IPurchase & { _id?: string };
type ProductRecord = IProduct & { _id?: string };
type PurchaseHistoryRecord = PurchaseHistory[];

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

const normalizeHistory = (payload: any): PurchaseHistory[] => {
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
  const [history, setHistory] = useState<PurchaseHistoryRecord>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [historyError, setHistoryError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editError, setEditError] = useState<string | null>(null);
  const [editSuccess, setEditSuccess] = useState<string | null>(null);
  const [editLoading, setEditLoading] = useState(false);
  const [editingPurchase, setEditingPurchase] = useState<PurchaseRecord | null>(
    null
  );
  const [editStatus, setEditStatus] = useState<PurchaseStatus>(
    PurchaseStatus.PENDING
  );
  const [confirmPassword, setConfirmPassword] = useState("");
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

  const handleOpenHistory = useCallback(async (purchase: PurchaseRecord) => {
    const purchaseId = getPurchaseId(purchase);
    setSelectedPurchase(purchase);
    setHistoryLoading(true);
    setHistoryError(null);
    setHistory([]);
    if (!purchaseId) {
      setHistoryError("Không tìm thấy id purchase để tra lịch sử");
      setHistoryLoading(false);
      return;
    }
    try {
      const res = await purchaseService.getHistory(purchaseId);
      setHistory(normalizeHistory(res));
    } catch (err: any) {
      console.error("Fetch purchase history failed", err);
      setHistoryError(
        err?.response?.data?.message || "Không thể tải lịch sử purchase"
      );
    } finally {
      setHistoryLoading(false);
    }
  }, []);

  const handleCloseHistory = useCallback(() => {
    setSelectedPurchase(null);
    setHistory([]);
    setHistoryError(null);
    setHistoryLoading(false);
  }, []);

  const handleOpenEdit = (purchase: PurchaseRecord) => {
    setEditingPurchase(purchase);
    setEditStatus(purchase.status);
    setConfirmPassword("");
    setEditError(null);
    setEditSuccess(null);
  };

  const handleCloseEdit = () => {
    setEditingPurchase(null);
    setConfirmPassword("");
    setEditError(null);
    setEditSuccess(null);
  };

  const handleSubmitEdit = async () => {
    if (!editingPurchase) return;
    const purchaseId = getPurchaseId(editingPurchase);
    if (!purchaseId) {
      setEditError("Không tìm thấy purchaseId để cập nhật.");
      return;
    }
    if (!confirmPassword.trim()) {
      setEditError("Vui lòng nhập mật khẩu xác nhận.");
      return;
    }
    setEditLoading(true);
    setEditError(null);
    setEditSuccess(null);
    try {
      await purchaseService.update(purchaseId, {
        status: editStatus,
        confirmPassword,
      });
      await fetchData();
      setEntries((prev) =>
        prev.map((p) =>
          getPurchaseId(p) === purchaseId ? { ...p, status: editStatus } : p
        )
      );
      setEditSuccess("Cập nhật purchase thành công.");
      handleCloseEdit();
    } catch (err: any) {
      console.error("Update purchase failed", err);
      setEditError(
        err?.response?.data?.message ||
          "Không thể cập nhật purchase, vui lòng thử lại."
      );
    } finally {
      setEditLoading(false);
    }
  };

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
                  Lịch sử
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={8} className="py-10 text-center text-slate-500">
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : entries.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-10 text-center text-slate-500">
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
                          onClick={() => handleOpenHistory(entry)}
                          disabled={!purchaseId}
                          className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
                          title={
                            purchaseId ? "Xem lịch sử" : "Không có purchaseId"
                          }
                        >
                          <EyeIcon className="h-5 w-5" />
                        </button>
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => handleOpenEdit(entry)}
                          className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-teal-200 text-teal-700 hover:bg-teal-50 transition"
                        >
                          <PencilSquareIcon className="h-5 w-5" />
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
                  Lịch sử purchase
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  Purchase: {getPurchaseId(selectedPurchase) || "-"} · Product:{" "}
                  {selectedPurchase.productId || "-"}
                </p>
              </div>
              <button
                onClick={handleCloseHistory}
                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3 overflow-y-auto">
              <div className="rounded-2xl border border-slate-100">
                <div className="flex items-center justify-between p-3 border-b border-slate-100">
                  <p className="text-sm font-semibold text-slate-900">
                    Danh sách lịch sử
                  </p>
                  {historyLoading && (
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <span className="h-4 w-4 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải
                    </div>
                  )}
                </div>
                {historyError ? (
                  <div className="p-4 text-sm text-red-700 bg-red-50 border border-red-200">
                    {historyError}
                  </div>
                ) : historyLoading ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Đang tải lịch sử purchase...
                  </div>
                ) : history.length === 0 ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Chưa có lịch sử cho purchase này.
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-100">
                      <thead className="bg-slate-50">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Trạng thái
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Nguồn
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Thời gian
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Purchase time
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Expiry time
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {history.map((item, index) => {
                          const statusTone =
                            purchaseStatusTone[item.status] ||
                            "bg-slate-100 text-slate-700 border-slate-200";
                          const statusLabel =
                            purchaseStatusLabel[item.status] || item.status;
                          return (
                            <tr
                              key={`${item.at}-${item.status}-${index}`}
                              className="hover:bg-slate-50/70"
                            >
                              <td className="px-4 py-3">
                                <span
                                  className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium border ${statusTone}`}
                                >
                                  {statusLabel}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700 uppercase">
                                {item.source || "-"}
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700">
                                {formatDateTime(item.at)}
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700">
                                {formatDateTime(item.purchaseTime ?? undefined)}
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700">
                                {formatDateTime(item.expiryTime ?? undefined)}
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

      {editingPurchase && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden">
            <div className="flex items-start justify-between p-4 border-b border-slate-100">
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Chỉnh sửa purchase
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  Purchase: {getPurchaseId(editingPurchase) || "-"} · User:{" "}
                  {editingPurchase.userEmail || editingPurchase.userName || "-"}
                </p>
              </div>
              <button
                onClick={handleCloseEdit}
                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <form
              className="p-4 space-y-3"
              autoComplete="new-password"
              onSubmit={(e) => {
                e.preventDefault();
                handleSubmitEdit();
              }}
            >
              <div className="flex items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 p-3 text-amber-800">
                <ExclamationTriangleIcon className="h-5 w-5 flex-shrink-0 mt-0.5" />
                <div className="text-sm leading-relaxed">
                  Việc chỉnh sửa purchase có thể ảnh hưởng tới báo cáo doanh thu
                  và số liệu subscription. Hãy chắc chắn bạn hiểu rõ thay đổi
                  này.
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-medium text-slate-600">
                  Trạng thái
                </label>
                <select
                  value={editStatus}
                  onChange={(e) =>
                    setEditStatus(e.target.value as PurchaseStatus)
                  }
                  className="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm"
                  disabled={editLoading}
                >
                  {Object.values(PurchaseStatus).map((status) => (
                    <option key={status} value={status}>
                      {purchaseStatusLabel[status]}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-medium text-slate-600">
                  Mật khẩu xác nhận
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm"
                  autoComplete="one-time-code"
                  name={`purchase-edit-confirm-${getPurchaseId(
                    editingPurchase
                  )}`}
                  placeholder="Nhập mật khẩu của bạn để xác nhận"
                  disabled={editLoading}
                  data-form-type="other"
                />
                {/* Hidden dummy fields to discourage browser password save */}
                <input type="text" className="hidden" tabIndex={-1} />
                <input type="password" className="hidden" tabIndex={-1} />
              </div>

              {editError && (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                  {editError}
                </div>
              )}
              {editSuccess && (
                <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">
                  {editSuccess}
                </div>
              )}

              <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
                <button
                  type="button"
                  className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50"
                  onClick={handleCloseEdit}
                  disabled={editLoading}
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg bg-teal-600 text-white hover:bg-teal-700 disabled:opacity-60"
                  disabled={editLoading}
                >
                  {editLoading ? "Đang lưu..." : "Lưu thay đổi"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default RevenueDashboard;
