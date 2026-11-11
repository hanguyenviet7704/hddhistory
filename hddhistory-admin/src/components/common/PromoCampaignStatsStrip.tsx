import React from "react";

import { formatCtr, PromoCampaignStats } from "../../utils/promoCampaignForm";

interface Props {
  /** Undefined for a row added locally and never saved — it has no campaign yet. */
  stats?: PromoCampaignStats;
}

/**
 * Read-only performance strip shown on one Home banner slide / Home popup
 * campaign card: impressions, clicks, CTR and the content-hash campaign key,
 * so an operator can tell at a glance whether editing image/link forked a new
 * campaign (new key = stats restart at zero).
 */
const PromoCampaignStatsStrip: React.FC<Props> = ({ stats }) => (
  <div className="mt-4 rounded border border-gray-100 bg-gray-50 px-3 py-2 text-xs text-gray-600">
    {stats ? (
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span>
          Đã hiện: <strong>{stats.impressions}</strong> · Đã bấm:{" "}
          <strong>{stats.clicks}</strong> · CTR:{" "}
          <strong>{formatCtr(stats.ctr)}</strong>
        </span>
        <code className="rounded bg-gray-200 px-1.5 py-0.5 font-mono text-[11px] text-gray-700">
          {stats.campaignKey}
        </code>
      </div>
    ) : (
      <span>Chưa có số liệu — lưu để bắt đầu theo dõi.</span>
    )}
    <p className="mt-1 text-[11px] text-gray-400">
      Đổi ảnh hoặc link sẽ bắt đầu chiến dịch mới — mã và số liệu ở trên reset về 0.
    </p>
  </div>
);

export default PromoCampaignStatsStrip;
