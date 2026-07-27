import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  DocumentArrowUpIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TicketIcon,
} from "@heroicons/react/24/outline";
import VoucherModal from "../../../components/payments/VoucherModal";
import VoucherBulkImportModal from "../../../components/payments/VoucherBulkImportModal";
import { voucherService } from "../../../services/payments/voucherService";
import {
  IVoucher,
  IVoucherBulkCreatePayload,
  IVoucherPayload,
  VoucherListQuery,
} from "../../../types/interface/payments/voucher.interface";
import { useNotification } from "../../../utils/hooks/useNotification";
import { formatDateTime } from "../paymentShared";

const normalizeVouchers = (payload: any): IVoucher[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const unwrap = (payload: any) => payload?.data ?? payload;

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

const VoucherSection: React.FC = () => {
  const { showSuccess, showError } = useNotification();

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

  const [modalOpen, setModalOpen] = useState(false);
  const [selected, setSelected] = useState<IVoucher | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const [editLoadingId, setEditLoadingId] = useState<string | null>(null);

  const [bulkModalOpen, setBulkModalOpen] = useState(false);
  const [bulkLoading, setBulkLoading] = useState(false);
  const [bulkError, setBulkError] = useState<string | null>(null);

  const [mutatingId, setMutatingId] = useState<string | null>(null);
  const [confirmId, setConfirmId] = useState<string | null>(null);

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

  const openCreateModal = () => {
    setSelected(null);
    setModalError(null);
    setModalOpen(true);
  };

  const openEditModal = async (voucher: IVoucher) => {
    setEditLoadingId(voucher.id);
    try {
      const detail = unwrap(await voucherService.getById(voucher.id));
      setSelected(detail);
      setModalError(null);
      setModalOpen(true);
    } catch (err: any) {
      console.error("Failed to load voucher detail", err);
      showError(
        err?.response?.data?.message || "Không thể tải chi tiết voucher"
      );
    } finally {
      setEditLoadingId(null);
    }
  };

  const handleSave = async (payload: IVoucherPayload, id?: string) => {
    setModalLoading(true);
    setModalError(null);
    try {
      if (id) {
        await voucherService.update(id, payload);
        showSuccess("Đã lưu thay đổi voucher");
      } else {
        await voucherService.create(payload);
        showSuccess("Đã tạo voucher mới");
      }
      setModalOpen(false);
      setSelected(null);
      await fetchVouchers();
    } catch (err: any) {
      console.error("Save voucher failed", err);
      const message = err?.response?.data?.message || "Không thể lưu voucher";
      setModalError(message);
      showError(message);
    } finally {
      setModalLoading(false);
    }
  };

  const handleBulkImport = async (payload: IVoucherBulkCreatePayload) => {
    setBulkLoading(true);
    setBulkError(null);
    try {
      const res = unwrap(await voucherService.bulkCreate(payload));
      showSuccess(
        `Đã tạo ${res?.created ?? 0} voucher, bỏ qua ${
          res?.skipped ?? 0
        } mã trùng`
      );
      setBulkModalOpen(false);
      await fetchVouchers();
    } catch (err: any) {
      console.error("Bulk import vouchers failed", err);
      const message =
        err?.response?.data?.message || "Không thể tạo voucher hàng loạt";
      setBulkError(message);
      showError(message);
    } finally {
      setBulkLoading(false);
    }
  };

  const handleToggleActive = async (voucher: IVoucher) => {
    setMutatingId(voucher.id);
    try {
      await voucherService.update(voucher.id, { isActive: !voucher.isActive });
      setVouchers((prev) =>
        prev.map((item) =>
          item.id === voucher.id
            ? { ...item, isActive: !voucher.isActive }
            : item
        )
      );
    } catch (err: any) {
      console.error("Toggle voucher active failed", err);
      showError(
        err?.response?.data?.message || "Không thể cập nhật trạng thái"
      );
    } finally {
      setMutatingId(null);
    }
  };

  const handleDelete = async () => {
    if (!confirmId) return;
    setMutatingId(confirmId);
    try {
      await voucherService.remove(confirmId);
      setVouchers((prev) => prev.filter((item) => item.id !== confirmId));
      showSuccess("Đã xóa voucher");
    } catch (err: any) {
      console.error("Delete voucher failed", err);
      showError(err?.response?.data?.message || "Không thể xóa voucher");
    } finally {
      setMutatingId(null);
      setConfirmId(null);
    }
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
            <button
              onClick={() => {
                setBulkError(null);
                setBulkModalOpen(true);
              }}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              <DocumentArrowUpIcon className="h-5 w-5" />
              Bulk import
            </button>
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600"
            >
              <PlusIcon className="h-5 w-5" />
              Tạo voucher
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
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Hành động
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                      <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải voucher...
                    </div>
                  </td>
                </tr>
              ) : vouchers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                      <TicketIcon className="h-10 w-10 text-slate-300" />
                      <p className="font-medium text-slate-700">
                        {hasFilters
                          ? "Không tìm thấy voucher phù hợp"
                          : "Chưa có voucher nào"}
                      </p>
                      {hasFilters ? (
                        <button
                          onClick={resetFilters}
                          className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800"
                        >
                          Xóa bộ lọc
                        </button>
                      ) : (
                        <button
                          onClick={openCreateModal}
                          className="text-sm text-teal-700 underline underline-offset-2 hover:text-teal-800"
                        >
                          Tạo voucher đầu tiên
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
                        <button
                          onClick={() => handleToggleActive(voucher)}
                          disabled={mutatingId === voucher.id}
                          className={`px-3 py-1.5 rounded-full text-xs font-medium border transition ${
                            voucher.isActive
                              ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                              : "bg-slate-100 text-slate-600 border-slate-200"
                          } ${mutatingId === voucher.id ? "opacity-70" : ""}`}
                        >
                          {voucher.isActive ? "Active" : "Inactive"}
                        </button>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => openEditModal(voucher)}
                            disabled={editLoadingId === voucher.id}
                            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-sm inline-flex items-center gap-1.5 disabled:opacity-70"
                          >
                            {editLoadingId === voucher.id && (
                              <span className="h-3.5 w-3.5 border-2 border-slate-400 border-t-transparent rounded-full animate-spin" />
                            )}
                            Sửa
                          </button>
                          <button
                            onClick={() => setConfirmId(voucher.id)}
                            disabled={mutatingId === voucher.id}
                            className="px-3 py-1.5 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 text-sm"
                          >
                            Xóa
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

      {confirmId && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/30 px-3">
          <div className="bg-white rounded-2xl shadow-xl border border-slate-100 max-w-sm w-full p-6 space-y-4">
            <div className="flex items-center gap-3">
              <ExclamationTriangleIcon className="h-8 w-8 text-amber-500" />
              <div>
                <p className="font-semibold text-slate-900">Xóa voucher này?</p>
                <p className="text-sm text-slate-600">
                  Hành động này không thể hoàn tác. Các ánh xạ SKU của voucher
                  cũng sẽ bị xóa.
                </p>
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setConfirmId(null)}
                className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50"
              >
                Hủy
              </button>
              <button
                onClick={handleDelete}
                disabled={mutatingId === confirmId}
                className="px-4 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700 disabled:opacity-70"
              >
                Xóa
              </button>
            </div>
          </div>
        </div>
      )}

      <VoucherModal
        isOpen={modalOpen}
        initial={selected}
        onClose={() => {
          setModalOpen(false);
          setSelected(null);
        }}
        onSubmit={handleSave}
        loading={modalLoading}
        error={modalError}
      />

      <VoucherBulkImportModal
        isOpen={bulkModalOpen}
        onClose={() => setBulkModalOpen(false)}
        onSubmit={handleBulkImport}
        loading={bulkLoading}
        error={bulkError}
      />
    </div>
  );
};

export default VoucherSection;
