import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  BanknotesIcon,
  ChartBarIcon,
  CurrencyDollarIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import { purchaseService } from "../../../services/payments/purchaseService";
import {
  GetRevenueListQuery,
  IPurchase,
  RevenueStatisticsResponse,
} from "../../../types/interface/payments/purchase.interface";
import {
  PaymentCurrency,
  PaymentPlatform,
  PurchaseStatus,
} from "../../../types/enum/payment.enum";
import {
  formatDateTime,
  platformLabels,
  priceLabel,
  purchaseStatusLabel,
  purchaseStatusTone,
  eventTypeLabel,
  eventTypeTone,
} from "../paymentShared";

type PurchaseRecord = IPurchase & { _id?: string };

const normalizeEntries = (payload: any): PurchaseRecord[] => {
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

const RevenueDashboard: React.FC = () => {
  const [currency, setCurrency] = useState<PaymentCurrency>(
    PaymentCurrency.VND
  );
  const [from, setFrom] = useState<string>(
    startOfCurrentMonth().toISOString()
  );
  const [to, setTo] = useState<string>(endOfCurrentMonth().toISOString());
  const [platform, setPlatform] = useState<string>("");
  const [status, setStatus] = useState<string>("");
  const [stats, setStats] = useState<RevenueStatisticsResponse | null>(null);
  const [entries, setEntries] = useState<PurchaseRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const take = 20;
  const [lastCount, setLastCount] = useState(0);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new GetRevenueListQuery({
        currency,
        page,
        take,
      });
      if (from) query.from = from;
      if (to) query.to = to;
      if (platform) query.platform = platform as PaymentPlatform;
      if (status) query.status = status as PurchaseStatus;

      const [statRes, entryRes] = await Promise.all([
        purchaseService.getRevenueStatistics(query),
        purchaseService.getRevenueEntries(query),
      ]);
      const normalizedStats = normalizeStats(statRes);
      const normalizedEntries = normalizeEntries(entryRes);
      setStats(normalizedStats);
      setEntries(normalizedEntries);
      setLastCount(normalizedEntries.length);
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
  }, [currency, from, platform, status, to, page]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    setPage(1);
  }, [currency, from, to, platform, status]);

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
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value={PaymentCurrency.USD}>USD</option>
              <option value={PaymentCurrency.VND}>VND</option>
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
                className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
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
                className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
              />
            </div>

            <select
              value={platform}
              onChange={(e) => setPlatform(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>

            <select
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả trạng thái</option>
              <option value={PurchaseStatus.PAID}>Paid</option>
              <option value={PurchaseStatus.PENDING}>Pending</option>
              <option value={PurchaseStatus.FAILED}>Failed</option>
              <option value={PurchaseStatus.CANCELED}>Canceled</option>
              <option value={PurchaseStatus.REFUNDED}>Refunded</option>
            </select>
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
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">User</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Product</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Platform</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Giá</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Event</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Thời gian</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-10 text-center text-slate-500">Đang tải dữ liệu...</td>
                </tr>
              ) : entries.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-10 text-center text-slate-500">Chưa có giao dịch nào trong khoảng thời gian này.</td>
                </tr>
              ) : (
                entries.map((entry) => {
                  const amount = entry.rawPrice ?? entry.price;
                  const eventTone =
                    entry.eventType && eventTypeTone[entry.eventType]
                      ? eventTypeTone[entry.eventType]
                      : "bg-slate-50 text-slate-700 border-slate-200";
                  const eventLabel =
                    entry.eventType && eventTypeLabel[entry.eventType]
                      ? eventTypeLabel[entry.eventType]
                      : entry.eventType || "-";
                  return (
                    <tr key={entry.id} className="hover:bg-slate-50/70">
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-slate-900">{entry.userName || entry.userEmail || "N/A"}</p>
                          {entry.userEmail && <p className="text-[11px] text-slate-500">{entry.userEmail}</p>}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-slate-900">{entry.productId}</p>
                          {entry.orderId && <p className="text-[11px] text-slate-500">Order: {entry.orderId}</p>}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                          <SparklesIcon className="h-4 w-4 text-amber-500" />
                          {platformLabels[entry.platform]}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-800">{priceLabel(amount, entry.currency)}</td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        <div className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full border text-xs font-medium ${eventTone}`}>
                          <span className="h-2 w-2 rounded-full bg-current/60" />
                          <span className="uppercase tracking-wide">
                            {eventLabel}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">{formatDateTime(entry.purchaseTime)}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${purchaseStatusTone[entry.status]}`}>
                          {purchaseStatusLabel[entry.status]}
                        </span>
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
    </div>
  );
};

export default RevenueDashboard;
