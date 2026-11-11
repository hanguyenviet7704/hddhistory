import React, { useEffect, useState } from "react";
import {
  ArrowDownIcon,
  ArrowPathIcon,
  ArrowUpIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  TagIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import ToggleSwitch from "../../../components/paywall-config/ToggleSwitch";
import ProductRefsEditor from "../../../components/paywall-config/ProductRefsEditor";
import { paywallConfigService } from "../../../services/paywallConfigService";
import { segmentService } from "../../../services/segmentService";
import { PaywallLogicSaleStats } from "../../../types/interface/paywall-config.interface";
import { SegmentOption } from "../../../types/interface/segment.interface";
import { fromInputDateTime, toInputDateTime } from "../../../utils/promoCampaignForm";
import {
  emptyLogicSale,
  LogicSaleDraft,
  ProductsByPlatform,
} from "../paywallConfigDraft";
import SectionCard from "./SectionCard";

const MAX_LOGIC_SALES = 20;

const unwrap = <T,>(payload: any): T => payload?.data ?? payload;

interface LogicSalesSectionProps {
  value: LogicSaleDraft[];
  onChange: (next: LogicSaleDraft[]) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

interface LogicSaleCardProps {
  index: number;
  count: number;
  value: LogicSaleDraft;
  onChange: (next: LogicSaleDraft) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
  disabled: boolean;
  fieldErrors: Record<string, string>;
  segments: SegmentOption[];
  segmentsLoading: boolean;
  segmentsError: string | null;
  onRetrySegments: () => void;
  productsByPlatform: ProductsByPlatform | null;
  productsLoading: boolean;
  productsError?: string | null;
  onRefreshProducts: () => void;
}

interface StatsState {
  loading: boolean;
  error: string | null;
  data: PaywallLogicSaleStats | null;
}

const LogicSaleCard: React.FC<LogicSaleCardProps> = ({
  index,
  count,
  value,
  onChange,
  onRemove,
  onMoveUp,
  onMoveDown,
  disabled,
  fieldErrors,
  segments,
  segmentsLoading,
  segmentsError,
  onRetrySegments,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  const prefix = `logicSales[${index}]`;
  const rowErrors = Object.keys(fieldErrors).filter((f) => f.startsWith(prefix));
  const [expanded, setExpanded] = useState(true);
  const [stats, setStats] = useState<StatsState>({
    loading: false,
    error: null,
    data: null,
  });

  // Never let a collapsed card hide a validation error from view.
  useEffect(() => {
    if (rowErrors.length > 0) setExpanded(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rowErrors.length]);

  const fetchStats = async () => {
    setStats((s) => ({ ...s, loading: true, error: null }));
    try {
      const res = await paywallConfigService.getLogicSaleStats(value.id);
      const data = unwrap<PaywallLogicSaleStats>(res);
      setStats({ loading: false, error: null, data });
    } catch (err: any) {
      setStats({
        loading: false,
        error: err?.response?.data?.message ?? "Không tải được thống kê",
        data: null,
      });
    }
  };

  const toggleSegment = (segmentId: string, checked: boolean) => {
    const segmentIds = checked
      ? [...value.segmentIds, segmentId]
      : value.segmentIds.filter((id) => id !== segmentId);
    onChange({ ...value, segmentIds });
  };

  return (
    <div className="rounded-xl border border-slate-200 bg-white">
      <div className="flex items-center justify-between gap-2 p-3 hover:bg-slate-50/60 rounded-xl transition-colors">
        <button
          type="button"
          onClick={() => setExpanded((prev) => !prev)}
          className="flex flex-1 items-center gap-2 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1 rounded min-w-0"
          aria-expanded={expanded}
        >
          {expanded ? (
            <ChevronUpIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          ) : (
            <ChevronDownIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          )}
          <span className="text-sm font-medium text-slate-800 truncate">
            {value.name.trim() || `Logic sale ${index + 1}`}
          </span>
          <span
            className={`text-[11px] px-1.5 py-0.5 rounded-full flex-shrink-0 ${
              value.enabled
                ? "bg-emerald-50 text-emerald-700"
                : "bg-slate-100 text-slate-500"
            }`}
          >
            {value.enabled ? "Bật" : "Tắt"}
          </span>
          {rowErrors.length > 0 && (
            <span className="inline-flex items-center gap-1 text-xs text-red-600 flex-shrink-0">
              <ExclamationTriangleIcon className="h-3.5 w-3.5" />
              {rowErrors.length} lỗi
            </span>
          )}
        </button>
        <div className="flex items-center gap-1 flex-shrink-0">
          <button
            type="button"
            onClick={onMoveUp}
            disabled={disabled || index === 0}
            aria-label={`Đưa logic sale ${index + 1} lên trên`}
            title="Đưa lên — quyết định thứ tự khi hoà ưu tiên"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-40"
          >
            <ArrowUpIcon className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onMoveDown}
            disabled={disabled || index === count - 1}
            aria-label={`Đưa logic sale ${index + 1} xuống dưới`}
            title="Đưa xuống — quyết định thứ tự khi hoà ưu tiên"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-40"
          >
            <ArrowDownIcon className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onRemove}
            disabled={disabled}
            aria-label={`Xóa logic sale ${index + 1}`}
            title="Xóa logic sale"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
          >
            <TrashIcon className="h-4 w-4" />
          </button>
        </div>
      </div>

      {expanded && (
        <div className="border-t border-slate-100 p-3 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr] gap-3">
            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">
                Tên
                <span className="text-red-500 ml-0.5">*</span>
              </span>
              <input
                value={value.name}
                onChange={(e) => onChange({ ...value, name: e.target.value })}
                placeholder="Flash sale cuối tuần"
                disabled={disabled}
                className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors[`${prefix}.name`] ? "border-red-300" : "border-slate-200"
                }`}
              />
              {fieldErrors[`${prefix}.name`] && (
                <span className="text-[11px] text-red-600">
                  {fieldErrors[`${prefix}.name`]}
                </span>
              )}
            </label>

            <div className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">Trạng thái</span>
              <ToggleSwitch
                checked={value.enabled}
                onChange={(enabled) => onChange({ ...value, enabled })}
                label={value.enabled ? "Đang bật" : "Đang tắt"}
                disabled={disabled}
              />
            </div>
          </div>

          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Id</span>
            <input
              value={value.id}
              readOnly
              disabled
              className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm font-mono text-slate-500 cursor-not-allowed"
            />
            <span className="text-[11px] text-slate-500">
              Id gắn với thống kê đơn hàng — không đổi và không tái sử dụng cho
              campaign khác.
            </span>
          </label>

          <div>
            <span className="text-xs font-medium text-slate-700">Phân khúc user</span>
            {segmentsError ? (
              <div className="mt-1 flex items-center justify-between gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                <span className="flex items-center gap-1.5">
                  <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
                  {segmentsError}
                </span>
                <button
                  type="button"
                  onClick={onRetrySegments}
                  className="flex-shrink-0 underline hover:no-underline"
                >
                  Thử lại
                </button>
              </div>
            ) : segmentsLoading ? (
              <p className="mt-1 text-xs text-slate-500">Đang tải danh sách phân khúc...</p>
            ) : segments.length === 0 ? (
              <p className="mt-1 text-xs text-slate-500">
                Chưa có phân khúc nào — tạo ở trang Segments trước.
              </p>
            ) : (
              <div className="mt-1 max-h-36 overflow-y-auto rounded-lg border border-slate-200 p-1.5 space-y-0.5">
                {segments.map((seg) => {
                  const checked = value.segmentIds.includes(seg._id);
                  return (
                    <label
                      key={seg._id}
                      className="flex cursor-pointer items-center gap-2 rounded px-1.5 py-1 text-xs text-slate-700 hover:bg-slate-50"
                    >
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={(e) => toggleSegment(seg._id, e.target.checked)}
                        disabled={disabled}
                        className="h-3.5 w-3.5 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
                      />
                      <span>{seg.name}</span>
                    </label>
                  );
                })}
              </div>
            )}
            <p className="mt-1 text-[11px] text-slate-500">
              Không chọn phân khúc nào = áp dụng cho tất cả user. Khớp BẤT KỲ
              phân khúc nào được chọn.
            </p>
          </div>

          <ProductRefsEditor
            fieldPrefix={`${prefix}.products`}
            title="Chọn gói bán"
            hint="Ghi đè danh sách gói của chiến lược đang thắng trong lúc logic sale này áp dụng."
            emptyHint="Chưa chọn gói — logic sale này đang ở trạng thái nháp, sẽ không được phục vụ cho ai."
            value={value.products}
            onChange={(products) => onChange({ ...value, products })}
            disabled={disabled}
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={onRefreshProducts}
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">Ưu tiên</span>
              <input
                type="number"
                step={1}
                value={value.priority}
                onChange={(e) => onChange({ ...value, priority: e.target.value })}
                placeholder="0"
                disabled={disabled}
                className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors[`${prefix}.priority`] ? "border-red-300" : "border-slate-200"
                }`}
              />
              {fieldErrors[`${prefix}.priority`] && (
                <span className="text-[11px] text-red-600">
                  {fieldErrors[`${prefix}.priority`]}
                </span>
              )}
            </label>

            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">Bắt đầu (UTC)</span>
              <input
                type="datetime-local"
                value={toInputDateTime(value.startAtUtc)}
                onChange={(e) =>
                  onChange({ ...value, startAtUtc: fromInputDateTime(e.target.value) })
                }
                disabled={disabled}
                className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors[`${prefix}.startAtUtc`] ? "border-red-300" : "border-slate-200"
                }`}
              />
              {fieldErrors[`${prefix}.startAtUtc`] && (
                <span className="text-[11px] text-red-600">
                  {fieldErrors[`${prefix}.startAtUtc`]}
                </span>
              )}
            </label>

            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">
                Kết thúc (UTC)
                {value.countdown && <span className="text-red-500 ml-0.5">*</span>}
              </span>
              <input
                type="datetime-local"
                value={toInputDateTime(value.endAtUtc)}
                onChange={(e) => {
                  const endAtUtc = fromInputDateTime(e.target.value);
                  // Clearing the end date while the countdown is on would leave
                  // an impossible state (countdown needs a target) — turn it
                  // off instead of leaving a disabled switch stuck checked.
                  onChange({
                    ...value,
                    endAtUtc,
                    countdown: endAtUtc ? value.countdown : false,
                  });
                }}
                disabled={disabled}
                className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors[`${prefix}.endAtUtc`] ? "border-red-300" : "border-slate-200"
                }`}
              />
              {fieldErrors[`${prefix}.endAtUtc`] && (
                <span className="text-[11px] text-red-600">
                  {fieldErrors[`${prefix}.endAtUtc`]}
                </span>
              )}
            </label>
          </div>
          <p className="text-[11px] text-slate-500 -mt-2">
            Để trống bắt đầu = đã bắt đầu. Để trống kết thúc = không hết hạn.
          </p>

          <div>
            <ToggleSwitch
              checked={value.countdown}
              onChange={(countdown) => onChange({ ...value, countdown })}
              label="Đếm ngược"
              description={
                value.endAtUtc
                  ? "Hiện đồng hồ đếm ngược tới thời điểm kết thúc trên paywall."
                  : "Cần điền Kết thúc (UTC) trước khi bật đếm ngược."
              }
              disabled={disabled || !value.endAtUtc}
            />
            {fieldErrors[`${prefix}.countdown`] && (
              <span className="mt-1 block text-[11px] text-red-600">
                {fieldErrors[`${prefix}.countdown`]}
              </span>
            )}
          </div>

          <div className="pt-3 border-t border-slate-100">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-slate-700">Thống kê</p>
              <button
                type="button"
                onClick={fetchStats}
                disabled={stats.loading}
                className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-700 disabled:opacity-50"
              >
                <ArrowPathIcon className={`h-3.5 w-3.5 ${stats.loading ? "animate-spin" : ""}`} />
                {stats.data ? "Làm mới" : "Xem thống kê"}
              </button>
            </div>

            {stats.error ? (
              <div className="mt-2 flex items-center justify-between gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                <span className="flex items-center gap-1.5">
                  <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
                  {stats.error}
                </span>
                <button
                  type="button"
                  onClick={fetchStats}
                  className="flex-shrink-0 underline hover:no-underline"
                >
                  Thử lại
                </button>
              </div>
            ) : stats.data ? (
              <div className="mt-2 space-y-2">
                <p className="text-xs text-slate-600">
                  Tổng đơn: <strong>{stats.data.totalOrders}</strong>
                </p>
                {stats.data.byProduct.length === 0 ? (
                  <p className="text-xs text-slate-500">
                    Chưa có đơn hàng nào cho logic sale này.
                  </p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-xs border-collapse">
                      <thead>
                        <tr className="text-left text-slate-500 border-b border-slate-200">
                          <th scope="col" className="py-1.5 pr-3 font-medium">
                            Gói
                          </th>
                          <th scope="col" className="py-1.5 pr-3 font-medium">
                            Tiền tệ
                          </th>
                          <th scope="col" className="py-1.5 pr-3 font-medium text-right">
                            Đơn
                          </th>
                          <th scope="col" className="py-1.5 pr-3 font-medium text-right">
                            Doanh thu (net)
                          </th>
                        </tr>
                      </thead>
                      <tbody>
                        {stats.data.byProduct.map((row) => (
                          <tr
                            key={`${row.productId}-${row.currency ?? "none"}`}
                            className="border-b border-slate-100 last:border-0"
                          >
                            <td className="py-1.5 pr-3 font-mono text-[11px] text-slate-700">
                              {row.productId}
                            </td>
                            <td className="py-1.5 pr-3 text-slate-600">
                              {row.currency ?? "—"}
                            </td>
                            <td className="py-1.5 pr-3 text-right text-slate-700">
                              {row.orders}
                            </td>
                            <td className="py-1.5 pr-3 text-right text-slate-700">
                              {row.netRevenue.toLocaleString("vi-VN")}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
                <p className="text-[11px] text-slate-500">
                  Doanh thu hiển thị riêng theo từng tiền tệ — không cộng dồn
                  giữa các dòng khác tiền tệ.
                </p>
              </div>
            ) : (
              <p className="mt-2 text-xs text-slate-500">
                Chưa tải — bấm "Xem thống kê" để lấy số liệu mới nhất.
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

/**
 * Merchandising rules layered on top of the base sale strategy: each row is
 * independently scheduled and segment-targeted, and carries its own SKU list
 * that overrides the winning strategy's plan list while it applies. Order in
 * the list only matters as a tie-breaker for `priority` — reordering is the
 * only thing the up/down buttons do here (unlike Reviews, where list order IS
 * display order).
 */
const LogicSalesSection: React.FC<LogicSalesSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
  productsByPlatform,
  productsLoading,
  productsError,
  onRefreshProducts,
}) => {
  const [segments, setSegments] = useState<SegmentOption[]>([]);
  const [segmentsLoading, setSegmentsLoading] = useState(true);
  const [segmentsError, setSegmentsError] = useState<string | null>(null);

  const loadSegments = async () => {
    setSegmentsLoading(true);
    setSegmentsError(null);
    try {
      const res = await segmentService.list();
      setSegments(unwrap<SegmentOption[]>(res) ?? []);
    } catch (err: any) {
      setSegmentsError(
        err?.response?.data?.message ?? "Không tải được danh sách phân khúc"
      );
    } finally {
      setSegmentsLoading(false);
    }
  };

  useEffect(() => {
    loadSegments();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const updateRow = (index: number, next: LogicSaleDraft) => {
    onChange(value.map((row, i) => (i === index ? next : row)));
  };

  const removeRow = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const addRow = () => {
    if (value.length >= MAX_LOGIC_SALES) return;
    onChange([...value, emptyLogicSale()]);
  };

  const moveRow = (index: number, direction: -1 | 1) => {
    const target = index + direction;
    if (target < 0 || target >= value.length) return;
    const next = [...value];
    [next[index], next[target]] = [next[target], next[index]];
    onChange(next);
  };

  const atCap = value.length >= MAX_LOGIC_SALES;

  return (
    <SectionCard
      title="Logic sales"
      description="Ưu đãi có thời hạn, nhắm theo phân khúc, xếp chồng lên chiến lược sale mặc định/sự kiện sale ở trên. Ưu tiên cao hơn thắng khi nhiều mục cùng áp dụng; hoà thì giữ thứ tự danh sách bên dưới."
      icon={TagIcon}
    >
      {value.length === 0 ? (
        <p className="text-xs text-slate-500">
          Chưa có logic sale nào — paywall chỉ dùng chiến lược mặc định/sự kiện
          sale ở trên.
        </p>
      ) : (
        <div className="space-y-2">
          {value.map((row, index) => (
            <LogicSaleCard
              key={row._localId}
              index={index}
              count={value.length}
              value={row}
              onChange={(next) => updateRow(index, next)}
              onRemove={() => removeRow(index)}
              onMoveUp={() => moveRow(index, -1)}
              onMoveDown={() => moveRow(index, 1)}
              disabled={disabled}
              fieldErrors={fieldErrors}
              segments={segments}
              segmentsLoading={segmentsLoading}
              segmentsError={segmentsError}
              onRetrySegments={loadSegments}
              productsByPlatform={productsByPlatform}
              productsLoading={productsLoading}
              productsError={productsError}
              onRefreshProducts={onRefreshProducts}
            />
          ))}
        </div>
      )}

      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={addRow}
          disabled={disabled || atCap}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-dashed border-slate-300 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
        >
          <PlusIcon className="h-4 w-4" />
          Thêm logic sale
        </button>
        <span className="text-[11px] text-slate-500">
          {value.length}/{MAX_LOGIC_SALES}
          {atCap ? " — đã đạt giới hạn, xoá bớt để thêm mới" : ""}
        </span>
      </div>
      {fieldErrors.logicSales && (
        <p className="text-xs text-red-600 flex items-center gap-1.5">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          {fieldErrors.logicSales}
        </p>
      )}
    </SectionCard>
  );
};

export default LogicSalesSection;
