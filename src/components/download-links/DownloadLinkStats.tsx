import React, { useCallback, useEffect, useState } from "react";
import {
  CircularProgress,
  Drawer,
  IconButton,
  TextField,
} from "@mui/material";
import { XIcon } from "lucide-react";

import { downloadLinkService } from "../../services/downloadLinkService";
import {
  ClickBucket,
  DownloadLinkStats as Stats,
  IDownloadLink,
} from "../../types/interface/download-link.interface";

interface Props {
  link: IDownloadLink | null;
  onClose: () => void;
}

const PLATFORM_LABEL: Record<string, string> = {
  ios: "iOS",
  android: "Android",
  desktop: "Máy tính",
  unknown: "Không rõ",
};

const SOURCE_LABEL: Record<string, string> = {
  facebook: "Facebook",
  instagram: "Instagram",
  threads: "Threads",
  tiktok: "TikTok",
  zalo: "Zalo",
  telegram: "Telegram",
  google: "Google",
  direct: "Trực tiếp / QR",
  other: "Nguồn khác",
  // Clicks recorded before source detection shipped.
  unknown: "Chưa phân loại",
};

const isoDate = (d: Date) => d.toISOString().slice(0, 10);

/** Bar list — a full chart library is not worth pulling in for this. */
const BucketBars: React.FC<{
  title: string;
  buckets: ClickBucket[];
  labelOf?: (key: string) => string;
  empty: string;
}> = ({ title, buckets, labelOf, empty }) => {
  const max = Math.max(1, ...buckets.map((b) => b.total));

  return (
    <section>
      <h3 className="mb-2 text-sm font-semibold text-gray-700">{title}</h3>
      {buckets.length === 0 ? (
        <p className="text-sm text-gray-400">{empty}</p>
      ) : (
        <ul className="flex flex-col gap-1.5">
          {buckets.map((b) => (
            <li key={b.key} className="flex items-center gap-2 text-sm">
              <span className="w-28 shrink-0 truncate text-gray-600">
                {labelOf ? labelOf(b.key) : b.key}
              </span>
              <span className="h-2 flex-1 overflow-hidden rounded bg-gray-100">
                <span
                  className="block h-full rounded bg-indigo-500"
                  style={{ width: `${(b.total / max) * 100}%` }}
                />
              </span>
              <span className="w-10 shrink-0 text-right tabular-nums text-gray-700">
                {b.total}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
};

const DownloadLinkStats: React.FC<Props> = ({ link, onClose }) => {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [from, setFrom] = useState(() =>
    isoDate(new Date(Date.now() - 29 * 86400000))
  );
  const [to, setTo] = useState(() => isoDate(new Date()));

  const load = useCallback(async () => {
    if (!link) return;
    setLoading(true);
    setError(null);
    try {
      const res = await downloadLinkService.getStats(link.id, { from, to });
      setStats(res.data ?? null);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được thống kê");
    } finally {
      setLoading(false);
    }
  }, [link, from, to]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <Drawer anchor="right" open={Boolean(link)} onClose={onClose}>
      <div className="flex h-full w-[440px] max-w-[92vw] flex-col">
        <header className="flex items-start justify-between border-b px-5 py-4">
          <div className="min-w-0">
            <h2 className="truncate text-base font-semibold">{link?.name}</h2>
            <p className="truncate text-xs text-gray-500">/r/{link?.slug}</p>
          </div>
          <IconButton size="small" onClick={onClose} aria-label="Đóng">
            <XIcon size={18} />
          </IconButton>
        </header>

        <div className="flex gap-3 border-b px-5 py-3">
          <TextField
            label="Từ"
            type="date"
            size="small"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
          <TextField
            label="Đến"
            type="date"
            size="small"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-4">
          {loading && (
            <div className="flex justify-center py-10">
              <CircularProgress size={24} />
            </div>
          )}

          {!loading && error && (
            <p className="text-sm text-red-600">{error}</p>
          )}

          {!loading && !error && stats && (
            <div className="flex flex-col gap-6">
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-lg bg-gray-50 p-3">
                  <p className="text-xs text-gray-500">Tổng click</p>
                  <p className="text-2xl font-semibold tabular-nums">
                    {stats.total}
                  </p>
                </div>
                <div className="rounded-lg bg-gray-50 p-3">
                  <p className="text-xs text-gray-500">Ước tính người khác nhau</p>
                  <p className="text-2xl font-semibold tabular-nums">
                    {/* Null, not 0: the server stores no ip hash when
                        DOWNLOAD_LINK_IP_SALT is unset, so a zero here would
                        read as "nobody clicked". */}
                    {stats.unique === null ? (
                      <span className="text-base font-normal text-gray-400">
                        chưa đo
                      </span>
                    ) : (
                      stats.unique
                    )}
                  </p>
                </div>
              </div>

              <BucketBars
                title="Theo ngày"
                buckets={stats.byDay}
                empty="Chưa có click nào trong khoảng này."
              />
              <BucketBars
                title="Theo nguồn chia sẻ"
                buckets={stats.bySource ?? []}
                labelOf={(k) => SOURCE_LABEL[k] ?? k}
                empty="Chưa có dữ liệu."
              />
              <BucketBars
                title="Theo nền tảng"
                buckets={stats.byPlatform}
                labelOf={(k) => PLATFORM_LABEL[k] ?? k}
                empty="Chưa có dữ liệu."
              />
              <BucketBars
                title="Theo quốc gia"
                buckets={stats.byCountry}
                empty="Chưa có dữ liệu."
              />

              <p className="border-t pt-3 text-xs leading-relaxed text-gray-500">
                Số này chỉ tính người <strong>chưa cài app</strong>. Ai đã có
                app thì hệ điều hành mở thẳng app, request không tới server nên
                không đếm được. Với link dùng để kéo người mới tải thì đó đúng
                là nhóm cần đo.
              </p>
            </div>
          )}
        </div>
      </div>
    </Drawer>
  );
};

export default DownloadLinkStats;
