import React from "react";
import { Button, CircularProgress, Drawer, IconButton } from "@mui/material";
import { XIcon } from "lucide-react";

import { ISegment, SegmentStats } from "../../types/interface/segment.interface";
import SegmentGrowthChart from "./SegmentGrowthChart";

interface Props {
  segment: ISegment | null;
  stats?: SegmentStats;
  loading: boolean;
  onRefresh: (id: string) => void;
  onClose: () => void;
}

/**
 * Per-segment stats detail: live count (recomputed on demand, never on open
 * automatically beyond the one fetch the page kicks off when this opens) and
 * the growth chart from nightly snapshots.
 */
const SegmentStatsDrawer: React.FC<Props> = ({ segment, stats, loading, onRefresh, onClose }) => {
  return (
    <Drawer anchor="right" open={Boolean(segment)} onClose={onClose}>
      <div className="flex h-full w-[640px] max-w-[94vw] flex-col">
        <header className="flex items-start justify-between border-b px-5 py-4">
          <div className="min-w-0">
            <h2 className="truncate text-base font-semibold">{segment?.name}</h2>
            <p className="text-xs text-gray-500">Thống kê phân khúc</p>
          </div>
          <IconButton size="small" onClick={onClose} aria-label="Đóng">
            <XIcon size={18} />
          </IconButton>
        </header>

        <div className="flex-1 overflow-y-auto px-5 py-4">
          <div className="mb-6 flex items-center justify-between rounded-lg bg-gray-50 p-4">
            <div>
              <p className="text-xs text-gray-500">Số user hiện tại</p>
              <p className="text-2xl font-semibold tabular-nums">
                {loading ? (
                  <span className="inline-flex items-center gap-2 text-base font-normal text-gray-400">
                    <CircularProgress size={16} /> Đang tính...
                  </span>
                ) : stats ? (
                  stats.count.toLocaleString("vi-VN")
                ) : (
                  <span className="text-base font-normal text-gray-400">Chưa đếm</span>
                )}
              </p>
            </div>
            <Button
              size="small"
              variant="outlined"
              disabled={loading || !segment}
              onClick={() => segment && onRefresh(segment._id)}
            >
              Đếm lại
            </Button>
          </div>

          <section>
            <h3 className="mb-2 text-sm font-semibold text-gray-700">
              Tăng trưởng (snapshot hằng đêm)
            </h3>
            {loading && !stats ? (
              <div className="flex justify-center py-10">
                <CircularProgress size={24} />
              </div>
            ) : (
              <SegmentGrowthChart history={stats?.history ?? []} />
            )}
          </section>

          <p className="mt-6 border-t pt-4 text-xs leading-relaxed text-gray-500">
            Số user hiện tại được tính trực tiếp mỗi lần bấm "Đếm lại", nên luôn
            đúng thời điểm xem — nhưng có thể chậm với phân khúc rộng. Biểu đồ
            tăng trưởng dựa trên snapshot chụp mỗi đêm; phân khúc mới tạo cần
            vài ngày để có dữ liệu.
          </p>
        </div>
      </div>
    </Drawer>
  );
};

export default SegmentStatsDrawer;
