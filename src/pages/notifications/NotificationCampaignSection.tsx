import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Autocomplete, TextField } from "@mui/material";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  PaperAirplaneIcon,
  PencilSquareIcon,
  UsersIcon,
} from "@heroicons/react/24/outline";

import NotificationImageField from "../../components/notification/NotificationImageField";
import { deeplinkService } from "../../services/deeplinkService";
import { notificationService } from "../../services/notificationService";
import { segmentService } from "../../services/segmentService";
import { IDeeplinkDestination } from "../../types/interface/deeplink.interface";
import {
  NotificationCampaign,
  NotificationCampaignSendMode,
  NotificationCampaignSendRow,
  NotificationCampaignStatus,
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

/**
 * Nhãn tiếng Việt cho tham số của đích. Khoá lạ rơi về chính tên tham số, nên
 * thêm một tham số ở API vẫn hiện ra được ngay — chỉ là chưa có nhãn đẹp.
 */
const DEEPLINK_PARAM_LABELS: Record<string, string> = {
  variant: "Biến thể paywall",
};

/** Nhãn cho từng giá trị của một tham số select. Thiếu thì hiện giá trị thô. */
const DEEPLINK_PARAM_VALUE_LABELS: Record<string, Record<string, string>> = {
  variant: {
    full: "Đầy đủ (full)",
    compact: "Gọn (compact)",
  },
};

/**
 * Đích của các loại noti CÓ LỊCH, không nằm trong danh mục deeplink.
 *
 * Chỉ `resume_lesson` được mời chọn: bốn cái còn lại chỉ có nghĩa khi bộ gửi
 * bơm thêm dữ liệu vào payload (`new_course` cần courseId, `week_recap` cần
 * recapId, `coach` cần planId) — campaign không có gì để bơm, chọn là gửi ra
 * một cú chạm rơi về Trang chủ. Vẫn giữ nhãn của chúng ở đây để một campaign cũ
 * đang mang giá trị đó còn hiện đúng tên thay vì hiện khoá trơ.
 */
const LEGACY_DEEPLINK_LABELS: Record<string, string> = {
  resume_lesson: "Roadmap khoá đang học dở",
  habit_tracker: "Thói quen",
  new_course: "Roadmap khoá mới",
  week_recap: "Poster Hành trình tuần qua",
  coach: "Sheet AI Coach",
};

/** Đích cũ duy nhất còn mời chọn — xem ghi chú trên. */
const OFFERED_LEGACY_KEYS = ["resume_lesson"];

/**
 * Môi trường app dùng để đếm CLICK. Cùng danh sách và cùng mặc định với card
 * "Theo dõi gửi" — `prod` là con số người ta thật sự muốn xem, nhưng phải cho
 * đổi được, không thì test bản dev sẽ thấy 0 click và tưởng là hỏng.
 *
 * Chỉ click bị lọc theo nó: số gửi là sổ sách của chính API, không gắn môi
 * trường nào — nên đọc bằng `dev` sẽ ra số gửi đúng nằm cạnh 0 click.
 */
const CLICK_APP_ENVS = ["prod", "stg", "dev"] as const;

/** Nhóm hiện trên dropdown cho các đích cũ. */
const LEGACY_GROUP = "Học";

/**
 * Bản app đầu tiên route được một cú CHẠM PUSH tới khoá của danh mục deeplink.
 *
 * KHÁC `minAppBuild` mà danh mục trả về: con số đó nói về LINK
 * (`meup.training/open/<key>`), đã chạy từ build 130. Đường push học danh mục
 * muộn hơn — trước bản này, một push trỏ tới `library` chỉ mở app rồi đứng im.
 * Sửa nếu bản ship thực tế muộn hơn 1.6.0+141.
 */
const PUSH_CATALOG_MIN_BUILD = 141;

/**
 * Bản app đầu tiên gắn `campaign_id` vào event `noti_tap` — dưới bản này một cú
 * chạm vẫn được đếm ở card "Theo dõi gửi" (gộp chung loại `campaign`) nhưng
 * không quy về được campaign nào, nên không hiện ở đây.
 *
 * Trùng [[PUSH_CATALOG_MIN_BUILD]] vì cùng một commit thêm cả hai; tách hằng
 * số ra để sau này một trong hai đổi thì cái kia không nói dối theo.
 */
const CLICK_MIN_BUILD = PUSH_CATALOG_MIN_BUILD;

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
 * CTR trên số NGƯỜI chạm, không phải số lần chạm: mở lại một push ba lần vẫn là
 * một người quan tâm, đếm cả ba sẽ đẩy tỷ lệ vượt 100% mà chẳng ai đổi hành vi.
 *
 * Trả chuỗi rỗng khi chưa gửi được ai — mẫu số 0 thì không có tỷ lệ nào để đọc,
 * và hiện "0%" ở dòng nháp là nói dối về một thứ chưa xảy ra.
 */
const ctrLabel = (campaign: NotificationCampaign) => {
  if (!campaign.sentCount) return "";
  const rate = ((campaign.clickedUsers ?? 0) / campaign.sentCount) * 100;
  return `${rate.toFixed(1)}%`;
};

const clickTitle = (campaign: NotificationCampaign, appEnv: string) =>
  [
    `${campaign.clicks ?? 0} lần chạm từ ${campaign.clickedUsers ?? 0} người`,
    `Môi trường app: ${appEnv}`,
    "Gắn đúng campaign qua campaign_id, nên chạm muộn mấy ngày vẫn tính về đây.",
    `Cần app từ bản 1.6.0+${CLICK_MIN_BUILD}; event xoá sau 90 ngày.`,
  ].join("\n");

/** Số click của một campaign, dán ngay sau bộ đếm gửi/lỗi/bỏ qua. */
function ClickStat({
  campaign,
  appEnv,
}: {
  campaign: NotificationCampaign;
  appEnv: string;
}) {
  const ctr = ctrLabel(campaign);
  return (
    <span className="ml-2 text-sky-700" title={clickTitle(campaign, appEnv)}>
      · click <b>{campaign.clicks ?? 0}</b>
      {ctr ? ` · CTR ${ctr}` : ""}
    </span>
  );
}

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
  const [deeplink, setDeeplink] = useState<string>("home");
  /**
   * Tham số tuỳ chọn của đích đang chọn — hiện chỉ `paywall` có một cái.
   *
   * Giữ theo TÊN tham số chứ không phải một state riêng cho `variant`: danh mục
   * đến từ API, nên thêm một tham số select ở màn khác sau này không phải sửa
   * lại chỗ này.
   */
  const [deeplinkParams, setDeeplinkParams] = useState<Record<string, string>>(
    {},
  );
  const [destinations, setDestinations] = useState<IDeeplinkDestination[]>([]);
  const [segmentIds, setSegmentIds] = useState<string[]>([]);
  const [sendMode, setSendMode] = useState<NotificationCampaignSendMode>("now");
  const [localHour, setLocalHour] = useState("20");
  const [localMinute, setLocalMinute] = useState("0");
  const [scheduledDate, setScheduledDate] = useState(todayInput());
  const [copies, setCopies] = useState(emptyCopies);
  const [imageUrl, setImageUrl] = useState("");
  const [uploadingImage, setUploadingImage] = useState(false);
  const [reach, setReach] = useState<number | null>(null);
  const [creating, setCreating] = useState(false);

  const [openSends, setOpenSends] = useState<string | null>(null);
  // Nội dung thật của campaign — chữ theo từng ngôn ngữ, ảnh, đích. Nó đã
  // nằm sẵn trong object campaign, chỉ là hàng ở trên mới hiện đúng một
  // dòng tiêu đề, nên không có cách nào xem lại thứ đã gửi đi.
  const [openCopy, setOpenCopy] = useState<string | null>(null);
  const [sends, setSends] = useState<NotificationCampaignSendRow[]>([]);

  /** Môi trường app mà cột click đang đọc — xem [[CLICK_APP_ENVS]]. */
  const [clickEnv, setClickEnv] = useState<string>("prod");

  /** Id của campaign nháp đang sửa; null = ô soạn đang ở chế độ tạo mới. */
  const [editingId, setEditingId] = useState<string | null>(null);
  const composerRef = useRef<HTMLElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCampaigns(await notificationService.listCampaigns(clickEnv));
    } catch (error: any) {
      showError(
        error?.response?.data?.message || "Không tải được danh sách campaign",
      );
    } finally {
      setLoading(false);
    }
    // showError is recreated each render by the hook.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clickEnv]);

  useEffect(() => {
    load();
  }, [load]);

  // Segment và danh mục deeplink chỉ nạp một lần: đổi môi trường đọc click
  // không được kéo theo hai request nữa.
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
        // Targeting is optional; an empty picker still lets you send to everyone.
      }
    })();
    (async () => {
      try {
        setDestinations(await deeplinkService.getDestinations());
      } catch {
        // Danh mục không tải được thì dropdown còn đúng một lựa chọn đang chọn
        // sẵn (`home`) — vẫn gửi được, chỉ là không đổi được đích.
      }
    })();
  }, []);

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

  /**
   * Đích mời chọn: mọi màn trong danh mục deeplink KHÔNG cần tham số bắt buộc,
   * cộng `resume_lesson`. Khoá cần tham số (`lesson`, `skillset-courses`) bị
   * loại vì màn này không có picker chọn khoá học/bài — chọn là gửi ra một cú
   * chạm chắc chắn rơi về Trang chủ.
   *
   * Danh mục đến từ API (`GET /deeplink/destinations`, cùng nguồn với trang Link
   * vào màn), nên thêm một màn sau này chỉ cần deploy API.
   */
  const deeplinkGroups = useMemo<
    [string, { key: string; label: string }[]][]
  >(() => {
    const byGroup = new Map<string, { key: string; label: string }[]>();
    const add = (group: string, item: { key: string; label: string }) =>
      byGroup.set(group, [...(byGroup.get(group) ?? []), item]);

    destinations
      .filter((destination) => !destination.params.some((p) => p.required))
      .forEach((destination) =>
        add(destination.group, {
          key: destination.key,
          label: destination.label,
        }),
      );
    OFFERED_LEGACY_KEYS.forEach((key) =>
      add(LEGACY_GROUP, { key, label: LEGACY_DEEPLINK_LABELS[key] ?? key }),
    );

    // Giá trị đang chọn phải luôn có mặt trong danh sách, kể cả khi danh mục
    // chưa tải được — native select không khớp option nào thì hiện ô trống và
    // operator không biết mình đang gửi đi đâu.
    const hasSelected = Array.from(byGroup.values()).some((items) =>
      items.some((item) => item.key === deeplink),
    );
    if (!hasSelected) {
      add("Đang chọn", {
        key: deeplink,
        label: LEGACY_DEEPLINK_LABELS[deeplink] ?? deeplink,
      });
    }

    // Array.from chứ không spread: tsconfig của CRA này chưa bật
    // downlevelIteration nên spread một IterableIterator là lỗi biên dịch.
    return Array.from(byGroup.entries());
  }, [destinations, deeplink]);

  const selectedDestination = useMemo(
    () => destinations.find((destination) => destination.key === deeplink),
    [destinations, deeplink],
  );

  /**
   * Tham số của đích mà màn này render được: đúng những cái TUỲ CHỌN có picker
   * `select`.
   *
   * Không phải sự lười: picker `course` / `keypoint` cần bộ chọn thực thể, và
   * chính vì màn này không có chúng mà những đích cần tham số BẮT BUỘC đã bị lọc
   * khỏi dropdown ở trên. Một `select` thì chỉ là mấy option do API khai sẵn.
   */
  const selectableParams = useMemo(
    () =>
      (selectedDestination?.params ?? []).filter(
        (param) =>
          !param.required &&
          param.picker === "select" &&
          (param.options?.length ?? 0) > 0,
      ),
    [selectedDestination],
  );

  /** Tên màn của một campaign đã tạo — danh mục trước, đích cũ sau, cuối cùng
   * là khoá trơ (campaign mang khoá mà bản admin này chưa biết). */
  const destinationLabel = useCallback(
    (key: string) =>
      destinations.find((destination) => destination.key === key)?.label ??
      LEGACY_DEEPLINK_LABELS[key] ??
      key,
    [destinations],
  );

  const filledCopies = useMemo(
    () => copies.filter((copy) => copy.title.trim() && copy.body.trim()),
    [copies],
  );
  const hasEnglish = filledCopies.some((copy) => copy.locale === "en");

  const resetComposer = useCallback(() => {
    setEditingId(null);
    setName("");
    setCopies(emptyCopies());
    setImageUrl("");
    setSegmentIds([]);
    setDeeplink("home");
    setDeeplinkParams({});
    setSendMode("now");
    setLocalHour("20");
    setLocalMinute("0");
    setScheduledDate(todayInput());
  }, []);

  /**
   * Nạp một campaign nháp vào ô soạn.
   *
   * Ô soạn nằm trên đầu trang còn nút Sửa nằm dưới danh sách, nên phải cuộn lên
   * — không thì bấm Sửa trông như không có gì xảy ra.
   */
  const startEdit = (campaign: NotificationCampaign) => {
    setEditingId(campaign._id);
    setName(campaign.name);
    setCopies(
      LOCALES.map((locale) => ({
        locale,
        title: campaign.copies?.[locale]?.title ?? "",
        body: campaign.copies?.[locale]?.body ?? "",
      })),
    );
    setImageUrl(campaign.imageUrl ?? "");
    setDeeplink(campaign.deeplink);
    setDeeplinkParams(campaign.deeplinkParams ?? {});
    setSegmentIds(campaign.segmentIds ?? []);
    setSendMode(campaign.sendMode);
    setLocalHour(String(campaign.localHour ?? 20));
    setLocalMinute(String(campaign.localMinute ?? 0));
    setScheduledDate(campaign.scheduledDate || todayInput());
    setOpenSends(null);
    composerRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  const saveEdit = async () => {
    if (!editingId) return;
    if (!name.trim()) return showError("Cần đặt tên campaign");
    if (!hasEnglish) {
      return showError(
        "Cần có bản tiếng Anh — đây là bản dự phòng cho mọi ngôn ngữ khác",
      );
    }
    setCreating(true);
    try {
      await notificationService.updateCampaign(editingId, {
        name,
        // Gửi CẢ danh sách: ngôn ngữ bị xoá trắng biến mất khỏi payload, và đó
        // đúng là cách gỡ một bản dịch khỏi campaign.
        copies: filledCopies,
        // Gửi kể cả khi rỗng: chuỗi rỗng là cách API hiểu "gỡ ảnh", còn bỏ hẳn
        // field lại có nghĩa là giữ ảnh cũ.
        imageUrl: imageUrl.trim(),
        deeplink,
        deeplinkParams,
        segmentIds,
        sendMode,
        localHour: Number(localHour),
        localMinute: Number(localMinute),
        ...(sendMode === "local_hour" ? { scheduledDate } : {}),
      });
      showSuccess("Đã lưu thay đổi");
      resetComposer();
      await load();
    } catch (error: any) {
      showError(
        error?.response?.data?.message || "Không lưu được thay đổi",
      );
    } finally {
      setCreating(false);
    }
  };

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
        imageUrl: imageUrl.trim(),
        deeplink,
        deeplinkParams,
        segmentIds,
        sendMode,
        localHour: Number(localHour),
        localMinute: Number(localMinute),
        ...(sendMode === "local_hour" ? { scheduledDate } : {}),
      });
      if (queueNow) await notificationService.queueCampaign(created._id);
      showSuccess(queueNow ? "Đã xếp hàng gửi" : "Đã lưu nháp");
      // Cố ý KHÔNG resetComposer: đích và giờ gửi được giữ lại vì campaign kế
      // tiếp thường đi cùng chỗ với campaign vừa tạo.
      setName("");
      setCopies(emptyCopies());
      // Ảnh KHÔNG được giữ lại như đích và giờ gửi: gửi lại ảnh cũ cho campaign
      // sau là cái sai người soạn không thấy cho tới khi push đã đi.
      setImageUrl("");
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
      <section
        ref={composerRef}
        className={`rounded-2xl border bg-white p-6 shadow-sm ${
          editingId ? "border-teal-400 ring-1 ring-teal-200" : "border-slate-200"
        }`}
      >
        <h3 className="mb-4 text-base font-semibold text-slate-900">
          {editingId ? "Sửa campaign nháp" : "Tạo campaign mới"}
        </h3>

        <div className="grid gap-4 md:grid-cols-2">
          <TextField
            size="small"
            label="Tên campaign (chỉ admin thấy)"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          {/* Đích và tham số của nó nằm trong CÙNG một ô của grid, xếp dọc:
              grid lấp theo hàng, nên để rời ra thì ô tham số rơi xuống dưới
              "Tên campaign" và đọc như một field của tên campaign. */}
          <div className="flex flex-col gap-4">
            <TextField
              size="small"
              select
              SelectProps={{ native: true }}
              label="Deep link"
              value={deeplink}
              onChange={(e) => {
                setDeeplink(e.target.value);
                // Đổi đích thì bỏ tham số cũ: `variant` của paywall còn sót lại
                // sau khi chuyển sang Trang chủ là một khoá vô nghĩa đi thẳng vào
                // payload push. API cũng lọc lại, đây chỉ là để ô chọn không hiện
                // một giá trị không còn thuộc về đâu.
                setDeeplinkParams({});
              }}
              helperText={
                selectedDestination
                  ? `Cần bản app build ≥ ${Math.max(
                      selectedDestination.minAppBuild,
                      PUSH_CATALOG_MIN_BUILD,
                    )}; bản cũ hơn chạm vào chỉ mở app, không báo lỗi.${
                      selectedDestination.note
                        ? ` ${selectedDestination.note}`
                        : ""
                    }`
                  : "Đích của noti có lịch — mọi bản app đang chạy đều hiểu."
              }
            >
              {deeplinkGroups.map(([group, items]) => (
                <optgroup key={group} label={group}>
                  {items.map((item) => (
                    <option key={item.key} value={item.key}>
                      {`${item.label} (${item.key})`}
                    </option>
                  ))}
                </optgroup>
              ))}
            </TextField>

            {selectableParams.map((param) => (
              <TextField
                key={param.name}
                size="small"
                select
                SelectProps={{ native: true }}
                label={DEEPLINK_PARAM_LABELS[param.name] ?? param.name}
                // Native select LUÔN hiện một option, kể cả khi value là chuỗi
                // rỗng — nên label phải luôn co lại, không thì nó nằm đè lên chữ
                // của option. MUI v7 suy `notched` của khung viền ra từ đúng prop
                // này (TextField.js:157), nên một dòng lo cả hai.
                InputLabelProps={{ shrink: true }}
                value={deeplinkParams[param.name] ?? ""}
                onChange={(e) =>
                  setDeeplinkParams((current) => {
                    const next = { ...current };
                    // Bỏ hẳn khoá thay vì để chuỗi rỗng: rỗng đi vào payload đọc
                    // như "có truyền nhưng bỏ trống", còn vắng mặt mới đúng nghĩa
                    // "không truyền" — cùng luật với buildDeeplinkUrl.
                    if (e.target.value) next[param.name] = e.target.value;
                    else delete next[param.name];
                    return next;
                  })
                }
                // Chi tiết riêng của từng đích đã nằm ở `note` trên ô Deep link;
                // câu này phải đúng với mọi tham số select, không riêng paywall.
                helperText="Bỏ trống = để app tự quyết theo cấu hình."
              >
                <option value="">Không chọn (theo cấu hình)</option>
                {(param.options ?? []).map((option) => (
                  <option key={option} value={option}>
                    {DEEPLINK_PARAM_VALUE_LABELS[param.name]?.[option] ?? option}
                  </option>
                ))}
              </TextField>
            ))}
          </div>
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
          <p className="text-xs text-slate-500">
            Biến dùng được: <code className="text-slate-700">{"{user_name}"}</code>.
            User chưa đặt tên sẽ thành <b>bạn</b> / <b>you</b> / <b>你</b> /{" "}
            <b>あなた</b> / <b>회원님</b> theo ngôn ngữ của chính bản dịch đó, đứng
            đầu câu thì viết hoa. Biến khác (<code>{"{course_name}"}</code>,{" "}
            <code>{"{quote}"}</code>…) bị từ chối khi lưu — campaign không có dữ
            liệu để điền, để lọt thì người đọc thấy nguyên dấu ngoặc nhọn.
          </p>

          {/* Ảnh đứng sau phần chữ vì nó là tuỳ chọn: người soạn không phải cuộn
              qua một ô upload để tới ô tiêu đề, thứ duy nhất bắt buộc. */}
          <div className="pt-2">
            <NotificationImageField
              value={imageUrl}
              onChange={setImageUrl}
              onUploadingChange={setUploadingImage}
              onError={showError}
              onSuccess={showSuccess}
              folder="notification-campaign"
              label="Ảnh kèm noti (tuỳ chọn, dùng chung mọi ngôn ngữ)"
            />
          </div>
        </div>

        <div className="mt-5 flex flex-wrap items-center gap-3">
          {editingId ? (
            <>
              <button
                type="button"
                disabled={creating || uploadingImage}
                onClick={saveEdit}
                className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-50"
              >
                Lưu thay đổi
              </button>
              <button
                type="button"
                disabled={creating}
                onClick={resetComposer}
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
              >
                Huỷ sửa
              </button>
              <span className="text-xs text-slate-500">
                Lưu xong bấm <b>Gửi</b> ở dòng của campaign bên dưới. Chỉ campaign
                còn ở trạng thái Nháp mới sửa được.
              </span>
            </>
          ) : (
            <>
              <button
                type="button"
                disabled={creating || uploadingImage}
                onClick={() => create(false)}
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
              >
                Lưu nháp
              </button>
              <button
                type="button"
                disabled={creating || uploadingImage}
                onClick={() => create(true)}
                className="inline-flex items-center gap-2 rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-50"
              >
                <PaperAirplaneIcon className="h-4 w-4" />
                {sendMode === "now" ? "Gửi ngay" : "Xếp hàng theo giờ user"}
              </button>
            </>
          )}
        </div>
      </section>

      {/* List */}
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-base font-semibold text-slate-900">
            Campaign đã tạo
          </h3>
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-1.5 text-xs text-slate-600">
              <span>Click từ môi trường</span>
              <select
                value={clickEnv}
                onChange={(e) => setClickEnv(e.target.value)}
                className="rounded-lg border border-slate-300 px-2 py-1.5 text-sm"
              >
                {CLICK_APP_ENVS.map((value) => (
                  <option key={value} value={value}>
                    {value}
                  </option>
                ))}
              </select>
            </label>
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
        </div>

        <p className="mb-4 rounded-xl border border-sky-200 bg-sky-50 px-3 py-2 text-xs leading-relaxed text-sky-900">
          <span className="font-semibold">Click đếm thế nào.</span> Lấy từ event
          app bắn lên khi user chạm vào push, gắn đúng campaign qua{" "}
          <code>campaign_id</code> — nên khác card "Theo dõi gửi", số này quy
          được về đúng lần gửi dù người ta chạm muộn mấy ngày.{" "}
          <span className="font-semibold">CTR</span> tính trên số NGƯỜI chạm chia
          số gửi. Chỉ app từ bản 1.6.0+{CLICK_MIN_BUILD} mới bắn kèm{" "}
          <code>campaign_id</code> và event tự xoá sau 90 ngày, nên campaign cũ
          hoặc người dùng bản cũ sẽ thiếu — đọc như con số sàn.
        </p>

        {campaigns.length === 0 ? (
          <p className="text-sm text-slate-500">
            {loading ? "Đang tải…" : "Chưa có campaign nào."}
          </p>
        ) : (
          <div className="space-y-3">
            {campaigns.map((campaign) => (
              <article
                key={campaign._id}
                className={`rounded-xl border p-4 ${
                  editingId === campaign._id
                    ? "border-teal-400 bg-teal-50/60"
                    : "border-slate-100 bg-slate-50/60"
                }`}
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
                    <ClickStat campaign={campaign} appEnv={clickEnv} />
                  </span>
                </div>

                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                  <span>
                    Đích: {destinationLabel(campaign.deeplink)}{" "}
                    <span className="text-slate-400">({campaign.deeplink})</span>
                  </span>
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
                    <>
                      <button
                        type="button"
                        disabled={busyId === campaign._id}
                        onClick={() => act(campaign._id, "queue")}
                        className="rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-teal-700 disabled:opacity-50"
                      >
                        Gửi
                      </button>
                      <button
                        type="button"
                        onClick={() => startEdit(campaign)}
                        className="inline-flex items-center gap-1 rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-white"
                      >
                        <PencilSquareIcon className="h-3.5 w-3.5" />
                        {editingId === campaign._id ? "Đang sửa" : "Sửa"}
                      </button>
                    </>
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
                  <button
                    type="button"
                    onClick={() =>
                      setOpenCopy((prev) =>
                        prev === campaign._id ? null : campaign._id
                      )
                    }
                    className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-white"
                  >
                    {openCopy === campaign._id
                      ? "Ẩn nội dung"
                      : "Xem nội dung"}
                  </button>
                </div>

                {openCopy === campaign._id ? (
                  <div className="mt-3 space-y-3 rounded-lg border border-slate-200 bg-white p-3">
                    <div className="space-y-2">
                      {LOCALES.map((locale) => {
                        const copy = campaign.copies?.[locale];
                        // Ngôn ngữ chưa soạn thì nói thẳng là chưa soạn: người
                        // đọc thuộc locale đó nhận bản `en` (server tự rơi về),
                        // và đó là điều cần thấy chứ không phải một dòng trống.
                        if (!copy?.title && !copy?.body) {
                          return (
                            <div
                              key={locale}
                              className="rounded-md bg-slate-50 px-3 py-2 text-xs text-slate-400"
                            >
                              <span className="font-mono font-semibold uppercase">
                                {locale}
                              </span>{" "}
                              — chưa soạn, sẽ dùng bản <b>en</b>
                            </div>
                          );
                        }

                        return (
                          <div
                            key={locale}
                            className="rounded-md border border-slate-200 px-3 py-2"
                          >
                            <div className="mb-1 font-mono text-[10px] font-semibold uppercase text-slate-400">
                              {locale}
                            </div>
                            <div className="text-sm font-semibold text-slate-900">
                              {copy.title || "—"}
                            </div>
                            {/* `whitespace-pre-wrap`: nội dung noti có xuống
                                dòng thật, cắt hết đi thì không còn là thứ
                                người dùng sẽ thấy. */}
                            <div className="whitespace-pre-wrap text-sm text-slate-600">
                              {copy.body || "—"}
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    <div className="flex flex-wrap items-start gap-4 border-t border-slate-100 pt-3 text-xs text-slate-500">
                      <div>
                        <div className="font-semibold text-slate-700">Đích</div>
                        <div>
                          {destinationLabel(campaign.deeplink)}{" "}
                          <span className="text-slate-400">
                            ({campaign.deeplink})
                          </span>
                        </div>
                        {campaign.deeplinkParams &&
                        Object.keys(campaign.deeplinkParams).length > 0 ? (
                          <div className="font-mono text-[11px] text-slate-400">
                            {Object.entries(campaign.deeplinkParams)
                              .map(([key, value]) => `${key}=${value}`)
                              .join(" · ")}
                          </div>
                        ) : null}
                      </div>
                      <div>
                        <div className="font-semibold text-slate-700">Ảnh</div>
                        {campaign.imageUrl ? (
                          <div className="flex items-center gap-2">
                            <img
                              src={campaign.imageUrl}
                              alt=""
                              className="h-12 w-12 rounded border border-slate-200 object-cover"
                            />
                            <span className="max-w-[320px] break-all font-mono text-[11px] text-slate-400">
                              {campaign.imageUrl}
                            </span>
                          </div>
                        ) : (
                          <div>Không có — noti chỉ có chữ</div>
                        )}
                      </div>
                    </div>
                  </div>
                ) : null}

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
