import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  BellAlertIcon,
  ChevronDownIcon,
  ChevronRightIcon,
  PaperAirplaneIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";

import { Autocomplete, TextField } from "@mui/material";

import NotificationCampaignSection from "./NotificationCampaignSection";
import NotificationImageField from "../../components/notification/NotificationImageField";
import ToggleSwitch from "../../components/paywall-config/ToggleSwitch";
import { segmentService } from "../../services/segmentService";
import { SegmentOption } from "../../types/interface/segment.interface";
import {
  notificationService,
  NotificationLogQuery,
} from "../../services/notificationService";
import {
  NotificationCopy,
  NotificationDeeplink,
  NotificationLog,
  NotificationLogStatus,
  NotificationSummary,
  NotificationTemplate,
  NotificationType,
} from "../../types/interface/notification.interface";

const TYPE_LABELS: Record<NotificationType, string> = {
  daily_remind: "1. Daily remind",
  progress_finish: "2a. Progress finish (còn bài học dở)",
  progress_start: "2b. Progress start (không còn bài dở)",
  habit_tracking: "3. Habit tracking",
  new_course: "4. Khoá học mới",
  weekly_recap_ready: "6a. Weekly recap (thứ 2, nhắc lần 1)",
  weekly_recap_reminder: "6b. Weekly recap (thứ 2, nhắc lần 2)",
  coach_plan_reminder: "7. Nhắc hẹn AI Coach",
  onboarding_study_reminder: "8. Nhắc học theo giờ đã chọn (onboarding)",
};

/**
 * The pair at 11:45 is one row in the sheet split by a condition, so the cards
 * say which reader each one reaches. Nobody receives both on the same day.
 */
const TYPE_HINTS: Partial<Record<NotificationType, string>> = {
  progress_finish: "Gửi cho user còn ít nhất 1 bài học dang dở.",
  progress_start:
    "Gửi cho user chưa bắt đầu bài nào, hoặc đã hoàn thành hết. Cùng khung giờ với 2a và loại trừ lẫn nhau.",
  weekly_recap_ready:
    "Chỉ gửi vào thứ 2 (theo giờ địa phương). Gửi cho tất cả user — recap tự sinh khi user mở.",
  weekly_recap_reminder:
    "Chỉ gửi vào thứ 2. Chỉ gửi cho user CHƯA MỞ recap tuần này (viewedAt còn trống; bấm \"Để sau\" vẫn tính là chưa mở).",
  coach_plan_reminder:
    "Giờ gửi do CHÍNH USER chọn lúc chốt nhắc hẹn, nên ô \"giờ\" ở đây không có tác dụng. Nội dung là chữ của user điền vào khung câu bên dưới. Tối đa 1 lần/ngày; nhiều nhắc hẹn trùng giờ thì gộp thành một.",
  onboarding_study_reminder:
    "Giờ gửi do USER chọn ở màn Nhắc nhở của onboarding (bước 15 phút), nên ô \"giờ\" ở đây không có tác dụng. Chỉ gửi cho user có đặt giờ; tối đa 1 lần/ngày và chịu trần 4 noti/ngày chung.",
};

/** Display order, so the cards do not follow whatever order Mongo returns. */
const TYPE_ORDER = Object.keys(TYPE_LABELS) as NotificationType[];

/**
 * What each type can substitute. A wording that uses a variable with no value
 * for a given user is skipped for that user, so this is not decoration — it is
 * the difference between a wording that sends and one that never does.
 */
const TYPE_VARIABLES: Record<NotificationType, string> = {
  daily_remind: "{quote}",
  progress_finish: "{user_name}, {course_name}, {topic_name}",
  // No course name: the tap lands on the catalog, not on a course.
  progress_start: "{user_name}, {topic_name}",
  habit_tracking: "{user_name}",
  new_course: "{user_name}, {course_name}, {topic_name}",
  weekly_recap_ready: "{user_name}",
  weekly_recap_reminder: "{user_name}",
  // The reader's own words, not a lookup. Nothing else in this table is.
  coach_plan_reminder: "{context}, {action}",
  onboarding_study_reminder: "{user_name}, {course_name}",
};

/** Every destination the API accepts, with what it opens in the app. */
const DEEPLINK_LABELS: Record<NotificationDeeplink, string> = {
  home: "home — Trang chủ",
  resume_lesson: "resume_lesson — Roadmap khoá đang học dở",
  habit_tracker: "habit_tracker — Màn Thói quen",
  new_course: "new_course — Roadmap khoá mới",
  explore: "explore — Tab Khám phá (cần bản app mới)",
  week_recap: "week_recap — Poster Hành trình tuần qua (cần bản app mới)",
  coach: "coach — Sheet AI Coach (cần bản app mới)",
};

const DEEPLINK_OPTIONS = Object.keys(
  DEEPLINK_LABELS
) as NotificationDeeplink[];

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

/** One wording being edited. No `key` means the server has yet to name it. */
interface VariantDraft {
  key?: string;
  copies: NotificationCopy[];
}

interface TemplateDraft {
  localHour: string;
  localMinute: string;
  deeplink: NotificationDeeplink;
  /** Empty string = no image. One image per type, shared by every variant. */
  imageUrl: string;
  segmentIds: string[];
  variants: VariantDraft[];
}

const toVariantDrafts = (template: NotificationTemplate): VariantDraft[] => {
  if (template.variants?.length) {
    return template.variants.map((variant) => ({
      key: variant.key,
      copies: toCopyList(variant.copies),
    }));
  }
  // Saved before variants existed: its single wording becomes the first one.
  return [{ copies: toCopyList(template.copies) }];
};

const emptyVariant = (): VariantDraft => ({
  copies: LOCALES.map((locale) => ({ locale, title: "", body: "" })),
});

/** First non-empty title, for the collapsed row. */
const variantPreview = (variant: VariantDraft): string =>
  variant.copies.find((copy) => copy.title.trim() !== "")?.title ?? "";

const NotificationsPage: React.FC = () => {
  const [tab, setTab] = useState<"content" | "campaign" | "monitor">("content");

  return (
    <div className="p-6 space-y-6">
      <header className="flex items-center gap-3">
        <span className="rounded-xl bg-teal-50 p-2 text-teal-600">
          <BellAlertIcon className="h-6 w-6" />
        </span>
        <div>
          <h1 className="text-xl font-semibold text-slate-900">Thông báo định kỳ</h1>
          <p className="text-sm text-slate-500">
            Nội dung + giờ gửi của 5 loại noti, và log đã gửi. Giờ là giờ địa
            phương của từng user; tối đa 4 noti/ngày/user (2a và 2b loại trừ
            nhau nên không ai nhận cả hai).
          </p>
        </div>
      </header>

      <nav className="flex gap-2 border-b border-slate-200">
        {(
          [
            ["content", "Nội dung & lịch"],
            ["campaign", "Gửi thủ công"],
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

      {tab === "content" ? <ContentSection /> : null}
      {tab === "campaign" ? <NotificationCampaignSection /> : null}
      {tab === "monitor" ? <MonitorSection /> : null}
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
  const [drafts, setDrafts] = useState<Record<string, TemplateDraft>>({});
  /**
   * Which type is mid-upload — a single value, not a set: the field is one file
   * input per card and only one card can be uploading at a time in practice, and
   * a set would let a stale entry keep Save disabled forever.
   */
  const [uploadingType, setUploadingType] = useState<NotificationType | null>(
    null,
  );
  // Keyed `<type>:<index>`. Seven wordings across eight locales is 56 inputs per
  // type, so everything but the first starts closed.
  const [openVariants, setOpenVariants] = useState<Record<string, boolean>>({});

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const list = await notificationService.getTemplates();
      const ordered = [...list].sort(
        (left, right) =>
          TYPE_ORDER.indexOf(left.type) - TYPE_ORDER.indexOf(right.type)
      );
      setTemplates(ordered);
      setDrafts(
        Object.fromEntries(
          ordered.map((template) => [
            template.type,
            {
              localHour: String(template.localHour ?? 0),
              localMinute: String(template.localMinute ?? 0),
              deeplink: template.deeplink,
              imageUrl: template.imageUrl ?? "",
              segmentIds: template.segmentIds ?? [],
              variants: toVariantDrafts(template),
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

  const updateVariants = (
    type: NotificationType,
    change: (variants: VariantDraft[]) => VariantDraft[]
  ) =>
    setDrafts((prev) => ({
      ...prev,
      [type]: { ...prev[type], variants: change(prev[type]?.variants ?? []) },
    }));

  // Loaded once for the whole page and shared by every type's picker — the same
  // shape Home banner / Home popup use for their own targeting.
  const [segments, setSegments] = useState<SegmentOption[]>([]);

  useEffect(() => {
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
        // Targeting is optional: a failed segment list must not block editing
        // wording or send times, so the picker just stays empty.
      }
    })();
  }, []);

  const save = async (template: NotificationTemplate, enabled?: boolean) => {
    const draft = drafts[template.type];

    // Locales left completely empty are dropped rather than saved as blanks — an
    // empty title would push a notification with no text.
    const variants = (draft?.variants ?? [])
      .map((variant) => ({
        ...(variant.key ? { key: variant.key } : {}),
        copies: variant.copies.filter(
          (copy) => copy.title.trim() !== "" || copy.body.trim() !== ""
        ),
      }))
      .filter((variant) => variant.copies.length > 0);

    if (variants.length === 0) {
      setMessage("Cần ít nhất 1 biến thể có nội dung");
      return;
    }
    const dropped = (draft?.variants?.length ?? 0) - variants.length;

    setSavingType(template.type);
    setMessage("");
    try {
      await notificationService.updateTemplate(template.type, {
        enabled: enabled ?? template.enabled,
        localHour: Number(draft?.localHour ?? template.localHour),
        localMinute: Number(draft?.localMinute ?? template.localMinute ?? 0),
        deeplink: draft?.deeplink ?? template.deeplink,
        // Always sent, including as "": the empty string is how the screen
        // removes the image, the same way [] clears targeting below.
        imageUrl: (draft?.imageUrl ?? template.imageUrl ?? "").trim(),
        // Always sent, including as []: that empty array is how the screen
        // clears targeting and goes back to everybody.
        segmentIds: draft?.segmentIds ?? template.segmentIds ?? [],
        variants,
      });
      setMessage(
        `Đã lưu ${TYPE_LABELS[template.type]}` +
          (dropped > 0 ? ` (bỏ ${dropped} biến thể trống)` : "")
      );
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
        <TestSendBox templates={templates} />
        {message && (
          <span className="text-xs text-slate-600">{message}</span>
        )}
      </div>

      {templates.map((template) => {
        const draft = drafts[template.type];
        const variants = draft?.variants ?? [];
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
                {TYPE_HINTS[template.type] && (
                  <p className="text-xs text-slate-500">
                    {TYPE_HINTS[template.type]}
                  </p>
                )}
                <label className="mt-1 flex items-center gap-2 text-xs text-slate-700">
                  <span className="font-medium">Deep link</span>
                  <select
                    value={draft?.deeplink ?? template.deeplink}
                    onChange={(e) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [template.type]: {
                          ...prev[template.type],
                          deeplink: e.target.value as NotificationDeeplink,
                        },
                      }))
                    }
                    className="rounded-lg border border-slate-200 px-2 py-1.5 text-sm"
                    aria-label="Deep link"
                  >
                    {DEEPLINK_OPTIONS.map((value) => (
                      <option key={value} value={value}>
                        {DEEPLINK_LABELS[value]}
                      </option>
                    ))}
                  </select>
                </label>
                <div className="mt-2 max-w-xl">
                  <Autocomplete
                    multiple
                    size="small"
                    options={segments}
                    value={(draft?.segmentIds ?? template.segmentIds ?? []).map(
                      (id) =>
                        segments.find((s) => s._id === id) ?? {
                          _id: id,
                          name: id,
                        },
                    )}
                    onChange={(_, selected) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [template.type]: {
                          ...prev[template.type],
                          segmentIds: selected.map((s) => s._id),
                        },
                      }))
                    }
                    isOptionEqualToValue={(a, b) => a._id === b._id}
                    getOptionLabel={(s) => s.name}
                    renderInput={(params) => (
                      <TextField
                        {...params}
                        label="Chỉ gửi cho các phân khúc user"
                        helperText="Bỏ trống = gửi cho mọi người. Khớp BẤT KỲ phân khúc nào được chọn. Nhớ bấm Lưu thay đổi."
                      />
                    )}
                  />
                </div>
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
                    aria-label="Giờ gửi"
                  />
                  <span className="text-slate-400">:</span>
                  <input
                    type="number"
                    min={0}
                    max={59}
                    value={draft?.localMinute ?? ""}
                    onChange={(e) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [template.type]: {
                          ...prev[template.type],
                          localMinute: e.target.value,
                        },
                      }))
                    }
                    className="w-16 rounded-lg border border-slate-200 px-2 py-1.5 text-sm"
                    aria-label="Phút gửi"
                  />
                </label>
                <ToggleSwitch
                  checked={template.enabled}
                  onChange={(checked) => void save(template, checked)}
                  label={template.enabled ? "Đang bật" : "Đang tắt"}
                  disabled={
                    savingType === template.type ||
                    uploadingType === template.type
                  }
                />
              </div>
            </div>

            <p className="mt-3 text-xs text-slate-500">
              {variants.length > 1
                ? `${variants.length} biến thể — mỗi ngày chọn ngẫu nhiên 1, không trùng 3 ngày gần nhất của cùng user. `
                : ""}
              Biến dùng được: <code>{TYPE_VARIABLES[template.type]}</code>. Câu
              nào chứa biến không có giá trị cho user đó sẽ bị bỏ qua, không gửi
              kèm chữ trong ngoặc.
            </p>

            <div className="mt-3 space-y-2">
              {variants.map((variant, variantIndex) => {
                const openKey = `${template.type}:${variantIndex}`;
                const isOpen = openVariants[openKey] ?? variantIndex === 0;
                const preview = variantPreview(variant);
                return (
                  <div
                    key={variant.key ?? `new-${variantIndex}`}
                    className="rounded-xl border border-slate-200"
                  >
                    <div className="flex items-center gap-2 px-3 py-2">
                      <button
                        type="button"
                        onClick={() =>
                          setOpenVariants((prev) => ({
                            ...prev,
                            [openKey]: !isOpen,
                          }))
                        }
                        aria-expanded={isOpen}
                        className="flex min-w-0 flex-1 items-center gap-2 text-left"
                      >
                        {isOpen ? (
                          <ChevronDownIcon className="h-4 w-4 shrink-0 text-slate-400" />
                        ) : (
                          <ChevronRightIcon className="h-4 w-4 shrink-0 text-slate-400" />
                        )}
                        <span className="shrink-0 text-sm font-medium text-slate-800">
                          Biến thể {variantIndex + 1}
                        </span>
                        <code className="shrink-0 rounded bg-slate-100 px-1.5 py-0.5 text-xs text-slate-500">
                          {variant.key ?? "mới"}
                        </code>
                        <span className="truncate text-xs text-slate-500">
                          {preview || "chưa có nội dung"}
                        </span>
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          if (
                            !window.confirm(
                              `Xoá biến thể ${variantIndex + 1}? Nội dung sẽ mất khi bấm Lưu thay đổi.`
                            )
                          )
                            return;
                          updateVariants(template.type, (list) =>
                            list.filter((_, index) => index !== variantIndex)
                          );
                        }}
                        aria-label={`Xoá biến thể ${variantIndex + 1}`}
                        className="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>

                    {isOpen && (
                      <div className="space-y-2 border-t border-slate-100 p-3">
                        {variant.copies.map((copy, copyIndex) => (
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
                                updateVariants(template.type, (list) =>
                                  list.map((item, index) =>
                                    index !== variantIndex
                                      ? item
                                      : {
                                          ...item,
                                          copies: item.copies.map((entry, i) =>
                                            i !== copyIndex
                                              ? entry
                                              : { ...entry, title: e.target.value }
                                          ),
                                        }
                                  )
                                )
                              }
                              className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
                              aria-label={`Title ${copy.locale} biến thể ${variantIndex + 1}`}
                            />
                            <input
                              placeholder={`Body — ${TYPE_VARIABLES[template.type]}`}
                              value={copy.body}
                              onChange={(e) =>
                                updateVariants(template.type, (list) =>
                                  list.map((item, index) =>
                                    index !== variantIndex
                                      ? item
                                      : {
                                          ...item,
                                          copies: item.copies.map((entry, i) =>
                                            i !== copyIndex
                                              ? entry
                                              : { ...entry, body: e.target.value }
                                          ),
                                        }
                                  )
                                )
                              }
                              className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
                              aria-label={`Body ${copy.locale} biến thể ${variantIndex + 1}`}
                            />
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Ảnh của cả type, không phải của từng biến thể: biến thể là để đổi
                câu chữ, và ảnh gắn theo biến thể thì mỗi wording mới lại phải
                nhớ đính ảnh. */}
            <div className="mt-4 border-t border-slate-100 pt-4">
              <NotificationImageField
                value={draft?.imageUrl ?? template.imageUrl ?? ""}
                onChange={(imageUrl) =>
                  setDrafts((prev) => ({
                    ...prev,
                    [template.type]: { ...prev[template.type], imageUrl },
                  }))
                }
                onUploadingChange={(uploading) =>
                  setUploadingType(uploading ? template.type : null)
                }
                onError={setMessage}
                onSuccess={setMessage}
                folder="notification-template"
                label="Ảnh kèm noti (tuỳ chọn, dùng chung mọi ngôn ngữ và biến thể)"
              />
            </div>

            <div className="mt-3 flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={() => {
                  updateVariants(template.type, (list) => [
                    ...list,
                    emptyVariant(),
                  ]);
                  setOpenVariants((prev) => ({
                    ...prev,
                    [`${template.type}:${variants.length}`]: true,
                  }));
                }}
                className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
              >
                <PlusIcon className="h-4 w-4" /> Thêm biến thể
              </button>
              <button
                onClick={() => void save(template)}
                disabled={
                  savingType === template.type ||
                  uploadingType === template.type
                }
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

const TestSendBox: React.FC<{ templates: NotificationTemplate[] }> = ({
  templates,
}) => {
  const [type, setType] = useState<NotificationType>("progress_finish");
  const [variantKey, setVariantKey] = useState("");
  const [userId, setUserId] = useState("");
  const [result, setResult] = useState("");

  const variants =
    templates.find((template) => template.type === type)?.variants ?? [];

  const send = async () => {
    if (!userId.trim()) return;
    setResult("Đang gửi…");
    try {
      const response = await notificationService.sendTest(
        type,
        userId.trim(),
        variantKey || undefined
      );
      const which = response.variantKey ? ` [${response.variantKey}]` : "";
      // Server trả `failures` — mã FCM cho từng token — chứ không có `reason`.
      // Đọc nhầm field là lý do ô này xưa nay chỉ nói được "không rõ", trong
      // khi câu trả lời thật đã nằm sẵn trong response.
      const why = response.failures?.length
        ? response.failures.join(", ")
        : response.conditionMet === false
          ? "điều kiện thực tế không thỏa"
          : "không có token nào để gửi";
      setResult(
        response.sent
          ? `Đã gửi${which}${response.conditionMet === false ? " (điều kiện thực tế KHÔNG thỏa — chỉ để xem nội dung)" : ""}`
          : `Không gửi: ${why}`
      );
    } catch (error: any) {
      setResult(error?.message ?? "Lỗi gửi test");
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-2">
      <select
        value={type}
        onChange={(e) => {
          setType(e.target.value as NotificationType);
          setVariantKey("");
        }}
        className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
        aria-label="Loại noti gửi thử"
      >
        {TYPE_ORDER.map((value) => (
          <option key={value} value={value}>
            {TYPE_LABELS[value]}
          </option>
        ))}
      </select>
      <select
        value={variantKey}
        onChange={(e) => setVariantKey(e.target.value)}
        className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
        aria-label="Biến thể gửi thử"
      >
        <option value="">Biến thể: random</option>
        {variants.map((variant, index) => (
          <option key={variant.key} value={variant.key}>
            {`Biến thể ${index + 1} (${variant.key})`}
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

/**
 * Môi trường app dùng để đếm click. Cùng danh sách trang Dashboard dùng, và
 * `prod` mặc định vì đó là con số người ta thật sự muốn xem — nhưng phải cho đổi
 * được, không thì mở panel dev sẽ thấy 0 click và tưởng là hỏng.
 */
const MONITOR_APP_ENVS = ["prod", "stg", "dev"] as const;

const MonitorSection: React.FC = () => {
  const [query, setQuery] = useState<NotificationLogQuery>({ page: 1, take: 20 });
  const [appEnv, setAppEnv] = useState<string>("prod");
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
          appEnv,
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
  }, [query, appEnv]);

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
        <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-4">
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
              <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm">
                <span className="text-emerald-700">
                  {counts.sent ?? 0} đã gửi
                </span>
                <span className="text-red-600">{counts.failed ?? 0} lỗi</span>
                <span className="text-slate-500">
                  {counts.skipped ?? 0} bỏ qua
                </span>
                <span
                  className="font-medium text-sky-700"
                  title="Số lần user chạm vào noti loại này, đếm theo THỜI ĐIỂM CHẠM (không quy về đúng lần gửi)."
                >
                  {counts.clicks ?? 0} click
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {summary && (
        <p className="rounded-2xl border border-sky-200 bg-sky-50 px-4 py-3 text-xs leading-relaxed text-sky-900">
          <span className="font-semibold">Click đếm thế nào.</span> Lấy từ event
          app bắn lên khi user chạm vào noti, nên đếm theo{" "}
          <span className="font-semibold">thời điểm chạm</span>, không quy về đúng
          lần gửi — nhận push 21:00 rồi chạm 8:00 sáng hôm sau thì tính vào ngày
          hôm sau. Đọc theo tuần thì đúng, đọc từng ngày lẻ thì chỉ nên xem là xu
          hướng. Chỉ có dữ liệu từ 08/08/2026 (bản app đầu tiên bắn event này) và
          event tự xoá sau 90 ngày, nên khoảng ngày cũ hơn sẽ ra 0 click dù vẫn có
          số gửi.
        </p>
      )}

      <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-slate-200 bg-white p-4">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Môi trường (chỉ ảnh hưởng click)</span>
          <select
            value={appEnv}
            onChange={(e) => setAppEnv(e.target.value)}
            className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
          >
            {MONITOR_APP_ENVS.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </label>

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
            {TYPE_ORDER.map((value) => (
              <option key={value} value={value}>
                {TYPE_LABELS[value]}
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
                    {typeof log.meta?.variantKey === "string" && (
                      <div className="mt-1">
                        <code className="rounded bg-slate-100 px-1.5 py-0.5 text-xs text-slate-500">
                          {log.meta.variantKey}
                        </code>
                      </div>
                    )}
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
