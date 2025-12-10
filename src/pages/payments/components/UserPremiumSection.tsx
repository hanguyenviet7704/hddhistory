import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  MagnifyingGlassIcon,
  ShieldCheckIcon,
  SparklesIcon,
  UserCircleIcon,
} from "@heroicons/react/24/outline";
import { subscriptionService } from "../../../services/payments/subscriptionService";
import { purchaseService } from "../../../services/payments/purchaseService";
import { IPurchase } from "../../../types/interface/payments/purchase.interface";
import { ISubscription } from "../../../types/interface/payments/subscription.interface";
import { IUser, UserListQuery } from "../../../types/interface/user.interface";
import { userService } from "../../../services/userService";
import {
  PaymentPlatform,
  PurchaseStatus,
  SubscriptionStatus,
} from "../../../types/enum/payment.enum";
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

const normalizeSubscription = (payload: any): SubscriptionRecord | null => {
  if (!payload) return null;
  if (payload.data) return payload.data;
  return payload;
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

const getUserId = (user?: UserRecord | null) =>
  user?.id || user?._id || user?.userId || "";

const getUserLabel = (user: UserRecord) => {
  const id = getUserId(user);
  return `${user.name || user.email || id}${
    user.email ? ` (${user.email})` : ""
  }`;
};

const UserPremiumSection: React.FC = () => {
  const [userSearch, setUserSearch] = useState("");
  const [userOptions, setUserOptions] = useState<UserRecord[]>([]);
  const [userId, setUserId] = useState<string | null>(null);
  const [premium, setPremium] = useState<SubscriptionRecord | null>(null);
  const [purchases, setPurchases] = useState<PurchaseRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showSuggestions, setShowSuggestions] = useState(false);

  const fetchUserData = useCallback(async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const [premiumRes, purchaseRes] = await Promise.all([
        subscriptionService.getActivePremiumForUser(id),
        purchaseService.findByUser(id),
      ]);
      setPremium(normalizeSubscription(premiumRes));
      setPurchases(normalizePurchases(purchaseRes));
    } catch (err: any) {
      console.error("Fetch premium/purchases failed", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải thông tin premium hoặc log mua hàng"
      );
      setPremium(null);
      setPurchases([]);
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchUsers = useCallback(async () => {
    setLoadingUsers(true);
    try {
      const query = new UserListQuery({
        search: userSearch.trim(),
        take: 20,
      });
      const res = await userService.getList(query);
      setUserOptions(normalizeUsers(res));
    } catch (err) {
      console.error("Fetch users failed", err);
    } finally {
      setLoadingUsers(false);
    }
  }, [userSearch]);

  const handleLookup = async () => {
    if (!userId) {
      setError("Vui lòng chọn user");
      return;
    }
    await fetchUserData(userId);
  };

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchUsers();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchUsers]);

  const sortedPurchases = useMemo(
    () =>
      [...purchases].sort((a, b) => {
        const aTime = a.purchaseTime ? new Date(a.purchaseTime).getTime() : 0;
        const bTime = b.purchaseTime ? new Date(b.purchaseTime).getTime() : 0;
        return bTime - aTime;
      }),
    [purchases]
  );

  const purchaseStats = useMemo(() => {
    const total = purchases.length;
    const paid = purchases.filter(
      (p) => p.status === PurchaseStatus.PAID
    ).length;
    const refunded = purchases.filter(
      (p) => p.status === PurchaseStatus.REFUNDED
    ).length;
    const failed = purchases.filter(
      (p) =>
        p.status === PurchaseStatus.FAILED ||
        p.status === PurchaseStatus.CANCELED
    ).length;
    return { total, paid, refunded, failed };
  }, [purchases]);

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div className="flex items-center gap-3 flex-1">
          <div className="h-10 w-10 rounded-xl bg-teal-50 text-teal-700 flex items-center justify-center">
            <UserCircleIcon className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-900">
              Tra cứu User Premium
            </p>
            <p className="text-xs text-slate-500">
              Tìm user rồi chọn để xem gói premium hiện tại và lịch sử giao
              dịch.
            </p>
          </div>
        </div>

        <div className="flex flex-col md:flex-row gap-3 w-full md:w-auto">
          <div className="relative flex-1 min-w-[280px]">
            <input
              value={userSearch}
              onChange={(e) => {
                setUserSearch(e.target.value);
                setError(null);
                setShowSuggestions(e.target.value.trim().length > 0);
              }}
              onFocus={() => setShowSuggestions(userSearch.trim().length > 0)}
              placeholder="Tìm user theo tên/email..."
              className="w-full pl-10 pr-3 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 bg-slate-50/50"
            />
            <MagnifyingGlassIcon className="h-5 w-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />

            {showSuggestions && userSearch.trim().length > 0 && (
              <div className="absolute z-20 mt-2 w-full max-h-64 overflow-y-auto rounded-xl border border-slate-100 bg-white shadow-lg">
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
                      setUserId(id);
                      setError(null);
                      setUserSearch(label);
                      setShowSuggestions(false);
                    }}
                    className={`w-full text-left px-3 py-2 text-sm hover:bg-teal-50 ${
                      userId === id
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

          <div className="flex gap-2">
            <button
              onClick={handleLookup}
              disabled={loading || !userId}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600 disabled:opacity-70"
            >
              {(loading || loadingUsers) && (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              )}
              Tra cứu
            </button>
            <button
              onClick={() => userId && fetchUserData(userId)}
              disabled={!userId || loading}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
            >
              <ArrowPathIcon className="h-5 w-5" />
              Làm mới
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center gap-2">
          <ExclamationTriangleIcon className="h-5 w-5" />
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <div className="col-span-1 xl:col-span-1">
          <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ShieldCheckIcon className="h-5 w-5 text-emerald-600" />
                <p className="text-sm font-semibold text-slate-900">
                  Premium hiện tại
                </p>
              </div>
              {premium && (
                <span
                  className={`px-2.5 py-1 rounded-full text-xs font-medium border ${
                    subscriptionStatusTone[premium.status]
                  }`}
                >
                  {subscriptionStatusLabel[premium.status]}
                </span>
              )}
            </div>

            {loading ? (
              <div className="flex items-center gap-3 text-slate-500 text-sm py-6">
                <span className="h-6 w-6 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                Đang tải thông tin premium...
              </div>
            ) : !premium ? (
              <div className="text-sm text-slate-600 py-4">
                {userId
                  ? "User chưa có premium active."
                  : "Nhập userId để xem thông tin premium."}
              </div>
            ) : (
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-2">
                  <div className="text-xs text-slate-500">User</div>
                  <div className="text-xs text-slate-800 font-medium text-right">
                    {premium.userId}
                  </div>
                  <div className="text-xs text-slate-500">Product</div>
                  <div className="text-xs text-slate-800 font-medium text-right">
                    {premium.productId}
                  </div>
                  <div className="text-xs text-slate-500">Platform</div>
                  <div className="text-xs text-slate-800 font-medium text-right flex items-center justify-end gap-1">
                    <SparklesIcon className="h-4 w-4 text-amber-500" />
                    {platformLabels[premium.platform]}
                  </div>
                  <div className="text-xs text-slate-500">Anchor</div>
                  <div className="text-xs text-slate-800 font-medium text-right">
                    {premium.anchorId}
                  </div>
                  <div className="text-xs text-slate-500">Auto-renew</div>
                  <div className="text-xs text-slate-800 font-medium text-right">
                    {premium.autoRenewing ? "Bật" : "Tắt"}
                  </div>
                  <div className="text-xs text-slate-500">Trial</div>
                  <div className="text-xs text-slate-800 font-medium text-right">
                    {premium.isTrial ? "Có" : "Không"}
                  </div>
                </div>
                <div className="text-xs text-slate-500">Chu kỳ</div>
                <div className="rounded-xl bg-slate-50 border border-slate-100 p-3 text-sm text-slate-700 space-y-1">
                  <p>Bắt đầu: {formatDateTime(premium.currentPeriodStart)}</p>
                  <p>Kết thúc: {formatDateTime(premium.currentPeriodEnd)}</p>
                </div>
                <div className="text-xs text-slate-500">Lần sync</div>
                <div className="rounded-xl bg-slate-50 border border-slate-100 p-3 text-sm text-slate-700 space-y-1">
                  <p>Event: {formatDateTime(premium.lastEventAt)}</p>
                  <p>Verify: {formatDateTime(premium.lastVerifiedAt)}</p>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="col-span-1 xl:col-span-2 space-y-3">
          <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Log mua hàng
                </p>
                <p className="text-xs text-slate-500">
                  {userId
                    ? `User: ${userId} · Tổng: ${purchaseStats.total} · Đã thanh toán: ${purchaseStats.paid}`
                    : "Chưa có dữ liệu, hãy tra cứu user."}
                </p>
              </div>
              {userId && (
                <button
                  onClick={() =>
                    fetchUserData(userId).catch(() => {
                      /* handled */
                    })
                  }
                  disabled={loading}
                  className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
                >
                  <ArrowPathIcon className="h-5 w-5" />
                  Làm mới log
                </button>
              )}
            </div>

            {loading ? (
              <div className="py-10 text-center text-slate-500 text-sm">
                Đang tải giao dịch...
              </div>
            ) : sortedPurchases.length === 0 ? (
              <div className="py-10 text-center text-slate-500 text-sm">
                {userId
                  ? "User chưa có giao dịch."
                  : "Nhập userId để xem giao dịch."}
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
                        Purchase
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                        Hết hạn
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                        Transaction
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {sortedPurchases.map((purchase) => {
                      const amount = purchase.rawPrice ?? purchase.price;
                      return (
                        <tr key={purchase.id} className="hover:bg-slate-50/70">
                          <td className="px-4 py-3">
                            <div className="flex flex-col gap-1">
                              <span
                                className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                                  purchaseStatusTone[purchase.status]
                                }`}
                              >
                                {purchaseStatusLabel[purchase.status]}
                              </span>
                              {purchase.failureReason && (
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
                              {purchase.orderId && (
                                <p className="text-[11px] text-slate-500">
                                  Order: {purchase.orderId}
                                </p>
                              )}
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
                            {formatDateTime(purchase.purchaseTime)}
                          </td>
                          <td className="px-4 py-3 text-sm text-slate-700">
                            {formatDateTime(purchase.expiryTime)}
                          </td>
                          <td className="px-4 py-3">
                            <div className="space-y-1">
                              <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700 block">
                                {purchase.storeTransactionId}
                              </code>
                              <p className="text-[11px] text-slate-500">
                                {purchase.id}
                              </p>
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
  );
};

export default UserPremiumSection;
