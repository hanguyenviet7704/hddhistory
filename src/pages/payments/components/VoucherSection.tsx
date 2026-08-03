import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  LockClosedIcon,
  TicketIcon,
} from "@heroicons/react/24/outline";
import { voucherService } from "../../../services/payments/voucherService";
import {
  IVoucher,
  VoucherListQuery,
} from "../../../types/interface/payments/voucher.interface";
import { formatDateTime } from "../paymentShared";

const normalizeVouchers = (payload: any): IVoucher[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const validityLabel = (voucher: IVoucher) => {
  if (!voucher.validFrom && !voucher.validTo) return "Không giới hạn";
  if (voucher.validFrom && voucher.validTo) {
    return `${formatDateTime(voucher.validFrom)} -> ${formatDateTime(
      voucher.validTo
    )}`;
  }
  if (voucher.validFrom) return `Từ ${formatDateTime(voucher.validFrom)}`;
  return `Đến ${formatDateTime(voucher.validTo)}`;
};

// Voucher creation moved to the affiliate (voucher.eup.ai). This section is
// read-only: no create/edit/bulk import/toggle/delete - it exists only so an
// operator can look up a voucher's history. Configuring how a discount %
// resolves to a SKU swap now happens in the "Bậc giảm giá" tab.
const VoucherSection: React.FC = () => {
  const [vouchers, setVouchers] = useState<IVoucher[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<
    "all" | "active" | "inactive"
  >("all");
  const [page, setPage] = useState(1);
  const take = 20;
  const [lastCount, setLastCount] = useState(0);

  const hasFilters = Boolean(search.trim()) || statusFilter !== "all";

  const fetchVouchers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new VoucherListQuery({ search: search.trim(), take, page });
      if (statusFilter !== "all") query.isActive = statusFilter === "active";

      const res = await voucherService.getList(query);
      const normalized = normalizeVouchers(res);
      setVouchers(normalized);
      setLastCount(normalized.length);
    } catch (err: any) {
      console.error("Failed to fetch vouchers", err);
      setError(
        err?.response?.data?.message || "Không thể tải danh sách voucher"
      );
      setVouchers([]);
      setLastCount(0);
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter, take]);

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchVouchers();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchVouchers]);

  useEffect(() => {
    setPage(1);
  }, [search, statusFilter]);

  const resetFilters = () => {
    setSearch("");
    setStatusFilter("all");
  };

  const stats = useMemo(() => {
    const active = vouchers.filter((v) => v.isActive).length;
    const exhausted = vouchers.filter(
      (v) => v.maxUses != null && v.usedCount >= v.maxUses
    ).length;
    return { total: vouchers.length, active, exhausted };
  }, [vouchers]);

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 flex items-start gap-3">
        <LockClosedIcon className="h-5 w-5 text-amber-600 flex-shrink-0 mt-0.5" />
        <div className="text-sm text-amber-800">
          <p className="font-medium">
            Chỉ đọc - mã giảm giá giờ được tạo ở affiliate.eupgroup.net
          </p>
          <p className="mt-1">
            Bảng bên dưới chỉ dùng để tra lịch sử voucher đã phát hành trước
            đây. Tạo/sửa/xoá mã hoặc bật/tắt trạng thái phải thực hiện trên hệ
            thống affiliate. Để khai % giảm giá quy đổi sang SKU cho mã mới,
            dùng tab "Bậc giảm giá".
          </p>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm theo code hoặc owner..."
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
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as "all" | "active" | "inactive")
              }
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="all">Trạng thái</option>
              <option value="active">Đang bật</option>
              <option value="inactive">Đang tắt</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchVouchers()}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              <ArrowPathIcon className="h-5 w-5" />
              Làm mới
            </button>
          </div>
        </div>

        {error && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center justify-between gap-2">
            <span className="flex items-center gap-2">
              <ExclamationTriangleIcon className="h-5 w-5" />
              {error}
            </span>
            <button
              onClick={() => fetchVouchers()}
              className="text-red-700 underline underline-offset-2 hover:text-red-800"
            >
              Thử lại
            </button>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-100">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Code
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Owner
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Discount %
                  <span className="block text-[10px] normal-case font-normal text-slate-400">
                    Chỉ hiển thị
                  </span>
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Hiệu lực
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Lượt dùng
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Trạng thái
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                      <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải voucher...
                    </div>
                  </td>
                </tr>
              ) : vouchers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                      <TicketIcon className="h-10 w-10 text-slate-300" />
                      <p className="font-medium text-slate-700">
                        {hasFilters
                          ? "Không tìm thấy voucher phù hợp"
                          : "Chưa có voucher nào trong lịch sử"}
                      </p>
                      {hasFilters && (
                        <button
                          onClick={resetFilters}
                          className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800"
                        >
                          Xóa bộ lọc
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                vouchers.map((voucher) => {
                  const exhausted =
                    voucher.maxUses != null &&
                    voucher.usedCount >= voucher.maxUses;
                  return (
                    <tr key={voucher.id} className="hover:bg-slate-50/70">
                      <td className="px-4 py-3">
                        <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700 font-semibold">
                          {voucher.code}
                        </code>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        {voucher.owner || "-"}
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        {voucher.discountPercent != null
                          ? `${voucher.discountPercent}%`
                          : "-"}
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-600">
                        {validityLabel(voucher)}
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-700">
                        <span
                          className={
                            exhausted ? "text-red-600 font-semibold" : ""
                          }
                        >
                          {voucher.usedCount}
                          {voucher.maxUses != null ? ` / ${voucher.maxUses}` : " / ∞"}
                        </span>
                        {exhausted && (
                          <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-red-50 text-red-700 border border-red-100">
                            Hết lượt
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`px-3 py-1.5 rounded-full text-xs font-medium border ${
                            voucher.isActive
                              ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                              : "bg-slate-100 text-slate-600 border-slate-200"
                          }`}
                        >
                          {voucher.isActive ? "Active" : "Inactive"}
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
          Trang {page} · {stats.total} voucher đang hiển thị
          {stats.exhausted > 0 && ` · ${stats.exhausted} đã hết lượt`}
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

export default VoucherSection;
