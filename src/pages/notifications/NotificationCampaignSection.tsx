import { useCallback, useEffect, useMemo, useState } from "react";
import { Autocomplete, TextField } from "@mui/material";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  PaperAirplaneIcon,
  UsersIcon,
} from "@heroicons/react/24/outline";

import { notificationService } from "../../services/notificationService";
import { segmentService } from "../../services/segmentService";
import {
  NotificationCampaign,
  NotificationCampaignSendMode,
  NotificationCampaignSendRow,
  NotificationCampaignStatus,
  NotificationDeeplink,
} from "../../types/interface/notification.interface";
import { SegmentOption } from "../../types/interface/segment.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/** Locales the app ships. `en` is required — it is the server-side fallback. */
const LOCALES = ["vi", "en", "zh", "ja", "ko"] as const;

const STATUS_STYLES: Record<NotificationCampaignStatus, string> = {
  draft: "bg-slate-100 text-slate-600",
  queued: "bg-amber-100 text-amber-700",
  sending: "bg-sky-100 text-sky-700",
  sent: "bg-emerald-100 text-emerald-700",
  cancelled: "bg-slate-200 text-slate-500",
  failed: "bg-red-100 text-red-700",
};

const STATUS_LABELS: Record<NotificationCampaignStatus, string> = {
  draft: "Nháp",
  queued: "Đã xếp hàng",
  sending: "Đang gửi",
  sent: "Đã gửi xong",
  cancelled: "Đã huỷ",
  failed: "Lỗi",
};

const DEEPLINK_LABELS: Record<string, string> = {
  home: "home — Trang chủ",
  resume_lesson: "resume_lesson — Roadmap khoá đang học dở",
  habit: "habit — Thói quen",
  library: "library — Thư viện",
  explore: "explore — Khám phá",
};

const emptyCopies = () =>
  LOCALES.map((locale) => ({ locale, title: "", body: "" }));

const formatDateTime = (value?: string | null) => {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? "—"
    : date.toLocaleString("vi-VN", { hour12: false });
};

const todayInput = () => {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60_000)
    .toISOString()
    .slice(0, 10);
};

/**
 * Manual campaigns: compose a push, aim it at segments, fire or schedule it.
 *
 * Unlike the five scheduled types, these do NOT count toward the 4/day cap — a
 * deliberate product decision, so the warning below says so out loud rather than
 * letting an operator discover it by surprising a reader.
 */
export default function NotificationCampaignSection() {
  const { showError, showSuccess } = useNotification();

  const [campaigns, setCampaigns] = useState<NotificationCampaign[]>([]);
  const [segments, setSegments] = useState<SegmentOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);

  // Composer state
  const [name, setName] = useState("");
  const [deeplink, setDeeplink] = useState<NotificationDeeplink>(
    "home" as NotificationDeeplink,
  );
  const [segmentIds, setSegmentIds] = useState<string[]>([]);
  const [sendMode, setSendMode] = useState<NotificationCampaignSendMode>("now");
  const [localHour, setLocalHour] = useState("20");
  const [localMinute, setLocalMinute] = useState("0");
  const [scheduledDate, setScheduledDate] = useState(todayInput());
  const [copies, setCopies] = useState(emptyCopies);
  const [reach, setReach] = useState<number | null>(null);
  const [creating, setCreating] = useState(false);

  const [openSends, setOpenSends] = useState<string | null>(null);
  const [sends, setSends] = useState<NotificationCampaignSendRow[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCampaigns(await notificationService.listCampaigns());
    } catch (error: any) {
      showError(
        error?.response?.data?.message || "Không tải được danh sách campaign",
      );
    } finally {
      setLoading(false);
    }
    // showError is recreated each render by the hook.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    load();
    (async () => {
      try {
        const res = await segmentService.list();
        setSegments(
          (res.data ?? []).map((s: { _id: string; name: string }) => ({
            _id: s._id,
            name: s.name,
          })),
        );
      } catch {
        // Targeting is optional; an empty picker still lets you send to everyone.
      }
    })();
  }, [load]);

  // Reach is re-asked whenever the targeting changes: an operator should never
  // press send without the number in front of them.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await notificationService.previewCampaign(segmentIds);
        if (!cancelled) setReach(res.reach);
      } catch {
        if (!cancelled) setReach(null);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [segmentIds]);

  const filledCopies = useMemo(
    () => copies.filter((copy) => copy.title.trim() && copy.body.trim()),
    [copies],
  );
  const hasEnglish = filledCopies.some((copy) => copy.locale === "en");

  const create = async (queueNow: boolean) => {
    if (!name.trim()) return showError("Cần đặt tên campaign");
    if (!hasEnglish) {
      return showError(
        "Cần có bản tiếng Anh — đây là bản dự phòng cho mọi ngôn ngữ khác",
      );
    }
    setCreating(true);
    try {
      const created = await notificationService.createCampaign({
        name,
        copies: filledCopies,
        deeplink,
        segmentIds,
        sendMode,
        localHour: Number(localHour),
        localMinute: Number(localMinute),
        ...(sendMode === "local_hour" ? { scheduledDate } : {}),
      });
      if (queueNow) await notificationService.queueCampaign(created._id);
      showSuccess(queueNow ? "Đã xếp hàng gửi" : "Đã lưu nháp");
      setName("");
      setCopies(emptyCopies());
      setSegmentIds([]);
      await load();
    } catch (error: any) {
      showError(error?.response?.data?.message || "Không tạo được campaign");
    } finally {
      setCreating(false);
    }
  };

  const act = async (
    id: string,
    action: "queue" | "cancel",
  ) => {
    setBusyId(id);
    try {
      if (action === "queue") await notificationService.queueCampaign(id);
      else await notificationService.cancelCampaign(id);
      showSuccess(action === "queue" ? "Đã xếp hàng gửi" : "Đã huỷ");
      await load();
    } catch (error: any) {
      showError(error?.response?.data?.message || "Không thực hiện được");
    } finally {
      setBusyId(null);
    }
  };

  const toggleSends = async (id: string) => {
    if (openSends === id) {
      setOpenSends(null);
      return;
    }
    setOpenSends(id);
    try {
      const res = await notificationService.campaignSends(id, 1, 20);
      setSends(res.items ?? []);
    } catch {
      setSends([]);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
        <ExclamationTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
        <span>
          Campaign thủ công <b>không</b> tính vào trần 4 noti/ngày/user, nên ngày
          nào bắn campaign thì user có thể nhận nhiều hơn 4. Đã gửi rồi thì{" "}
          <b>không thu hồi được</b> — huỷ chỉ chặn phần chưa gửi.
        </span>
      </div>

      {/* Composer */}
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-base font-semibold text-slate-900">
          Tạo campaign mới
        </h3>

        <div className="grid gap-4 md:grid-cols-2">
          <TextField
            size="small"
            label="Tên campaign (chỉ admin thấy)"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <TextField
            size="small"
            select
            SelectProps={{ native: true }}
            label="Deep link"
            value={deeplink}
            onChange={(e) => setDeeplink(e.target.value as NotificationDeeplink)}
          >
            {Object.keys(DEEPLINK_LABELS).map((value) => (
              <option key={value} value={value}>
                {DEEPLINK_LABELS[value]}
              </option>
            ))}
          </TextField>
        </div>

        <div className="mt-4">
          <Autocomplete
            multiple
            size="small"
            options={segments}
            value={segmentIds.map(
              (id) => segments.find((s) => s._id === id) ?? { _id: id, name: id },
            )}
            onChange={(_, selected) =>
              setSegmentIds(selected.map((s) => s._id))
            }
            isOptionEqualToValue={(a, b) => a._id === b._id}
            getOptionLabel={(s) => s.name}
            renderInput={(params) => (
              <TextField
                {...params}
                label="Gửi cho các phân khúc user"
                helperText="Bỏ trống = gửi cho MỌI user còn nhận được push. Khớp BẤT KỲ phân khúc nào được chọn."
              />
            )}
          />
        </div>

        <div className="mt-3 flex items-center gap-2 rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-700">
          <UsersIcon className="h-4 w-4 text-slate-400" />
          {reach === null ? (
            "Đang tính số người nhận…"
          ) : (
            <span>
              Sẽ gửi tới <b>{reach.toLocaleString("vi-VN")}</b> người{" "}
              <span className="text-slate-400">
                (đã trừ người không còn push token)
              </span>
            </span>
          )}
        </div>

        <div className="mt-4 grid gap-4 md:grid-cols-4">
          <TextField
            size="small"
            select
            SelectProps={{ native: true }}
            label="Thời điểm gửi"
            value={sendMode}
            onChange={(e) =>
              setSendMode(e.target.value as NotificationCampaignSendMode)
            }
          >
            <option value="now">Gửi ngay</option>
            <option value="local_hour">Theo giờ địa phương user</option>
          </TextField>
          {sendMode === "local_hour" ? (
            <>
              <TextField
                size="small"
                label="Giờ (giờ user)"
                type="number"
                inputProps={{ min: 0, max: 23 }}
                value={localHour}
                onChange={(e) => setLocalHour(e.target.value)}
              />
              <TextField
                size="small"
                label="Phút"
                type="number"
                inputProps={{ min: 0, max: 59 }}
                value={localMinute}
                onChange={(e) => setLocalMinute(e.target.value)}
              />
              <TextField
                size="small"
                label="Ngày gửi"
                type="date"
                InputLabelProps={{ shrink: true }}
                value={scheduledDate}
                onChange={(e) => setScheduledDate(e.target.value)}
                helperText="Ngày theo lịch của user"
              />
            </>
          ) : null}
        </div>

        <div className="mt-5 space-y-3">
          {copies.map((copy, index) => (
            <div key={copy.locale} className="grid gap-2 md:grid-cols-[60px_1fr_1fr]">
              <div className="flex items-center text-xs font-semibold uppercase text-slate-500">
                {copy.locale}
                {copy.locale === "en" ? (
                  <span className="ml-1 text-red-500">*</span>
                ) : null}
              </div>
              <TextField
                size="small"
                label="Tiêu đề"
                value={copy.title}
                onChange={(e) =>
                  setCopies((prev) =>
                    prev.map((item, i) =>
                      i === index ? { ...item, title: e.target.value } : item,
                    ),
                  )
                }
              />
              <TextField
                size="small"
                label="Nội dung"
                value={copy.body}
                onChange={(e) =>
                  setCopies((prev) =>
                    prev.map((item, i) =>
                      i === index ? { ...item, body: e.target.value } : item,
                    ),
                  )
                }
              />
            </div>
          ))}
          <p className="text-xs text-slate-500">
            Ngôn ngữ để trống sẽ dùng bản tiếng Anh. Bản tiếng Anh là bắt buộc.
          </p>
        </div>

        <div className="mt-5 flex flex-wrap items-center gap-3">
          <button
            type="button"
            disabled={creating}
            onClick={() => create(false)}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            Lưu nháp
          </button>
          <button
            type="button"
            disabled={creating}
            onClick={() => create(true)}
            className="inline-flex items-center gap-2 rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-50"
          >
            <PaperAirplaneIcon className="h-4 w-4" />
            {sendMode === "now" ? "Gửi ngay" : "Xếp hàng theo giờ user"}
          </button>
        </div>
      </section>

      {/* List */}
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-base font-semibold text-slate-900">
            Campaign đã tạo
          </h3>
          <button
            type="button"
            onClick={load}
            disabled={loading}
            className="flex items-center gap-2 rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            <ArrowPathIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            Làm mới
          </button>
        </div>

        {campaigns.length === 0 ? (
          <p className="text-sm text-slate-500">
            {loading ? "Đang tải…" : "Chưa có campaign nào."}
          </p>
        ) : (
          <div className="space-y-3">
            {campaigns.map((campaign) => (
              <article
                key={campaign._id}
                className="rounded-xl border border-slate-100 bg-slate-50/60 p-4"
              >
                <div className="flex flex-wrap items-center gap-3">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                      STATUS_STYLES[campaign.status]
                    }`}
                  >
                    {STATUS_LABELS[campaign.status]}
                  </span>
                  <b className="text-sm text-slate-900">{campaign.name}</b>
                  <span className="text-xs text-slate-500">
                    {campaign.sendMode === "now"
                      ? "Gửi ngay"
                      : `${String(campaign.localHour).padStart(2, "0")}:${String(
                          campaign.localMinute ?? 0,
                        ).padStart(2, "0")} giờ user · ${campaign.scheduledDate ?? "—"}`}
                  </span>
                  <span className="text-xs text-slate-500">
                    {(campaign.segmentIds ?? []).length === 0
                      ? "Mọi user"
                      : `${campaign.segmentIds!.length} phân khúc`}
                  </span>
                  <span className="ml-auto text-xs text-slate-600">
                    gửi <b className="text-slate-900">{campaign.sentCount}</b> ·
                    lỗi <b>{campaign.failedCount}</b> · bỏ qua{" "}
                    <b>{campaign.skippedCount}</b>
                  </span>
                </div>

                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                  <span>Tạo: {formatDateTime(campaign.createdAt)}</span>
                  {campaign.startedAt ? (
                    <span>Bắt đầu: {formatDateTime(campaign.startedAt)}</span>
                  ) : null}
                  {campaign.finishedAt ? (
                    <span>Xong: {formatDateTime(campaign.finishedAt)}</span>
                  ) : null}
                  {campaign.lastError ? (
                    <span className="text-red-600">
                      Lỗi gần nhất: {campaign.lastError}
                    </span>
                  ) : null}
                </div>

                <div className="mt-3 flex flex-wrap gap-2">
                  {campaign.status === "draft" ? (
                    <button
                      type="button"
                      disabled={busyId === campaign._id}
                      onClick={() => act(campaign._id, "queue")}
                      className="rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-teal-700 disabled:opacity-50"
                    >
                      Gửi
                    </button>
                  ) : null}
                  {campaign.status === "queued" ||
                  campaign.status === "sending" ? (
                    <button
                      type="button"
                      disabled={busyId === campaign._id}
                      onClick={() => act(campaign._id, "cancel")}
                      className="rounded-lg border border-red-300 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50"
                    >
                      Huỷ phần chưa gửi
                    </button>
                  ) : null}
                  <button
                    type="button"
                    onClick={() => toggleSends(campaign._id)}
                    className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-white"
                  >
                    {openSends === campaign._id ? "Ẩn log gửi" : "Xem log gửi"}
                  </button>
                </div>

                {openSends === campaign._id ? (
                  <div className="mt-3 overflow-x-auto rounded-lg border border-slate-200 bg-white">
                    <table className="w-full text-left text-xs">
                      <thead className="text-slate-400">
                        <tr>
                          <th className="px-3 py-2">User</th>
                          <th className="px-3 py-2">Trạng thái</th>
                          <th className="px-3 py-2">Locale</th>
                          <th className="px-3 py-2">Thiết bị</th>
                          <th className="px-3 py-2">Thời điểm</th>
                          <th className="px-3 py-2">Lý do</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {sends.length === 0 ? (
                          <tr>
                            <td className="px-3 py-3 text-slate-500" colSpan={6}>
                              Chưa có bản ghi gửi nào.
                            </td>
                          </tr>
                        ) : (
                          sends.map((row, index) => (
                            <tr key={`${row.userId}-${index}`}>
                              <td className="px-3 py-2 font-mono">{row.userId}</td>
                              <td className="px-3 py-2">{row.status}</td>
                              <td className="px-3 py-2">{row.locale ?? "—"}</td>
                              <td className="px-3 py-2">
                                {row.successCount}/{row.deviceCount}
                              </td>
                              <td className="px-3 py-2">
                                {formatDateTime(row.sentAt)}
                              </td>
                              <td className="px-3 py-2 text-slate-500">
                                {row.reason ?? "—"}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
