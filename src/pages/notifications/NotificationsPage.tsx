import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  BellAlertIcon,
  PaperAirplaneIcon,
} from "@heroicons/react/24/outline";

import ToggleSwitch from "../../components/paywall-config/ToggleSwitch";
import {
  notificationService,
  NotificationLogQuery,
} from "../../services/notificationService";
import {
  NotificationCopy,
  NotificationLog,
  NotificationLogStatus,
  NotificationSummary,
  NotificationTemplate,
  NotificationType,
} from "../../types/interface/notification.interface";

const TYPE_LABELS: Record<NotificationType, string> = {
  daily_remind: "1. Daily remind",
  progress_finish: "2. Progress finish",
  habit_tracking: "3. Habit tracking",
};

const STATUS_LABELS: Record<NotificationLogStatus, string> = {
  sent: "Đã gửi",
  failed: "Thất bại",
  skipped: "Bỏ qua",
};

const STATUS_CLASSES: Record<NotificationLogStatus, string> = {
  sent: "bg-emerald-50 text-emerald-700 border-emerald-200",
  failed: "bg-red-50 text-red-700 border-red-200",
  skipped: "bg-slate-50 text-slate-600 border-slate-200",
};

/** The eight the sheet ships. Order matters only for display. */
const LOCALES = ["vi", "en", "ko", "zh", "ja", "id", "ms", "fil"];

const toCopyList = (
  copies: Record<string, { title: string; body: string }> | undefined
): NotificationCopy[] =>
  LOCALES.map((locale) => ({
    locale,
    title: copies?.[locale]?.title ?? "",
    body: copies?.[locale]?.body ?? "",
  }));

const NotificationsPage: React.FC = () => {
  const [tab, setTab] = useState<"content" | "monitor">("content");

  return (
    <div className="p-6 space-y-6">
      <header className="flex items-center gap-3">
        <span className="rounded-xl bg-teal-50 p-2 text-teal-600">
          <BellAlertIcon className="h-6 w-6" />
        </span>
        <div>
          <h1 className="text-xl font-semibold text-slate-900">Thông báo định kỳ</h1>
          <p className="text-sm text-slate-500">
            Nội dung + giờ gửi của 3 loại noti, và log đã gửi. Giờ là giờ địa
            phương của từng user; tối đa 2 noti/ngày/user.
          </p>
        </div>
      </header>

      <nav className="flex gap-2 border-b border-slate-200">
        {(
          [
            ["content", "Nội dung & lịch"],
            ["monitor", "Theo dõi gửi"],
          ] as const
        ).map(([key, label]) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`-mb-px border-b-2 px-4 py-2 text-sm font-medium ${
              tab === key
                ? "border-teal-600 text-teal-700"
                : "border-transparent text-slate-500 hover:text-slate-700"
            }`}
          >
            {label}
          </button>
        ))}
      </nav>

      {tab === "content" ? <ContentSection /> : <MonitorSection />}
    </div>
  );
};

// ---------------------------------------------------------------------------
// Nội dung & lịch
// ---------------------------------------------------------------------------

const ContentSection: React.FC = () => {
  const [templates, setTemplates] = useState<NotificationTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [savingType, setSavingType] = useState<NotificationType | null>(null);
  const [message, setMessage] = useState<string>("");
  const [drafts, setDrafts] = useState<
    Record<string, { localHour: string; copies: NotificationCopy[] }>
  >({});

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const list = await notificationService.getTemplates();
      setTemplates(list);
      setDrafts(
        Object.fromEntries(
          list.map((template) => [
            template.type,
            {
              localHour: String(template.localHour ?? 0),
              copies: toCopyList(template.copies),
            },
          ])
        )
      );
    } catch (error: any) {
      setMessage(error?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const save = async (template: NotificationTemplate, enabled?: boolean) => {
    const draft = drafts[template.type];
    setSavingType(template.type);
    setMessage("");
    try {
      await notificationService.updateTemplate(template.type, {
        enabled: enabled ?? template.enabled,
        localHour: Number(draft?.localHour ?? template.localHour),
        // Locales left completely empty are dropped rather than saved as blanks —
        // an empty title would push a notification with no text.
        copies: (draft?.copies ?? []).filter(
          (copy) => copy.title.trim() !== "" || copy.body.trim() !== ""
        ),
      });
      setMessage(`Đã lưu ${TYPE_LABELS[template.type]}`);
      await load();
    } catch (error: any) {
      setMessage(error?.message ?? "Lưu thất bại");
    } finally {
      setSavingType(null);
    }
  };

  const exportFile = async () => {
    const file = await notificationService.exportTemplates();
    const blob = new Blob([JSON.stringify(file, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `meup-notifications-${new Date()
      .toISOString()
      .slice(0, 10)}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const importFile = async (file: File) => {
    setMessage("");
    try {
      const parsed = JSON.parse(await file.text());
      const result = await notificationService.importTemplates(parsed);
      setMessage(`Đã import: ${result.imported.join(", ")}`);
      await load();
    } catch (error: any) {
      setMessage(error?.message ?? "File không đúng định dạng export");
    }
  };

  if (loading) return <p className="text-sm text-slate-500">Đang tải…</p>;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <button
          onClick={exportFile}
          className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm hover:bg-slate-50"
        >
          <ArrowDownTrayIcon className="h-4 w-4" /> Export JSON
        </button>
        <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm hover:bg-slate-50">
          <ArrowUpTrayIcon className="h-4 w-4" /> Import JSON
          <input
            type="file"
            accept="application/json"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) void importFile(file);
              e.target.value = "";
            }}
          />
        </label>
        <TestSendBox />
        {message && (
          <span className="text-xs text-slate-600">{message}</span>
        )}
      </div>

      {templates.map((template) => {
        const draft = drafts[template.type];
        return (
          <section
            key={template.type}
            className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="text-base font-semibold text-slate-900">
                  {TYPE_LABELS[template.type]}
                </h2>
                <p className="text-xs text-slate-500">
                  Deep link: <code>{template.deeplink}</code>
                </p>
              </div>
              <div className="flex items-center gap-4">
                <label className="flex items-center gap-2 text-xs text-slate-700">
                  <span className="font-medium">Giờ gửi (giờ user)</span>
                  <input
                    type="number"
                    min={0}
                    max={23}
                    value={draft?.localHour ?? ""}
                    onChange={(e) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [template.type]: {
                          ...prev[template.type],
                          localHour: e.target.value,
                        },
                      }))
                    }
                    className="w-16 rounded-lg border border-slate-200 px-2 py-1.5 text-sm"
                  />
                </label>
                <ToggleSwitch
                  checked={template.enabled}
                  onChange={(checked) => void save(template, checked)}
                  label={template.enabled ? "Đang bật" : "Đang tắt"}
                  disabled={savingType === template.type}
                />
              </div>
            </div>

            <div className="mt-4 space-y-3">
              {(draft?.copies ?? []).map((copy, index) => (
                <div
                  key={copy.locale}
                  className="grid grid-cols-1 gap-2 rounded-xl bg-slate-50 p-3 md:grid-cols-[64px_1fr_1fr]"
                >
                  <span className="self-center text-xs font-semibold uppercase text-slate-500">
                    {copy.locale}
                  </span>
                  <input
                    placeholder="Title"
                    value={copy.title}
                    onChange={(e) =>
                      setDrafts((prev) => {
                        const copies = [...prev[template.type].copies];
                        copies[index] = { ...copies[index], title: e.target.value };
                        return {
                          ...prev,
                          [template.type]: { ...prev[template.type], copies },
                        };
                      })
                    }
                    className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
                  />
                  <input
                    placeholder="Body — dùng {user_name}, {lesson_name}, {quote}"
                    value={copy.body}
                    onChange={(e) =>
                      setDrafts((prev) => {
                        const copies = [...prev[template.type].copies];
                        copies[index] = { ...copies[index], body: e.target.value };
                        return {
                          ...prev,
                          [template.type]: { ...prev[template.type], copies },
                        };
                      })
                    }
                    className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
                  />
                </div>
              ))}
            </div>

            <div className="mt-4 flex items-center gap-3">
              <button
                onClick={() => void save(template)}
                disabled={savingType === template.type}
                className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700 disabled:opacity-60"
              >
                {savingType === template.type ? "Đang lưu…" : "Lưu thay đổi"}
              </button>
              <span className="text-xs text-slate-500">
                id/ms/fil chưa có trong app — user thuộc các locale đó nhận bản
                tiếng Anh.
              </span>
            </div>
          </section>
        );
      })}
    </div>
  );
};

const TestSendBox: React.FC = () => {
  const [type, setType] = useState<NotificationType>("progress_finish");
  const [userId, setUserId] = useState("");
  const [result, setResult] = useState("");

  const send = async () => {
    if (!userId.trim()) return;
    setResult("Đang gửi…");
    try {
      const response = await notificationService.sendTest(type, userId.trim());
      setResult(
        response.sent
          ? `Đã gửi${response.conditionMet === false ? " (điều kiện thực tế KHÔNG thỏa — chỉ để xem nội dung)" : ""}`
          : `Không gửi: ${response.reason ?? "không rõ"}`
      );
    } catch (error: any) {
      setResult(error?.message ?? "Lỗi gửi test");
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-2">
      <select
        value={type}
        onChange={(e) => setType(e.target.value as NotificationType)}
        className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
      >
        {Object.entries(TYPE_LABELS).map(([value, label]) => (
          <option key={value} value={value}>
            {label}
          </option>
        ))}
      </select>
      <input
        placeholder="userId để test"
        value={userId}
        onChange={(e) => setUserId(e.target.value)}
        className="w-48 rounded-lg border border-slate-200 px-3 py-2 text-sm"
      />
      <button
        onClick={() => void send()}
        className="inline-flex items-center gap-2 rounded-lg border border-teal-200 bg-teal-50 px-3 py-2 text-sm text-teal-700 hover:bg-teal-100"
      >
        <PaperAirplaneIcon className="h-4 w-4" /> Gửi thử
      </button>
      {result && <span className="text-xs text-slate-600">{result}</span>}
    </div>
  );
};

// ---------------------------------------------------------------------------
// Theo dõi gửi
// ---------------------------------------------------------------------------

const MonitorSection: React.FC = () => {
  const [query, setQuery] = useState<NotificationLogQuery>({ page: 1, take: 20 });
  const [logs, setLogs] = useState<NotificationLog[]>([]);
  const [totalPages, setTotalPages] = useState(1);
  const [summary, setSummary] = useState<NotificationSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const [page, stats] = await Promise.all([
        notificationService.getLogs(query),
        notificationService.getSummary({
          fromDate: query.fromDate,
          toDate: query.toDate,
        }),
      ]);
      setLogs(page.items ?? []);
      setTotalPages(page.totalPages ?? 1);
      setSummary(stats);
    } catch (err: any) {
      setError(err?.message ?? "Không tải được log");
    } finally {
      setLoading(false);
    }
  }, [query]);

  useEffect(() => {
    void load();
  }, [load]);

  const summaryRows = useMemo(() => {
    if (!summary) return [];
    return Object.entries(summary.byType).map(([type, counts]) => ({
      type: type as NotificationType,
      counts,
    }));
  }, [summary]);

  return (
    <div className="space-y-4">
      {summary && (
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          {summaryRows.map(({ type, counts }) => (
            <div
              key={type}
              className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"
            >
              <p className="text-sm font-semibold text-slate-900">
                {TYPE_LABELS[type] ?? type}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {summary.fromDate} → {summary.toDate}
              </p>
              <div className="mt-3 flex gap-4 text-sm">
                <span className="text-emerald-700">
                  {counts.sent ?? 0} đã gửi
                </span>
                <span className="text-red-600">{counts.failed ?? 0} lỗi</span>
                <span className="text-slate-500">
                  {counts.skipped ?? 0} bỏ qua
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-slate-200 bg-white p-4">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Loại</span>
          <select
            value={query.type ?? ""}
            onChange={(e) =>
              setQuery((prev) => ({
                ...prev,
                page: 1,
                type: (e.target.value || undefined) as NotificationType | undefined,
              }))
            }
            className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
          >
            <option value="">Tất cả</option>
            {Object.entries(TYPE_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Trạng thái</span>
          <select
            value={query.status ?? ""}
            onChange={(e) =>
              setQuery((prev) => ({
                ...prev,
                page: 1,
                status: (e.target.value || undefined) as
                  | NotificationLogStatus
                  | undefined,
              }))
            }
            className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
          >
            <option value="">Tất cả</option>
            {Object.entries(STATUS_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Từ ngày (giờ user)</span>
          <input
            type="date"
            value={query.fromDate ?? ""}
            onChange={(e) =>
              setQuery((prev) => ({
                ...prev,
                page: 1,
                fromDate: e.target.value || undefined,
              }))
            }
            className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Đến ngày</span>
          <input
            type="date"
            value={query.toDate ?? ""}
            onChange={(e) =>
              setQuery((prev) => ({
                ...prev,
                page: 1,
                toDate: e.target.value || undefined,
              }))
            }
            className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
          />
        </label>

        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">User id</span>
          <input
            value={query.userId ?? ""}
            onChange={(e) =>
              setQuery((prev) => ({
                ...prev,
                page: 1,
                userId: e.target.value || undefined,
              }))
            }
            className="w-56 rounded-lg border border-slate-200 px-3 py-2 text-sm"
          />
        </label>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}

      <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-50 text-xs uppercase text-slate-500">
            <tr>
              <th className="px-4 py-3 text-left">Ngày (user)</th>
              <th className="px-4 py-3 text-left">Loại</th>
              <th className="px-4 py-3 text-left">Trạng thái</th>
              <th className="px-4 py-3 text-left">User</th>
              <th className="px-4 py-3 text-left">Nội dung đã gửi</th>
              <th className="px-4 py-3 text-left">Thiết bị</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-slate-500">
                  Đang tải…
                </td>
              </tr>
            )}
            {!loading && logs.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-slate-500">
                  Chưa có log nào khớp bộ lọc.
                </td>
              </tr>
            )}
            {!loading &&
              logs.map((log) => (
                <tr key={log._id} className="border-t border-slate-100">
                  <td className="px-4 py-3 align-top">
                    <div className="font-medium text-slate-900">{log.localDate}</div>
                    <div className="text-xs text-slate-500">
                      {new Date(log.sentAt).toLocaleTimeString()}
                    </div>
                  </td>
                  <td className="px-4 py-3 align-top">
                    {TYPE_LABELS[log.type] ?? log.type}
                  </td>
                  <td className="px-4 py-3 align-top">
                    <span
                      className={`rounded-full border px-2 py-0.5 text-xs ${
                        STATUS_CLASSES[log.status]
                      }`}
                    >
                      {STATUS_LABELS[log.status]}
                    </span>
                    {log.reason && (
                      <div className="mt-1 text-xs text-slate-500">{log.reason}</div>
                    )}
                  </td>
                  <td className="px-4 py-3 align-top">
                    <code className="text-xs">{log.userId}</code>
                    {log.locale && (
                      <div className="text-xs text-slate-500">{log.locale}</div>
                    )}
                  </td>
                  <td className="px-4 py-3 align-top">
                    <div className="max-w-md truncate font-medium text-slate-800">
                      {log.title || "—"}
                    </div>
                    <div className="max-w-md truncate text-xs text-slate-500">
                      {log.body}
                    </div>
                  </td>
                  <td className="px-4 py-3 align-top text-xs text-slate-600">
                    {log.successCount ?? 0}/{log.deviceCount ?? 0} thành công
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-end gap-2 text-sm">
        <button
          disabled={(query.page ?? 1) <= 1}
          onClick={() =>
            setQuery((prev) => ({ ...prev, page: (prev.page ?? 1) - 1 }))
          }
          className="rounded-lg border border-slate-200 px-3 py-1.5 disabled:opacity-50"
        >
          Trước
        </button>
        <span className="text-slate-600">
          {query.page ?? 1} / {totalPages}
        </span>
        <button
          disabled={(query.page ?? 1) >= totalPages}
          onClick={() =>
            setQuery((prev) => ({ ...prev, page: (prev.page ?? 1) + 1 }))
          }
          className="rounded-lg border border-slate-200 px-3 py-1.5 disabled:opacity-50"
        >
          Sau
        </button>
      </div>
    </div>
  );
};

export default NotificationsPage;
