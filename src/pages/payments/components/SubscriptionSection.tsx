import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CreditCardIcon,
  ExclamationTriangleIcon,
  QueueListIcon,
  ShieldCheckIcon,
  SparklesIcon,
  EyeIcon,
  XMarkIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { subscriptionService } from "../../../services/payments/subscriptionService";
import { purchaseService } from "../../../services/payments/purchaseService";
import { userService } from "../../../services/userService";
import {
  ISubscription,
  SubscriptionListQuery,
} from "../../../types/interface/payments/subscription.interface";
import { IPurchase } from "../../../types/interface/payments/purchase.interface";
import { IUser, UserListQuery } from "../../../types/interface/user.interface";
import {
  PaymentPlatform,
  PurchaseStatus,
  SubscriptionStatus,
} from "../../../types/enum/payment.enum";
import PaymentStatCard from "./PaymentStatCard";
import {
  formatDateTime,
  platformLabels,
  priceLabel,
  purchaseStatusLabel,
  purchaseStatusTone,
  subscriptionStatusLabel,
  subscriptionStatusTone,
} from "../paymentShared";

type SubscriptionRecord = ISubscription & { _id?: string };
type PurchaseRecord = IPurchase & { _id?: string };
type UserRecord = IUser & { id?: string; _id?: string; userId?: string };

const getSubscriptionId = (subscription: SubscriptionRecord) =>
  subscription.id || subscription._id || "";

const getUserId = (user: UserRecord) =>
  user.userId || user.id || user._id || "";

const getUserLabel = (user: UserRecord) => {
  const id = getUserId(user);
  return `${user.name || user.email || id}${
    user.email ? ` (${user.email})` : ""
  }`;
};

const statusDotTone: Record<SubscriptionStatus, string> = {
  [SubscriptionStatus.ACTIVE]: "bg-emerald-500",
  [SubscriptionStatus.EXPIRED]: "bg-slate-400",
  [SubscriptionStatus.GRACE]: "bg-amber-500",
  [SubscriptionStatus.ON_HOLD]: "bg-orange-500",
  [SubscriptionStatus.CANCELED]: "bg-red-500",
};

const normalizeSubscriptions = (payload: any): SubscriptionRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizePurchases = (payload: any): PurchaseRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const normalizeUsers = (payload: any): UserRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const SubscriptionSection: React.FC = () => {
  const [subscriptions, setSubscriptions] = useState<SubscriptionRecord[]>([]);
  const [selectedSub, setSelectedSub] = useState<SubscriptionRecord | null>(
    null
  );
  const [relatedPurchases, setRelatedPurchases] = useState<PurchaseRecord[]>(
    []
  );
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<SubscriptionRecord | null>(
    null
  );
  const [confirmPassword, setConfirmPassword] = useState("");
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [userSearch, setUserSearch] = useState("");
  const [userFilter, setUserFilter] = useState<string>("");
  const [userOptions, setUserOptions] = useState<UserRecord[]>([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [showUserSuggestions, setShowUserSuggestions] = useState(false);
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
        take,
        page,
      });
      if (userFilter) query.userId = userFilter;
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
  }, [page, platformFilter, statusFilter, take, userFilter]);

  const handleOpenDetail = useCallback(
    async (subscription: SubscriptionRecord) => {
      setSelectedSub(subscription);
      setRelatedPurchases([]);
      setDetailError(null);
      if (!subscription.anchorId) {
        setDetailError("Subscription không có anchorId để tra cứu giao dịch");
        return;
      }
      setDetailLoading(true);
      try {
        const res = await purchaseService.findByAnchor(subscription.anchorId);
        const normalized = normalizePurchases(res);
        const sorted = normalized.sort((a, b) => {
          const aTime = a.purchaseTime ? new Date(a.purchaseTime).getTime() : 0;
          const bTime = b.purchaseTime ? new Date(b.purchaseTime).getTime() : 0;
          return bTime - aTime;
        });
        setRelatedPurchases(sorted);
      } catch (err: any) {
        console.error("Failed to fetch purchases by anchor", err);
        setDetailError(
          err?.response?.data?.message ||
            "Không thể tải purchase liên quan đến subscription này"
        );
      } finally {
        setDetailLoading(false);
      }
    },
    []
  );

  const handleCloseDetail = useCallback(() => {
    setSelectedSub(null);
    setRelatedPurchases([]);
    setDetailError(null);
    setDetailLoading(false);
  }, []);

  const handleOpenDelete = useCallback((subscription: SubscriptionRecord) => {
    setDeleteTarget(subscription);
    setConfirmPassword("");
    setDeleteError(null);
  }, []);

  const handleConfirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    const id = getSubscriptionId(deleteTarget);
    if (!id) {
      setDeleteError("Không tìm thấy id subscription để xoá");
      return;
    }
    if (!confirmPassword.trim()) {
      setDeleteError("Vui lòng nhập mật khẩu xác nhận");
      return;
    }
    setDeleteLoading(true);
    setDeleteError(null);
    try {
      await subscriptionService.remove(id, {
        confirmPassword: confirmPassword.trim(),
      });
      setDeleteTarget(null);
      setConfirmPassword("");
      fetchSubscriptions();
    } catch (err: any) {
      console.error("Failed to delete subscription", err);
      setDeleteError(
        err?.response?.data?.message ||
          "Không thể xoá subscription, vui lòng kiểm tra mật khẩu"
      );
    } finally {
      setDeleteLoading(false);
    }
  }, [confirmPassword, deleteTarget, fetchSubscriptions]);

  const handleCloseDelete = useCallback(() => {
    setDeleteTarget(null);
    setConfirmPassword("");
    setDeleteError(null);
    setDeleteLoading(false);
  }, []);

  const handleSubmitDelete = useCallback(
    async (e?: React.FormEvent<HTMLFormElement>) => {
      if (e) e.preventDefault();
      await handleConfirmDelete();
    },
    [handleConfirmDelete]
  );

  useEffect(() => {
    const handle = setTimeout(() => {
      if (!userSearch.trim()) {
        setUserOptions([]);
        return;
      }
      setLoadingUsers(true);
      const query = new UserListQuery({ search: userSearch.trim(), take: 8 });
      userService
        .getList(query)
        .then((res) => setUserOptions(normalizeUsers(res)))
        .catch((err) => console.error("Fetch users failed", err))
        .finally(() => setLoadingUsers(false));
    }, 250);
    return () => clearTimeout(handle);
  }, [userSearch]);

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchSubscriptions();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchSubscriptions]);

  useEffect(() => {
    setPage(1);
  }, [platformFilter, statusFilter, userFilter]);

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
                value={userSearch}
                onChange={(e) => {
                  setUserSearch(e.target.value);
                  setShowUserSuggestions(true);
                }}
                onFocus={() => setShowUserSuggestions(true)}
                onBlur={() => setTimeout(() => setShowUserSuggestions(false), 150)}
                placeholder="Lọc theo user (tên/email)"
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
              {userFilter && (
                <button
                  onClick={() => {
                    setUserFilter("");
                    setUserSearch("");
                    setUserOptions([]);
                  }}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  <XMarkIcon className="h-4 w-4" />
                </button>
              )}

              {showUserSuggestions && userSearch.trim().length > 0 && (
                <div className="absolute z-30 mt-2 w-full max-h-64 overflow-y-auto rounded-xl border border-slate-100 bg-white shadow-lg">
                  {loadingUsers ? (
                    <div className="px-3 py-2 text-sm text-slate-500">
                      Đang tìm user...
                    </div>
                  ) : userOptions.length === 0 ? (
                    <div className="px-3 py-2 text-sm text-slate-500">
                      Không có kết quả
                    </div>
                  ) : (
                    userOptions.map((user) => {
                      const id = getUserId(user);
                      const label = getUserLabel(user);
                      return (
                        <button
                          key={id}
                          onClick={() => {
                            setUserFilter(id);
                            setUserSearch(label);
                            setShowUserSuggestions(false);
                          }}
                          className={`w-full text-left px-3 py-2 text-sm hover:bg-teal-50 ${
                            userFilter === id
                              ? "bg-teal-50 text-teal-800"
                              : "text-slate-800"
                          }`}
                        >
                          <div className="font-semibold">{label}</div>
                          {user.email && (
                            <div className="text-xs text-slate-500">
                              {user.email}
                            </div>
                          )}
                        </button>
                      );
                    })
                  )}
                </div>
              )}
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
                  Chi tiết
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
                          <p className="text-sm font-semibold text-slate-900">
                            {sub.userName || sub.userEmail || "Không có tên"}
                          </p>
                          {sub.userEmail && (
                            <p className="text-xs text-slate-500">
                              {sub.userEmail}
                            </p>
                          )}
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
                          className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium border shadow-sm ${
                            subscriptionStatusTone[sub.status]
                          }`}
                        >
                          <span
                            className={`h-2 w-2 rounded-full ${
                              statusDotTone[sub.status]
                            }`}
                          />
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
                      <td className="px-4 py-3 text-sm text-slate-700 min-w-[220px]">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-slate-50 border border-slate-200">
                            <span className="text-xs text-slate-500">
                              Bắt đầu:
                            </span>
                            <span className="font-medium text-slate-800">
                              {formatDateTime(sub.currentPeriodStart)}
                            </span>
                          </span>
                          <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-slate-50 border border-slate-200">
                            <span className="text-xs text-slate-500">
                              Kết thúc:
                            </span>
                            <span className="font-medium text-slate-800">
                              {formatDateTime(sub.currentPeriodEnd)}
                            </span>
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => handleOpenDetail(sub)}
                            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
                          >
                            <EyeIcon className="h-5 w-5" />
                            Chi tiết
                          </button>
                          <button
                            onClick={() => handleOpenDelete(sub)}
                            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-red-200 text-red-700 hover:bg-red-50 transition"
                          >
                            <TrashIcon className="h-5 w-5" />
                            Xoá
                          </button>
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

      {selectedSub && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-5xl max-h-[85vh] overflow-hidden flex flex-col">
            <div className="flex items-start justify-between p-4 border-b border-slate-100">
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Purchase liên quan
                </p>
              </div>
              <button
                onClick={handleCloseDetail}
                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3 overflow-y-auto">
              <div className="rounded-2xl border border-slate-100">
                <div className="flex items-center justify-between border-b border-slate-100">
                  {detailLoading && (
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <span className="h-4 w-4 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải
                    </div>
                  )}
                </div>
                {detailError ? (
                  <div className="p-4 text-sm text-red-700 bg-red-50 border border-red-200">
                    {detailError}
                  </div>
                ) : detailLoading ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Đang tải danh sách purchase...
                  </div>
                ) : relatedPurchases.length === 0 ? (
                  <div className="p-6 text-center text-sm text-slate-500">
                    Chưa có purchase liên quan tới anchor này.
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-100">
                      <thead className="bg-slate-50">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                            Status
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
                            Thời gian
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {relatedPurchases.map((purchase) => {
                          const amount = purchase.rawPrice ?? purchase.price;
                          return (
                            <tr
                              key={purchase.id}
                              className="hover:bg-slate-50/70"
                            >
                              <td className="px-4 py-3">
                                <div className="flex flex-col gap-1">
                                  <span
                                    className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                                      purchaseStatusTone[purchase.status]
                                    }`}
                                  >
                                    {purchaseStatusLabel[purchase.status]}
                                  </span>
                                  {purchase.status === PurchaseStatus.FAILED &&
                                    purchase.failureReason && (
                                      <p className="text-[11px] text-red-600">
                                        {purchase.failureReason}
                                      </p>
                                    )}
                                </div>
                              </td>
                              <td className="px-4 py-3">
                                <div className="space-y-1">
                                  <p className="text-sm font-semibold text-slate-900">
                                    {purchase.productId}
                                  </p>
                                  <p className="text-[11px] text-slate-500">
                                    Order: {purchase.orderId || "-"}
                                  </p>
                                  <p className="text-[11px] text-slate-500">
                                    Transaction: {purchase.storeTransactionId}
                                  </p>
                                </div>
                              </td>
                              <td className="px-4 py-3">
                                <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                                  <SparklesIcon className="h-4 w-4 text-amber-500" />
                                  {platformLabels[purchase.platform]}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-800">
                                {priceLabel(amount, purchase.currency)}
                              </td>
                              <td className="px-4 py-3 text-sm text-slate-700">
                                <div className="space-y-0.5">
                                  <p className="font-semibold uppercase">
                                    {purchase.eventType}
                                  </p>
                                  <p>Purchase: {formatDateTime(purchase.purchaseTime)}</p>
                                  <p>Expire: {formatDateTime(purchase.expiryTime)}</p>
                                </div>
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

      {deleteTarget && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-5 space-y-4"
            autoComplete="off"
            onSubmit={handleSubmitDelete}
          >
            {/* hidden input to discourage password managers from treating this as login */}
            <input
              type="text"
              name="fake-username"
              autoComplete="username"
              value="."
              onChange={() => {
                /* noop */
              }}
              className="hidden"
              aria-hidden="true"
              tabIndex={-1}
            />
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Xoá subscription
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  Product: {deleteTarget.productId} · User:{" "}
                  {deleteTarget.userEmail || deleteTarget.userName || "-"}
                </p>
              </div>
              <button
                onClick={handleCloseDelete}
                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-2">
              <label className="text-xs text-slate-600">
                Nhập mật khẩu xác nhận
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                autoComplete="one-time-code"
                name="delete-subscription-password"
                className="w-full px-3 py-2 rounded-lg border border-slate-200 focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Mật khẩu"
              />
              {deleteError && (
                <p className="text-xs text-red-600">{deleteError}</p>
              )}
            </div>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                onClick={handleCloseDelete}
                disabled={deleteLoading}
                className="px-3 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
              >
                Huỷ
              </button>
              <button
                type="submit"
                disabled={deleteLoading}
                className="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-gradient-to-r from-red-600 to-rose-500 text-white shadow hover:from-red-700 hover:to-rose-600 disabled:opacity-70"
              >
                {deleteLoading && (
                  <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
                )}
                Xoá ngay
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default SubscriptionSection;
