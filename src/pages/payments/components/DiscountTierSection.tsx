import React, { useCallback, useEffect, useState } from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  Square3Stack3DIcon,
} from "@heroicons/react/24/outline";
import DiscountTierModal from "../../../components/payments/DiscountTierModal";
import { discountTierService } from "../../../services/payments/discountTierService";
import {
  DiscountTierListQuery,
  IDiscountTier,
  IDiscountTierPayload,
} from "../../../types/interface/payments/discount-tier.interface";
import { PaymentPlatform } from "../../../types/enum/payment.enum";
import { useNotification } from "../../../utils/hooks/useNotification";
import { platformLabels, formatDateTime } from "../paymentShared";

const normalizeTiers = (payload: any): IDiscountTier[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const getPaginationMeta = (payload: any, fallbackPage: number) => {
  const body = payload?.data ?? payload;
  return {
    page: body?.currentPage ?? fallbackPage,
    totalPages: body?.totalPages ?? 1,
  };
};

const TAKE = 20;

const DiscountTierSection: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [tiers, setTiers] = useState<IDiscountTier[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [platformFilter, setPlatformFilter] = useState<PaymentPlatform | "">(
    ""
  );

  const [pagination, setPagination] = useState({ page: 1, totalPages: 1 });

  const [modalOpen, setModalOpen] = useState(false);
  const [selected, setSelected] = useState<IDiscountTier | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);

  const [mutatingId, setMutatingId] = useState<string | null>(null);
  const [confirmId, setConfirmId] = useState<string | null>(null);

  const hasFilters = Boolean(debouncedSearch) || platformFilter !== "";

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(handle);
  }, [search]);

  const fetchTiers = useCallback(
    async (page = 1) => {
      setLoading(true);
      setError(null);
      try {
        const query = new DiscountTierListQuery({
          search: debouncedSearch,
          take: TAKE,
          page,
        });
        if (platformFilter) query.platform = platformFilter;

        const res = await discountTierService.getList(query);
        setTiers(normalizeTiers(res));
        setPagination(getPaginationMeta(res, page));
      } catch (err: any) {
        console.error("Failed to fetch discount tiers", err);
        setError(
          err?.response?.data?.message ||
            "Không thể tải danh sách bậc giảm giá"
        );
        setTiers([]);
        setPagination({ page: 1, totalPages: 1 });
      } finally {
        setLoading(false);
      }
    },
    [debouncedSearch, platformFilter]
  );

  useEffect(() => {
    fetchTiers(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch, platformFilter]);

  const resetFilters = () => {
    setSearch("");
    setPlatformFilter("");
  };

  const openCreateModal = () => {
    setSelected(null);
    setModalError(null);
    setModalOpen(true);
  };

  const openEditModal = (tier: IDiscountTier) => {
    setSelected(tier);
    setModalError(null);
    setModalOpen(true);
  };

  const handleSave = async (payload: IDiscountTierPayload, id?: string) => {
    setModalLoading(true);
    setModalError(null);
    try {
      if (id) {
        await discountTierService.update(id, payload);
        showSuccess("Đã lưu thay đổi bậc giảm giá");
      } else {
        await discountTierService.create(payload);
        showSuccess("Đã tạo bậc giảm giá mới");
      }
      setModalOpen(false);
      setSelected(null);
      await fetchTiers(pagination.page);
    } catch (err: any) {
      console.error("Save discount tier failed", err);
      let message =
        err?.response?.data?.message || "Không thể lưu bậc giảm giá";
      if (err?.response?.status === 409) {
        const platformLabel = payload.platform
          ? platformLabels[payload.platform]
          : "";
        message = `Đã tồn tại bậc giảm giá cho package "${payload.packageKey}" trên ${platformLabel} với mức giảm ${payload.discountPercent}% - sửa bậc đó thay vì tạo mới.`;
      }
      setModalError(message);
      showError(message);
    } finally {
      setModalLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!confirmId) return;
    setMutatingId(confirmId);
    try {
      await discountTierService.remove(confirmId);
      showSuccess("Đã xóa bậc giảm giá");
      await fetchTiers(pagination.page);
    } catch (err: any) {
      console.error("Delete discount tier failed", err);
      showError(
        err?.response?.data?.message || "Không thể xóa bậc giảm giá"
      );
    } finally {
      setMutatingId(null);
      setConfirmId(null);
    }
  };

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-sky-100 bg-sky-50/60 px-4 py-3 flex items-start gap-3">
        <Square3Stack3DIcon className="h-5 w-5 text-sky-600 flex-shrink-0 mt-0.5" />
        <p className="text-sm text-sky-800">
          Mỗi bậc quy đổi % giảm giá của affiliate (voucher.eup.ai) sang một
          cặp SKU <span className="font-medium">gốc → khuyến mãi</span> theo
          package + platform, vì IAP chỉ thu tiền theo SKU đã đăng ký. Khai
          một lần cho mỗi (package key, platform, %) - không khai theo từng mã
          giảm giá.
        </p>
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm theo package key hoặc SKU..."
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
              onChange={(e) =>
                setPlatformFilter(e.target.value as PaymentPlatform | "")
              }
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchTiers(pagination.page)}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              <ArrowPathIcon className="h-5 w-5" />
              Làm mới
            </button>
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600"
            >
              <PlusIcon className="h-5 w-5" />
              Tạo bậc giảm giá
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
              onClick={() => fetchTiers(pagination.page)}
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
                  Package key
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Platform
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Giảm giá
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  SKU gốc → SKU khuyến mãi
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Cập nhật
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Hành động
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                      <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải bậc giảm giá...
                    </div>
                  </td>
                </tr>
              ) : tiers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                      <Square3Stack3DIcon className="h-10 w-10 text-slate-300" />
                      <p className="font-medium text-slate-700">
                        {hasFilters
                          ? "Không tìm thấy bậc giảm giá phù hợp"
                          : "Chưa có bậc giảm giá nào"}
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
                          Tạo bậc giảm giá đầu tiên
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                tiers.map((tier) => (
                  <tr key={tier.id} className="hover:bg-slate-50/70">
                    <td className="px-4 py-3">
                      <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700 font-semibold">
                        {tier.packageKey}
                      </code>
                    </td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                        {platformLabels[tier.platform] || tier.platform}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-slate-700">
                      {tier.discountPercent}%
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600">
                      <code className="bg-slate-100 px-2 py-1 rounded-lg">
                        {tier.baseProductId}
                      </code>
                      <span className="mx-1.5 text-slate-400">→</span>
                      <code className="bg-slate-100 px-2 py-1 rounded-lg">
                        {tier.targetProductId}
                      </code>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">
                      {formatDateTime(tier.updatedAt || tier.createdAt)}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => openEditModal(tier)}
                          className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-sm"
                        >
                          Sửa
                        </button>
                        <button
                          onClick={() => setConfirmId(tier.id)}
                          disabled={mutatingId === tier.id}
                          className="px-3 py-1.5 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 text-sm disabled:opacity-70"
                        >
                          Xóa
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex items-center justify-between text-sm text-slate-700">
        <div>
          Trang {pagination.page} / {pagination.totalPages}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => fetchTiers(pagination.page - 1)}
            disabled={pagination.page <= 1 || loading}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            Trang trước
          </button>
          <button
            onClick={() => fetchTiers(pagination.page + 1)}
            disabled={pagination.page >= pagination.totalPages || loading}
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
                <p className="font-semibold text-slate-900">
                  Xóa bậc giảm giá này?
                </p>
                <p className="text-sm text-slate-600">
                  Mã giảm giá của affiliate ứng với package + platform + % này
                  sẽ không còn quy đổi được sang SKU nào cho đến khi khai bậc
                  mới.
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

      <DiscountTierModal
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
    </div>
  );
};

export default DiscountTierSection;
