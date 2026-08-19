import React, { useState } from "react";
import { ChartBarIcon } from "@heroicons/react/24/outline";
import { paywallConfigService } from "../../../services/paywallConfigService";
import SectionCard from "./SectionCard";

/** One arm of the run, as the readout endpoint returns it. */
interface ExperimentArm {
  variant: string;
  viewers: number;
  planClickers: number;
  upgradeClickers: number;
  buyers: number;
  orders: number;
  conversionRate: number;
  revenue: Array<{
    currency: string | null;
    paidRevenue: number;
    refundedRevenue: number;
    netRevenue: number;
  }>;
}

interface ExperimentStats {
  key: string;
  enabled: boolean;
  comparisonPercent: number;
  appEnv: string;
  from: string;
  to: string;
  arms: ExperimentArm[];
}

const ARM_LABELS: Record<string, string> = {
  benefits: "Danh sách lợi ích",
  comparison: "Bảng so sánh",
};

const unwrap = <T,>(payload: any): T => payload?.data ?? payload;

const percent = (value: number) => `${(value * 100).toFixed(2)}%`;

const formatMoney = (value: number) =>
  value.toLocaleString("vi-VN", { maximumFractionDigits: 2 });

/**
 * Kết quả A/B thân paywall — tải theo yêu cầu (một nút), không tự gọi khi mở
 * trang: đây là màn để SỬA config, và một truy vấn quét user_events mỗi lần mở
 * trang là cái giá phải trả cho thứ hầu hết lần vào không ai đọc.
 */
const BodyExperimentStatsSection: React.FC<{ experimentKey: string }> = ({
  experimentKey,
}) => {
  const [state, setState] = useState<{
    loading: boolean;
    error: string | null;
    data: ExperimentStats | null;
  }>({ loading: false, error: null, data: null });
  const [appEnv, setAppEnv] = useState("prod");

  const load = async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const res = await paywallConfigService.getBodyExperimentStats({ appEnv });
      setState({ loading: false, error: null, data: unwrap<ExperimentStats>(res) });
    } catch (err: any) {
      setState({
        loading: false,
        error: err?.response?.data?.message ?? "Không tải được kết quả",
        data: null,
      });
    }
  };

  return (
    <SectionCard
      title="Kết quả A/B thân paywall"
      description="Phễu đếm theo NGƯỜI từ event của app; đơn và doanh thu lấy từ purchase đã verify (không tính đơn huỷ/hoàn)."
      icon={ChartBarIcon}
      headerRight={
        <div className="flex items-center gap-2">
          <select
            value={appEnv}
            onChange={(e) => setAppEnv(e.target.value)}
            className="rounded-lg border border-slate-200 px-2 py-1 text-xs"
          >
            <option value="prod">prod</option>
            <option value="stg">stg</option>
            <option value="dev">dev</option>
          </select>
          <button
            type="button"
            onClick={load}
            disabled={state.loading || !experimentKey.trim()}
            className="rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-medium text-white disabled:bg-slate-300"
          >
            {state.loading ? "Đang tải…" : "Tải kết quả"}
          </button>
        </div>
      }
    >
      {!experimentKey.trim() && (
        <p className="text-xs text-slate-500">
          Chưa có đợt test nào trong config. Nhập mã đợt ở khối "A/B test thân
          paywall" rồi Đăng trước khi đọc kết quả.
        </p>
      )}

      {state.error && (
        <p className="text-xs text-red-600">{state.error}</p>
      )}

      {state.data && (
        <div className="flex flex-col gap-3">
          <p className="text-[11px] text-slate-500">
            Đợt <span className="font-medium">{state.data.key}</span> ·{" "}
            {state.data.enabled ? "đang chạy" : "đã tắt"} · chia{" "}
            {state.data.comparisonPercent}% vào Bảng so sánh ·{" "}
            {new Date(state.data.from).toLocaleDateString("vi-VN")} →{" "}
            {new Date(state.data.to).toLocaleDateString("vi-VN")}
          </p>

          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead className="text-slate-500">
                <tr className="text-left">
                  <th className="py-1.5 pr-3 font-medium">Nhánh</th>
                  <th className="py-1.5 pr-3 font-medium">Người thấy</th>
                  <th className="py-1.5 pr-3 font-medium">Bấm gói</th>
                  <th className="py-1.5 pr-3 font-medium">Bấm nâng cấp</th>
                  <th className="py-1.5 pr-3 font-medium">Người mua</th>
                  <th className="py-1.5 pr-3 font-medium">Đơn</th>
                  <th className="py-1.5 pr-3 font-medium">Chuyển đổi</th>
                </tr>
              </thead>
              <tbody className="text-slate-700">
                {state.data.arms.map((arm) => (
                  <tr key={arm.variant} className="border-t border-slate-100">
                    <td className="py-1.5 pr-3 font-medium">
                      {ARM_LABELS[arm.variant] ?? arm.variant}
                    </td>
                    <td className="py-1.5 pr-3">{arm.viewers}</td>
                    <td className="py-1.5 pr-3">{arm.planClickers}</td>
                    <td className="py-1.5 pr-3">{arm.upgradeClickers}</td>
                    <td className="py-1.5 pr-3">{arm.buyers}</td>
                    <td className="py-1.5 pr-3">{arm.orders}</td>
                    <td className="py-1.5 pr-3">{percent(arm.conversionRate)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Doanh thu tách theo tiền tệ, không cộng gộp: tổng của nhiều loại
              tiền không phải là số tiền của cái gì cả. */}
          <div className="flex flex-col gap-1">
            {state.data.arms.map((arm) =>
              arm.revenue.length === 0 ? null : (
                <div key={arm.variant} className="text-[11px] text-slate-600">
                  <span className="font-medium">
                    {ARM_LABELS[arm.variant] ?? arm.variant}:
                  </span>{" "}
                  {arm.revenue
                    .map(
                      (row) =>
                        `${formatMoney(row.netRevenue)} ${row.currency ?? "?"}` +
                        (row.refundedRevenue > 0
                          ? ` (đã trừ hoàn ${formatMoney(row.refundedRevenue)})`
                          : "")
                    )
                    .join(" · ")}
                </div>
              )
            )}
          </div>

          <p className="text-[11px] text-slate-500">
            Chênh lệch nhỏ giữa hai nhánh phần lớn là nhiễu. Đừng dừng test khi
            vừa thấy một bên nhỉnh hơn — với tỷ lệ chuyển đổi khoảng 3%, cần cỡ
            5.000 người mỗi nhánh mới phân biệt được 3% với 4%.
          </p>
        </div>
      )}
    </SectionCard>
  );
};

export default BodyExperimentStatsSection;
