import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CreditCardIcon,
  ExclamationTriangleIcon,
  QueueListIcon,
  ShieldCheckIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import { subscriptionService } from "../../../services/payments/subscriptionService";
import {
  ISubscription,
  SubscriptionListQuery,
} from "../../../types/interface/payments/subscription.interface";
import {
  PaymentPlatform,
  SubscriptionStatus,
} from "../../../types/enum/payment.enum";
import PaymentStatCard from "./PaymentStatCard";
import {
  formatDateTime,
  platformLabels,
  subscriptionStatusLabel,
  subscriptionStatusTone,
} from "../paymentShared";

type SubscriptionRecord = ISubscription & { _id?: string };

const getSubscriptionId = (subscription: SubscriptionRecord) =>
  subscription.id || subscription._id || "";

const normalizeSubscriptions = (payload: any): SubscriptionRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const SubscriptionSection: React.FC = () => {
  const [subscriptions, setSubscriptions] = useState<SubscriptionRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [platformFilter, setPlatformFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [page, setPage] = useState(1);
  const take = 20;
  const [lastCount, setLastCount] = useState(0);

  const fetchSubscriptions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new SubscriptionListQuery({
        search: search.trim(),
        take,
        page,
      });
      if (platformFilter) query.platform = platformFilter as PaymentPlatform;
      if (statusFilter) query.status = statusFilter as SubscriptionStatus;

      const res = await subscriptionService.getList(query);
      const normalized = normalizeSubscriptions(res);
      setSubscriptions(normalized);
      setLastCount(normalized.length);
    } catch (err: any) {
      console.error("Failed to fetch subscriptions", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải danh sách subscription/premium"
      );
      setSubscriptions([]);
      setLastCount(0);
    } finally {
      setLoading(false);
    }
  }, [page, platformFilter, search, statusFilter, take]);

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchSubscriptions();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchSubscriptions]);

  useEffect(() => {
    setPage(1);
  }, [platformFilter, search, statusFilter]);

  const stats = useMemo(() => {
    const total = subscriptions.length;
    const active = subscriptions.filter(
      (s) => s.status === SubscriptionStatus.ACTIVE
    ).length;
    const trials = subscriptions.filter((s) => s.isTrial).length;
    const autoRenew = subscriptions.filter((s) => s.autoRenewing).length;
    return { total, active, trials, autoRenew };
  }, [subscriptions]);

  const filteredSubscriptions = useMemo(() => subscriptions, [subscriptions]);

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <PaymentStatCard
          label="Tổng subscription"
          value={stats.total}
          icon={QueueListIcon}
          accent="from-slate-500 to-slate-700"
        />
        <PaymentStatCard
          label="Đang active"
          value={stats.active}
          icon={ShieldCheckIcon}
          accent="from-emerald-500 to-teal-500"
        />
        <PaymentStatCard
          label="Đang trial"
          value={stats.trials}
          icon={SparklesIcon}
          accent="from-amber-500 to-orange-500"
        />
        <PaymentStatCard
          label="Auto-renew"
          value={stats.autoRenew}
          icon={CreditCardIcon}
          accent="from-indigo-500 to-purple-500"
        />
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm theo userId, productId hoặc anchorId..."
                className="pl-10 pr-3 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 bg-slate-50/50"
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
            </div>

            <select
              value={platformFilter}
              onChange={(e) => setPlatformFilter(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Trạng thái</option>
              <option value={SubscriptionStatus.ACTIVE}>Active</option>
              <option value={SubscriptionStatus.GRACE}>Grace</option>
              <option value={SubscriptionStatus.ON_HOLD}>On hold</option>
              <option value={SubscriptionStatus.CANCELED}>Canceled</option>
              <option value={SubscriptionStatus.EXPIRED}>Expired</option>
            </select>
          </div>

          <button
            onClick={() => fetchSubscriptions()}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
          >
            <ArrowPathIcon className="h-5 w-5" />
            Làm mới
          </button>
        </div>

        {error && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center gap-2">
            <ExclamationTriangleIcon className="h-5 w-5" />
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
                  Status
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Auto-renew
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Chu kỳ
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Lần sync
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                      <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải subscription...
                    </div>
                  </td>
                </tr>
              ) : filteredSubscriptions.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                      <ShieldCheckIcon className="h-10 w-10 text-slate-300" />
                      <p className="font-medium text-slate-700">
                        Chưa có subscription
                      </p>
                      <p className="text-sm text-slate-500">
                        Khi user có premium, trạng thái sẽ hiển thị tại đây.
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredSubscriptions.map((sub) => {
                  const id = getSubscriptionId(sub);
                  return (
                    <tr key={id} className="hover:bg-slate-50/70">
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700">
                            {sub.userId}
                          </code>
                          <p className="text-[11px] text-slate-500">
                            Anchor: {sub.anchorId}
                          </p>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700">
                          {sub.productId}
                        </code>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                          <SparklesIcon className="h-4 w-4 text-amber-500" />
                          {platformLabels[sub.platform]}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${subscriptionStatusTone[sub.status]}`}
                        >
                          {subscriptionStatusLabel[sub.status]}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                            sub.autoRenewing
                              ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                              : "bg-slate-100 text-slate-600 border-slate-200"
                          }`}
                        >
                          {sub.autoRenewing ? "Bật" : "Tắt"}
                        </span>
                        {sub.isTrial && (
                          <p className="text-[11px] text-amber-600 mt-1">
                            Trial
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        <div className="space-y-0.5">
                          <p>Bắt đầu: {formatDateTime(sub.currentPeriodStart)}</p>
                          <p>Kết thúc: {formatDateTime(sub.currentPeriodEnd)}</p>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        <div className="space-y-0.5">
                          <p>Event: {formatDateTime(sub.lastEventAt)}</p>
                          <p>Verify: {formatDateTime(sub.lastVerifiedAt)}</p>
                        </div>
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

export default SubscriptionSection;
